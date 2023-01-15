//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

//Import ERC721Enumerable to inherit
import "./ERC721A/ERC721AQueryable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

//Import the Stats interface 
import "./interfaces/IStats.sol";

//This contract is for the collab raptors
contract SecondaryMinter is ERC721AQueryable, Ownable {

    error NotStatContract();
    error NullAddress();
    error NullString();
    error NotAdmin();
    error DoesntExist();

    //Declaring the interface for the stats contract
    IStats private stats;

    //TokenId => tokenURI
    mapping(uint256 => string) private tokenURIs;

    constructor(address _stats) Ownable ERC721A("Collab Raptors", "CR") {

        if(_stats == address(0)) revert NullAddress();
 
        //Defining the interface for the stats contract
        stats = IStats(_stats);
    }

    //This function is only callable by the admin of this contract
    function mint(string memory URI, address to) external onlyOwner {

        if(bytes(URI).length == 0) revert NullString();

        if(to == address(0)) revert NullAddress();
        
        uint256 tokenId;

        //Get the current tokenId
        unchecked{
            tokenId = totalSupply() +1;
        }

        //Mint a NFT for the "to" address with the tokenId
        _mint(to, 1);

        stats.instantiateStats(address(this),tokenId);

        //Setting the tokenURI for tokenId
        tokenURIs[tokenId] = URI;
    }

    //This function is used to set a link to metadata usually stored on IPFS/IPNS/Pinata for a given tokenId
    function setTokenURI(string memory uri, uint256 tokenId)
        external
        onlyOwner
    {
        if(bytes(uri).length == 0) revert NullString();


        if(!_exists(tokenId)) revert DoesntExist();

        //Set the tokenURI for tokenId
        tokenURIs[tokenId] = uri;
    }

    //This function is used to retreive a link to the metadata for tokenId 
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A,IERC721Metadata)
        returns(string memory)
    {
        if(!_exists(tokenId)) revert DoesntExist();

        return tokenURIs[tokenId];
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }


    //This function allows the burning of tokenIDs
    //This is unlikely to be called by a user directly
    //If a tokenID loses a fight in a death race it is burned
    function burn(uint256 tokenId) external virtual  {
        _burn(tokenId, true);
    }

    function burnByStats(uint256 tokenId) external virtual  {
        if(msg.sender != address(stats)) revert NotStatContract();
        _burn(tokenId, false);
    }

}
