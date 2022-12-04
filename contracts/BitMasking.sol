// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

//import "hardhat/console.sol";

contract BitMasking {
    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // function unpack() public view {
    //     // first64= 6 , second64 = 7, third64 = 8, fourth64 = 9
    //     uint256 whatever = 0x0000000000000009000000000000000800000000000000070000000000000006;

    //     console.log(whatever & _BITMASK_ADDRESS_DATA_ENTRY); // 0-63 first64Bit, print(6)
    //     console.log((whatever >> 64) & _BITMASK_ADDRESS_DATA_ENTRY); // 64-127 , second64Bit,print(7)
    //     console.log((whatever >> 128) & _BITMASK_ADDRESS_DATA_ENTRY); // 128-191 , third64Bit,print(8)
    //     console.log(whatever >> 192); // 192-255 , fourth64Bit,print(9)
    //     console.logBytes(abi.encodePacked(whatever & _BITMASK_ADDRESS_DATA_ENTRY));
    // }

    function pack()
        public
        pure
        returns (
            /*uint64 integer1,uint64 integer2,uint64 integer3,uint64 integer4*/
            uint256
        )
    {
        uint64 integer1 = 0xf000000000000006;
        uint64 integer2 = 0xa000000000000007;
        uint64 integer3 = 0xb000000000000008;
        uint64 integer4 = 0xc000000000000009;

        uint256 result = uint256(0);

        return result | integer1 | (uint256(integer2) << 64) | (uint256(integer3) << 128) | (uint256(integer4) << 192);
    }

    // function bar2() public view {
    //     uint256 whatever = 0xffffffff88887777666655555B38Da6a701c568545dCfcB03FcB875f56beddC4;
    //     console.log(address(uint160(whatever)));
    //     console.logBytes(abi.encodePacked(uint64(whatever >> 160)));
    //     console.log();
    // }
}
