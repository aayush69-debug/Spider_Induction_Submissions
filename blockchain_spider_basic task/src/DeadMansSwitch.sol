// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IDeadMansSwitch.sol";

// Minimal interface for ERC20 transfers
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract DeadMansSwitch is IDeadMansSwitch {
    address public owner;
    uint256 public checkInInterval;
    uint256 public gracePeriod;
    uint256 public lastCheckIn;
    Status public status;

    Beneficiary[] public beneficiaries;
    uint256 public totalSharePercent;

    // Custom Reentrancy Guard
    bool private locked;
    modifier nonReentrant() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor(address _owner, uint256 _checkInInterval, uint256 _gracePeriod) {
        owner = _owner;
        checkInInterval = _checkInInterval;
        gracePeriod = _gracePeriod;
        lastCheckIn = block.timestamp;
        status = Status.Active;
    }

    function deposit(address token, uint256 amount) external payable onlyOwner {
        if (token == address(0)) {
            require(msg.value > 0, "Must send ETH");
        } else {
            require(msg.value == 0, "Do not send ETH with ERC20");
            require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        }
    }

    function checkIn() external onlyOwner {
        require(status == Status.Active || status == Status.GracePeriod, "Switch triggered or cancelled");
        lastCheckIn = block.timestamp;
        status = Status.Active;
        emit CheckedIn(owner, block.timestamp);
    }

    function addBeneficiary(address wallet, uint256 share) external onlyOwner {
        require(totalSharePercent + share <= 100, "Total shares exceed 100%");
        beneficiaries.push(Beneficiary({wallet: wallet, sharePercent: share}));
        totalSharePercent += share;
    }

    function removeBeneficiary(address wallet) external onlyOwner {
        for (uint i = 0; i < beneficiaries.length; i++) {
            if (beneficiaries[i].wallet == wallet) {
                totalSharePercent -= beneficiaries[i].sharePercent;
                beneficiaries[i] = beneficiaries[beneficiaries.length - 1];
                beneficiaries.pop();
                break;
            }
        }
    }

    function triggerGracePeriod() external {
        require(status == Status.Active, "Not in Active state");
        require(block.timestamp > lastCheckIn + checkInInterval, "Check-in interval not passed");
        
        status = Status.GracePeriod;
        emit GracePeriodStarted(lastCheckIn + checkInInterval + gracePeriod);
    }

    function claim() external nonReentrant {
        require(status == Status.GracePeriod || status == Status.Triggered, "Not claimable");
        require(block.timestamp > lastCheckIn + checkInInterval + gracePeriod, "Grace period not over");
        
        if (status == Status.GracePeriod) {
            status = Status.Triggered;
            emit SwitchTriggered(block.timestamp);
        }

        uint256 ethBalance = address(this).balance;
        
        for (uint i = 0; i < beneficiaries.length; i++) {
            address bWallet = beneficiaries[i].wallet;
            uint256 bShare = beneficiaries[i].sharePercent;
            
            if (ethBalance > 0) {
                uint256 payout = (ethBalance * bShare) / 100;
                (bool success, ) = bWallet.call{value: payout}("");
                require(success, "ETH transfer failed");
                emit BeneficiaryClaimed(bWallet, payout);
            }
        }
    }

    function cancel() external onlyOwner {
        require(status == Status.Active || status == Status.GracePeriod, "Cannot cancel now");
        status = Status.Cancelled;
        
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            (bool success, ) = owner.call{value: ethBalance}("");
            require(success, "Refund failed");
        }
        emit Cancelled(owner);
    }
}