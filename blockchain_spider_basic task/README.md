# 🕸️ Decentralized Dead Man's Switch Vault

An advanced smart contract system built using Foundry, implementing a time-locked decentralized inheritance and backup asset distribution safe. 

## 🏗️ Architecture & Component Design

The system separates core interfaces, implementation logic, and deployment factories to ensure scalable architectural standards.

* **`IDeadMansSwitch.sol`**: Explicit interface layout separating contract design from core functionality.
* **`DeadMansSwitch.sol`**: Core logic implementing the state machine rules (`Active`, `GracePeriod`, `Triggered`, `Cancelled`). Features a gas-optimized custom Reentrancy Guard to safeguard payouts.
* **`SwitchFactory.sol`**: Factory design pattern allowing scalable, independent instances of individual user safes.

## 🛡️ Security Implementations Tested
* **Reentrancy Guard**: Integrated on user asset claims to block malicious external contract withdraw vectors.
* **State Machine Validation**: Multi-phase state checks ensuring zero access to assets until grace periods expire entirely.

## 🧪 Testing Suite (Foundry Time-Simulation)
The time-dependent execution functions are fully verified via state-level simulation testing using `vm.warp()` to fast-forward block timestamps.

To execute the test script and verify coverage:
```bash
forge test -vv