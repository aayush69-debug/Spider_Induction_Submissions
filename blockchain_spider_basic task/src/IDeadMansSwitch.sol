// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDeadMansSwitch {
    enum Status { Active, GracePeriod, Triggered, Cancelled }

    struct Beneficiary {
        address wallet;
        uint256 sharePercent; // Out of 100
    }

    event CheckedIn(address owner, uint256 timestamp);
    event GracePeriodStarted(uint256 deadline);
    event SwitchTriggered(uint256 timestamp);
    event BeneficiaryClaimed(address beneficiary, uint256 amount);
    event Cancelled(address owner);

    function deposit(address token, uint256 amount) external payable;
    function checkIn() external;
    function addBeneficiary(address wallet, uint256 share) external;
    function removeBeneficiary(address wallet) external;
    function triggerGracePeriod() external;
    function claim() external;
    function cancel() external;
}