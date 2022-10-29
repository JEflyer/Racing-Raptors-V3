//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

//Import ERC721Enumerable to inherit
import "./ERC721A/ERC721AQueryable.sol";

//Import the Stats interface 
import "./interfaces/IStats.sol";

//This contract is for the collab raptors
contract SecondaryMinter is ERC721AQueryable {

    error NotStatContract();

    //Declaring the interface for the stats contract
    IStats private stats;

    //The address of the current admin of this contract
    address private admin;

    //TokenId => tokenURI
    mapping(uint256 => string) private tokenURIs;

    constructor(address _stats) ERC721A("Collab Raptors", "CR") {

        //Defining the interface for the stats contract
        stats = IStats(_stats);
    }

    //Modifiers can be attached to multiple functions within the contract
    modifier onlyAdmin() {

        //Check that the caller is the admin of the contract
        require(msg.sender == admin, "ERR:NA"); //Na => Not Admin
        
        //This is here to signal that the code in the function this modifier is attached to can now continue
        _;
    }

    //This function is only callable by the admin of this contract
    function mint(string memory URI, address to) external onlyAdmin {
        

        uint256 tokenId;

        //Get the current tokenId
        unchecked{
            tokenId = totalSupply() +1;
        }

        //Mint a NFT for the "to" address with the tokenId
        _mint(to, tokenId);

        //Setting the tokenURI for tokenId
        tokenURIs[tokenId] = URI;
    }

    //This function is only callable by the admin of this contract
    function changeAdmin(address _new) external onlyAdmin {

        //Set the new admin
        admin = _new;
    }

    //This function is used to set a link to metadata usually stored on IPFS/IPNS/Pinata for a given tokenId
    function setTokenURI(string memory uri, uint256 tokenId)
        external
        onlyAdmin
    {
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
