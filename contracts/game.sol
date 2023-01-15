//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

//import IStats interface
import "./interfaces/IStats.sol";
import "./interfaces/ICoin.sol";

//using library for the majority of internal functions as to reduce gas units used in function calls
import "./libraries/gameLib.sol";

//importing of structs as they are used in multiple file
import "./structs/stats.sol";
import "./structs/gameVars.sol";

//importing receiver so that I can block people being dumb & sending NFTs to the contract
//apparently this is a common stupidity
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

//importing so msg.sender can be replaced with _msgSender() - this is more secure
import "@openzeppelin/contracts/utils/Context.sol";

//imports for oracle usage
import "./RND.sol";

contract GameV3 is IERC721Receiver, Context, RNG {

    error MintingError();
    error NoneNeeded();
    error FailedBurn();
    error NotAdmin();
    error NullAddress();
    error InvalidChoice();
    error NullNumber();
    error NullBytes();

    error WrongRace();
    error NoSpace();
    error NotYours();
    error NotReady();
    error WrongFunds();

    //does these need an explanation?
    event NewAdmin(address admin);
    event RaceChosen(string raceType);
    event QPRandomRequested();
    event CompRandomRequested();
    event DRRandomRequested();

    //imported the following events so that events showup on the explorer correctly
    //as the events are emitted in the library & do not show otherwise
    event InjuredRaptor(uint8 minterIndex, uint16 raptor);
    event FightWinner(uint8 minterIndex, uint16 raptor);
    event Fighters(uint8[2] minterIndexes, uint16[2] fighters);
    event Top3(uint8[3] minterIndexes, uint16[3] places);
    event QuickPlayRaceStarted(uint8[8] minterIndexes, uint16[8] raptors);
    event QuickPlayRaceWinner(uint8 minterIndex, uint16 raptor);
    event CompetitiveRaceStarted(uint8[8] minterIndexes, uint16[8] raptors);
    event CompetitiveRaceWinner(uint8 minterIndex, uint16 raptor);
    event DeathRaceStarted(uint8[8] minterIndexes, uint16[8] raptors);
    event DeathRaceWinner(uint8 minterIndex, uint16 raptor);
    event RipRaptor(uint8 minterIndex, uint16 raptor);

    //wallet that controls the game
    address private admin;

    address private raptorCoin;

    //wallet that will receive 5% of the pot of each race for buying NFTs from other community projects
    // & giving these away to the community to help bring exposure to upcoming projects
    address private communityWallet;

    //an array of 8 tokenIds used for keeping track of the current list of tokens in queue
    uint16[8] public currentRaptors;

    uint8[8] public minterIndexes;

    //used to store the current balance for a race
    uint256 private pot;

    //fee storage for different races
    uint256 private QPFee;
    uint256 private CompFee;
    uint256 private DRFee;

    //enumerator for keeping track of the current race that has been set
    enum CurrentRace {
        StandBy,
        QuickPlay,
        Competitive,
        DeathRace
    }

    //used for returning a string value of the race
    string[] private raceNames = [
        "StandBy",
        "QuickPlay",
        "Competitive",
        "DeathRace"
    ];

    //instantiating a variable of the currentRace enumerator
    CurrentRace public currentRace;


    //used for keeping a track of how many raptors are currently in the queue
    uint16 private currentPosition;

    //PARAMS
    //_stats => This is the address of the stats contract
    //_communityWallet => This is the address of the multi sig contract that will be used to purchase NFTs from other projects
    //_subsciptionId => This is an ID given by chainlink so that payments can be taken
    //_vrfCoordinator => This is the address of the oracle we will be interacting with
    //_keyHash => This is something
    //_distance => This is the distance that raptors will race through
    //_fee => This is the entrance fee that users will have to pay
    //Thoughts, why don't we take the fee in raptor coin
    constructor(
        address _stats,
        address _raptorCoin,
        address _communityWallet,
        address _vrfCoordinator,
        uint64 _subscriptionId,
        bytes32 _keyHash,
        uint32 _distance,
        uint256 _fee
    ) RNG(_subscriptionId, _vrfCoordinator, _keyHash) {

        if(
            _stats == address(0)
            ||
            _raptorCoin == address(0)
            ||
            _communityWallet == address(0)
            ||
            _vrfCoordinator == address(0)
        ) revert NullAddress();

        if(
            _subscriptionId == 0
            ||
            _distance == 0
            ||
            _fee == 0
        ) revert NullNumber();

        if(_keyHash.length == 0) revert NullBytes();

        //Setting the Distance in the game library
        gameLib.setDistance(_distance);

        //Set the address of the stats contract in the game library
        gameLib.setStats(_stats);

        //Store the deployer address of the admin
        admin = _msgSender();

        //Stores the address of the community wallet
        communityWallet = _communityWallet;

        //Setting the Quick Play entrance fee to _fee
        QPFee = _fee;

        //Setting the Competitive entrance fee to _fee times 5
        CompFee = _fee * 5;

        //Setting the Death Race entrance fee to _fee times 25
        DRFee = _fee * 25;

        raptorCoin = _raptorCoin;
    }

    //This modifier checks that a caller is the admin of the contract
    modifier onlyAdmin() {
        if(_msgSender() != admin) revert NotAdmin(); //NA => Not Admin
        _;
    }

    function setAdmin(address _admin) external onlyAdmin {
        if(_admin == address(0)) revert NullAddress();
        admin = _admin;
    }

    function forceReset() external onlyAdmin {
        uint16[8] memory raptors = currentRaptors;
        uint8[8] memory indexes = minterIndexes;

        if(raptors[0] == 0 && indexes[0] == 0) revert NoneNeeded();

        uint256 fee;

        if(uint256(currentRace) == 0){
            delete minterIndexes;
            delete currentRaptors;
            delete pot;
            return;
        }else if(uint256(currentRace) == 1){
            fee = QPFee;
        }else if(uint256(currentRace) == 2){
            fee = CompFee;
        }else if(uint256(currentRace) == 3){
            fee = DRFee;
        }

        ICoin token = ICoin(raptorCoin);

        for(uint256 i = 0; i < 8;){

            address owner = gameLib.getOwner(indexes[i],raptors[i]);

            if(owner == address(0)) break;

            if(!token.mint(fee,owner)) revert MintingError();

            unchecked{
                i++;
            }
        }

        delete minterIndexes;
        delete currentRaptors;
        delete pot;

    } 

    //This function changes the distance stored in the game library
    function setDist(uint32 _new) external onlyAdmin {
        if(_new == 0) revert NullNumber();
        gameLib.setDistance(_new);
    }

    function setFee(uint256 _new) external onlyAdmin {
        if(_new == 0) revert NullNumber();
        
        //Setting the Quick Play entrance fee to _new
        QPFee = _new;

        //Setting the Competitive entrance fee to _new times 5
        CompFee = _new * 5;

        //Setting the Death Race entrance fee to _new times 25
        DRFee = _new * 25;
    }

    //Select Race only callable by admin
    function raceSelect(uint256 choice) external onlyAdmin {
        //Check that the choice is greater than zero AND is less than or equal to three
        if(choice > uint256(type(CurrentRace).max)) revert InvalidChoice();

        //Assign the new race
        currentRace = CurrentRace(choice);

        //Emit an event with the string of the racetype chose
        emit RaceChosen(raceNames[choice]);
    }

    //builds the struct of game variables to be passed to game library
    function buildVars(
        uint16[8] memory randomness,
        bool dr
    ) private returns (GameVars memory gameVars) {
        gameVars.raptors = currentRaptors;
        gameVars.minterIndexes = minterIndexes;
        gameVars.randomness = randomness;
        gameVars.dr = dr;
    }

    //pays 95% of pot to the winner & 5% to the community wallet & resets the pot var to 0
    function _payOut(
        uint256 winner,
        uint256 minterIndex,
        uint256 payout,
        uint256 communityPayout
    ) private {

        address owner = gameLib.getOwner(minterIndex, winner);

        ICoin rc = ICoin(raptorCoin);

        if(!rc.mint(payout,owner)) revert MintingError();

        if(!rc.mint(communityPayout,communityWallet)) revert MintingError();


        //Setting the pot to zero
        pot = 0;
    }

    // //returns the array of tokenIDs currently in the queue - this also returns 0 in unfilled slots
    // function getCurrentQueue() public view returns (uint16[8] memory raptors) {
    //     return currentRaptors;
    // }



    //Quickplay Entry
    function enterRaptorIntoQuickPlay(uint8 minterIndex, uint16 raptor)
        external
        returns(bool)
    {
        //check that current race is enabled
        if(uint256(currentRace) != 1) revert WrongRace(); //WR => Wrong Race

        _queue(minterIndex, raptor, QPFee);

        //if 8 entrants then start race
        if (currentPosition == 8) {
            //Request 8 random numbers with a callback limit of 1M gas
            requestRandomWords(8, 1000000);

            //Emit an event to signal that a quick play race will happen shortly
            emit QPRandomRequested();
        }

        return true;
    }

    //Competitive Entry
    function enterRaptorIntoComp(uint8 minterIndex, uint16 raptor)
        external
        returns(bool)
    {
        //check that current race is enabled
        if(uint256(currentRace) != 2) revert WrongRace(); //WR => Wrong Race

        _queue(minterIndex, raptor, CompFee);

        //if 8 entrants then start race
        if (currentPosition == 8) {
            //Request 8 random numbers with a callback limit of 1M gas
            requestRandomWords(8, 1000000);

            //Emit an event to signal that a comp race will happen shortly
            emit CompRandomRequested();
        }

        return true;
    }

    //DeathRace Entry
    function enterRaptorIntoDR(uint256 minterIndex, uint16 raptor)
        external
        returns(bool)
    {

        //check that current race is enabled
        if(uint256(currentRace) != 3) revert WrongRace(); //WR => Wrong Race

        _queue(minterIndex, raptor, DRFee);

        //if 8 entrants then start race
        if (currentPosition == 8) {
            //Request 8 random numbers with a callback limit of 1M gas
            requestRandomWords(8, 1000000);

            //Emit an event to signal that a deathrace will happen shortly
            emit DRRandomRequested();
        }

        return true;
    }

    function _queue(uint8 minterIndex, uint16 raptor, uint256 fee) private {
        //check if there are spaces left
        if(currentRaptors[7] != 0) revert NoSpace(); //NS => No Space

        //check that raptor is not on cooldown
        if(gameLib.getTime(minterIndex, raptor) > block.timestamp) revert NotReady(); //OC => On Cooldown

        //check the raptor is owned by msg.Sender
        if(!gameLib.owns(minterIndex, raptor)) revert NotYours(); //NY => Not Yours

        uint256 amountApproved = ICoin(raptorCoin).allowance(msg.sender,address(this));

        //check that msg.value is the entrance fee
        if(amountApproved < fee) revert WrongFunds(); //WF => Wrong Funds

        if(!ICoin(raptorCoin).BurnFrom(msg.sender,fee)) revert FailedBurn();

        //Put transfer block on raptor being queued

        unchecked{
            //add msg.value to pot
            pot += fee;
        }
        //add raptor to the queue
        currentRaptors[currentPosition] = raptor;

        //add the minter index to the array
        minterIndexes[currentPosition] = minterIndex;

        unchecked{
            //increment current Position
            currentPosition++;
        }

    }

    //reverts before letting a ERC721 token be sent to this contract
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        revert("Nah bro");
        return IERC721Receiver.onERC721Received.selector;
    }

    //------------------------------------Oracle functions--------------------------------------------//

    //callback function used by VRF Coordinator
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory _randomness
    ) internal override {
        //Defined a variable to store the tokenId of the winner
        uint256 winner;

        //Defined a variable to store the winning tokens minter index in the stats contract
        uint256 minterIndex;

        uint16[8] memory randomness;

        for(uint8 i = 0; i < _randomness.length;){

            randomness[i] = uint16(_randomness[i]%25000);

            unchecked{
                i++;
            }
        }

        //If the current race is quickplat
        if (uint8(currentRace) == 1) {
            //Start the game & return the winner details
            (minterIndex,winner) = gameLib._quickPlayStart(
                //Build the game variable struct to be passed to the library
                buildVars(randomness, false)
            );

            //If the current race is competitive
        } else if (uint256(currentRace) == 2) {
            //Starts the competitive race & return the winner details
            (minterIndex,winner) = gameLib._compStart(
                //Build the game variable struct to be passed into the library
                buildVars(randomness, false)
            );

            //If the current race is a death race
        } else if (uint256(currentRace) == 3) {
            //Starts the race & returns the winner details
            (minterIndex,winner) = gameLib._deathRaceStart(
                //Builds the game variable struct to be passed to the library
                buildVars(randomness, true)
            );

        }

        reset(minterIndex,winner);

    }

    function reset(uint256 minterIndex, uint256 winner) private {

        //Sets the current position to zero
        currentPosition = 0;

        //Pays out to the winner & the community multi sig contract
        _payOut(
            winner,
            minterIndex,
            pot/2,
            pot/20
        );

        //Unblock transfers for each participating raptor 
        
        //Deletes the current race
        delete currentRace;

        //Deletes the contents of the currentRaptors array
        delete currentRaptors;

        //Deletes the contents of the minterIndexed array
        delete minterIndexes;

    }
}
