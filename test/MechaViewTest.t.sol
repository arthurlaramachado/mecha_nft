// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./MechaTest.t.sol";

contract MechaViewTest is MechaTest {
    uint256 amount;

    function setUp() public override {
        super.setUp();
        amount = mecha.MINT_PRICE();
    }

    // ============ balanceOf() tests ============

    function testBalanceOfZeroAddressReverts() public {
        vm.expectRevert(abi.encodeWithSelector(Mecha.InvalidAddress.selector, address(0)));
        mecha.balanceOf(address(0));
    }

    function testBalanceOfReturnsZeroForNewAddress() public {
        address newUser = address(0x999);
        assertEq(mecha.balanceOf(newUser), 0);
    }

    function testBalanceOfIncreasesAfterMint() public {
        assertEq(mecha.balanceOf(user1), 0);

        vm.prank(user1);
        _mint(amount);

        assertEq(mecha.balanceOf(user1), 1);

        vm.prank(user1);
        _mint(amount);

        assertEq(mecha.balanceOf(user1), 2);
    }

    function testBalanceOfDecreasesAfterTransfer() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        assertEq(mecha.balanceOf(user1), 1);
        assertEq(mecha.balanceOf(user2), 0);

        vm.prank(user1);
        mecha.transferFrom(user1, user2, tokenId);

        assertEq(mecha.balanceOf(user1), 0);
        assertEq(mecha.balanceOf(user2), 1);
    }

    function testBalanceOfDecreasesAfterBurn() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        assertEq(mecha.balanceOf(user1), 1);

        vm.prank(user1);
        mecha.burn(tokenId);

        assertEq(mecha.balanceOf(user1), 0);
    }

    // ============ ownerOf() tests ============

    function testOwnerOfNonExistentTokenReverts() public {
        vm.expectRevert(abi.encodeWithSelector(Mecha.InvalidOwner.selector, address(0)));
        mecha.ownerOf(999);
    }

    function testOwnerOfBurnedTokenReverts() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        vm.prank(user1);
        mecha.burn(tokenId);

        vm.expectRevert(abi.encodeWithSelector(Mecha.InvalidOwner.selector, address(0)));
        mecha.ownerOf(tokenId);
    }

    function testOwnerOfReturnsCorrectOwner() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        assertEq(mecha.ownerOf(tokenId), user1);
    }

    function testOwnerOfChangesAfterTransfer() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        assertEq(mecha.ownerOf(tokenId), user1);

        vm.prank(user1);
        mecha.transferFrom(user1, user2, tokenId);

        assertEq(mecha.ownerOf(tokenId), user2);
    }

    // ============ getAttributes() tests ============

    function testGetAttributesReturnsCorrectValues() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        Mecha.MechaAttributes memory attr = mecha.getAttributes(tokenId);

        assertGe(attr.strength, 1);
        assertLe(attr.strength, 99);
        assertGe(attr.health, 1);
        assertLe(attr.health, 99);
        assertGe(attr.speed, 1);
        assertLe(attr.speed, 99);
    }

    function testGetAttributesReturnsZeroAfterBurn() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        Mecha.MechaAttributes memory attrBefore = mecha.getAttributes(tokenId);

        vm.prank(user1);
        mecha.burn(tokenId);

        Mecha.MechaAttributes memory attrAfter = mecha.getAttributes(tokenId);

        assertEq(attrAfter.strength, 0);
        assertEq(attrAfter.health, 0);
        assertEq(attrAfter.speed, 0);
    }

    function testGetAttributesNonExistentToken() public {
        Mecha.MechaAttributes memory attr = mecha.getAttributes(999);

        assertEq(attr.strength, 0);
        assertEq(attr.health, 0);
        assertEq(attr.speed, 0);
    }

    function testGetAttributesPersistsAfterTransfer() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        Mecha.MechaAttributes memory attrBefore = mecha.getAttributes(tokenId);

        vm.prank(user1);
        mecha.transferFrom(user1, user2, tokenId);

        Mecha.MechaAttributes memory attrAfter = mecha.getAttributes(tokenId);

        assertEq(attrBefore.strength, attrAfter.strength);
        assertEq(attrBefore.health, attrAfter.health);
        assertEq(attrBefore.speed, attrAfter.speed);
    }

    // ============ getActiveTokens() tests ============

    function testGetActiveTokensStartsAtZero() public {
        assertEq(mecha.getActiveTokens(), 0);
    }

    function testGetActiveTokensIncreasesAfterMint() public {
        vm.prank(user1);
        _mint(amount);

        assertEq(mecha.getActiveTokens(), 1);

        vm.prank(user2);
        _mint(amount);

        assertEq(mecha.getActiveTokens(), 2);

        vm.prank(user1);
        _mint(amount);

        assertEq(mecha.getActiveTokens(), 3);
    }

    function testGetActiveTokensDecreasesAfterBurn() public {
        vm.prank(user1);
        uint256 tokenId1 = _mint(amount);

        vm.prank(user2);
        uint256 tokenId2 = _mint(amount);

        assertEq(mecha.getActiveTokens(), 2);

        vm.prank(user1);
        mecha.burn(tokenId1);

        assertEq(mecha.getActiveTokens(), 1);

        vm.prank(user2);
        mecha.burn(tokenId2);

        assertEq(mecha.getActiveTokens(), 0);
    }

    function testGetActiveTokensUnaffectedByTransfer() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);

        assertEq(mecha.getActiveTokens(), 1);

        vm.prank(user1);
        mecha.transferFrom(user1, user2, tokenId);

        assertEq(mecha.getActiveTokens(), 1);
    }

    function testGetActiveTokensMultipleBurns() public {
        vm.startPrank(user1);
        uint256 token1 = _mint(amount);
        uint256 token2 = _mint(amount);
        uint256 token3 = _mint(amount);
        vm.stopPrank();

        assertEq(mecha.getActiveTokens(), 3);

        vm.prank(user1);
        mecha.burn(token1);

        assertEq(mecha.getActiveTokens(), 2);

        vm.prank(user1);
        mecha.burn(token2);

        assertEq(mecha.getActiveTokens(), 1);

        vm.prank(user1);
        mecha.burn(token3);

        assertEq(mecha.getActiveTokens(), 0);
    }

    // ============ name and symbol tests ============

    function testName() public {
        assertEq(mecha.name(), "Mecha");
    }

    function testSymbol() public {
        assertEq(mecha.symbol(), "MCH");
    }

    // ============ MINT_PRICE tests ============

    function testMintPrice() public {
        assertEq(mecha.MINT_PRICE(), 0.001 ether);
    }
}

