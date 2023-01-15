//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

//import ERC721AQueryable
import "./ERC721A/ERC721AQueryable.sol";


import "@openzeppelin/contracts/access/Ownable.sol";

//import RND custom contract
import "./RND.sol";

//import stats interface
import "./interfaces/IStats.sol";

//import the uniswap V2 router for querying & converting funds to USD
import "./FlatRouter.sol";

//Import the minter library
import "./libraries/mainMinterLib.sol";

//Define contract
//Inherit the ERC721AQueryable & RND
contract MainMinter is ERC721AQueryable, RNG, Ownable{
    //winner declared upon full mint completion
    event Winner(address winner);

    //stored here to make sure library event is recorded in explorer correctly
    event PriceIncrease(uint256 newPrice);

    error NullAddress();
    error NullArray();
    error NullAmount();
    error NotAdmin();
    error AlreadyRevealed();
    error NullString();
    error WrongLength();
    error NullLength();
    error TotalLimit();
    error MintAmount();
    error WrongValue();
    error StatsInitializationFailed();
    error ApprovedAmount();
    error FailedTransfer();
    error NotStatContract();

    //Stores the made interface of the stats contract
    //This variable is private because it is not needed to be retreived from the contract
    IStats private stats;

    address[] public allowedUSDTokens;

    //Stores the addresses of the wallets that minting fees will be divided between
    //This variable is private because it is not needed to be retreived from the contract
    address[] private payees;

    //Stores the amounts that the minting fees will be split up into
    //This variable is private because it is not needed to be retreived from the contract
    uint16[] private shares;

    uint16 private totalShares;

    //Stores the limit of NFTs that can be minted
    //This variable is private because it is not needed to be retreived from the contract
    uint256 private totalLimit;

    //Stores the current price to mint a NFT in wei
    //This variable is private because there is a function to retreive it from the contract
    uint256 private currentPrice;


    mapping(uint256 => bool) private isFoundingRaptor;

    //metadata URI vars
    //These variables are private because they are not needed to be retreived from the contract
    string private baseURI = "https://mrhemp.pinata.cloud/ipfs/";
    string private ciD = "Some CID/";
    string private extension = ".JSON";
    string private notRevealed = "NotRevealed Hash";

    //Stores whether the NFT images have been revealed or not
    //This variable is private because it is not needed to be retreived from the contract
    bool private revealed;

    //bool used to keep track of if sale is active or not
    //This variable is private because it is not needed to be retreived from the contract
    bool private active;

    //Params
    //subscriptionId => This is used for tracking & paying for oracle calls
    //vrfCoordinator => This is the address that we will be requesting random numbers from
    //keyHash => This is something
    //name => The name the ERC721 token tracker will show on the explorer
    //symbol => The symbol the ERC721 token tracker will show on the explorer
    //stats => The address of the stats contract
    constructor(
        uint64 _subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash,
        string memory _name,
        string memory _symbol,
        address _stats,
        address[] memory _usdTokens
    )
        //Initializing the ERC721A contract
        ERC721A(_name, _symbol)
        //
        //Initializing the custom Oracle contract
        RNG(_subscriptionId, _vrfCoordinator, _keyHash)
        Ownable()
    {
        if(
            _vrfCoordinator == address(0) ||
            _stats == address(0)
        ) revert NullAddress();

        if(
            bytes(_name).length == 0 ||
            bytes(_symbol).length == 0 
        ) revert NullString();

        for(uint256 i = 0; i < _usdTokens.length;){

            if(_usdTokens[i] == address(0)) revert NullAddress();

            unchecked{
               i++; 
            }
        }

        //Set the current price to 20 USD
        currentPrice = 20000000;

        //Declaring the total limit to equal 10k
        totalLimit = 5000;

        //Defining the stats contract to communicate with
        stats = IStats(_stats);

        //Assign the address of the usd token we are using
        allowedUSDTokens = _usdTokens;

    }

    modifier NotNullString(string memory str){
        if(bytes(str).length == 0) revert NullString();
        _;
    }

    //-------------------------ADMIN FUNCTIONS -------------------------//
    function reveal() external onlyOwner {

        //Check that the CID is not already revealed
        if(revealed) revert AlreadyRevealed();

        //Reveal the actual tokenURIs
        revealed = true;
    }

    function setBaseURI(string memory base) external NotNullString(base) onlyOwner {

        //Set the base URI
        baseURI = base;
    }

    function setCID(string memory cid) external NotNullString(cid) onlyOwner {

        //Set the CID
        ciD = cid;
    }

    function setNotRevealed(string memory not) external NotNullString(not) onlyOwner {

        //Set the not revealed URI
        notRevealed = not;
    }

    function flipSaleState(bool state) external onlyOwner {
        //Pause or unpause the contract
        active = state;
    }

    //This function updates the addresses that are receving the USD from minting
    //These payee addresses other than the teams payout address is going to be event or time dependant contracts 
    function updateSplit(address[] memory _payees, uint16[] memory _shares)
        external
        onlyOwner
    {
        //Check that the arrays are the same size
        if(_payees.length != _shares.length) revert WrongLength(); 

        //Check that the arrays are not empty
        if (_payees.length == 0) revert NullLength();

        uint16 total = 0;

        //Check that the sum of all shares do not exceed the maximum number a uint16 can hold 
        //Because the addition happens out of the unchecked box it is being checked by safe math already 
        for(uint256 i = 0; i < _shares.length;){

            total += _shares[i];

            if(_shares[i] == 0) revert NullAmount(); 

            //Check that the receiving addresses are not equal to address(0)
            if(_payees[i] == address(0)) revert NullAddress();

            unchecked{
                i++;
            }
        }

        totalShares = total;

        //Assing the new payees
        payees = _payees;

        //Assign the new shares to be split
        shares = _shares;
    }

    function setAllowedUSDAddresses(address[] memory _new) external onlyOwner {
        if(_new.length == 0) revert NullArray();

        for(uint256 i = 0; i < _new.length;){


            if(_new[i] == address(0)) revert NullAddress();

            unchecked{
                i++;
            }
        }

        allowedUSDTokens = _new;
    }

    //This function is only callable by the admin
    function reward(address[] memory receivers, uint8[] memory amounts)
        external
        onlyOwner
    {
        //Check that the arrays are the same length
        if (receivers.length != amounts.length) revert WrongLength();

        //Check that the arrays length does not equal zero
        if (receivers.length == 0) revert WrongLength();

        //Define total NFTs minted variable
        uint256 total;

        //Iterate through the addresses receiving NFTs
        for (uint256 i = 0; i < receivers.length;) {
            //Get the total NFTs Minted
            total = totalSupply();

            //Mint to address for the amount being minted
            _mint(receivers[i], amounts[i]);

            //Iterates through each tokenId being minted for this address
            for (uint256 j = total + 1; j <= total + amounts[i]; ) {
                

                //Instantiate the stats for the NFT
                bool success = stats.instantiateStats(j);

                //Check that the token was initialized correctly
                if (!success) revert StatsInitializationFailed(); //OI => On Initialisation

                //Give the token Founding Raptor privilledges
                isFoundingRaptor[j] = true;

                //Remove safe mah wrapper
                unchecked {
                    j++;
                }
            }

            //Remove safe math wrapper
            unchecked {
                i++;
            }
        }
    }

    //-------------------------ADMIN FUNCTIONS -------------------------//

    //Automatically splits USD funds between designated wallets for the designated shares
    function splitFunds(uint256 fundsToSplit,uint256 usdArrIndex) private {

        //Calculate the total shares
        uint16 total = totalShares;

        address[] memory _payees = payees;
        uint16[] memory _shares = shares;

        address usd = allowedUSDTokens[usdArrIndex];

        if(usd == address(0)) revert NullAddress();

        //Building interface of usd
        IERC20 usdToken = IERC20(usd);

        //Iterate through the shares array
        for (uint256 i = 0; i < _shares.length; ) {

            //send the split funds to each payee & check that the transfer was successful
            if(
                !usdToken.transfer(
                    _payees[i],
                    (fundsToSplit * _shares[i]) / total
                )
            ) revert FailedTransfer(); 

            //Remove the safe math wrapper
            unchecked {
                i++;
            }
        }
    }

    //This function charges in USD directly
    function mintWithUSD(uint256 amount,uint256 usdArrIndex) external {
        //Get the total supply of tokens currently minted
        uint256 total = totalSupply();

        //Check that the total minted + requested mint amount does not exceed the total limti of mintable tokens
        if (total + amount > totalLimit) revert TotalLimit(); 

        //Check that the requested mint amount is less than 10
        if(amount > 10 || amount == 0) revert MintAmount(); 

        address usd = allowedUSDTokens[usdArrIndex];

        if(usd == address(0)) revert NullAddress();

        //Build the interface
        IERC20 usdToken = IERC20(usd);

        //If the caller is not the admin address
        if (_msgSender() != owner()) {

            uint256 usdTotal = usdToken.allowance(_msgSender(),address(this));

            uint256 totalPrice = minterLib.getPrice(amount, currentPrice, uint16(total)); 

            //Check that the value sent is equal to the full USD price equivelant in matic
            if (usdTotal < totalPrice) revert WrongValue(); 

            //If the amount minted crosses 1000 mints then double the price
            if (minterLib.crossesThreshold(amount, total)) {
                currentPrice += (currentPrice / 4) ;
            }

            //Tranfering the USD from the callers wallet to this contract & checking that the transfer was successful
            if (!usdToken.transferFrom(_msgSender(), address(this), usdTotal)) revert FailedTransfer();//TH => Transfer Here

            //Send the funds to be split
            splitFunds(usdToken.balanceOf(address(this)),usdArrIndex);
        }

        //Mint the tokens to the _msgSender()
        _mint(_msgSender(), amount);

        //iterate through the amount
        for (uint256 i = total + 1; i <= total + amount; ) {
            //Call the stats contract to instantiate the raptors stats passing through the token ID & this address as the minter address
            bool success = stats.instantiateStats(uint16(i));

            //Check that the initialisation was successful
            if (!success) revert StatsInitializationFailed();

            //Removing safe math wrapper
            unchecked{
                i++;
            }
        }

        //When all tokens have been minted
        if (total == totalLimit) {
            //Request a random number specifying that we want a limit of 200k gas limit used on callback
            requestRandomWords(1, 200000);
        }
    }

    //This function will be called on VRF callback
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        virtual
        override
    {
        //Calculate the tokenID that wins the porsche
        uint256 id = (randomWords[0] % totalLimit) + 1;

        //Get the owner of that token
        address owner = ownerOf(id);

        //Emit an event declaring the winner
        emit Winner(owner);
    }



    //This function allows the burning of tokenIDs
    //This is unlikely to be called by a user directly
    //If a tokenID loses a fight in a death race it is burned
    function burn(uint256 tokenId) external virtual  {
        _burn(tokenId, true);
    }

    function burnByStats(uint256 tokenId) external virtual  {
        if(msg.sender != address(stats)) revert NotStatContract();
        _burn(tokenId, false);
    }

    //--------------INFO Gathering ---------------------//

    //Calls the minter library to calculate the price
    function getPrice(uint256 amount) public view returns (uint256 total) {
        return minterLib.getPrice(amount, currentPrice, uint16(totalSupply()));
    }

    //Getter for isFoundingRaptor maping
    function isFoundingRaptorCheck(uint256 tokenId)
        external
        view
        returns (bool)
    {
        return isFoundingRaptor[tokenId];
    }


    //--------------INFO Gathering ---------------------//

    //This function is here for security reasons
    fallback() external {}
}
