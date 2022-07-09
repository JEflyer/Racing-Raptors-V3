//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./ERC721A/IERC721A.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Marketplace {

    enum SaleType {
        FixedSale,
        Auction
    }

    struct SaleDetails {
        uint16 tokenId;
        uint8 minterIndex;
        SaleType saleType;
        uint256 buyPrice;
        uint256 minAuctionPrice;
        uint256 currentAuctionPrice;
        address seller;
        address currentHighestBidder;
        uint32 timeSaleEnds;
        bool active;
    }

    uint256 private saleID;

    mapping(uint256 => SaleDetails) private saleDetails;

    mapping(uint16 => mapping(uint8 => uint256)) private latestSaleID;

    IERC721A private minter1;
    IERC721A private minter2;

    IERC20 private token;

    uint256 private feePercent;

    address private admin;

    mapping(address => uint256) private refunds;    

    constructor(
        address _minter1,
        address _minter2,
        uint256 _feePercent,
        address _token
    ){
        minter1 = IERC721A(_minter1);
        minter2 = IERC721A(_minter2);

        feePercent = _feePercent;

        token = IERC20(_token);

        admin = msg.sender;
    }

    modifier onlyAdmin{
        require(msg.sender == admin, "ERR:NA");//NA => Not Admin
        _;
    }

    function changeAdmin(address _new) external onlyAdmin {
        admin = _new;
    } 

    function setFeePercent(uint256 _new) external onyAdmin {
        feePercent = _new;
    }


    function createSale(uint16 _tokenId, uint8 _minterIndex,SaleType _type, uint256 _price, uint32 _lengthOfSale) external {

        require(uint(_type) < 2, "ERR:WT");//WT => Wrong Type

        require(_price > 0, "ERR:ZP");//ZP => Zero Price

        address caller = msg.sender;

        if(_minterIndex == 0){
            require(minter1.ownerOf(uint256(_tokenId)) == caller, "ERR:NO");//NO => Not Owner

            require(minter1.getApproved(_tokenId) == address(this),"ERR:NA");//NA => Not Approved

            minter1.transferFrom(caller, address(this), _tokenId);
        
        }else if (_minterIndex == 1){
            require(minter2.ownerOf(uint256(_tokenId)) == caller, "ERR:NO");//NO => Not Owner
        
            require(minter2.getApproved(_tokenId) == address(this),"ERR:NA");//NA => Not Approved

            minter2.transferFrom(caller, address(this), _tokenId);        
        
        }else {
            revert("Minter index out of bounds");
        }


        uint256 saleId = ++saleID;

        latestSaleID[_tokenId][_minterIndex] = saleId;

        if(uint(_type) == 0){
            
            saleDetails[saleId] = SaleDetails({
                tokenId: _tokemId;
                minterIndex: _minterIndex;
                saleType: _type;
                buyPrice: _price;
                minAuctionPrice: 0;
                currentAuctionPrice: 0;
                seller: caller;
                currentHighestBidder: address(0);
                timeSaleEnds: block.timestamp + _lrngthOfSale;
                active: true;
            })
        }else if(uint(_type) == 1){
            
            saleDetails[saleId] = SaleDetails({
                tokenId: _tokemId;
                minterIndex: _minterIndex;
                saleType: _type;
                buyPrice: 0;
                minAuctionPrice: _price;
                currentAuctionPrice: 0;
                seller: caller;
                currentHighestBidder: address(0);
                timeSaleEnds: block.timestamp + _lrngthOfSale;
                active: true;
            })
        }


    }

    function buyItem(uint256 _saleID, uint256 _value) external {

        SaleDetails storage details = saleDetails(_saleID);        

        address caller = _msgSender();

        uint256 amountApproved = token.allowance(caller, address(this));
        require(amountApproved >= details.buyPrice ,"ERR:AA");//AA => Approved Amount

        require(uint8(details.saleType) == 0, "ERR:ST");//ST => Sale Type

        token.transferFrom(caller,details.seller,details.buyPrice);

        if(details.minterIndex == 0){
            minter1.transferFrom(address(this),caller,details.tokenId);
        }else if(details.minterIndex == 1) {
            minter2.transferFrom(address(this),caller,details.tokenId);
        }

        delete details.active;
    }

    function bidOnItem(uint256 _saleID, uint256 _value) external {
        
        SaleDetails storage details = saleDetails(_saleID);        

        address caller = _msgSender();
        
        uint256 amountApproved = token.allowance(caller, address(this));
        
        if(details.currentAuctionPrice != 0){
            require(amountApproved > details.currentAuctionPrice, "ERR:LB");//LB => Low Balling
        }else {
            require(amountApproved >= details.minAuctionPrice, "ERR:LB");//LB => Low Balling
        }
        
        require(amountApproved >= _value,"ERR:AA");//AA => Approved Amount
        
        token.transferFrom(caller,address(this), _value);

        if(details.currentHighestBidder != address(0)){
            token.transferFrom(address(this), details.currentHighestBidder, details.currentAuctionPrice);
        }

        details.currentHighestBidder = caller;
        details.currentAuctionPrice = _value;
    }

    function claimNFT(uint256 _saleID) external {
        SaleDetails storage details = saleDetails(_saleID);        

        address caller = _msgSender();

        require(details.timeSaleEnds <= block.timestamp, "ERR:NO");

        require(details.currentHighestBidder == caller, "ERR:DW");//DW => Didn't Win

        if(details.minterIndex == 0){
            minter1.transferFrom(address(this),caller,details.tokenId);
        }else if(details.minterIndex == 1) {
            minter2.transferFrom(address(this),caller,details.tokenId);
        }

        token.transferFrom(address(this),details.seller,details.currentAuctionPrice);

        delete details.active;
    }

}