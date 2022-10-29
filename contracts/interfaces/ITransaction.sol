pragma solidity 0.8.15;

interface ITransaction {
    function execute(uint256 amount) external;
}