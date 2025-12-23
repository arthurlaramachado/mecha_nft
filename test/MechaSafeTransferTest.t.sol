// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./MechaTest.t.sol";
import "../src/utils/erc721-token-receiver.sol";

// Mock contract that implements ERC721TokenReceiver correctly
contract ERC721Receiver is ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return 0x150b7a02;
    }
}

// Mock contract that does NOT implement ERC721TokenReceiver
contract NonReceiver {
    // Empty contract - no onERC721Received function
}

// Mock contract that implements ERC721TokenReceiver incorrectly
contract BadReceiver is ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return 0x00000000; // Wrong magic value
    }
}

contract MechaSafeTransferTest is MechaTest {
    uint256 amount;
    ERC721Receiver public receiver;
    NonReceiver public nonReceiver;
    BadReceiver public badReceiver;

    function setUp() public override {
        super.setUp();
        amount = mecha.MINT_PRICE();
        receiver = new ERC721Receiver();
        nonReceiver = new NonReceiver();
        badReceiver = new BadReceiver();
    }

    function testSafeTransferFromWithoutData() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        vm.prank(user1);
        mecha.safeTransferFrom(user1, user2, tokenId);

        assertEq(mecha.ownerOf(tokenId), user2);
        assertEq(mecha.balanceOf(user1), 0);
        assertEq(mecha.balanceOf(user2), 1);
    }

    function testSafeTransferFromWithData() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        bytes memory data = "test data";
        vm.prank(user1);
        mecha.safeTransferFrom(user1, user2, tokenId, data);

        assertEq(mecha.ownerOf(tokenId), user2);
        assertEq(mecha.balanceOf(user1), 0);
        assertEq(mecha.balanceOf(user2), 1);
    }

    function testSafeTransferFromEmitsEvent() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        vm.expectEmit(true, true, true, false);
        emit Transfer(user1, user2, tokenId);

        vm.prank(user1);
        mecha.safeTransferFrom(user1, user2, tokenId);
    }

    function testSafeTransferFromResetsApproval() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        vm.prank(user1);
        mecha.approve(user3, tokenId);

        assertEq(mecha.getApproved(tokenId), user3);

        vm.prank(user1);
        mecha.safeTransferFrom(user1, user2, tokenId);

        assertEq(mecha.getApproved(tokenId), address(0));
    }

    function testSafeTransferFromByApprovedAddress() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        vm.prank(user1);
        mecha.approve(user2, tokenId);

        vm.prank(user2);
        mecha.safeTransferFrom(user1, user3, tokenId);

        assertEq(mecha.ownerOf(tokenId), user3);
    }

    function testSafeTransferFromByOperator() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        vm.prank(user1);
        mecha.setApprovalForAll(user2, true);

        vm.prank(user2);
        mecha.safeTransferFrom(user1, user3, tokenId);

        assertEq(mecha.ownerOf(tokenId), user3);
    }

    function testSafeTransferFromToContractReceiver() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        vm.prank(user1);
        mecha.safeTransferFrom(user1, address(receiver), tokenId);

        assertEq(mecha.ownerOf(tokenId), address(receiver));
    }

    function testSafeTransferFromToContractReceiverWithData() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        bytes memory data = "custom data";
        vm.prank(user1);
        mecha.safeTransferFrom(user1, address(receiver), tokenId, data);

        assertEq(mecha.ownerOf(tokenId), address(receiver));
    }

    function testSafeTransferFromToNonReceiverContractReverts() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        vm.prank(user1);
        // When a contract doesn't implement onERC721Received, the call will fail
        // The contract checks code.length > 0, then tries to call onERC721Received
        // which will revert because the function doesn't exist
        vm.expectRevert();
        mecha.safeTransferFrom(user1, address(nonReceiver), tokenId);
    }

    function testSafeTransferFromToBadReceiverContractReverts() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        vm.prank(user1);
        vm.expectRevert("Unable to receive NFT");
        mecha.safeTransferFrom(user1, address(badReceiver), tokenId);
    }

    function testSafeTransferFromWithoutPermission() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        vm.prank(user2);
        vm.expectRevert();
        mecha.safeTransferFrom(user1, user2, tokenId);
    }

    function testSafeTransferFromToZeroAddress() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        vm.prank(user1);
        vm.expectRevert();
        mecha.safeTransferFrom(user1, address(0), tokenId);
    }

    function testSafeTransferFromNonExistentToken() public {
        vm.prank(user1);
        vm.expectRevert();
        mecha.safeTransferFrom(user1, user2, 999);
    }

    function testSafeTransferFromWrongOwner() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        vm.prank(user1);
        vm.expectRevert();
        mecha.safeTransferFrom(user2, user1, tokenId);
    }

    function testSafeTransferFromSelfTransfer() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        vm.prank(user1);
        vm.expectRevert();
        mecha.safeTransferFrom(user1, user1, tokenId);
    }

    function testSafeTransferFromAfterApprovalRevoked() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        vm.prank(user1);
        mecha.approve(user2, tokenId);

        vm.prank(user1);
        mecha.approve(address(0), tokenId);

        vm.prank(user2);
        vm.expectRevert();
        mecha.safeTransferFrom(user1, user3, tokenId);
    }
}

