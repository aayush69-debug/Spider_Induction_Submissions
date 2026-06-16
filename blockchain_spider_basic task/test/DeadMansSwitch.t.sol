// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/DeadMansSwitch.sol";

contract DeadMansSwitchTest is Test {
    DeadMansSwitch public dms;
    
    // Setting up some fake wallet addresses for testing
    address public owner = address(1);
    address public beneficiary1 = address(2);
    
    uint256 public checkInInterval = 3600; // 1 hour in seconds
    uint256 public gracePeriod = 1800;     // 30 mins in seconds

    function setUp() public {
        // vm.startPrank tells Foundry: "Pretend I am the owner for these next lines"
        vm.startPrank(owner);
        
        // 1. Deploy the contract
        dms = new DeadMansSwitch(owner, checkInInterval, gracePeriod);
        
        // 2. Add a beneficiary with 100% share
        dms.addBeneficiary(beneficiary1, 100);
        
        // 3. Give our fake owner 10 fake ETH, and deposit 1 ETH into the vault
        vm.deal(owner, 10 ether);
        dms.deposit{value: 1 ether}(address(0), 1 ether);
        
        vm.stopPrank();
    }

    function testCheckInResetsTimer() public {
        vm.prank(owner);
        dms.checkIn();
        
        assertEq(uint(dms.status()), uint(IDeadMansSwitch.Status.Active));
    }

    function testTriggerGracePeriodWithWarp() public {
        // Fast-forward time past the 1-hour check-in interval using vm.warp
        vm.warp(block.timestamp + 3601); 
        
        // Anyone can trigger the grace period, so we don't need a prank here
        dms.triggerGracePeriod();
        
        assertEq(uint(dms.status()), uint(IDeadMansSwitch.Status.GracePeriod));
    }

    function testBeneficiaryClaimAfterWarp() public {
        // 1. Fast forward past the check-in interval
        vm.warp(block.timestamp + 3601);
        dms.triggerGracePeriod();
        
        // 2. Fast forward past the 30-minute grace period
        vm.warp(block.timestamp + 1801);
        
        // 3. Beneficiary claims the ETH
        vm.prank(beneficiary1);
        dms.claim();
        
        // Check if the contract status is triggered and beneficiary got paid
        assertEq(uint(dms.status()), uint(IDeadMansSwitch.Status.Triggered));
        assertEq(beneficiary1.balance, 1 ether);
    }
    
    function testCancelRefundsOwner() public {
        vm.prank(owner);
        dms.cancel();
        
        assertEq(uint(dms.status()), uint(IDeadMansSwitch.Status.Cancelled));
        assertEq(owner.balance, 10 ether); // Owner gets their 1 ETH back
    }
}