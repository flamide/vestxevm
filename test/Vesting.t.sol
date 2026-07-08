// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Vesting} from "../src/Vesting.sol";

contract VestingTest is Test {

    Vesting public vesting;
    address public admin = address(0x1);
    address public factory = address(0x2);
    address public user = address(0x3);
    uint8 public categoryId = 1;
    uint256 public rate = 2;
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

    
}
