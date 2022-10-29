pragma solidity 0.8.15;

interface ILpDepositor {
    function check() external view returns(bool);
    function update() external;
}