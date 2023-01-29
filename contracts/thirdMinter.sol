//SPDX-License-Identifier: GLWTPL
pragma solidity 0.8.15;

import "./ERC721A/ERC721AQueryable.sol";

//import stats interface
import "./interfaces/IStats.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract ThirdMinter is ERC721AQueryable, Ownable {

    error NotAdmin();
    error NullAddress();
    error NullNumber();
    error NullString();
    error WrongLength();

    error AlreadyBreeding();
    error AlreadyBred();
    error NotCurrentlyBreeding();
    
    error NotOwner();
    error AmountApproved();

    error InvalidSeason();
    error InvalidRaptor();
    error InvalidIndex();

    error NotStatContract();


    address private minter;
    address private stats;

    address[] private usdTokens;

    uint256 public seasonID;
    uint256 public breedingFee;

    string private baseURI;

    bool public breedingEnabled;

    address[] private payees;
    uint16[] private shares; 
    
    uint16 private totalShares;

    // uint256 private minPayout;

    mapping(uint256 => mapping(uint256 => bool)) private bred;

    mapping(uint256 => uint256) private amountMintedThisSeason;

    mapping(uint256 => string) private cids;

    mapping(uint256 => uint256[2]) private mintRanges;

    constructor(
        string memory _name,
        string memory _symbol,
        address _minter,
        address _stats,
        address[] memory _usdTokens,
        uint256 _breedingFee,
        address[] memory _payees,
        uint16[] memory _shares
    )ERC721A(_name,_symbol) Ownable(){

        if(
            _minter == address(0) ||
            _stats == address(0) 
        ) revert NullAddress();

        if(_breedingFee == 0) revert NullNumber();

        if(
            bytes(_name).length == 0 || 
            bytes(_symbol).length == 0  
        ) revert NullString();

        if(_payees.length != _shares.length || _payees.length == 0) revert WrongLength();

        uint16 total = 0;

        for(uint256 i = 0; i < _payees.length;){

            if(_payees[i] == address(0)) revert NullAddress();
            if(_shares[i] == 0) revert NullNumber();
            
            total += _shares[i];

            unchecked{
                i++;
            }
        }

        for(uint256 i = 0 ; i < _usdTokens.length;){

            if(_usdTokens[i] == address(0)) revert NullAddress();

            unchecked{
                i++;
            }
        }

        minter = _minter;
        stats = _stats; 
        usdTokens = _usdTokens;
        breedingFee = _breedingFee;
        seasonID = 0;
        breedingEnabled = false;
        shares = _shares;
        payees = _payees;
        totalShares = total;
    }


    modifier NotNullString(string memory str){
        if(bytes(str).length == 0) revert NullString();
        _;
    }



    function setBaseURI(string memory _new)external onlyOwner NotNullString(_new){
        baseURI = _new;
    }

    function startNewSeason(string memory _CID) external onlyOwner NotNullString(_CID){

        if(breedingEnabled) revert AlreadyBreeding();

        uint256 id = ++seasonID;


        breedingEnabled = true;

        mintRanges[id][0] = totalSupply();


    }

    function setCID(string memory _new, uint256 _seasonID) external onlyOwner NotNullString(_new) {
        if(_seasonID == 0 || _seasonID > seasonID) revert InvalidSeason();

        cids[_seasonID] = _new;
    }

    function endSeason() external onlyOwner {
        if(!breedingEnabled) revert NotCurrentlyBreeding();

        uint256 id = seasonID;

        breedingEnabled = false;

        mintRanges[id][1] = totalSupply();
    }

    function setBreedingFee(uint256 _fee) external onlyOwner {
        if(_fee == 0) revert NullNumber();
        breedingFee = _fee;
    }

    function setUSD(address[] memory _new) external onlyOwner {
        for(uint256 i = 0; i < _new.length;){

            if(_new[i] == address(0)) revert NullAddress();

            unchecked{
                i++;
            }
        }
        usdTokens = _new;
    }

    function setSplit(
        address[] memory _payees,
        uint16[] memory _shares
    ) external onlyOwner {

        if(_payees.length != _shares.length || _payees.length == 0) revert WrongLength();

        for(uint256 i = 0; i < _payees.length;){

            if(_payees[i] == address(0)) revert NullAddress();
            if(_shares[i] == 0) revert NullNumber();

            unchecked{
                i++;
            }
        }

        shares = _shares;
        payees = _payees;
    }

    function breed(uint256[2] memory raptors, uint256 usdArrIndex) external {
        if(!breedingEnabled) revert NotCurrentlyBreeding();
        
        if(raptors[0] == 0 || raptors[1] == 0) revert InvalidRaptor();

        if(raptors[0] == raptors[1]) revert InvalidRaptor();

        address caller = _msgSender();

        if(getOwnerOf(raptors[0]) != caller || getOwnerOf(raptors[1]) != caller) revert NotOwner();

        uint256 id = seasonID;

        if(
            bred[id][raptors[0]] || bred[id][raptors[1]]
        ) revert AlreadyBred();

        address usd = usdTokens[usdArrIndex];

        if(usd == address(0)) revert InvalidIndex();

        IERC20 token = IERC20(usd);

        uint256 amountApproved = token.allowance(caller,address(this));

        if(amountApproved < breedingFee) revert AmountApproved();

        token.transferFrom(caller,address(this),breedingFee);

        uint256 bal = token.balanceOf(address(this));

        splitFunds(bal,token);

        _mint(caller, 1);

    }

    function splitFunds(uint256 amount,IERC20 token) private {
        
        uint16 _totalShares = totalShares;

        uint16[] memory _shares = shares;

        address[] memory _payees = payees;


        for(uint256 i =0; i < _shares.length;){

            token.transfer(_payees[i], amount * _shares[i] / _totalShares);

            unchecked{
                i++;
            }
        }
    }

    function getOwnerOf(uint256 raptor) private view returns(address){
        return IERC721A(minter).ownerOf(raptor);
    }

    //This being public is required 
    function tokenURI(uint256 _tokenID) public view override(ERC721A,IERC721Metadata) returns (string memory){
        if(!_exists(_tokenID)) revert InvalidRaptor();

        string memory base = baseURI;
        string memory cid;
    
        for(uint256 i = 1; i <= seasonID;){

            uint256[2] memory range = mintRanges[i];

            if(range[1] == 0){
                cid = cids[i];
            }else {
                if(
                    _tokenID > range[0] && _tokenID <= range[1]
                ) cid = cids[i];
            }

            unchecked{
                i++;
            }
        }

        return string(abi.encodePacked(base,"/",cid,"/",string(abi.encodePacked(_tokenID)),".JSON"));
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
        if(msg.sender != stats) revert NotStatContract();
        _burn(tokenId, false);
    }

}