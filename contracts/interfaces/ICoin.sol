pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICoin is IERC20{
    
    function mint(uint256 amount, address to) external;

    function Burn(uint256 amount) external;

    function BurnFrom(address account, uint256 amount) external;

    function transfer(address to, uint256 amount)
        external
        returns (bool);

    
}