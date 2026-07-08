// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Vesting} from "../src/Vesting.sol";

contract VestingDeployment is Script {
    event log_string(string message);
    event log_address(address message);
    function setUp() public {}

    function run() public {
        // Get deployment parameters from environment variables or use defaults
        uint256 protocolId = vm.envOr("PROTOCOL_ID", uint256(1));
        address factory = vm.envOr("FACTORY_ADDRESS", msg.sender);
        address admin = vm.envOr("ADMIN_ADDRESS", msg.sender);

        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy Vesting contract
        Vesting vesting = new Vesting(protocolId, factory, admin);

        // Stop broadcasting
        vm.stopBroadcast();

        // Log deployment details
        logDeploymentInfo(address(vesting), protocolId, factory, admin);
    }

    function logDeploymentInfo(
        address vestingAddress,
        uint256 protocolId,
        address factory,
        address admin
    ) internal  {
        string memory chainName = getChainName(block.chainid);

        emit log_string("========== Vesting Deployment ==========");
        emit log_string(string(abi.encodePacked("Chain: ", chainName)));
        emit log_address(vestingAddress);
        emit log_string(string(abi.encodePacked("PROTOCOL_ID: ", vm.toString(protocolId))));
        emit log_string("FACTORY_ADDRESS:");
        emit log_address(factory);
        emit log_string("ADMIN_ADDRESS:");
        emit log_address(admin);
        emit log_string("=========================================");
    }

    function getChainName(uint256 chainId) internal pure returns (string memory) {
        if (chainId == 1) return "Ethereum Mainnet";
        if (chainId == 11155111) return "Sepolia Testnet";
        if (chainId == 8453) return "Base Mainnet";
        if (chainId == 84532) return "Base Sepolia Testnet";
        if (chainId == 42161) return "Arbitrum One";
        if (chainId == 421614) return "Arbitrum Sepolia Testnet";
        if (chainId == 137) return "Polygon Mainnet";
        if (chainId == 80002) return "Polygon Amoy Testnet";
        return "Unknown Chain";
    }
}
