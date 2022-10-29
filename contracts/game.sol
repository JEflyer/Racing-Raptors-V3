//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

//import IStats interface
import "./interfaces/IStats.sol";

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

    //wallet that will receive 5% of the pot of each race for buying NFTs from other community projects
    // & giving these away to the community to help bring exposure to upcoming projects
    address private communityWallet;

    //an array of 8 tokenIds used for keeping track of the current list of tokens in queue
    uint16[8] private currentRaptors;

    uint8[8] private minterIndexes;

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

    //instantiates a struct of gamevariables
    GameVars private currentVars;

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
        address _communityWallet,
        uint64 _subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint32 _distance,
        uint256 _fee
    ) RNG(_subscriptionId, _vrfCoordinator, _keyHash) {
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
    }

    //This modifier checks that a caller is the admin of the contract
    modifier onlyAdmin() {
        require(_msgSender() == admin, "ERR:NA"); //NA => Not Admin
        _;
    }

    function setAdmin(address _admin) external onlyAdmin {
        admin = _admin;
    }

    //This function changes the distance stored in the game library
    function setDist(uint32 dist) public onlyAdmin {
        gameLib.setDistance(dist);
    }

    //Select Race only callable by admin
    function raceSelect(uint8 choice) public onlyAdmin {
        //Check that the choice is greater than zero AND is less than or equal to three
        require(choice > 0 && choice <= 3);

        //Assign the new race
        currentRace = CurrentRace(choice);

        //Emit an event with the string of the racetype chose
        emit RaceChosen(raceNames[choice]);
    }

    //builds the struct of game variables to be passed to game library
    function buildVars(
        uint16[8] memory raptors,
        uint16[8] memory randomness,
        bool dr
    ) internal returns (GameVars memory gameVars) {
        currentVars.raptors = raptors;
        currentVars.minterIndexes = minterIndexes;
        currentVars.randomness = randomness;
        currentVars.dr = dr;
        gameVars = currentVars;
    }

    //pays 95% of pot to the winner & 5% to the community wallet & resets the pot var to 0
    function _payOut(
        uint16 winner,
        uint8 minterIndex,
        uint256 payout,
        uint256 communityPayout
    ) internal {
        //Transfering the payout to the winner
        (bool success, ) = gameLib.getOwner(minterIndex, winner).call{
            value: payout
        }("");

        //Checking that the transfer was successful
        require(success, "ERR:PW"); //PW => Paying Winmer

        //Transferring the communityPayout to the community multisig contract
        (bool success2, ) = communityWallet.call{value: communityPayout}("");

        //Checking that the transfer was successful
        require(success2, "ERR:PC"); //PC => Paying Community Wallet

        //Setting the pot to zero
        pot = 0;
    }

    //returns the array of tokenIDs currently in the queue - this also returns 0 in unfilled slots
    function getCurrentQueue() public view returns (uint16[8] memory raptors) {
        return currentRaptors;
    }

    //Quickplay Entry
    function enterRaptorIntoQuickPlay(uint8 minterIndex, uint16 raptor)
        public
        payable
    {
        //check that current race is enabled
        require(uint256(currentRace) == 1, "ERR:WR"); //WR => Wrong Race

        //check if there are spaces left
        require(currentRaptors[7] == 0, "ERR:NS"); //NS => No Space

        //check the raptor is owned by msg.Sender
        require(gameLib.owns(minterIndex, raptor), "ERR:NY"); //NY => Not Yours

        //check that raptor is not on cooldown
        require(
            gameLib.getTime(minterIndex, raptor) < block.timestamp,
            "ERR:OC"
        ); //OC => On Cooldown

        //check that msg.value is the entrance fee
        require(msg.value == QPFee, "ERR:WF"); //WF => Wrong Funds

        //add msg.value to pot
        pot += msg.value;

        //add raptor to the queue
        currentRaptors[currentPosition] = raptor;

        //add the minter index to the array
        minterIndexes[currentPosition] = minterIndex;

        //increment current Position
        currentPosition += 1;

        //if 8 entrants then start race
        if (currentPosition == 8) {
            //Request 8 random numbers with a callback limit of 1M gas
            requestRandomWords(8, 1000000);

            //Emit an event to signal that a quick play race will happen shortly
            emit QPRandomRequested();
        }
    }

    //Competitive Entry
    function enterRaptorIntoComp(uint8 minterIndex, uint16 raptor)
        public
        payable
    {
        //check that current race is enabled
        require(uint256(currentRace) == 2, "ERR:WR"); //WR => Wrong Race

        //check if there are spaces left
        require(currentRaptors[7] == 0, "ERR:NS"); //NS => No Space

        //check that raptor is not on cooldown
        require(
            gameLib.getTime(minterIndex, raptor) < block.timestamp,
            "ERR:OC"
        ); //OC => On Cooldown

        //check the raptor is owned by msg.Sender
        require(gameLib.owns(minterIndex, raptor), "ERR:NY"); //NY => Not Yours

        //check that msg.value is the entrance fee
        require(msg.value == CompFee, "ERR:WF"); //WF => Wrong Funds

        //add msg.value to pot
        pot += msg.value;

        //add raptor to the queue
        currentRaptors[currentPosition] = raptor;

        //add the minter index to the array
        minterIndexes[currentPosition] = minterIndex;

        //increment current Position
        currentPosition += 1;

        //if 8 entrants then start race
        if (currentPosition == 8) {
            //Request 8 random numbers with a callback limit of 1M gas
            requestRandomWords(8, 1000000);

            //Emit an event to signal that a comp race will happen shortly
            emit CompRandomRequested();
        }
    }

    //DeathRace Entry
    function enterRaptorIntoDR(uint8 minterIndex, uint16 raptor)
        public
        payable
    {
        //check that the stats contract has approval over this token to burn if it is to be burned
        require(gameLib.isApproved(minterIndex, raptor), "ERR:NA"); //NA => Not Approved

        //check that current race is enabled
        require(uint256(currentRace) == 3, "ERR:WR"); //WR => Wrong Race

        //check if there are spaces left
        require(currentRaptors[7] == 0, "ERR:NS"); //NS => No Space

        //check that raptor is not on cooldown
        require(
            gameLib.getTime(minterIndex, raptor) < block.timestamp,
            "ERR:OC"
        ); //OC => On Cooldown

        //check the raptor is owned by msg.Sender
        require(gameLib.owns(minterIndex, raptor), "ERR:NY"); //NY => Not Yours

        //check that msg.value is the entrance fee
        require(msg.value == DRFee, "ERR:WF"); //WF => Wrong Funds

        //add msg.value to pot
        pot += msg.value;

        //add raptor to the queue
        currentRaptors[currentPosition] = raptor;

        //add the minter index to the array
        minterIndexes[currentPosition] = minterIndex;

        //increment current Position
        currentPosition += 1;

        //if 8 entrants then start race
        if (currentPosition == 8) {
            //Request 8 random numbers with a callback limit of 1M gas
            requestRandomWords(8, 1000000);

            //Emit an event to signal that a deathrace will happen shortly
            emit DRRandomRequested();
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
        uint16 winner;

        //Defined a variable to store the winning tokens minter index in the stats contract
        uint8 minterIndex;

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
                buildVars(currentRaptors, randomness, false)
            );

            //Set the current position to zero
            currentPosition = 0;

            //Pays out funds to the winner & the community wallet
            _payOut(
                winner,
                minterIndex,
                gameLib.calcPrize(pot),
                gameLib.calcFee(pot)
            );

            //Delete the current Race variable
            delete currentRace;

            //Delete the contents of the currentRaptors array
            delete currentRaptors;

            //Delete the contents of the minterIndexes array
            delete minterIndexes;

            //Delete the contents of the current game variables
            delete currentVars;

            //If the current race is competitive
        } else if (uint256(currentRace) == 2) {
            //Starts the competitive race & return the winner details
            (minterIndex,winner) = gameLib._compStart(
                //Build the game variable struct to be passed into the library
                buildVars(currentRaptors, randomness, false)
            );

            //Set current position to zero
            currentPosition = 0;

            //Pays out the winner & the community multi sig contract
            _payOut(
                winner,
                minterIndex,
                gameLib.calcPrize(pot),
                gameLib.calcFee(pot)
            );

            //Delete the current race
            delete currentRace;

            //Delete the contents of the currentRaptors array
            delete currentRaptors;

            //Delete the contents of the minterIndexes array
            delete minterIndexes;

            //Delete the current game variable struct
            delete currentVars;

            //If the current race is a death race
        } else if (uint256(currentRace) == 3) {
            //Starts the race & returns the winner details
            (minterIndex,winner) = gameLib._deathRaceStart(
                //Builds the game variable struct to be passed to the library
                buildVars(currentRaptors, randomness, true)
            );

            //Sets the current position to zero
            currentPosition = 0;

            //Pays out to the winner & the community multi sig contract
            _payOut(
                winner,
                minterIndex,
                gameLib.calcPrize(pot),
                gameLib.calcFee(pot)
            );

            //Deletes the current race
            delete currentRace;

            //Deletes the contents of the currentRaptors array
            delete currentRaptors;

            //Deletes the contents of the minterIndexed array
            delete minterIndexes;

            //Deletes the current game variable struct
            delete currentVars;
        }
    }
}
