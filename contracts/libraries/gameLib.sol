//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

//imports structs used across multiple files
import "../structs/stats.sol";
import "../structs/gameVars.sol";

//imports interfaces for stats contract
import "../interfaces/IStats.sol";

library gameLib {
    //-------------------------Events-------------------------------//
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

    //-------------------------Events-------------------------------//

    //-------------------------storage----------------------------------//
    //-------------------------stats----------------------------------//
    //create a 32byte "constant" mem slot
    bytes32 constant statSlot = keccak256("statsAddress");

    //Declare a struct to store minter contract address
    struct StatStore {
        address statContract;
    }

    //Use assembly to assign the minterStore struct to the 32byte mem slot
    //Uses storage tag in return so that any changes made are made directly in the mem slot
    function statStore() internal pure returns (StatStore storage stat) {
        //define the slot
        bytes32 slot = statSlot;

        //use assembly code
        assembly {
            //Assign the return variables source
            stat.slot := slot
        }
    }

    //Gets struct & sets the address in the "constant" mem slot
    function setStats(address _stat) internal {
        //Get the storage of the statStore struct
        StatStore storage store = statStore();

        //Assign the new stat contract address
        store.statContract = _stat;
    }

    //-------------------------stats----------------------------------//
    //-------------------------distance----------------------------------//
    //same logic as above
    bytes32 constant distanceSlot = keccak256("distance");

    struct DistanceStore {
        uint32 distance;
    }

    function distanceStore()
        internal
        pure
        returns (DistanceStore storage distance)
    {
        bytes32 slot = distanceSlot;
        assembly {
            distance.slot := slot
        }
    }

    function setDistance(uint32 _distance) internal {
        DistanceStore storage store = distanceStore();
        store.distance = _distance;
    }

    //-------------------------distance----------------------------------//
    //-------------------------storage----------------------------------//

    //-------------------------Helpers-------------------------------//

    //Gets the cooldownTime from the minter contract for a given tokenID
    function getTime(uint8 minterIndex, uint16 raptor)
        internal
        view
        returns (uint64)
    {
        //Gets the storage of the minter address
        StatStore storage store = statStore();

        //Get the cooldown time for the given raptor & minter & return the time
        return IStats(store.statContract).getCooldownTime(minterIndex, raptor);
    }

    //Checks the minter contract to see if msg.sender owns  a given tokenID
    function owns(uint8 minterIndex, uint16 raptor)
        internal
        view
        returns (bool)
    {
        //Gets the storage of the minter address
        StatStore storage store = statStore();

        //Check that an address owns the token for the given minter & return a bool
        return IStats(store.statContract).owns(msg.sender, minterIndex, raptor);
    }

    //gets the owner of a given tokenID
    function getOwner(uint8 minterIndex, uint16 raptor)
        internal
        view
        returns (address)
    {
        //Gets the storage of the minter address
        StatStore storage store = statStore();

        //Retreive the owner address of a token for a given minter
        return IStats(store.statContract).ownerOf(minterIndex, raptor);
    }

    function isApproved(uint8 minterIndex, uint16 tokenId)
        internal
        view
        returns (bool)
    {
        //Gets the storage of the minter address
        StatStore storage store = statStore();

        //Check that the token for a given minterhas the stats contract approved to burn if necessary
        return IStats(store.statContract).checkApproval(minterIndex, tokenId);
    }

    //calculates 5% of the wei amount sent
    function calcFee(uint256 pool) internal pure returns (uint256 fee) {
        fee = (pool * 5) / 100;
    }

    //calculates 95% of the wei amount sent
    function calcPrize(uint256 pool) internal pure returns (uint256 prize) {
        prize = (pool / 100) * 95;
    }

    //checks that a value is between 0 & 7
    //used as a index check
    function checkBounds(uint8 input) internal pure returns (bool response) {
        (input < 8 && input >= 0) ? response = true : response = false;
    }

    //figures out what 2 raptors will fight
    function getFighters(GameVars memory gameVars)
        internal
        returns (GameVars memory)
    {
        //Pick the fighters indexes
        gameVars.fighters[0] = uint8(gameVars.randomness[0] % 8);
        gameVars.fighters[1] = uint8(gameVars.randomness[3] % 8);

        //Define a counter
        uint8 i;

        //While the indexes chosen are the same
        while (gameVars.fighters[0] == gameVars.fighters[1]) {
            //Add one to the first index
            gameVars.fighters[0] += 1;

            //Check that the index is within the boundaries
            bool check = checkBounds(gameVars.fighters[0]);

            //If the value isn't in the the boundaries
            if (!check) {
                //Set the first fighter index to a new random index
                gameVars.fighters[0] = uint8(gameVars.randomness[i] % 8);

                //Remove the safe math wrapper
                unchecked {
                    i++;
                }
            }
        }

        //Emit an event to signal the fighters in this race
        emit Fighters(
            [
                gameVars.minterIndexes[gameVars.fighters[0]],
                gameVars.minterIndexes[gameVars.fighters[1]]
            ],
            [
                gameVars.raptors[gameVars.fighters[0]],
                gameVars.raptors[gameVars.fighters[1]]
            ]
        );

        return gameVars;
    }

    //calculates which raptor wins the fight
    //if the current game is deathrace the losing raptor is burned
    //if the current game is QP or Comp the losing raptor has a added cooldown
    function getFightWinner(GameVars memory gameVars)
        internal
        returns (GameVars memory)
    {
        //Define a counter
        uint8 index;

        //If the 5th random number is even the winner is fighter 1, otherwise fihter 2 wins
        (gameVars.randomness[4] % 2 == 0)
            ? index = gameVars.fighters[0]
            : index = gameVars.fighters[1];

        // If the winner is fighter 1
        if (index == gameVars.fighters[0]) {
            //Emit an event saying that fighter 1 won
            emit FightWinner(gameVars.minterIndexes[gameVars.fighters[0]], gameVars.raptors[gameVars.fighters[0]]);

            //Assign the fight winner
            gameVars.fightWinner = gameVars.fighters[0];

            //If the current race isn't deathrace
            if (!gameVars.dr) {
                //Emit an event saying that fighter 2 is injured
                emit InjuredRaptor(gameVars.minterIndexes[gameVars.fighters[1]], gameVars.raptors[gameVars.fighters[1]]);

                //Add a cooldown to the losing rar
                addCooldownPeriod(gameVars);

                //If the current race is a death race
            } else {
                uint256 index2 = gameVars.fighters[1];
                //Burn fighter 2
                _kill(gameVars.minterIndexes[index2], gameVars.raptors[index2]);

                //Emit an event saying that fighter 2 has been killed
                emit RipRaptor(gameVars.minterIndexes[index2], gameVars.raptors[index2]);
            }

            //If the winner is fighter 2
        } else {
            //Assign the winner of the fight
            gameVars.fightWinner = gameVars.fighters[1];

            //Emit an event that fighter 2 won the fight
            emit FightWinner(gameVars.minterIndexes[gameVars.fighters[1]], gameVars.raptors[gameVars.fighters[1]]);

            //If the current race is not a death race
            if (!gameVars.dr) {
                //Add a cooldown to fighter 1
                addCooldownPeriod(gameVars);

                //Emit an event saying that fighter 1 has been injured
                emit InjuredRaptor(gameVars.minterIndexes[gameVars.fighters[0]], gameVars.raptors[gameVars.fighters[0]]);

                //Is the current race is a death race
            } else {
                //Burn the raptor
                _kill(
                    gameVars.minterIndexes[gameVars.fighters[0]],
                    gameVars.raptors[gameVars.fighters[0]]
                );

                //Emit an event saying that fighter 1 has been killed
                emit RipRaptor(gameVars.minterIndexes[gameVars.fighters[0]], gameVars.raptors[gameVars.fighters[0]]);
            }
        }
        return gameVars;
    }

    //calculates the top 3 placed raptors in the race
    //uses a element of randomness to add unpredictability to the race
    //calculates the fastest then ignores that index when calculating 2nd place
    //ignores the top 2 fastest indexes when calculating 3rd place
    function getFastest(uint8[2] memory fighters, uint32[8] memory time)
        internal
        pure
        returns (uint8[3] memory)
    {
        //Assign this value a high number
        uint16 lowest = 20000;

        //Make an array to store the placed raptors
        uint8[3] memory places;

        //Define a counter to be used in each forloop
        uint8 i = 0;

        //Iterate through the current Raptors
        for (; i < 8; ) {
            //If i does not equal the indexes of either fighter
            if (i != fighters[0] && i != fighters[1]) {
                //Check if the time that it takes for raptor at position i to finish the race is the lowest
                if (time[i] < lowest) {
                    //Assign the lowest amount of time
                    lowest = uint16(time[i]);

                    //Store the index of the winner
                    places[0] = i;
                }
            }

            //Remove the safe math wrapper
            unchecked {
                i++;
            }
        }

        //Reset the lowest time variable
        lowest = 20000;

        //Reset the counter
        i = 0;

        //Iterate through the current raptors
        for (; i < 8; ) {
            //If I does not equal the indexes of either fighter OR the winner
            if (i != fighters[0] && i != fighters[1] && i != places[0]) {
                //Check if the time that it takes for raptor at position i to finish the race is the lowest
                if (time[i] < lowest) {
                    //Assign the lowest amount of time
                    lowest = uint16(time[i]);

                    //Store the index of second place
                    places[1] = i;
                }
            }

            //Remove the safe math wrapper
            unchecked {
                i++;
            }
        }

        //Reset the lowest time variable
        lowest = 20000;

        //Reset the counter
        i = 0;

        //Iterate through the current raptors
        for (; i < 8; ) {
            //If I does not equal the indexes of either fighter OR the winner OR the 2nd place raptor
            if (
                i != fighters[0] &&
                i != fighters[1] &&
                i != places[0] &&
                i != places[1]
            ) {
                //Check if the time that it takes for raptor at position i to finish the race is the lowest
                if (time[i] < lowest) {
                    //Store the lowest time
                    lowest = uint16(time[i]);

                    //Store the index of third place
                    places[2] = i;
                }
            }

            //Remove safe math wrapper
            unchecked {
                i++;
            }
        }
        return places;
    }

    //calculates the winner & top 3 places
    function getWinner(GameVars memory gameVars)
        internal
        view
        returns (GameVars memory)
    {
        //Define the counter
        uint8 i = 0;

        //Declare an empty array of 8 values
        uint64[8] memory speed;

        //Get the stat contract address
        address stat = statStore().statContract;

        //get speed for each raptor
        for (; i < 8; i++) {
            //Retreive the speed of a raptor for it's minter
            speed[i] = IStats(stat).getSpeed(
                gameVars.minterIndexes[i],
                gameVars.raptors[i]
            );
        }

        //Reset the counter
        i = 0;

        //Declare an empty array for random values
        uint8[8] memory randomness;

        //Declare an empty array for the time it takes a raptor to finish
        uint32[8] memory time;

        //Get the distance
        uint32 distance = distanceStore().distance;

        //Iterate for the current raptors
        for (; i < 8; i++) {
            //Calculate the random value
            randomness[i] = uint8(gameVars.randomness[i] % 5);

            //Calculate the time it takes each raptor to finish the race
            time[i] = uint32(distance / (speed[i] + randomness[i]));
        }

        //Get the 3 winning raptors
        gameVars.places = getFastest(gameVars.fighters, time);
        return gameVars;
    }

    //-------------------------Helpers--------------------------------//

    //------------------------Stat-Changes------------------------------//
    // -------  +vary ----------//

    function upgradeStrength(GameVars memory gameVars) internal {
        //Get a value between or equal to 1 & 3
        uint8 rand = uint8(gameVars.randomness[4] % 3) + 1;

        //Get the address of the stat contract
        address stat = statStore().statContract;

        //Define a index
        uint8 index;

        //Figure out the index
        (gameVars.fightWinner == gameVars.fighters[0])
            ? (index = 0)
            : (index = 1);

        //Upgrade the strength stat for raptor & minter by the random value
        bool success = IStats(stat).increaseStrength(
            gameVars.minterIndexes[index],
            gameVars.raptors[gameVars.fighters[index]],
            rand
        );

        //Check that increasing the stat was successful
        require(success, "ERR:US"); //US => Upgrading Life
    }

    //upgrades the winning raptors speed stat by a value between 1 & 3
    function upgradeSpeed(GameVars memory gameVars) internal {
        //Get a value betwewn or equal to 1 & 3
        uint8 rand = uint8(gameVars.randomness[7] % 3) + 1;

        //Get the address of the stat contract
        address stat = statStore().statContract;

        //Upgrade the speed stat for raptor & minter by the random value
        bool success = IStats(stat).increaseStrength(
            gameVars.minterIndexes[gameVars.places[0]],
            gameVars.raptors[gameVars.places[0]],
            rand
        );

        //Check that increasing the speed stat was successful
        require(success, "ERR:US"); //US => Upraging Speed
    }

    // -------  +Vary ----------//

    // -------  +1 ----------//
    //increases the QP wins of the winning raptor by 1
    function increaseQPWins(GameVars memory gameVars) internal {
        //Get the address of the stat contract
        address stat = statStore().statContract;

        //Increase the number of QP wins for a raptor & minter
        bool success = IStats(stat).increaseQPRacesWon(
            gameVars.minterIndexes[gameVars.places[0]],
            gameVars.raptors[gameVars.places[0]]
        );

        //Check that the increase in the stat was successful
        require(success, "ERR:QW"); //QW => Quickplay Wins
    }

    //increases the Comp wins of the winning raptor by 1
    function increaseCompWins(GameVars memory gameVars) internal {
        //Get the address of the stat contract
        address stat = statStore().statContract;

        //Increase the number of comp wins for a raptor & minter
        bool success = IStats(stat).increaseCompRacesWon(
            gameVars.minterIndexes[gameVars.places[0]],
            gameVars.raptors[gameVars.places[0]]
        );

        //Check the increasing of the stat was successful
        require(success, "ERR:CW"); //CW => Competitive Wins
    }

    //increases the DR wins of the winning raptor by 1
    function increaseDeathRaceWins(GameVars memory gameVars) internal {
        //Get the address of the stat contract
        address stat = statStore().statContract;

        //Increase the number of death race wins for a raptor & minter
        bool success = IStats(stat).increaseDRWon(
            gameVars.minterIndexes[gameVars.places[0]],
            gameVars.raptors[gameVars.places[0]]
        );

        //Check that the increasing if the stat was successful
        require(success, "ERR:DW"); //DW => Deathrace Wins
    }

    //increases the top3finishes of the top 3 raptors by 1
    function increaseTop3RaceFinishes(GameVars memory gameVars) internal {
        //Get the address of the stat contract
        address stat = statStore().statContract;

        //Iterate through the raptors who finished top 3
        for (uint8 i = 0; i < 3; ) {
            //Upgrade the stats for a raptor & minter
            bool success = IStats(stat).increaseTop3Finishes(
                gameVars.minterIndexes[gameVars.places[i]],
                gameVars.raptors[gameVars.places[i]]
            );

            //Check that increasing the stat was successful
            require(success, "ERR:TT"); //TT => Top Three

            //Remove safe math wrapper
            unchecked {
                i++;
            }
        }
    }

    function increaseDRSurvived(GameVars memory gameVars) internal {
        //Get the address of the stat contract
        address stat = statStore().statContract;

        //Get the index of the losing fighter
        uint8 index = (gameVars.fighters[0] == gameVars.fightWinner) ? gameVars.fighters[1] : gameVars.fighters[0];

        //Iterate through the raptors
        for(uint8 i = 0; i < 8;){
            
            //If i isn't the losing fighter's index
            if(i != index){
                bool success = IStats(stat).increaseDRSurvived(
                    gameVars.minterIndexes[i],
                    gameVars.raptors[i]
                );

                //Check that increasing the stat was successful
                require(success, "ERR:DS");//DS => Deathraces Survived
            }
        }        
    }

    // -------  +1 ----------//

    // -----  +12 Hours/ Unless Founding Raptor 3 Hours -----//

    //increases the cooldown of a losing raptor in QP or comp
    //checks to see if a raptor is a rewarded raptor for V1 holders
    //if it is a rewarded raptor then the additional cooldown time is 6 hours, if it is not then it is a 12 hour cooldown
    function addCooldownPeriod(GameVars memory gameVars) internal {
        //Get the address of the stat contract
        address stat = statStore().statContract;

        //Declare a index variable
        uint8 index;

        //Figure out the index
        (gameVars.fightWinner == gameVars.fighters[0])
            ? (index = 1)
            : (index = 0);

        //Increase the cooldown time for a raptor & minter
        bool success = IStats(stat).increaseCooldownTime(
            gameVars.minterIndexes[index],
            gameVars.raptors[gameVars.fighters[index]]
        );

        //Check that increasing the stat was successful
        require(success, "ERR:SC"); //SC => Setting Cooldown
    }

    // -----  +12 Hours/ Unless Founding Raptor 6 Hours -----//
    //------------------------Stat-Changes---------------------------------//

    //-----------------------------QP--------------------------------------//

    //QP Start
    function _quickPlayStart(GameVars memory gameVars)
        internal
        returns (uint8, uint16)
    {
        //Emit an event saying that the race has started
        emit QuickPlayRaceStarted(gameVars.minterIndexes, gameVars.raptors);

        //gets fighters, finds the winner & adds both indexes to ignore for choosing race winner
        gameVars = getFighters(gameVars);
        gameVars = getFightWinner(gameVars);

        //gets the winner & next two places
        gameVars = getWinner(gameVars);

        //index 0 = winner; index 1 = second; index 2 = third
        emit Top3(
            [
                gameVars.minterIndexes[gameVars.places[0]],
                gameVars.minterIndexes[gameVars.places[1]],
                gameVars.minterIndexes[gameVars.places[2]]
            ],
            [
                gameVars.raptors[gameVars.places[0]],
                gameVars.raptors[gameVars.places[1]],
                gameVars.raptors[gameVars.places[2]]
            ]
        );

        //Increase the according stats
        handleQPStats(gameVars);

        //Emit an event with the winners tokenId
        emit QuickPlayRaceWinner(gameVars.minterIndexes[gameVars.places[0]], gameVars.raptors[gameVars.places[0]]);

        //Return the minter index & the winner tokenID
        return (gameVars.minterIndexes[gameVars.places[0]], gameVars.raptors[gameVars.places[0]]);
    }

    //Handle the stat changes
    function handleQPStats(GameVars memory gameVars) internal {

        //Increase the winners QP wins
        increaseQPWins(gameVars);

        //Increase the winners speed
        upgradeSpeed(gameVars);

        //Increase the top 3 racers top 3 finish stats
        increaseTop3RaceFinishes(gameVars);

        //Increase the fight winning raptors strength
        upgradeStrength(gameVars);
    }

    //---------------------------QP--------------------------------------//
    //----------------------------Comp-----------------------------------//

    //Comp Start
    function _compStart(GameVars memory gameVars) internal returns (uint8, uint16) {

        //Emit an event saying that the race has started
        emit CompetitiveRaceStarted(gameVars.minterIndexes, gameVars.raptors);

        //gets fighters, finds the winner & adds both indexes to ignore for choosing race winner
        gameVars = getFighters(gameVars);
        gameVars = getFightWinner(gameVars);

        //gets the winner & next two places
        gameVars = getWinner(gameVars);

        //index 0 = winner; index 1 = second; index 2 = third
        emit Top3(
            [
                gameVars.minterIndexes[gameVars.places[0]],
                gameVars.minterIndexes[gameVars.places[1]],
                gameVars.minterIndexes[gameVars.places[2]]
            ],
            [
                gameVars.raptors[gameVars.places[0]],
                gameVars.raptors[gameVars.places[1]],
                gameVars.raptors[gameVars.places[2]]
            ]
        );

        //Handles the stats for this race
        handleCompStats(gameVars);

        //Emit an event saying which raptor won the race
        emit CompetitiveRaceWinner(gameVars.minterIndexes[gameVars.places[0]], gameVars.raptors[gameVars.places[0]]);

        //Return the minter index & raptors tokenId
        return (gameVars.minterIndexes[gameVars.places[0]], gameVars.raptors[gameVars.places[0]]);
    }

    //Handle the stat changes
    function handleCompStats(GameVars memory gameVars) internal {
        
        //Increase the winners comp wins stat
        increaseCompWins(gameVars);

        //Increase the winners speed
        upgradeSpeed(gameVars);

        //Increase the top 3 raptors top 3 finish stats
        increaseTop3RaceFinishes(gameVars);

        //Increase the fight winners strength stat
        upgradeStrength(gameVars);
    }

    // //---------------------------------Comp--------------------------------//
    // //-------------------------------DR------------------------------------//

    // //DR Start
    function _deathRaceStart(GameVars memory gameVars)
        internal
        returns (uint8, uint16)
    {

        //Emit an event saying that the race has started
        emit DeathRaceStarted(gameVars.minterIndexes, gameVars.raptors);

        //gets fighters, finds the winner & adds them to indexes to ignore for choosing winner
        gameVars = getFighters(gameVars);
        gameVars = getFightWinner(gameVars);

        //gets the winner & next two places
        gameVars = getWinner(gameVars);

        //index 0 = winner; index 1 = second; index 2 = third
        emit Top3(
            [
                gameVars.minterIndexes[gameVars.places[0]],
                gameVars.minterIndexes[gameVars.places[1]],
                gameVars.minterIndexes[gameVars.places[2]]
            ],
            [
                gameVars.raptors[gameVars.places[0]],
                gameVars.raptors[gameVars.places[1]],
                gameVars.raptors[gameVars.places[2]]
            ]
        );

        //Handle the stat changes
        handleDRStats(gameVars);

        //Emit an event saying which raptor won
        emit DeathRaceWinner(gameVars.minterIndexes[gameVars.places[0]], gameVars.raptors[gameVars.places[0]]);

        //Return the minter index & the winning tokenId
        return (gameVars.minterIndexes[gameVars.places[0]], gameVars.raptors[gameVars.places[0]]);
    }

    //DR Kill/BURN RAPTOR
    function _kill(uint8 minterIndex, uint16 raptor) internal {
        
        //Get the address of the stat contract
        StatStore storage store = statStore();

        //Burn the raptor
        IStats(store.statContract).burn(minterIndex, raptor);
    }

    //Handle the stat changes 
    function handleDRStats(GameVars memory gameVars) internal {

        //Increase the Death Race wins for the winner
        increaseDeathRaceWins(gameVars);
        
        //Increase the winners speed
        upgradeSpeed(gameVars);

        //Increase the top 3 raptors top 3 finish stats
        increaseTop3RaceFinishes(gameVars);

        //Increase the fight winners strength stat
        upgradeStrength(gameVars);
    }

    // //---------------------------------------DR----------------------------//
}
