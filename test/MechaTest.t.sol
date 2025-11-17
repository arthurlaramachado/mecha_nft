// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//Forge can re-run your tests when you make changes to your files using forge test --watch.
//By default, only changed test files are re-run. If you want to re-run all tests on a change, you can use forge test --watch --run-all.

import "forge-std/Test.sol";
import "../src/Mecha.sol";

contract MechaTest is Test {
    Mecha public mecha;
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public user3 = address(0x3);

    event Transfer(
        address indexed _from, 
        address indexed _to, 
        uint256 indexed _tokenId
    );

    event Approval(
        address indexed _owner, 
        address indexed _approved, 
        uint256 indexed _tokenId
    );

    event ApprovalForAll(
        address indexed _owner, 
        address indexed _operator, 
        bool _approved
    );

    event MechaMinted(
        address indexed minter,
        uint256 indexed tokenId,
        uint8 strength,
        uint8 health,
        uint8 speed,
        uint256 mintPrice
    );
    
    function setUp() virtual public {
        mecha = new Mecha();
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);
    }

    /**
    *   @dev Pranks the user to mint an NFT
    *   @param amount The amount to try minting the NFT
    */
    function _mint(uint256 amount) internal returns (uint256 tokenId) {
        tokenId = mecha.mint{value: amount}();
    }
}