//SPDX-License-Identifier: GLWTPL
pragma solidity 0.8.15;

contract SignatureVerifier {
    error NullAddress();
    error NotAdmin();

    address private admin;

    address private permissionGiver;

    mapping (address => uint256) public currentNonce;

    constructor(address _permissionGiver) {
        if(_permissionGiver == address(0)) revert NullAddress();
        
        admin = msg.sender;
        permissionGiver = _permissionGiver;
    }

    modifier onlyAdmin{
        if(msg.sender != admin) revert NotAdmin();
        _;
    }

    modifier NotNullAddress(address addr){
        if(addr == address(0)) revert NullAddress();
        _;
    }

    function setAdmin(address _new) external onlyAdmin NotNullAddress(_new) {
        admin = _new;
    }

    function setPermissionGiver(address _new) external onlyAdmin NotNullAddress(_new){
        permissionGiver = _new;
    }

    function verifySignature(uint8 v, bytes32 r, bytes32 s, address query) external returns(bool){
        uint256 nonce = currentNonce[query]; 
        
        bytes32 hashedMessage = keccak256(abi.encodePacked(query,nonce));

        address signer = ecrecover(hashedMessage,v,r,s);

        if(signer == permissionGiver){
            currentNonce[query]++;
            return true;
        }
        else {
            return false;
        }
    }
}