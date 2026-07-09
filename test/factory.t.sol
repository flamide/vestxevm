// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {IVesting} from "../src/IVesting.sol";
import {Factory} from "../src/Factory.sol";

contract VestingTest is Test {

    Factory public factory;
    address public admin = address(0x1);
    address public vestAdmin1 = address(0x2);
    address public vestUser = address(0x3);


    function setUp() public {
        vm.prank(admin);
        factory = new Factory();
    }

    function test_create_vesting() public {
        vm.startPrank(admin);
        address vestingContracts = factory.deployVesting(vestAdmin1);
        assertEq(admin, factory.owner());
        assertEq(factory.totalVestingContracts(), 1);
        assertEq(factory.vestingContracts(1), vestingContracts);
    }

    function test_vesting_created() public {
        vm.startPrank(admin);
        address vestingContracts = factory.deployVesting(vestAdmin1);
        assertEq(IVesting(vestingContracts).admin(), vestAdmin1);
    }

    function test_vesting_created_works() public {
        vm.startPrank(admin);
        address vestingContracts = factory.deployVesting(vestAdmin1);
        vm.startPrank(vestAdmin1);
        IVesting vest = IVesting(vestingContracts);
        vest.createCategory(1, 200, 30 ether);
        vest.createVesting(vestUser, 1);
        (, , , bool active) = vest.userData(vestUser, 1);
        assertTrue(active);
    }

}