pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/ILpDepositor.sol";

import "./interfaces/ICoin.sol";

import "./interfaces/IRate.sol";

import { IUniswapV2Pair } from "./FlatRouter.sol";

contract LpStaking {

    error NotAdmin();
    error NullAddress();
    error NullNumber();
    error AlreadyAReward();
    error NotActive();
    error UsdApproval();
    error LpApproval();
    error AlreadyStaking();
    error NotRate();

    address private admin;
    address private usd;
    address private lpDepositor;
    address private raptorCoin;
    address private rate;

    uint256 private latestLpId;
    uint256 private lastTimeSharesUpdated;
    uint256[] public activeRewards;

    uint256 private amountToDivide;
    
    struct StakeInfo {
        uint256 amountStaked;
        uint256 stepStaked;
    }

    struct StepInfo {
        uint256 treasury;
        uint256 rewardPerSecond;
        uint256 totalRewardThisStep;
        uint256 totalLpStaked;
        uint256 timeStarted;
        uint256 timeEnded;
    }

    //LP ID to address
    mapping(uint256 => address) private pairs;
    
    //address to LP ID
    mapping(address => uint256) private isReward;
    
    //LP ID to Step ID to StepInfo
    mapping(uint256 => mapping(uint256 => StepInfo)) private stepInfo;

    //LP ID to latest step
    mapping(uint256 => uint256) private stepIDs;

    //Staker to rewardID to StakeInfo
    mapping(address => mapping(uint256 => StakeInfo)) private stakeInfo;

    //LP ID to amount Due to be added to treasury in update for synced steps
    mapping(uint256 => uint256) private amountDue;

    constructor(
        address _usd,
        address _lpDepositor,
        address _raptorCoin,
        address _rate
    ) {
        if(
            _usd == address(0) ||
            _lpDepositor == address(0) ||
            _raptorCoin == address(0) ||
            _rate == address(0) 
        ) revert NullAddress();

        usd = _usd;
        lpDepositor = _lpDepositor;
        raptorCoin = _raptorCoin;
        rate = _rate;
        admin = msg.sender;
    }

    modifier onlyAdmin {
        if(msg.sender != admin) revert NotAdmin();
        _;
    }

    modifier NotNullAddress(address addr) {
        if(addr == address(0)) revert NullAddress();
        _;
    }

    function setAdmin(address _new) external onlyAdmin NotNullAddress(_new){
        admin = _new;
    }

    function setUSD(address _new) external onlyAdmin NotNullAddress(_new){
        usd = _new;
    }

    //Give every new pool an initial treasury of 100k raptorcoin
    function addReward(address _new) external onlyAdmin NotNullAddress(_new){
        uint256 id = latestLpId + 1;

        if(isReward[_new] != 0) revert AlreadyAReward();

        isReward[_new] = id;
        pairs[id] = _new;

        //Set treasury for step 0
        stepInfo[id][0].treasury = 100000 * 10 ** 18;

        latestLpId = id;

        activeRewards.push(id);
    }

    function endReward(uint256 _lpID) external onlyAdmin {
        if(pairs[_lpID] == address(0)) revert NotActive();

        StepInfo storage step = stepInfo[_lpID][stepIDs[_lpID]];

        step.timeEnded = block.timestamp;
        step.totalRewardThisStep = step.rewardPerSecond * (block.timestamp - step.timeStarted);

        //Remove the LP ID from the activeRewards
        for(uint256 i  = 0; i < activeRewards.length;){

            if(activeRewards[i] == _lpID){
                activeRewards[i] = activeRewards[activeRewards.length-1];
                delete activeRewards[activeRewards.length-1];
                activeRewards.pop();
            }

            unchecked{
                i++;
            }
        }

        delete pairs[_lpID];

    }
    
    function stake(uint256 _rewardId, uint256 _amount) external {
        if(pairs[_rewardId] == address(0)) revert NotActive();

        address caller = msg.sender;

        ICoin _usd = ICoin(usd);

        uint256 usdApproved = _usd.allowance(caller,address(this));

        if(usdApproved < 1000000) revert UsdApproval();

        IUniswapV2Pair pair = IUniswapV2Pair(pairs[_rewardId]);

        uint256 lpApproved = pair.allowance(caller, address(this));

        if(lpApproved < _amount) revert LpApproval();

        StakeInfo storage info = stakeInfo[caller][_rewardId];

        if(info.amountStaked != 0) revert AlreadyStaking();

        _usd.transferFrom(caller, lpDepositor, 1000000);

        pair.transferFrom(caller,address(this),_amount);

        info.amountStaked = _amount;
        info.stepStaked = stepIDs[_rewardId] + 1;

        _update(0,_amount,_rewardId);
    }

    function claim(uint256 _rewardId) external {
        if(pairs[_rewardId] == address(0)) revert NotActive();

        address caller = msg.sender;

        uint256 reward = getDueReward(caller,_rewardId);

        StakeInfo storage info = stakeInfo[caller][_rewardId];

        info.stepStaked = stepIDs[_rewardId] + 1;

        ICoin(raptorCoin).mint(reward, caller);

        _update(0,0,_rewardId);
    }

    function unstake(uint256 _rewardId) external {
        if(pairs[_rewardId] == address(0)) revert NotActive();

        address caller = msg.sender;

        StakeInfo storage info = stakeInfo[caller][_rewardId];

        uint256 reward = getDueReward(caller,_rewardId) ;

        IUniswapV2Pair pair = IUniswapV2Pair(pairs[_rewardId]);

        pair.transfer(caller,info.amountStaked);

        ICoin(raptorCoin).mint(reward, caller);

        _update(info.amountStaked,0,_rewardId);
        
        delete info.stepStaked;
        delete info.amountStaked;
    }

    function emergencyUnstake(uint256 _rewardId) external {
        if(pairs[_rewardId] == address(0)) revert NotActive();

        address caller = msg.sender;

        StakeInfo storage info = stakeInfo[caller][_rewardId];

        IUniswapV2Pair pair = IUniswapV2Pair(pairs[_rewardId]);
        pair.transfer(caller,info.amountStaked);

        _update(info.amountStaked,0,_rewardId);
        
        delete info.stepStaked;
        delete info.amountStaked;
    }

    function getDueReward(address _query, uint256 _rewardId) public view returns(uint256){

        StakeInfo storage info = stakeInfo[_query][_rewardId];

        uint256 total = 0;

        uint256 amountStaked = info.amountStaked;

        uint256 lastStep = stepIDs[_rewardId];

        StepInfo memory step;

        for(uint256 i = info.stepStaked; i < lastStep;){

            step = stepInfo[_rewardId][i];
            
            total += (amountStaked * step.totalRewardThisStep) / step.totalLpStaked;

            unchecked {
                i++;
            }
        }
        
        step = stepInfo[_rewardId][lastStep];

        total += ((amountStaked * step.rewardPerSecond) / step.totalLpStaked) * (block.timestamp - step.timeStarted);
    }

    function _update(uint256 _amountUnstaked, uint256 _amountStaked, uint256 _rewardID) internal {
        
        uint256 id = stepIDs[_rewardID];
        StepInfo memory lastStep = stepInfo[_rewardID][id];
        StepInfo memory nextStep = stepInfo[_rewardID][++id];

        uint256 rewardThisStep = lastStep.rewardPerSecond * (block.timestamp - lastStep.timeStarted);

        nextStep.treasury = lastStep.treasury - rewardThisStep + amountDue[_rewardID];

        nextStep.rewardPerSecond = nextStep.treasury / 100000;

        nextStep.timeStarted = block.timestamp;

        if(_amountStaked > 0){
            nextStep.totalLpStaked += _amountStaked;
        } else if(_amountUnstaked > 0){
            nextStep.totalLpStaked -= _amountUnstaked;
        }

        IRate(rate).acceptUpdateFromLPS(getRaptorCoinBalance());
    }

    function getRaptorCoinBalance() public view returns(uint256){
        uint256[] memory ids = activeRewards;

        uint256 total = 0;
        uint256 reserve = 0;

        IUniswapV2Pair pair;

        for(uint256 i = 0; i < ids.length;){

            pair = IUniswapV2Pair(pairs[ids[i]]);

            if(pair.token0() == raptorCoin){
                (reserve,,) = pair.getReserves();
            }else {
                (,reserve,) = pair.getReserves();
            }
            
            total += (stepInfo[ids[i]][stepIDs[ids[i]]].treasury * reserve) / pair.totalSupply();

            unchecked{
                i++;
            }
        }

        return total * 2;
    }

    function Update(uint256 amount) external returns(bool){
        if(msg.sender != rate) revert NotRate();

        uint256[] memory ids = activeRewards;

        (uint256[] memory shares,uint256 totalShares) = getShares(ids);

        for(uint256 i = 0; i < ids.length;){
            
            amountDue[ids[i]] += (shares[i] * amount) / totalShares;

            unchecked{
                i++;
            }
        }
        return true;
    }

    function getShares(uint256[] memory ids) internal view returns(uint256[] memory arr, uint256 totalShares){
        uint256 reserve = 0;
        IUniswapV2Pair pair;
        for(uint256 i = 0; i < ids.length;){
            pair = IUniswapV2Pair(pairs[ids[i]]);

            if(pair.token0() == raptorCoin){
                (reserve,,) = pair.getReserves();
            }else {
                (,reserve,) = pair.getReserves();
            }
            arr[i] = reserve;
            totalShares += reserve;

            unchecked{
                i++;
            }
        }
    }
}