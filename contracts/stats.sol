//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

//import IGame
import "./interfaces/IGame.sol";

//import IBurn interface
import "./interfaces/IBurn.sol";

//import the IERC721 interface
import "@openzeppelin/contracts/tokoen/ERC721/IERC721.sol";

//import the Raptor Stats struct
import "./structs/stats.sol";

//importing so msg.sender can be replaced with _msgSender() - this is more secure
import "@openzeppelin/contracts/utils/Context.sol";

contract Stats {

    //minter address => whether or not it has been added to this contract
    mapping(address => bool) private minters;

    //Hold an array of minter addresses
    address[] private minterArray;

    //This is a nested mapping, think of it like a 2D table
    //   addr1, addr2
    // 1 stats, stasts
    // 2 ...    ... 
    // 3 ...    ...
    // 4 ...    ...
    //MinterAddress => TokenId => RaptorStats
    mapping(address => mapping(uint16 => RaptorStats)) private tokenStats;

    //Stores the address of the current admin of this contract
    address private admin;

    //Stores the game interface
    IGame private game;

    constructor(address _game) {

        //Build the game interface
        game = IGame(_game);
    }

    //This modifier checks that the caller is the admin of this contract
    modifier onlyAdmin {
        require(_msgSender() == admin, "ERR:NA");//NA => Not Admin
        _;
    }

    //This modifier checks that the caller is the set game contract
    modifier onlyGame {
        require(_msgSender() == address(game), "ERR:NG");//NG => Not Game
    }

    
    function instantiateStats(uint16 tokenId) external returns(bool){

        //Check that the caller is an approved minter
        require(minter[_msgSender()], "ERR:NA");//NA => Not Approved

        //Build the stats array for the tokenID & minter 
        tokenStats[_msgSender()][tokenId] = RaptorStats({
            speed = 1,
            strength = 1,
            fightsWon = 0,
            fightsLost = 0,
            quickPlayRacesWon = 0,
            compRacesWon = 0,
            deathRacesWon = 0,
            deathRacesSurvived = 0,
            totalRacesTop3Finish = 0,
            cooldownTime = uint64(block.timestamp)
        });

        return true;
    }

    //This function can only be called by the admin
    function addMinter(address _minter) external onlyAdmin {

        //Check that the address is not a zero address
        require(_minter != address(0), "ERR:ZA");//ZA => Zero Address

        //Add the minter address to the minter array
        minterArray.push(_minter);

        //Give the minter approval
        minters[_minter] = true;
    }

    //This function can only be called by the admin
    function setAdmin(address _new) external onlyAdmin {

        //Check that the address is not a zero address
        require(_new != address(0),"ERR:ZA");//Za => Zero Address

        //Assign the new admin to storage
        admin = _new;
    }

    //This function can only be called by the admin contract
    function setGame(address _game) external onlyAdmin {
        
        //Check that the address is not a zero address
        require(_game != address(0), "ERR:ZA");//Za => Zero Address

        //Assign the new game contract to storage
        game = _game;
    }

    //For a minterIndex & tokenId return the Raptor Stats struct
    function getStats(uint8 index, uint16 tokenId) external view returns(RaptorStats memory){
        return tokenStats[minterArray[index]][tokenId];
    }

    //For a minterIndex & tokenId return the raptors speed
    function getSpeed(uint8 index, uint16 tokenId) external view returns(uint64){
        tokenStats[minterArray[index]][tokenId].speed;
    }

    //For a minterIndex & tokenId return the raptors strength
    function getStrength(uint8 index, uint16 tokenId) external view returns(uint64){
        tokenStats[minterArray[index]][tokenId].strength;
    }

    //For a minterIndex & tokenId return the raptors cooldown time
    //A raptor will only be on cooldown if the raptor is injured
    function getCooldownTime(uint8 index, uint16 tokenId) external view returns(uint64){
        tokenStats[minterArray[index]][tokenId].cooldownTime;
    }

    //For a minterIndex & tokenId increase the raptors speed by increaseAmount
    function increaseSpeed(uint8 index, uint16 tokenId, uint64 increaseAmount) external onlyGame returns(bool){
        tokenStats[minterArray[index]][tokenId].speed += increaseAount;
        return true;
    }

    //For a minterIndex & tokenId increase the raptors strength by increaseAmount
    function increaseStrength(uint8 index, uint16 tokenId, uint64 increaseAmount) external onlyGame returns(bool){
        tokenStats[minterArray[index]][tokenId].strength += increaseAmount;
        return true;
    }

    //For a minterIndex & tokenId increase the raptors fightsWon stat by 1
    function increaseFightsWon(uint8 index, uint16 tokenId) external onlyGame returns(bool){
        tokenStats[minterArray[index]][tokenId].fightsWon++;
        return true;
    }

    //For a minterIndex & tokenId increase the raptors fightsLost stat by 1
    function increaseFightsLost(uint8 index, uint16 tokenId) external onlyGame returns(bool){
        tokenStats[minterArray[index]][tokenId].fightsLost++;
        return true;
    }

    //For a minterIndex & tokenId increase the raptors QPRacesWon stat by 1
    function increaseQPRacesWon(uint8 index, uint16 tokenId) external onlyGame returns(bool){
        tokenStats[minterArray[index]][tokenId].quickPlayRacesWon++;
        return true;
    }

    //For a minterIndex & tokenId increase the raptors CompRacesWon stat by 1
    function increaseCompRacesWon(uint8 index, uint16 tokenId) external onlygame returns(bool){
        tokenStats[minterArray[index]][tokenId].compRacesWon++;
        return true;
    } 

    //For a minterIndex & tokenId increase the raptors DeathRacesWon stat by 1
    function increaseDRWon(uint8 index, uint16 tokenId) external onlyGame returns(bool){
        tokenStats[minterArray[index]][tokenId].deathRacesWon++;
        return true;
    }

    //For a minterIndex & tokenId increase the raptors DeathRacesSurvived stat by 1
    function increaseDRSurvived(uint8 index, uint16 tokenId) external onlyGame returns(bool){
        tokenStats[minterArray[index]][tokenId].deathRacesSurvived++;
        return true;
    }

    //For a minterIndex & tokenId increase the raptors cooldownTime to a period of time from now
    function increaseCooldownTime(uint8 index, uint16 tokenId) external onlyGame returns(bool){

        //minterArray[0] is the mainMinter
        if(index == 0){

            //If the tokenId is a founding raptor only increase the cooldown time by 3 hours
            //Otherwise increase the cooldown time by 12 hours
            if(IMainMinter(minter).isFoundingRaptorCheck(tokenId)){
                tokenStats[minter][tokenId].cooldownTime = uint64(block.timestamp + 3 hours);
            }else {
                tokenStats[minter][tokenId].cooldownTime = uint64(block.timestamp + 12 hours);
            }

        }else {
            tokenStats[minterArray[index]][tokenId].cooldownTime = uint64(block.timestamp + 12 hours);
        }

        return true;
    }

    //Calls the minter contract to burn a given token Id
    function burn(uint8 minterIndex, uint16 tokenId) external onlyGame returns(bool){
        require(IBurn(minterArray[minterIndex]).burn(uint256(tokenId)),"ERR:OB");//OB => On Burn

        return true;
    }

    //Checks to see if an address owns the token being queried
    function owns(address _query, uint8 index, uint16 tokenId) external view returns(bool){

        //Find the owner address for the given minter index & tokenId 
        address owner  = IERC721(minterArray[index]).ownerOf(tokenId);

        //If _query does equal the owner then return true, else return false
        return _query == owner ? true : false;
    }

    //Finds the owner of a token for a given minter contract
    function ownerOf(uint8 index, uint16 tokenId)  external view returns(address){
        return IERC721(minterArray[index]).ownerOf(tokenId);
    }

    // Checks to see that the this contraact does have approval to burn it
    function checkApproval(uint8 index, uint16 tokenId) external view returns(bool){
        return IERC721(minterArray[index]).getApproved(tokenId) == address(this) ? true : false;
    }


}

