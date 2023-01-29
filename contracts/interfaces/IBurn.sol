pragma solidity 0.8.15;

interface IBurn {
    function burn(uint256 tokenId) external;
    function burnByStats(uint256 tokenId) external;
}
