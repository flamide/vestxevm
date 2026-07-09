// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Vesting} from "../src/Vesting.sol";

contract VestingTest is Test {

    Vesting public vesting;
    address public admin = address(0x1);
    address public factory = address(0x2);
    address public user = address(0x3);
    address public fakeUser = address(0x4);
    uint8 public categoryId = 1;
    uint256 public rate = 200;
    uint256 public totalVestAmount = 2 ether;
   

    function setUp() public {
        vm.prank(admin);
        vesting = new Vesting(1, factory, admin);
    }

    function test_create_catogory() public {
        //admin creates category for vesing plan
        vm.startPrank(admin);
        vesting.createCategory(categoryId, rate, totalVestAmount);
        assertTrue(vesting.isVestingCreated(categoryId));
    }

    
    function test_create_vesting() public {
        //admin creates category for vesing plan
        vm.startPrank(admin);
        vesting.createCategory(categoryId, rate, totalVestAmount);
        //admin register user for the vesting plan
        vesting.createVesting(user, categoryId);
        assertEq(vesting.balanceOf(user, categoryId), 0);
    }

    function test_vest_token() public {
        vm.startPrank(admin);
        vesting.createCategory(categoryId, rate, totalVestAmount);
        //admin register user for the vesting plan
        vesting.createVesting(user, categoryId);
        vm.warp(block.timestamp + 1 days);
        vm.startPrank(user);
        uint256 vestedAmount =  vesting.getTotalVest(user, categoryId);
        console2.log("vested amount: %s", vestedAmount);
        vesting.vest(categoryId);
        assertEq(vesting.balanceOf(user, categoryId), vestedAmount);
    }

    function test_pause_protocol() public {
        vm.startPrank(admin);
        vesting.createCategory(categoryId, rate, totalVestAmount);
        //admin register user for the vesting plan
        vesting.createVesting(user, categoryId);
        vesting.toggleVesting();
        vm.warp(block.timestamp + 1 days);
        vm.startPrank(user);
        vm.expectRevert();
        vesting.vest(categoryId);
        
    }

    function test_pause_user() public {
        vm.startPrank(admin);
        vesting.createCategory(categoryId, rate, totalVestAmount);
        //admin register user for the vesting plan
        vesting.createVesting(user, categoryId);
        vesting.toggleUser(user, categoryId);
        vm.warp(block.timestamp + 1 days);
        vm.startPrank(user);
        vm.expectRevert();
        vesting.vest(categoryId);
    }

    function test_blacklist_user() public {
        vm.startPrank(admin);
        vesting.createCategory(categoryId, rate, totalVestAmount);
        //admin register user for the vesting plan
        vesting.createVesting(user, categoryId);
        vesting.blacklistUser(user, categoryId);
        vm.warp(block.timestamp + 1 days);
        vm.startPrank(user);
        vm.expectRevert();
        vesting.vest(categoryId);
    }

    function test_invalid_cant_vest() public {
        vm.startPrank(admin);
        vesting.createCategory(categoryId, rate, totalVestAmount);
        //admin register user for vesting plan
        vesting.createVesting(user, categoryId);
        //invalid user tries to claim vest
        vm.warp(block.timestamp + 1 days);
        vm.startPrank(fakeUser);
        vm.expectRevert();
        vesting.vest(categoryId);

    }
    
}
