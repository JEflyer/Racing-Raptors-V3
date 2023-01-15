//SPDX-License-Identifier: GLWTPL
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/ICoin.sol";

import "./interfaces/IRate.sol";

import "./interfaces/ILpDepositor.sol";

contract RaptorCoinStaking {

    error NullAddress();
    error NotAdmin();
    error AmountApproved();
    error RCAmountApproved();
    error NullAmount();
    error AlreadyStaking();
    error NotStaking();
    error NoReward();
    error FailedUpdate();
    error NotAuthorised();
    

    address private admin;
    address private usd;
    address private lpDepositor;
    address private raptorCoin;
    address private rateContract;
    uint256 public stepID;

    uint256 private amountToAdd;


    struct StakingInfo {
        uint256 amountStaked;
        uint256 stepStakedOn;
    }

    mapping(address => StakingInfo) private stakeInfo;

    struct StepInfo {
        uint256 treasury;
        uint256 totalStaked;
        uint256 rewardPerSecond;
        uint256 totalRewardThisStep;
        uint256 timeStarted;
    }

    mapping(uint256 => StepInfo) private stepInfo;

    constructor(
        address _usd,
        address _lpDepositor,
        address _raptorCoin,
        address _rateContract
    ){
        if(
            _usd == address(0) ||
            _lpDepositor == address(0) ||
            _raptorCoin == address(0) ||
            _rateContract == address(0) 
        ) revert NullAddress();


        usd = _usd;
        lpDepositor = _lpDepositor;
        raptorCoin = _raptorCoin;
        rateContract = _rateContract;
        
        admin = msg.sender;
        
        stepID = 0;
    
        stepInfo[0].treasury = 250000 * 10 ** 18;
    }

    modifier onlyAdmin {
        if(msg.sender == admin) revert NotAdmin();
        _;
    }

    modifier NotNullAddress(address addr){
        if(addr == address(0)) revert NullAddress();
        _;
    }

    
    function relinquishControl() external onlyAdmin{
        delete admin;
    }

    function setUSD(address _new) external onlyAdmin NotNullAddress(_new) {
        usd = _new;
    }

    function setAdmin(address _new) external onlyAdmin NotNullAddress(_new) {
        admin = _new;
    }

    function stake(uint256 amount) external {

        if(amount == 0) revert NullAmount();
        
        IERC20 _usd = IERC20(usd);

        address caller = msg.sender;

        uint256 amountApproved = _usd.allowance(caller, address(this));

        //1M = 1USD
        if(amountApproved < 1000000) revert AmountApproved();

        ICoin rc = ICoin(raptorCoin);

        uint256 rcAA = rc.allowance(caller, address(this));

        if(rcAA < amount) revert RCAmountApproved();

        StakingInfo storage details = stakeInfo[caller];

        if(details.stepStakedOn != 0) revert AlreadyStaking();

        _usd.transferFrom(caller,lpDepositor,amount);

        ILpDepositor depositor = ILpDepositor(lpDepositor);

        if(depositor.check()) depositor.update();

        rc.BurnFrom(caller, amount);

        details.amountStaked = amount;
        details.stepStakedOn = stepID + 1;

        _update(amount,0);

        //emit event
    }

    function unstake() external {
        address caller = msg.sender;

        StakingInfo storage details = stakeInfo[caller];

        if(details.stepStakedOn == 0) revert NotStaking();

        uint256 reward = getDueReward(caller);

        if(reward == 0) revert NoReward();

        uint256 amountStaked = details.amountStaked;

        ICoin(raptorCoin).mint(reward + amountStaked,caller);

        delete details.amountStaked;
        delete details.stepStakedOn;

        _update(0, amountStaked);

    }

    function claim() external {
        address caller = msg.sender;

        StakingInfo storage details = stakeInfo[caller];

        if(details.stepStakedOn == 0) revert NotStaking();

        uint256 reward = getDueReward(caller);

        if(reward == 0) revert NoReward();

        ICoin(raptorCoin).mint(reward,caller);

        details.stepStakedOn = stepID + 1;

        _update(0,0);
    }

    function emergencyUnstake() external {
        address caller = msg.sender;

        StakingInfo storage details = stakeInfo[caller];

        if(details.stepStakedOn == 0) revert NotStaking();

        uint256 amount = details.amountStaked;

        ICoin(raptorCoin).mint(amount,caller);

        delete details.amountStaked;
        delete details.stepStakedOn;

        _update(0,amount);
    }

    function getDueReward(address query) public view returns(uint256) {
        StakingInfo memory details = stakeInfo[query];

        if(details.stepStakedOn == 0 || details.stepStakedOn == stepID) return 0;

        uint256 total = 0;

        uint256 amountStaked = details.amountStaked;

        uint256 id = stepID;

        for(uint256 i = details.stepStakedOn; i < id;){

            total += (amountStaked * stepInfo[i].totalRewardThisStep) / stepInfo[i].totalStaked;

            unchecked{
                i++;
            }
        }

        total += ((amountStaked * stepInfo[id].rewardPerSecond) / stepInfo[id].totalStaked) * (block.timestamp - stepInfo[id].timeStarted);

        return total;
    }

    function getCurrentRewardRate() external view returns(uint256) {
        return stepInfo[stepID].rewardPerSecond;
    }

    function getStepDetails(uint256 step) external view returns(StepInfo memory) {
        return stepInfo[step];
    }

    function getStakerDetails(address query) external view returns(StakingInfo memory){
        return stakeInfo[query];
    }

    function _update(uint256 amountStaked, uint256 amountUnstaked) private {

        StepInfo memory lastStep = stepInfo[stepID];
        StepInfo memory nextStep = stepInfo[++stepID];

        uint256 treasury = lastStep.treasury + amountToAdd;

        //First deposit into pool
        if(lastStep.totalStaked == 0 && amountStaked > 0){

            nextStep.treasury = treasury;
            nextStep.rewardPerSecond = treasury / 100000;
            nextStep.timeStarted = block.timestamp;
            nextStep.totalStaked = amountStaked;

        }
        //Regular Deposit
        else if(amountStaked > 0 && amountUnstaked == 0){

            uint256 amountRewarded = lastStep.rewardPerSecond * (block.timestamp - lastStep.timeStarted);

            uint256 newTreasury = treasury - amountRewarded;

            nextStep.treasury = newTreasury;
            
            lastStep.totalRewardThisStep = amountRewarded;

            nextStep.rewardPerSecond = newTreasury / 100000;
            nextStep.timeStarted = block.timestamp;
            nextStep.totalStaked = lastStep.totalStaked + amountStaked;
        }
        //Claim
        else if(amountStaked == 0 && amountUnstaked == 0){

            uint256 amountRewarded = lastStep.rewardPerSecond * (block.timestamp - lastStep.timeStarted);

            uint256 newTreasury = treasury - amountRewarded;

            nextStep.treasury = newTreasury;
            
            lastStep.totalRewardThisStep = amountRewarded;

            nextStep.rewardPerSecond = newTreasury / 100000;
            nextStep.timeStarted = block.timestamp;
            nextStep.totalStaked = lastStep.totalStaked;

        }
        //Unstake
        else if(amountStaked == 0 && amountUnstaked > 0){
            uint256 amountRewarded = lastStep.rewardPerSecond * (block.timestamp - lastStep.timeStarted);

            uint256 newTreasury = treasury - amountRewarded;

            nextStep.treasury = newTreasury;
            
            lastStep.totalRewardThisStep = amountRewarded;

            nextStep.rewardPerSecond = newTreasury / 100000;
            nextStep.timeStarted = block.timestamp;
            nextStep.totalStaked = lastStep.totalStaked - amountUnstaked;
        }

        if(!IRate(rateContract).acceptUpdateFromRCS(ICoin(raptorCoin).balanceOf(address(this)))) revert FailedUpdate();
    }

    function Update(uint256 amount) external returns(bool){
        if(msg.sender != rateContract) revert NotAuthorised();
        amountToAdd += amount;
        return true;
    }
}