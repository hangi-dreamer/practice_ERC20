// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";
import "../src/ERC20.sol";

contract DreamTokenTest2 is Test {
    address internal constant alice = address(1);
    address internal constant bob = address(2);

    ERC20 drm;

    function setUp() public {
        drm = new ERC20("DREAM", "DRM");
        drm.transfer(alice, 50 ether);
        drm.transfer(bob, 50 ether);
    }
    
    function testFailPauseNotOwner() public {
        vm.prank(alice);
        drm.pause();
    }

    function testFailTransfer() public {
        drm.pause();
        vm.prank(alice);
        drm.transfer(bob, 10 ether);
    }

    function testFailTransferFrom() public {
        drm.pause();
        vm.prank(alice);
        drm.approve(msg.sender, 10 ether);
        drm.transferFrom(alice, bob, 10 ether);
    }
}
