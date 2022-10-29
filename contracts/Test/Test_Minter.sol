pragma solidity 0.8.15;

import "../ERC721A/ERC721AQueryable.sol";

contract TestMinter is ERC721AQueryable {
    constructor(address[] memory addresses)ERC721A("name","symbol"){
        for(uint256 i = 0; i < addresses.length;){

            _mint(addresses[i], 10);

            unchecked{
                i++;
            }
        }
    }
}