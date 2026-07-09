// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Vesting} from "./Vesting.sol";

contract Factory {

    //Owner of the factory contracts
    address public owner;

    // Track total vesting contracts deployed globally
    uint256 public totalVestingContracts;

    // Map deployment ID to deployed Vesting contract address
    mapping(uint256 => address) public vestingContracts;

    // Map deployer address to an array of their deployed Vesting contracts
    mapping(address => address[]) public deployerToVestings;

    // Event emitted when a new Vesting contract is deployed
    event VestingDeployed(address indexed deployer, address vestingAddress, uint256 indexed contractId);

    error NotOwner();

    constructor () {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }


    /**
     * @notice Deploys a new Vesting contract and records the deployment tracking.
     */
    function deployVesting(address _admin) external onlyOwner returns (address) {
        // Increment the total counter
        totalVestingContracts++;
        uint256 currentId = totalVestingContracts;

        // Deploy the new Vesting contract (msg.sender acts as the factory)
        Vesting newVesting = new Vesting(currentId, msg.sender, _admin);

        // Store the contract address in the mappings
        vestingContracts[currentId] = address(newVesting);
        deployerToVestings[msg.sender].push(address(newVesting));

        emit VestingDeployed(msg.sender, address(newVesting), currentId);

        return address(newVesting);
    }

    /**
     * @notice Retrieves all Vesting contract addresses deployed by a specific address.
     */
    function getVestingsByDeployer(address _deployer) external view returns (address[] memory) {
        return deployerToVestings[_deployer];
    }

    function _onlyOwner() private view {
        if (msg.sender != owner) revert NotOwner();
    }
}
