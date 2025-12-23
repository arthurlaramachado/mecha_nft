// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./MechaTest.t.sol";

contract MechaERC165Test is MechaTest {
    // ERC165 interface ID
    bytes4 constant ERC165_INTERFACE_ID = 0x01ffc9a7;
    // ERC721 interface ID
    bytes4 constant ERC721_INTERFACE_ID = 0x80ac58cd;

    function testSupportsERC165() public {
        assertTrue(mecha.supportsInterface(ERC165_INTERFACE_ID));
    }

    function testSupportsERC721() public {
        assertTrue(mecha.supportsInterface(ERC721_INTERFACE_ID));
    }

    function testDoesNotSupportRandomInterface() public {
        bytes4 randomInterface = 0x12345678;
        assertFalse(mecha.supportsInterface(randomInterface));
    }

    function testSupportsInterfaceRevertsOnInvalidInterfaceId() public {
        bytes4 invalidInterface = 0xffffffff;
        vm.expectRevert();
        mecha.supportsInterface(invalidInterface);
    }

    function testSupportsInterfaceReturnsFalseForZero() public {
        bytes4 zeroInterface = 0x00000000;
        assertFalse(mecha.supportsInterface(zeroInterface));
    }
}

