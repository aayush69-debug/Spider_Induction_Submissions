// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./DeadMansSwitch.sol";

contract SwitchFactory {
    event SwitchCreated(address indexed owner, address switchAddress);

    mapping(address => address[]) public userSwitches;

    function createSwitch(uint256 checkInInterval, uint256 gracePeriod) external returns (address) {
        // Deploys a new DeadMansSwitch contract
        DeadMansSwitch newSwitch = new DeadMansSwitch(msg.sender, checkInInterval, gracePeriod);
        
        // Save it to the user's list
        userSwitches[msg.sender].push(address(newSwitch));
        
        emit SwitchCreated(msg.sender, address(newSwitch));
        return address(newSwitch);
    }

    function getSwitchesByOwner(address owner) external view returns (address[] memory) {
        return userSwitches[owner];
    }
}