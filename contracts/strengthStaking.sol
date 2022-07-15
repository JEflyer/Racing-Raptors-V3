//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

//Import the interface for the stats contract
import "./interfaces/IStats.sol";

//Imported the context library for safe usage of msg.sender
import "@openzeppelin/contracts/utils/Context.sol";

//Import the interface for ERC20
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//Import the interface for ERC721A
import "./ERC721A/IERC721A.sol";

contract StrengthStaking is Context {


    struct StepDetails {
        uint256 totalStrength;
        uint64 blockUpdated;
        uint64 blockUntil;
    }

    struct StakeDetails {
        address staker;
        uint64 strength; 
        uint64 blockStaked;
        uint64 blockLastClaimed;
    }

    struct UserData {
        uint8[] minterIndexes;
        uint16[] tokenIDs;
    }

    mapping(uint8 => mapping(uint16 => StakeDetails)) private stakeDetails;

    mapping(uint256 => StepDetails) private stepDetails;

    mapping(address => UserData) private userData;

    uint256 private stepId;

    uint256 private totalBlockReward;

    //Stores the address of the admin of this contract
    address private admin;

    //Stores an instance of an ERC20 interface
    IERC20 private token;

    //Stores instances of the ERC721A interface
    IERC721A private minter1;
    IERC721A private minter2;

    //Stores an instance of the Stats interface
    IStats private stats;

    constructor(
        address _minter1, address _minter2, address _token, address _stats, uint256 _totalRewardPerBlock
    ){
        admin = _msgSender();

        minter1 = IERC721A(_minter1);
        minter2 = IERC721A(_minter2);

        token = IERC20(_token);

        stats = IStats(_stats);

        totalBlockReward = _totalRewardPerBlock;
        
    }

    function updateStep(uint256 totalStrength) internal {
        
        uint256 step = stepId;

        uint64 currentBlock = block.number;

        stepDetails[step].blockUntil = currentBlock-1;
        
        stepDetails[++step] = StepDetails({
            totalStrength: totalStrength,
            blockUpdated: currentBlock
        });
    }

    function stake(uint8 minterIndex, uint16 tokenId) external {
        //Check that minterIndex is less than 2
        require(minterIndexc < 2, "ERR:MI");//MI => Minter Index

        //Get the address of the caller
        address caller = _msgSender();
        
        //Define an instance of the minter
        IERC721A memory minter;

        //Assign the minter to memory
        if(minterIndex == 0){
            minter = minter1;
        }else if(minterIndex == 1){
            minter = minter2;
        }  

        //Check that the caller owns the token for minter index
        require(minter.ownerOf(tokenId) == caller,"ERR:NO");//NO => Not Owner
        
        //Check that the caller has given this contract approval over the token being staked
        require(minter.getApproved(tokenId) == address(this), "ERR:NA");//NA => Not Approved

        //Retreive the number of death races this token has survived from the stat contract 
        IStats.RaptorStats memory _stats = stats.getStats(minterIndex, tokenId);

        uint64 strength = _stats.strength;

        //Move the NFT to this contract
        require(minter.transferFrom(caller, address(this), tokenId),"ERR:OT");//OT => On Transfer

        //Update stake details for this token & minter
        stakeDetails[minterIndex][tokenId] = StakeDetails({
            staker: caller,
            strength: strength,
            blockStaked: uint64(block.number),
            blockLastClaimed: uint64(block.number)
        }); 

        //Update the next step with the new total strength
        updateStep(stepDetails[stepId] + strength);

        //Pull user details
        UserData storage data = userData[caller];

        //Store data
        data.minterIndexes.push(minterIndex);
        data.tokenIDs.push(tokenId);
    }

    function unstake() external {

    }

    function claim() external {

    }

    function getDueRewardForUser() public view returns(uint256){

    } 

    function getDueRewardForToken() internal view returns(uint256){

    }

}