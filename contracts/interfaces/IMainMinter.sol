pragma solidity 0.8.14;

interface IMainMinter {
    function isFoundingRaptorCheck(uint16 tokenId) external view returns (bool);
}
