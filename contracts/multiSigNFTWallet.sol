//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

//Import the ITransaction interface
import "./interfaces/ITransaction.sol";

//Imported the context library for safe usage of msg.sender
import "@openzeppelin/contracts/utils/Context.sol";

//Import the interface for ERC20
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Multisig is Context{

    address[] private signers;

    mapping(address => bool) private isSigner;

    address private proposedTransactionAddress;
    uint256 private proposedTransactionAmount;

    address[] private haveSigned;
    mapping(address => bool) private hasSigned;

    address private proposer;

    IERC20 private token;

    constructor(address[] memory _signers, address _token){

        require(_signers.length != 0, "ERR:NA");

        for(uint i = 0 ; i < _signers.length;){

            require(_signers[i] != address(0),"ERR:ZA");

            unchecked{
                i++;
            }
        }

        require(_token != address(0),"ERR:ZA");

        signers = _signers;

        for(uint i = 0 ; i < _signers.length;){

            isSigner[_signers[i]] = true;

            unchecked{
                i++;
            }
        }

        proposer = _msgSender();

        token = IERC20(_token);
    }

    function propose(address _txAddr, uint256 _txAmnt) external {
        require(_msgSender() == proposer, "ERR:NP");//NP => Not Proposer

        require(_txAddr != address(0), "ERR:ZA");//ZA => Zero Address

        require(proposedTransactionAddress == address(0),"ERR:AS");//AS => Already Set

        proposedTransactionAddress = _txAddr;

        proposedTransactionAmount = _txAmnt;
    }

    function vote(bool _vote) external {
        
        address caller = _msgSender();
        
        require(isSigner[caller], "ERR:NS");//NS => Not Signer

        require(!hasSigned[caller],"ERR:AS");//AS => Already Signed

        require(proposedTransactionAddress != address(0), "ERR:NV");//NV => No Voting

        if(_vote){
            haveSigned.push(caller);
            hasSigned[caller] = true;

            if(haveSigned.length * 100 / signers.length >= 51){
                token.approve(proposedTransactionAddress, proposedTransactionAmount);
                ITransaction(proposedTransactionAddress).execute(proposedTransactionAmount);
                delete proposedTransactionAddress;
                delete proposedTransactionAmount;
                for(uint i = 0; i < haveSigned.length;){

                    delete hasSigned[haveSigned[i]];

                    unchecked{
                        i++;
                    }
                }

                delete haveSigned;
            }
        }else{ 
            delete proposedTransactionAddress;
            delete proposedTransactionAmount;
            for(uint i = 0; i < haveSigned.length;){

                    delete hasSigned[haveSigned[i]];

                    unchecked{
                        i++;
                    }
                }

                delete haveSigned;
        }
    }

    function removeFromArray(address[] storage arr, address remove) private {
        for(uint8 i = 0; i < arr.length;){

            if(arr[i] == remove){
                arr[i] = arr[arr.length-1];
                delete arr[arr.length-1];
                arr.pop();
            }

            unchecked{
                i++;
            }


        }
    }

    
}