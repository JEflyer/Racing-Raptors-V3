//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

//import ERC721AQueryable
import "./ERC721A/ERC721AQueryable.sol";

//import reentrancy guard
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

//import ERC721 interface
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

//import RND custom contract
import "./RND.sol";

//import stats interface
import "./interfaces/IStats.sol";

//import the uniswap V2 router for querying & converting funds to USD
import "@uniswap/v2-periphery/contracts/UniswapV2Router02.sol";

//Define contract
//Inherit the ERC721AQueryable, RND, IERC721 & Reentrancy Guard
contract MainMinter is ERC721AQueryable, IERC721, ReentrancyGuard, RND {
    //winner declared upon full mint completion
    event PorscheWinner(address winner);

    //stored here to make sure library event is recorded in explorer correctly
    event PriceIncrease(uint256 newPrice);

    //Stores the made interface of the stats contract
    //This variable is private because it is not needed to be retreived from the contract
    IStats private stats;

    IUniswapV2Router02 private exchange;

    address private usd;

    address private wmatic;

    //Stores the address of the admin wallet address
    //This variable is private because it is not needed to be retreived from the contract
    address private admin;

    //Stores the addresses of the wallets that minting fees will be divided between
    //This variable is private because it is not needed to be retreived from the contract
    address[] private payees;

    //Stores the amounts that the minting fees will be split up into
    //This variable is private because it is not needed to be retreived from the contract
    uint16[] private shares;

    //Stores the limit of NFTs that can be minted
    //This variable is private because it is not needed to be retreived from the contract
    uint16 private totalLimit;

    //Stores the current price to mint a NFT in wei
    //This variable is private because there is a function to retreive it from the contract
    uint256 private currentPrice;

    //bool used to keep track of if sale is active or not
    //This variable is private because it is not needed to be retreived from the contract
    bool private active;

    mapping(uint16 => bool) private isFoundingRaptor;

    //metadata URI vars
    //These variables are private because they are not needed to be retreived from the contract
    string private baseURI = "https://mrhemp.pinata.cloud/ipfs/";
    string private ciD = "Some CID/";
    string private extension = ".JSON";
    string private notRevealed = "NotRevealed Hash";

    //Stores whether the NFT images have been revealed or not
    //This variable is private because it is not needed to be retreived from the contract
    bool private revealed;

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
        address _router,
        address _usd,
        address _wmatic
    )
        //Initializing the ERC721A contract
        ERC721A(_name, _symbol)
        //
        //Initializing the custom Oracle contract
        RNG(_subscriptionId, _vrfCoordinator, _keyHash)
    {
        //Set the current price to 5 USDT
        price = 5000000;

        //Declaring the total limit to equal 10k
        totalLimit = 10000;

        //Defining the stats contract to communicate with
        stats = IStats(_stats);

        //Building the uniswap router contract
        exchange = IUniswapV2Router02(_router);

        //Assign the address of the usd token we are using
        usd = _usd;

        //Assign the address of wrapped matic
        wmatic = _wmatic;
    }

    //A modifier is repeated code that can be attached to multiple functions
    //This modifier requires that the caller of the function is the admin of the contract
    modifier onlyAdmin() {
        require(_msgSender() == admin, "ERR:NA"); //NA => Not Admin
        _;
    }

    //-------------------------ADMIN FUNCTIONS -------------------------//
    function changeAdmin(address _new) external onlyAdmin {

        //Check that the address being set is not a zero address
        require(_nwe != address(0),"ERR:ZA");//ZA => Zero Address
        
        //Assign the new admin address
        admin = _new;
    }

    function relinquishControl() external onlyAdmin {
        //By deleting the admin it is by default address(0)
        delete admin;
    }

    function reveal() external onlyAdmin {

        //Check that the CID is not already revealed
        require(!revealed,""ERR:AR");//AR => Already Revealed

        //Reveal the actual tokenURIs
        revealed = true;
    }

    function setBaseURI(string memory base) external onlyAdmin {

        //Check that the string is not null
        require(base != "", "ERR:SM");//SM => String Message

        //Set the base URI
        baseURI = base;
    }

    function setCID(string memory cid) external onlyAdmin {

        //Check that the string is not null
        require(cid != "", "ERR:SM");//SM => String Message

        //Set the CID
        ciD = cid;
    }

    function setNotRevealed(string memory not) external onlyAdmin {

        //Check that the string is not null
        require(not != "", "ERR:SM");//SM => String Message

        //Set thye not revealed URI
        notRevealed = not;
    }

    function flipSaleState(bool state) external onlyAdmin {
        //Pause or unpause the contract
        active = state;
    }

    //This function updates the addresses that are receving the USD from minting
    //These payee addresses other than the teams payout address is going to be event or time dependant contracts 
    function updateSplit(address[] memory _payees, uint16[] memory _shares)
        external
        onlyAdmin
    {
        //Check that the arrays are the same size
        require(_payees.length == _shares.length, "ERR:WL"); //WL => Wrong length

        //Check that the arrays are not empty
        require(_payees.length != 0, "ERR:ZL"); //ZL => Zero Length

        //Assing the new payees
        payees = _payees;

        //Assign the new shares to be split
        shares = _shares;
    }

    //-------------------------ADMIN FUNCTIONS -------------------------//

    //Automatically splits USD funds between designated wallets for the designated shares
    function splitFunds(uint256 fundsToSplit) internal {

        //Calculate the total shares
        uint16 totalShares = minterLib.totalShares(shares);

        //Building interface of usd
        IERC20 memory usdToken = IERC20(usd);

        //Iterate through the shares array
        for (uint8 i = 0; i < shares.length; ) {

            //send the split funds to each payee & check that the transfer was successful
            require(
                usdToken.transfer(
                    payees[i],
                    (fundsToSplit * shares[i]) / totalShares
                ),
                "ERR:OT"
            ); //OT => On Transfer

            //Remove the safe math wrapper
            unchecked {
                i++;
            }
        }
    }

    //Function name says it all
    function convertAndSplitFunds(uint256 matic, uint256 usdValue) internal {
        
        //Build the path going from Matic to USD
        address[] memory path;
        path[0] = wmatic;
        path[1] = usd;

        //Exchange Matic for USD & send to this contract
        exchange.swapExactEthForTokens(
            amountOut,
            path,
            address(this),
            (block.timestamp + 1200)
        );

        //Get the USD balance of this contract
        uint256 usdBal = IERC20(usd).balanceOf(address(this));

        //Split the usd balance 
        splitFunds(usdBal);
    }

    //This function allows a user to mint using Matic, this is then converted to USD 
    function mintWithMatic(uint8 amount) external payable {
        //Get the total supply of tokens currently minted
        uint256 total = totalSupply();

        //Check that the total minted + requested mint amount does not exceed the total limti of mintable tokens
        require(total + amount <= totalLimit, "ERR:TL"); //TL => Total Limit

        //Check that the requested mint amount is less than 10
        require(_amount <= 10, "ERR:MA"); //MA => Mint Amount

        //If the caller is not the admin address
        if (_msgSender() != admin) {

            //Get the USD value of the matic sent
            uint256 usdValue = toUSD(msg.value);

            //Check that the value sent is equal to the full USD price equivelant in matic
            require(usdValue == getPrice(amount), "ERR:WV"); //WV => Wrong Value

            //If the amount minted crosses 1000 mints then double the price
            if (minterLib.crossesThreshold(_amount, totalMintSupply)) {
                price = price * 2;
            }

            //Send the funds to be split
            convertAndSplitFunds(msg.value,usdValue);
        }

        //Mint the tokens to the _msgSender()
        _mint(_msgSender(), amount);

        //iterate through the amount
        for (uint8 i = 0; i < amount; ) {
            //Call the stats contract to instantiate the raptors stats passing through the token ID & this address as the minter address
            bool success = stats.instantiateStats(
                uint16(total + i + 1),
                address(this)
            );

            //Check that the initialisation was successful
            require(success, "ERR:OI"); //OI => On Initialisation#

            unchecked {
                i++;
            }
        }

        //When all tokens have been minted
        if (totalMintSupply == totalLimit) {
            //Request a random number specifying that we want a limit of 200k gas limit used on callback
            requestRandomWords(1, 200000);
        }
    }

    //This function charges in USD directly
    function mintWithUSD(int8 amount) external {
        //Get the total supply of tokens currently minted
        uint256 total = totalSupply();

        //Check that the total minted + requested mint amount does not exceed the total limti of mintable tokens
        require(total + amount <= totalLimit, "ERR:TL"); //TL => Total Limit

        //Check that the requested mint amount is less than 10
        require(_amount <= 10, "ERR:MA"); //MA => Mint Amount

        //Build the interface
        IERC20 memory usdToken = IERC20(usd);

        //If the caller is not the admin address
        if (_msgSender() != admin) {

            uint256 usdTotal = getPrice(amount);
            //Check that the value sent is equal to the full USD price equivelant in matic
            require(usdToken.balanceOf(_msgSender()) >= , "ERR:IF"); //IF => Insufficient Funds

            //If the amount minted crosses 1000 mints then double the price
            if (minterLib.crossesThreshold(_amount, totalMintSupply)) {
                price = price * 2;
            }

            //Tranfering the USD from the callers wallet to this contract & checking that the transfer was successful
            require(usdToken.transferFrom(_msgSender(), address(this), usdTotal), "ERR:TH");//TH => Tranfer Here

            //Send the funds to be split
            splitFunds(usdToken.balanceOf(address(this)));
        }

        //Mint the tokens to the _msgSender()
        _mint(_msgSender(), amount);

        //iterate through the amount
        for (uint8 i = 1; i <= amount; ) {
            //Call the stats contract to instantiate the raptors stats passing through the token ID & this address as the minter address
            bool success = stats.instantiateStats(
                uint16(total + i),
                address(this)
            );

            //Check that the initialisation was successful
            require(success, "ERR:OI"); //OI => On Initialisation

            //Removing safe math wrapper
            unchecked{
                i++;
            }
        }

        //When all tokens have been minted
        if (totalMintSupply == totalLimit) {
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
        uint256 id = (randomWords[0] % 10000) + 1;

        //Get the owner of that token
        address owner = ownerOf(id);

        //Emit an event declaring the winner
        emit PorscheWinner(owner);
    }

    //This function is only callable by the admin
    function reward(address[] memory receivers, uint8[] memory amounts)
        internal
    {
        //Check that the arrays are the same length
        require(receivers.length == amounts.length, "ERR:WS");//WS => Wrong Sizes

        //Check that the arrays length does not equal zero
        require(receivers.length != 0, "ERR:WL");//Wrong Length

        //Define total NFTs minted variable
        uint256 total;

        //Iterate through the addresses receiving NFTs
        for (uint8 i = 0; i < receivers.length;) {
            //Get the total NFTs Minted
            total = totalSupply();

            //Mint to address for the amount being minted
            _mint(receivers[i], amounts[i]);

            //Iterates through each tokenId being minted for this address
            for (uint8 j = 1; j <= amounts[i]; ) {
                
                //Calculate the tokenId on each iteraton
                uint16 token = uint16(total + j);

                //Instantiate the stats for the NFT
                bool success = stats.instantiateStats(token, address(this));

                //Check that the token was initialized correctly
                require(success, "ERR:OI"); //OI => On Initialisation

                //Give the token Founding Raptor privilledges
                isFoundingRaptor[token] = true;

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

    //This function allows the burning of tokenIDs
    //This is unlikely to be called by a user directly
    //If a tokenID loses a fight in a death race it is burned
    function burn(uint256 tokenId) external virtual override {
        _burn(tokenId, true);
    }

    //--------------INFO Gathering ---------------------//

    //Calls the minter library to calculate the price
    function getPrice(uint8 amount) public view returns (uint256 total) {
        return minterLib.getPrice(amount, price, totalSupply());
    }

    //Getter for isFoundingRaptor maping
    function isFoundingRaptorCheck(uint16 tokenId)
        external
        view
        returns (bool)
    {
        return isFoundingRaptor[tokenId];
    }

    //Gets the USD value of a matic amount
    function toUSD(uint256 amount) internal returns (uint256) {

        //Build the path
        address[] memory path;
        path[0] = wmatic;
        pa[1] = usd;

        //Call the get amount out function on the uniswap router
        uint[] memory amounts = exhange.getAmountsOut(amount, path);

        //Return the second index in the array
        return amounts[1];
    }

    //--------------INFO Gathering ---------------------//

    //This function is here so that the contract can receive matic 
    receive() external payable {}

    //This function is here for security reasons
    fallback() external {}
}
