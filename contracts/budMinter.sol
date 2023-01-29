//SPDX-License-Identifier: GLWTPL
pragma solidity 0.8.15;

import "./ERC721A/ERC721AQueryable.sol";

contract BudMinter is ERC721AQueryable {

    error NotAdmin();
    error NullAddress();
    error NullNumber();
    error NotStarted();
    error MintHasFinished();
    error SignatureAlreadyUsed();
    error NotAuthorisedSigner();
    error NullBalance();
    error AlreadyStarted();
    

    address private admin;

    address private permissionGiver;

    uint256 private lastMintTime;
    uint256 private timeMintStarted;

    uint256 private rewardPerMint;

    // uint8 v,
    // bytes32 r,
    // bytes32 s

    mapping(uint8 => mapping(bytes32 => mapping(bytes32 => bool))) private usedSignatures;

    constructor()ERC721A("Buds","Bd"){
        admin = msg.sender;
    }

    modifier onlyAdmin {
        if(msg.sender != admin) revert NotAdmin();
        _;
    }

    function setAdmin (address _new) external onlyAdmin {
        if(_new == address(0)) revert NullAddress();
        admin = _new;
    }

    function relinquishControl() external onlyAdmin {
        delete admin;
    }

    function setPermissionGiver(address _new) external onlyAdmin {
        if(_new == address(0)) revert NullAddress();
        permissionGiver = _new;
    }

    function initialize(uint256 _rewardPerMint, address _permissionGiver) external onlyAdmin {
        if(timeMintStarted != 0) revert AlreadyStarted();

        if(_rewardPerMint == 0) revert NullNumber();
        
        if(_permissionGiver == address(0)) revert NullAddress();

        permissionGiver = _permissionGiver;

        rewardPerMint = _rewardPerMint;

        timeMintStarted = block.timestamp;
    }

    function mint(uint8 v,bytes32 r,bytes32 s) external {
        if(timeMintStarted == 0) revert NotStarted();
        if(timeMintStarted + 2 days < block.timestamp) revert MintHasFinished();
        if(lastMintTime != 0 && lastMintTime + 1 days < block.timestamp) revert MintHasFinished();
        
        if(usedSignatures[v][r][s]) revert SignatureAlreadyUsed();

        if(ecrecover(keccak256(abi.encodePacked(msg.sender)), v, r, s) != permissionGiver) revert NotAuthorisedSigner();

        usedSignatures[v][r][s] = true;

        lastMintTime = block.timestamp;

        _mint(msg.sender, rewardPerMint);

    }

    function burnFirstAvailable(address burner) external returns(bool){
        uint256[] memory tokens = tokensOfOwner(burner);
        if(tokens.length == 0) revert NullBalance();
        _burn(tokens[0],true);
        return true;
    }

}