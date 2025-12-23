// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./MechaTest.t.sol";

contract MechaApprovalTest is MechaTest {
    uint256 amount;

    function setUp() public override {
        super.setUp();
        amount = mecha.MINT_PRICE();
    }

    // ============ approve() tests ============

    function testApproveByOwner() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        vm.prank(user1);
        mecha.approve(user2, tokenId);

        assertEq(mecha.getApproved(tokenId), user2);
    }

    function testApproveEmitsEvent() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        vm.expectEmit(true, true, true, false);
        emit Approval(user1, user2, tokenId);

        vm.prank(user1);
        mecha.approve(user2, tokenId);
    }

    function testApproveByOperator() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        vm.prank(user1);
        mecha.setApprovalForAll(user3, true);

        vm.prank(user3);
        mecha.approve(user2, tokenId);

        assertEq(mecha.getApproved(tokenId), user2);
    }

    function testApproveToCurrentOwnerReverts() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        vm.prank(user1);
        vm.expectRevert("Approval to current owner");
        mecha.approve(user1, tokenId);
    }

    function testApproveByNonOwnerReverts() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        vm.prank(user2);
        vm.expectRevert();
        mecha.approve(user3, tokenId);
    }

    function testApproveNonExistentTokenReverts() public {
        vm.prank(user1);
        vm.expectRevert();
        mecha.approve(user2, 999);
    }

    function testApproveRevokeApproval() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        vm.prank(user1);
        mecha.approve(user2, tokenId);

        assertEq(mecha.getApproved(tokenId), user2);

        vm.prank(user1);
        mecha.approve(address(0), tokenId);

        assertEq(mecha.getApproved(tokenId), address(0));
    }

    function testApproveChangeApproval() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        vm.prank(user1);
        mecha.approve(user2, tokenId);

        assertEq(mecha.getApproved(tokenId), user2);

        vm.prank(user1);
        mecha.approve(user3, tokenId);

        assertEq(mecha.getApproved(tokenId), user3);
    }

    // ============ setApprovalForAll() tests ============

    function testSetApprovalForAllTrue() public {
        vm.prank(user1);
        mecha.setApprovalForAll(user2, true);

        assertTrue(mecha.isApprovedForAll(user1, user2));
    }

    function testSetApprovalForAllFalse() public {
        vm.prank(user1);
        mecha.setApprovalForAll(user2, true);

        vm.prank(user1);
        mecha.setApprovalForAll(user2, false);

        assertFalse(mecha.isApprovedForAll(user1, user2));
    }

    function testSetApprovalForAllEmitsEvent() public {
        vm.expectEmit(true, true, false, false);
        emit ApprovalForAll(user1, user2, true);

        vm.prank(user1);
        mecha.setApprovalForAll(user2, true);
    }

    function testSetApprovalForAllCannotApproveSelf() public {
        vm.prank(user1);
        vm.expectRevert("Cannot approve self");
        mecha.setApprovalForAll(user1, true);
    }

    function testSetApprovalForAllMultipleOperators() public {
        vm.startPrank(user1);
        mecha.setApprovalForAll(user2, true);
        mecha.setApprovalForAll(user3, true);
        vm.stopPrank();

        assertTrue(mecha.isApprovedForAll(user1, user2));
        assertTrue(mecha.isApprovedForAll(user1, user3));
    }

    function testSetApprovalForAllIndependentPerOwner() public {
        vm.startPrank(user1);
        uint256 token1 = _mint(amount);
        mecha.setApprovalForAll(user2, true);
        vm.stopPrank();

        vm.startPrank(user3);
        uint256 token2 = _mint(amount);
        mecha.setApprovalForAll(user2, true);
        vm.stopPrank();

        assertTrue(mecha.isApprovedForAll(user1, user2));
        assertTrue(mecha.isApprovedForAll(user3, user2));

        // user2 can transfer both tokens
        vm.prank(user2);
        mecha.transferFrom(user1, user2, token1);

        vm.prank(user2);
        mecha.transferFrom(user3, user2, token2);

        assertEq(mecha.ownerOf(token1), user2);
        assertEq(mecha.ownerOf(token2), user2);
    }

    function testSetApprovalForAllToggle() public {
        vm.prank(user1);
        mecha.setApprovalForAll(user2, true);

        assertTrue(mecha.isApprovedForAll(user1, user2));

        vm.prank(user1);
        mecha.setApprovalForAll(user2, false);

        assertFalse(mecha.isApprovedForAll(user1, user2));

        vm.prank(user1);
        mecha.setApprovalForAll(user2, true);

        assertTrue(mecha.isApprovedForAll(user1, user2));
    }

    // ============ getApproved() tests ============

    function testGetApprovedReturnsZeroWhenNotApproved() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        assertEq(mecha.getApproved(tokenId), address(0));
    }

    function testGetApprovedNonExistentTokenReverts() public {
        vm.expectRevert();
        mecha.getApproved(999);
    }

    function testGetApprovedAfterTransfer() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        vm.prank(user1);
        mecha.approve(user2, tokenId);

        vm.prank(user1);
        mecha.transferFrom(user1, user3, tokenId);

        assertEq(mecha.getApproved(tokenId), address(0));
    }

    // ============ isApprovedForAll() tests ============

    function testIsApprovedForAllReturnsFalseByDefault() public {
        assertFalse(mecha.isApprovedForAll(user1, user2));
    }

    function testIsApprovedForAllReturnsTrueAfterApproval() public {
        vm.prank(user1);
        mecha.setApprovalForAll(user2, true);

        assertTrue(mecha.isApprovedForAll(user1, user2));
    }

    function testIsApprovedForAllReturnsFalseAfterRevocation() public {
        vm.prank(user1);
        mecha.setApprovalForAll(user2, true);

        vm.prank(user1);
        mecha.setApprovalForAll(user2, false);

        assertFalse(mecha.isApprovedForAll(user1, user2));
    }

    function testIsApprovedForAllIndependentOwners() public {
        vm.prank(user1);
        mecha.setApprovalForAll(user2, true);

        assertTrue(mecha.isApprovedForAll(user1, user2));
        assertFalse(mecha.isApprovedForAll(user3, user2));
    }
}

