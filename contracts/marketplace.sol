//This is the License speciified for this contract. I chose MIT as opensource, if you would like to use this contract you can do so.
//SPDX-License-Identifier: MIT

//Security consideration - Specify exact solidity version to avoid incompatibility bugs between different versions
pragma solidity 0.8.15;

//Import the interface for ERC721A
import "./ERC721A/IERC721A.sol";

//Import the interface for ERC20
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICoin.sol";

import "./interfaces/IRate.sol";
import "./interfaces/IStats.sol";

//Imported the context library for safe usage of msg.sender
import "@openzeppelin/contracts/utils/Context.sol";

contract Marketplace is Context{

    error NullArray();
    error NullAddress();
    error NullNumber();
    error WrongSaleType();

    //Fixed Sale - Lister set a buy now price
    //Auction - Lister set a minimum auction price
    enum SaleType {
        FixedSale,
        Auction
    }
    


    //tokenId => This is the token ID of the token for sale
    //minterIndex => This is a choice of either minter A or minter B
    //saleType => This is a choice of FixedSale or Auction
    //buyPrice => This is the price that the NFT can be bought for. If the saleType is Auction then this value will equal 0
    //minAuctionPrice => This is the minimum price that the NFT bidding can start at
    //currentAuctionPrice => This is the current bidding price for the NFT. If there are no bids then this value will equal 0
    //seller => This is the address of the seller/ lister of the NFT
    //currentHighestBidder => This is the address of the bidder who has currently bid the most. If no one has bid this will equal address(0)
    //timeSaleEnds => This is the time upon which the sale ends & the winner or owner can collect the NFT back
    //active => This stores wether the sale is currently active or wether it has finished 
    struct SaleDetails {
        address seller;
        address currentHighestBidder;
        SaleType saleType;
        uint256 buyPrice;
        uint256 minAuctionPrice;
        uint256 currentAuctionPrice;
        uint32 timeSaleEnds;
        uint16 tokenId;
        uint8 minterIndex;
        bool active;
    }


    //Stores the details regarding a sale 
    mapping(uint256 => SaleDetails) private saleDetails;

    //Stores the latest sale id for a token ID & MinterIndex
    mapping(uint16 => mapping(uint8 => uint256)) private latestSaleID;

    //Stores instances of the ERC721A contracts
    IERC721A[] private minters;

    //Define the interface for raptor coin
    ICoin private token;

    IStats private stats;

    //Stores the address of the admin of this contract
    address private admin;

    address private rate;

    //Stores the percentage of each transaction amount that will be burned 
    uint256 private feePercent;

    //Stores the latest saleID 
    uint256 private saleID;

    uint256 private numberOfRaptorsSold;

    uint256 private averageResalePrice;


    //_minter1 => This is the address of the first minter
    //_minter2 => This is the address of the second minter
    //_feePercent => This is the percentage of each sale that will be burned
    //_token => This is the address of raptor coin
    constructor(
        address[] _minters,
        uint256 _feePercent,
        address _token,
        address _rate,
        address _stats
    ){

        if(_minters.length == 0) revert NullArray();

        IERC721A[] memory interfaces;

        for(uint256 i = 0; i < _minters.length;){

            if(_minters[i]) revert NullAddress();

            interfaces.push(IERC721A(_minters[i]));

            unchecked{
                i++;
            }
        }

        if(_feePercent == 0) revert NullNumber();

        if(_token == address(0)) revert NullAddress();
        
        if(_rate == address(0)) revert NullAddress();
        if(_stats == address(0)) revert NullAddress();

        minters = interfaces;

        //Storing the burn percent in storage
        feePercent = _feePercent;

        //Building the ERC20 interface for the token address
        token = ICoin(_token);

        //Setting the admin as the creator of this contract
        admin = _msgSender();

        numberOfRaptorsSold = 0;

        averageResalePrice = 0;

        rate = _rate;

        stats = IStats(_stats);

    }

    //This modifier will be applied to multiple functions
    //This modifier makes sure that only the admin of this contract can call the function this modifier is attached to
    modifier onlyAdmin{

        //Check that the caller is the admin
        if(_msgSender() != admin) revert NotAdmin();//NA => Not Admin

        //This is to signify the code in the function this modifier is attached to can now run
        _;
    }

    //This function is only callable by the admin
    //This function sets a new admin
    function changeAdmin(address _new) external onlyAdmin {
        if(_new == address(0)) revert NullAddress();
        admin = _new;
    } 

    function relinquishControl() external onlyAdmin {
        delete admin;
    }

    //This function is only callable by the admin
    //This function sets the burn percentage taken on each sale
    function setFeePercent(uint256 _new) external onlyAdmin {
        if(_new == 0) revert NullNumber();
        feePercent = _new;
    }

    function update(uint256 price, uint256 burnFee) private {
        uint256 numSold = ++numberOfRaptorsSold;

        uint256 difference;

        if(averageResalePrice > price){
            difference = averageResalePrice - price;
            averageResalePrice -= (difference/numSold);
        }else{
            difference = price - averageResalePrice;
            averageResalePrice += (difference/numSold);
        }

        IRate(rate).acceptUpdateFromMarketplace(burnFee, averageResalePrice);
    }

    //Anyone can call this function
    //Creates a new listing of a sale
    //_tokenId => This is the token ID of the NFT being listed
    //_minterIndex => This is the choice of minter A or minter B
    //_type => This is the type of sale the seller is deciding on
    //_price => This is the price the seller has set
    //_lengthOfSale => This is the time in seconds that the seller would like the sale to last
    function createSale(uint16 _tokenId, uint8 _minterIndex,SaleType _type, uint256 _price, uint32 _lengthOfSale) external {

        //Check that the sale type requested is not  out of bounds
        if(uint(_type) > 2) revert WrongSaleType();//WT => Wrong Type

        //Check that the seller is not setting a zero price
        if(_price == 0) revert NullNumber();//ZP => Zero Price

        if(_lengthOfSale < 60 * 60 * 12) revert NotLongEnough();

        //Get the address of the seller
        address caller = _msgSender();

        if(caller == address(0)) revert NullAddress();

        //Define an instance of the minter
        IERC721A minter;

        if( _minterIndex > minters.length -1) {
            //Check on the stats contract if the minter index exists, returns with address if true
            address minterCheck = stats.checkMinterIndex(_minterIndex);
            
            if(minterCheck == address(0)){
                revert IncorrectMinter();
            }else {
                minters.push(IERC721A(minterCheck));
                minter = IERC721A(minterCheck);
            }

        }else {
            minter = minters[_minterIndex];
        }

        //Check that the seller is the owner of the token ID
        if(minter.ownerOf(uint256(_tokenId)) != caller) revert NotOwner();//NO => Not Owner
    
        //Check that this contract is approved to move that token
        if(minter.getApproved(_tokenId) != address(this)) revert NotApproved();//NA => Not Approved

        //Transfer the NFT from the seller to this contract
        minter.transferFrom(caller, address(this), _tokenId);  

        //Get saleID into memory & increment it before assigning it to the saleId variable
        uint256 saleId = ++saleID;

        //Store the latest sale Id for the tokenID & minterIndex 
        latestSaleID[_tokenId][_minterIndex] = saleId;

        //If Fixed Sale
        if(uint(_type) == 0){
            
            //Build new sale details
            saleDetails[saleId] = SaleDetails({
                tokenId: _tokenId,
                minterIndex: _minterIndex,
                saleType: _type,
                buyPrice: _price,
                minAuctionPrice: 0,
                currentAuctionPrice: 0,
                seller: caller,
                currentHighestBidder: address(0),
                timeSaleEnds: uint32(block.timestamp) + _lengthOfSale,
                active: true
            });
        }else if(uint(_type) == 1){//If Auction
            
            //Build new sale details
            saleDetails[saleId] = SaleDetails({
                tokenId: _tokenId,
                minterIndex: _minterIndex,
                saleType: _type,
                buyPrice: 0,
                minAuctionPrice: _price,
                currentAuctionPrice: 0,
                seller: caller,
                currentHighestBidder: address(0),
                timeSaleEnds: uint32(block.timestamp) + _lengthOfSale,
                active: true
            });
        }


    }

    //Anyone can call this function
    // _saleID => This is the sale ID that contains the details of the purchase
    // _amount => This is the amount that the purchaser is looking to pay
    function buyItem(uint256 _saleID, uint256 _amount) external {

        //Perform one SLOAD assembly function 
        SaleDetails storage details = saleDetails[_saleID];        

        //Check that sale is active
        if(!details.active) revert NotActive();//NA => Not Active

        //Check that the amount the caller is paying is greater than or equal to the buy price
        if(_amount != details.buyPrice) revert WrongValue() ;//PA => Paying Amount

        //Get the address of the purchaser
        address caller = _msgSender();

        if(caller == address(0)) revert NullAddress();

        //Get the value that the purchaser has approved this contract to spend
        uint256 amountApproved = token.allowance(caller, address(this));

        //Check that the amount approved is greater than or equal to the amount the purchaser is paying
        if(amountApproved < _amount) revert ApprovedAmount();//AA => Approved Amount

        //Check that the sale type is of type FixedSale
        if(uint8(details.saleType) != 0) revert WrongSale();//ST => Sale Type

        //Calculate the amount that will be burned
        uint256 burnAmount = details.buyPrice * feePercent / 100;

        //Transfer the receiving amount to the seller
        token.transferFrom(caller,details.seller,details.buyPrice - burnAmount);

        //Burn the burn amount
        token.BurnFrom(caller,burnAmount);

        //Transfer NFT from this contract to the purchaser 
        minter.transferFrom(address(this),caller,details.tokenId);
        
        //Delete the bool keeping track of if the sale is active or not. This by defaults sets the variable back to false & refunds gas to the caller
        delete details.active;

        update(details.buyPrice,burnAmount);
    }

    //Anyone can call this function
    // _saleID => This is the sale ID that contains the details of the purchase
    // _amount => This is the amount that the bidder is looking to pay
    function bidOnItem(uint256 _saleID, uint256 _amount) external {
        
        //Perform one SLOAD assembly function 
        SaleDetails storage details = saleDetails[_saleID];        

        if(_amount == 0) revert NullNumber();

        //Check that the sale is active
        if(!details.active) revert NotActive() ;//NA => Not Active

        //Get the address of the caller
        address caller = _msgSender();

        if(caller == address(0)) revert NullAddress();
        
        //Get the amount that the caller has approved this contract to spend
        uint256 amountApproved = token.allowance(caller, address(this));

        //Check that the amount approved is greater than or equal to the amount the purchaser is paying
        if(amountApproved < _amount) revert ApprovedAmount();//AA => Approved Amount
        
        //Check that the sale type is of type Auction
        if(uint8(details.saleType) != 1) revert WrongSale();//ST => Sale Type

        //If there has been a bidder before
        if(details.currentAuctionPrice != 0){

            //Check that the value is greater than the current bid
            if(_amount < details.currentAuctionPrice) revert LowBalling();//LB => Low Balling
        }else {

            //Otherwise check that the value is greater than or equal to the minimum auction price
            if(_amount < details.minAuctionPrice) revert LowBalling();//LB => Low Balling
        }
        
        //Burn the bidders tokens
        token.BurnFrom(caller,_amount);

        //If there has been a bidder before
        if(details.currentHighestBidder != address(0)){

            //Mint the old bidder their tokens back
            token.mint(details.currentAuctionPrice, details.currentHighestBidder);
        }

        //Set the current highest bidder to the caller
        details.currentHighestBidder = caller;

        //Set the highest auction price 
        details.currentAuctionPrice = _amount;
    }

    //This function is callable by the winner of the given sale ID
    function claimNFT(uint256 _saleID) external {

        //Perform one SLOAD assembly function 
        SaleDetails storage details = saleDetails[_saleID];       

        //Check that the sale is active
        if(!details.active) revert NotActive();//NA => Not Active

        //Get the address of the caller 
        address caller = _msgSender();

        if(caller == address(0)) revert NullAddress();

        //Check that the sale is able to be finished
        if(details.timeSaleEnds > block.timestamp) revert NotOver();//NO => Not Over

        //Check that the caller is the winner
        //At this point the check for sale type is done as if this is a fixed sale saleType then the currentHighestBidder would equal address(0)
        if(details.currentHighestBidder != caller) revert NotWinner();//DW => Didn't Win

    
        //Define an instance of the minter
        IERC721A minter;

        if( details.minterIndex > minters.length -1) {
            //Check on the stats contract if the minter index exists, returns with address if true
            address minterCheck = stats.checkMinterIndex(details.minterIndex);
            
            if(minterCheck == address(0)){
                revert IncorrectMinter();
            }else {
                minters.push(IERC721A(minterCheck));
                minter = IERC721A(minterCheck);
            }

        }else {
            minter = minters[details.minterIndex];
        }

        //Transfer the NFT to the winner
        minter.transferFrom(address(this),caller,details.tokenId);

        //Calculate the burn amount
        uint256 burnAmount = details.currentAuctionPrice * feePercent / 100;

        //Mint the receive amount to the seller
        token.mint(details.currentAuctionPrice - burnAmount, details.seller);

        //Delete the bool tracking wether the sale is active or not, setting it to false in the process & refunding gas
        delete details.active;

        update(details.currentAuctionPrice,burnAmount);

    }

    //Seller unlist item
    function unlistItem(uint256 _saleId) external {
        //Perform one SLOAD assembly function 
        SaleDetails storage details = saleDetails[_saleId];       

        //Check that the sale is active
        if(!details.active) revert NotActive();//NA => Not Active

        //Get the address of the caller 
        address caller = _msgSender();

        if(caller == address(0)) revert NullAddress();

        //Check that the seller is the caller
        if(details.seller != caller) revert NotSeller();//NS => Not Seller

        //If the sale is an auction check if there has been any bids, if so repay the bidder
        if(uint(details.saleType) == 1){
            if(details.currentAuctionPrice != 0){
                token.mint(details.currentAuctionPrice, details.currentHighestBidder);
            }
        }

        //Define an instance of the minter
        IERC721A minter;

        if( details.minterIndex > minters.length -1) {
            //Check on the stats contract if the minter index exists, returns with address if true
            address minterCheck = stats.checkMinterIndex(details.minterIndex);
            
            if(minterCheck == address(0)){
                revert IncorrectMinter();
            }else {
                minters.push(IERC721A(minterCheck));
                minter = IERC721A(minterCheck);
            }

        }else {
            minter = minters[details.minterIndex];
        }

        //Transfer the NFT back to the seller
        minter.transferFrom(address(this),caller,details.tokenId);
        
        //Delete the active bool so it turns false & refunds gas
        delete details.active;
    }

}