// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./MechaTest.t.sol";

contract MechaBurnTest is MechaTest {
    uint256 amount;

    function setUp() public override {
        super.setUp();
        amount = mecha.MINT_PRICE();
    }
    
    function testBurnByOwner() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);
        
        vm.prank(user1);
        mecha.burn(tokenId);
        
        assertEq(mecha.balanceOf(user1), 0);
        
        vm.expectRevert();
        mecha.ownerOf(tokenId);
    }
    
    function testBurnDecreasesBalance() public {
        vm.startPrank(user1);
        uint256 tokenId1 = _mint(amount);
        _mint(amount);
        _mint(amount);
        
        assertEq(mecha.balanceOf(user1), 3);

        mecha.burn(tokenId1);
        
        assertEq(mecha.balanceOf(user1), 2);
    }
    
    function testBurnEmitsTransferEvent() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);
        
        vm.expectEmit(true, true, true, false);
        emit Transfer(user1, address(0), tokenId);
        
        vm.prank(user1);
        mecha.burn(tokenId);
    }
    
    function testBurnPreservesAttributes() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);
        
        Mecha.MechaAttributes memory attrBefore = mecha.getAttributes(tokenId);
        
        vm.prank(user1);
        mecha.burn(tokenId);
        
        Mecha.MechaAttributes memory attrAfter = mecha.getAttributes(tokenId);
        
        assertNotEq(attrAfter.strength, attrBefore.strength);
        assertNotEq(attrAfter.health, attrBefore.health);
        assertNotEq(attrAfter.speed, attrBefore.speed);

        assertEq(attrAfter.strength, 0);
        assertEq(attrAfter.health, 0);
        assertEq(attrAfter.speed, 0);
    }
    
    function testBurnByNonOwner() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);
        
        vm.prank(user2);
        vm.expectRevert();
        mecha.burn(tokenId);
    }
    
    function testBurnNonExistentToken() public {
        vm.prank(user1);
        vm.expectRevert();
        mecha.burn(999);
    }
    
    function testBurnAlreadyBurnedToken() public {
        vm.startPrank(user1);
        uint256 tokenId = _mint(amount);
        mecha.burn(tokenId);
        
        vm.expectRevert();
        mecha.burn(tokenId);
        vm.stopPrank();
    }
    
    function testBurnResetsApproval() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);
        
        vm.prank(user1);
        mecha.approve(user2, tokenId);
        
        assertEq(mecha.getApproved(tokenId), user2);
        
        vm.prank(user1);
        mecha.burn(tokenId);
        
        vm.expectRevert();
        mecha.getApproved(tokenId);
    }
    
    function testOwnerOfAfterBurn() public {
        vm.prank(user1);
        uint256 tokenId = _mint(amount);
        
        assertEq(mecha.ownerOf(tokenId), user1);
        
        vm.prank(user1);
        mecha.burn(tokenId);
        
        vm.expectRevert();
        mecha.ownerOf(tokenId);
    }
    
    function testMultipleBurns() public {
        // Setup: minta 5 tokens
        vm.startPrank(user1);
        uint256 token1 = _mint(amount);
        uint256 token2 = _mint(amount);
        uint256 token3 = _mint(amount);
        uint256 token4 = _mint(amount);
        uint256 token5 = _mint(amount);
        
        assertEq(mecha.balanceOf(user1), 5);

        mecha.burn(token1);
        mecha.burn(token3);
        mecha.burn(token5);
        vm.stopPrank();
        
        assertEq(mecha.balanceOf(user1), 2);
        
        assertEq(mecha.ownerOf(token2), user1);
        assertEq(mecha.ownerOf(token4), user1);
        
        vm.expectRevert();
        mecha.ownerOf(token1);
        
        vm.expectRevert();
        mecha.ownerOf(token3);
        
        vm.expectRevert();
        mecha.ownerOf(token5);
    }
}