pragma solidity 0.8.15;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LpDepositor {
    error NotReady();
    error NullAddress();
    error NullAmount();
    error NotAdmin();

    IUniswapV2Router02 private router;

    IERC20 private usd;

    IERC20 private raptorCoin;

    address private admin;

    uint256 private amount;

    constructor(address _router,address _usd,address _raptorCoin,uint256 _amount){
        if(
            _router == address(0) ||
            _usd == address(0) ||
            _raptorCoin == address(0) 
        ) revert NullAddress();

        if(_amount == 0) revert NullAmount();
        
        admin = msg.sender;
        amount = _amount;
        usd = IERC20(_usd);
        raptorCoin = IERC20(_raptorCoin);
        router = IUniswapV2Router02(_router);
    }

    modifier onlyAdmin(){
        if(msg.sender != admin) revert NotAdmin();
        _;
    }

    modifier NotNullAddress(address addr){
        if(addr == address(0)) revert NullAddress();
        _;
    }

    function setAdmin(address _new) external onlyAdmin NotNullAddress(_new) {
        admin = _new;
    }

    function relinquishControl() external onlyAdmin {
        delete admin;
    }

    function setUSD(address _new) external onlyAdmin NotNullAddress(_new) {
        uint256 bal = usd.balanceOf(address(this));

        if(bal != 0){
            uint256 usdToConvertToRC = bal / 2;

            uint256 usdToDeposit = bal - usdToConvertToRC;
        
            address[] memory path;

            path[0] = address(usd);
            path[1] = address(raptorCoin);

            usd.approve(address(router),bal);

            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(usdToConvertToRC, 0, path, address(this), block.timestamp+1);

            uint256 rcBal = raptorCoin.balanceOf(address(this));

            raptorCoin.approve(address(router),rcBal);

            router.addLiquidity(address(usd), address(raptorCoin), usdToDeposit, rcBal, 0, 0, address(0), block.timestamp + 1);
        }

        usd = IERC20(_new);
    }
 
    function check() external view returns(bool){
        return usd.balanceOf(address(this)) > amount;
    }

    function update() external {
        uint256 bal = usd.balanceOf(address(this));

        if(bal < amount) revert NotReady();
    
        uint256 usdToConvertToRC = bal / 2;

        uint256 usdToDeposit = bal - usdToConvertToRC;
    
        address[] memory path;

        path[0] = address(usd);
        path[1] = address(raptorCoin);

        usd.approve(address(router),bal);

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(usdToConvertToRC, 0, path, address(this), block.timestamp+1);

        uint256 rcBal = raptorCoin.balanceOf(address(this));

        raptorCoin.approve(address(router),rcBal);

        router.addLiquidity(address(usd), address(raptorCoin), usdToDeposit, rcBal, 0, 0, address(0), block.timestamp + 1);    
    }

}