interface IVerify {
    function verfySignature(uint8 v, bytes32 r, bytes32 s, address query) external returns(bool);
}