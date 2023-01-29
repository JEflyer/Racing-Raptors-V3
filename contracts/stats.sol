//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

//import IMainMinter
import "./interfaces/IMainMinter.sol";

//import IBurn interface
import "./interfaces/IBurn.sol";

//import the IERC721 interface
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

//import the Raptor Stats struct
import "./structs/stats.sol";

import "./interfaces/IBud.sol";

//importing so msg.sender can be replaced with _msgSender() - this is more secure
import "@openzeppelin/contracts/utils/Context.sol";

contract Stats is Context {

    error NullAddress();
    error NotAdmin();
    error NotGame();
    error NotMinter();
    error AlreadyAuthorised();
    error NotApprovedForAll();
    error NoCooldown();
    error NotSet();

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
    mapping(address => mapping(uint256 => RaptorStats)) private tokenStats;

    //Stores the address of the current admin of this contract
    address private admin;

    //Stores the game interface
    address private game;


    address private budMinter;

    constructor(address _budMinter) {

        // if(_game == address(0)) revert NullAddress();
        if(_budMinter == address(0)) revert NullAddress();

        budMinter = _budMinter;
        //Build the game interface
        // game = _game;
    }

    //This modifier checks that the caller is the admin of this contract
    modifier onlyAdmin {
        if(_msgSender() != admin) revert NotAdmin();//NA => Not Admin
        _;
    }

    //This modifier checks that the caller is the set game contract
    modifier onlyGame {
        if(_msgSender() != game) revert NotGame();//NG => Not Game
        _;
    }

    modifier gameIsSet{
        if(game == address(0)) revert NotSet();
        _;
    }

    
    function instantiateStats(uint256 tokenId) external returns(bool){

        address caller = _msgSender();

        //Check that the caller is an approved minter
        if (!minters[caller]) revert NotMinter();//NA => Not Approved

        //Build the stats array for the tokenID & minter 
        tokenStats[caller][tokenId] = RaptorStats({
            speed: 1,
            strength: 1,
            fightsWon: 0,
            fightsLost: 0,
            quickPlayRacesWon: 0,
            compRacesWon: 0,
            deathRacesWon: 0,
            deathRacesSurvived: 0,
            totalRacesTop3Finish: 0,
            cooldownTime: uint64(block.timestamp)
        });

        return true;
    }

    //This function can only be called by the admin
    function addMinter(address _minter) external onlyAdmin {

        //Check that the address is not a zero address
        if(_minter == address(0)) revert NullAddress();//ZA => Zero Address

        if(minters[_minter]) revert AlreadyAuthorised();

        //Add the minter address to the minter array
        minterArray.push(_minter);

        //Give the minter approval
        minters[_minter] = true;
    }

    //This function can only be called by the admin
    function setAdmin(address _new) external onlyAdmin {

        //Check that the address is not a zero address
        if(_new == address(0)) revert NullAddress();//Za => Zero Address

        //Assign the new admin to storage
        admin = _new;
    }

    //This function can only be called by the admin
    function relinquishControl() external onlyAdmin {
        delete admin;
    }

    //This function can only be called by the admin contract
    function setGame(address _game) external onlyAdmin {
        
        //Check that the address is not a zero address
        if(_game == address(0)) revert NullAddress();//Za => Zero Address

        //Assign the new game contract to storage
        game = _game;
    }

    //For a minterIndex & tokenId return the Raptor Stats struct
    function getStats(uint256 index, uint256 tokenId) external view returns(RaptorStats memory){
        return tokenStats[minterArray[index]][tokenId];
    }

    //For a minterIndex & tokenId return the raptors speed
    function getSpeed(uint256 index, uint256 tokenId) external view returns(uint64){
        return tokenStats[minterArray[index]][tokenId].speed;
    }

    //For a minterIndex & tokenId return the raptors strength
    function getStrength(uint256 index, uint256 tokenId) external view returns(uint64){
        return tokenStats[minterArray[index]][tokenId].strength;
    }

    //For a minterIndex & tokenId return the raptors cooldown time
    //A raptor will only be on cooldown if the raptor is injured
    function getCooldownTime(uint256 index, uint256 tokenId) external view returns(uint64){
        return tokenStats[minterArray[index]][tokenId].cooldownTime;
    }

    //Increase races participated in

    //For a minterIndex & tokenId increase the raptors speed by increaseAmount
    function increaseSpeed(uint256 index, uint256 tokenId, uint64 increaseAmount) external onlyGame gameIsSet returns(bool){
        tokenStats[minterArray[index]][tokenId].speed += increaseAmount;
        return true;
    }

    //For a minterIndex & tokenId increase the raptors strength by increaseAmount
    function increaseStrength(uint256 index, uint256 tokenId, uint64 increaseAmount) external onlyGame gameIsSet returns(bool){
        tokenStats[minterArray[index]][tokenId].strength += increaseAmount;
        return true;
    }

    //For a minterIndex & tokenId increase the raptors fightsWon stat by 1
    function increaseFightsWon(uint256 index, uint256 tokenId) external onlyGame gameIsSet returns(bool){
        tokenStats[minterArray[index]][tokenId].fightsWon++;
        return true;
    }

    //For a minterIndex & tokenId increase the raptors fightsLost stat by 1
    function increaseFightsLost(uint256 index, uint256 tokenId) external onlyGame gameIsSet returns(bool){
        tokenStats[minterArray[index]][tokenId].fightsLost++;
        return true;
    }

    //For a minterIndex & tokenId increase the raptors QPRacesWon stat by 1
    function increaseQPRacesWon(uint256 index, uint256 tokenId) external onlyGame gameIsSet returns(bool){
        tokenStats[minterArray[index]][tokenId].quickPlayRacesWon++;
        return true;
    }

    //For a minterIndex & tokenId increase the raptors CompRacesWon stat by 1
    function increaseCompRacesWon(uint256 index, uint256 tokenId) external onlyGame gameIsSet returns(bool){
        tokenStats[minterArray[index]][tokenId].compRacesWon++;
        return true;
    } 

    //For a minterIndex & tokenId increase the raptors DeathRacesWon stat by 1
    function increaseDRWon(uint256 index, uint256 tokenId) external onlyGame gameIsSet returns(bool){
        tokenStats[minterArray[index]][tokenId].deathRacesWon++;
        return true;
    }

    //For a minterIndex & tokenId increase the raptors DeathRacesSurvived stat by 1
    function increaseDRSurvived(uint256 index, uint256 tokenId) external onlyGame gameIsSet returns(bool){
        tokenStats[minterArray[index]][tokenId].deathRacesSurvived++;
        return true;
    }


    function increaseTop3Finishes(uint256 index, uint256 tokenId) external onlyGame gameIsSet returns(bool){
        tokenStats[minterArray[index]][tokenId].totalRacesTop3Finish++;
        return true;
    }

    //For a minterIndex & tokenId increase the raptors cooldownTime to a period of time from now
    function increaseCooldownTime(uint256 index, uint256 tokenId) external onlyGame gameIsSet returns(bool){

        //minterArray[0] is the mainMinter
        if(index == 0){

            //If the tokenId is a founding raptor only increase the cooldown time by 3 hours
            //Otherwise increase the cooldown time by 12 hours
            if(IMainMinter(minterArray[index]).isFoundingRaptorCheck(tokenId)){
                tokenStats[minterArray[index]][tokenId].cooldownTime = uint64(block.timestamp + 3 hours);
            }else {
                tokenStats[minterArray[index]][tokenId].cooldownTime = uint64(block.timestamp + 12 hours);
            }

        }else {
            tokenStats[minterArray[index]][tokenId].cooldownTime = uint64(block.timestamp + 12 hours);
        }

        return true;
    }

    //Calls the minter contract to burn a given token Id
    function burn(uint8 minterIndex, uint256 tokenId) external onlyGame gameIsSet returns(bool){
        IBurn(minterArray[minterIndex]).burnByStats(tokenId);//OB => On Burn

        return true;
    }

    //Checks to see if an address owns the token being queried
    function owns(address _query, uint256 index, uint256 tokenId) external view returns(bool){

        //Find the owner address for the given minter index & tokenId 
        address owner  = IERC721(minterArray[index]).ownerOf(tokenId);

        //If _query does equal the owner then return true, else return false
        return _query == owner ? true : false;
    }

    //Finds the owner of a token for a given minter contract
    function ownerOf(uint256 index, uint256 tokenId)  external view returns(address){
        return IERC721(minterArray[index]).ownerOf(tokenId);
    }

    // // Checks to see that the this contraact does have approval to burn it
    // function checkApproval(uint256 index, uint256 tokenId) external view returns(bool){
    //     return IERC721(minterArray[index]).getApproved(tokenId) == address(this) ? true : false;
    // }

    function checkMinterIndex(uint8 minterIndex) external view returns(address){
        return minterIndex < minterArray.length ? minterArray[minterIndex] : address(0);
    }

    function TakeAHitOfTheBong(uint256 index, uint256 tokenID) external {
        IBud bud = IBud(budMinter);

        if(!bud.isApprovedForAll(msg.sender, address(this))) revert NotApprovedForAll();

        RaptorStats storage stats = tokenStats[minterArray[index]][tokenID];

        if(stats.cooldownTime < block.timestamp) revert NoCooldown();

        bud.burnFirstAvailable(msg.sender);

        delete stats.cooldownTime;
    }
}

