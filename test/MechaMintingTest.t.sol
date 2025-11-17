// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MechaTest.t.sol";

contract MechaMintingTest is MechaTest {
    uint256 amount;

    function setUp() public override {
        super.setUp();
        amount = mecha.MINT_PRICE();
    }

    function testMintWithRightPrice() public {
        vm.prank(user1);
        uint256 tokenId = _mintTo(amount);

        assertEq(mecha.ownerOf(tokenId), user1);
        assertEq(mecha.balanceOf(user1), 1);
    }
    
    function testMintHigherAmountRevert() public {
        vm.prank(user1);
        vm.expectRevert("Invalid amount of ether");

        _mintTo(amount + 1);
    }

    function testMintLowerAmountRevert() public {
        vm.prank(user1);
        vm.expectRevert("Invalid amount of ether");
        
        _mintTo(0);
    }

    function testMintTokenAttributesCreated() public {
        vm.prank(user1);
        uint256 tokenId = _mintTo(mecha.MINT_PRICE());
        Mecha.MechaAttributes memory attr = mecha.getAttributes(tokenId);

        assertGe(attr.strength, 1);
        assertLe(attr.strength, 99);

        assertGe(attr.health, 1);
        assertLe(attr.health, 99);

        assertGe(attr.speed, 1);
        assertLe(attr.speed, 99);
    }

    function testMintEventTransferValid() public {
        vm.prank(user1);
        vm.expectEmit();
        emit Transfer(address(0), address(user1), 1);

        _mintTo(amount);
    }

    function testMintEventMechaMintedValid() public {
        vm.prank(user1);
        vm.expectEmit(true, true, false, false);
        emit MechaMinted(user1, 1, 0, 0, 0, 0);

        _mintTo(amount);
    }

    function testSameUserMintingIds() public {
        vm.prank(user1);
        uint256 tokenId1 = _mintTo(amount);

        vm.prank(user1);
        uint256 tokenId2 = _mintTo(amount);

        assertEq(tokenId1, 1);
        assertEq(tokenId2, 2);
    }

    function testMultipleUsersMintingIds() public {
        vm.prank(user1);
        uint256 tokenId1 = _mintTo(amount);

        vm.prank(user2);
        uint256 tokenId2 = _mintTo(amount);

        vm.prank(user3);
        uint256 tokenId3 = _mintTo(amount);

        assertEq(tokenId1, 1);
        assertEq(tokenId2, 2);
        assertEq(tokenId3, 3);
    }

    function testMintedAmount() public {
        vm.prank(user1);
        _mintTo(amount);

        vm.prank(user2);
        _mintTo(amount);

        vm.prank(user1);
        _mintTo(amount);

        uint256 numOfUser1Tokens = mecha.balanceOf(user1);
        uint256 numOfUser2Tokens = mecha.balanceOf(user2);
        uint256 numOfTotalTokens = mecha.getActiveTokens();
        
        assertEq(numOfUser1Tokens, 2);
        assertEq(numOfUser2Tokens, 1);
        assertEq(numOfTotalTokens, 3);
    }
}