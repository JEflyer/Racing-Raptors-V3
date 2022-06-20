//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

//Import ERC721Enumerable to inherit
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

//Import the Stats interface 
import "./interfaces/IStats.sol";

//This contract is for the collab raptors
contract SecondaryMinter is ERC721Enumerable {

    //Declaring the interface for the stats contract
    IStats private stats;

    //The address of the current admin of this contract
    address private admin;

    //TokenId => tokenURI
    mapping(uint256 => string) private tokenURIs;

    constructor(address _stats) ERC721("Collab Raptors", "CR") {

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
        
        //Get the current tokenId
        uint256 tokenId = unchecked{totalSupply() +1;}

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
        external
        view
        returns (string memory)
    {
        return tokenURIs[tokenId];
    }

    //Wallet of owner
    //Returns an array of tokens held by a wallet
    function walletOfOwner(address _wallet)
        public
        view
        returns (uint16[] memory ids)
    {
        //Get the amount of NFTs the query wallet holds
        uint16 ownerTokenCount = uint16(balanceOf(_wallet));

        //Define a new array for ids
        ids = new uint16[](ownerTokenCount);

        //Iterate through the ownerCount
        for (uint16 i = 0; i < ownerTokenCount; ) {
            
            //Get the tokenIds that a user owns
            ids[i] = uint16(tokenOfOwnerByIndex(_wallet, i));

            //Removing the safe math wrapper
            unchecked{
                i++;
            }
        }
    }


    function burn(uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}
