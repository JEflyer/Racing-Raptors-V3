interface IRate {
    function acceptUpdateFromDRS(uint256 numRaptor) external returns(bool);
    function acceptUpdateFromSS(uint256 numRaptor) external returns(bool);
    function acceptUpdateFromLPS(uint256 numRaptor) external returns(bool);
    function acceptUpdateFromRCS(uint256 numRaptor) external returns(bool);
    function acceptUpdateFromGame(uint256 numBurned) external returns(bool);
    function acceptUpdateFromRCT(uint256 numBurned) external returns(bool);
    function acceptUpdateFromMarketplace(uint256 numBurned,uint256 averagePrice) external returns(bool);
    function acceptUpdateFromVB(uint256 numBurned, uint256 numMinted) external returns(bool);
    function retrieveDetails() external view returns(uint256,uint256,uint256);
}