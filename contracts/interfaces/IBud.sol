import "../ERC721A/IERC721AQueryable.sol";
interface IBud is IERC721AQueryable {
    function burnFirstAvailable(address) external returns(bool);
}