# CrowdFunding

A minimal, campaign-based crowdfunding smart contract written in Solidity and tested with Foundry.

![Solidity](https://img.shields.io/badge/Solidity-%5E0.8.19-363636?logo=solidity&logoColor=white)
![Foundry](https://img.shields.io/badge/Built%20with-Foundry-2A2A2A?logo=foundry&logoColor=white)
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)

## Overview

`CrowdFunding` is a single-contract platform where anyone can launch a funding campaign with a goal and a deadline. Contributors send ETH while the campaign is open. If the goal is reached before the deadline, the creator withdraws the raised funds. If the deadline passes without the goal being met, contributors can reclaim what they put in.

Each campaign is identified by an incremental ID and tracks its creator, goal, deadline, total raised, and a per-address ledger of contributions. The project is built and tested entirely with Foundry, with unit tests covering campaign creation, donations, withdrawals, refunds, and the main revert paths.

## Contract

The contract lives in `src/CrowdFunding.sol`. Each campaign is stored in the following structure, keyed by campaign ID:

```solidity
struct Campaign {
    address payable creator;
    uint256 goal;
    uint256 deadline;
    uint256 amtRaised;
    mapping(address => uint256) donors;
}
```

State is held in `mapping(uint256 => Campaign) public Campaigns`, and `campaignCount` (starting at 1) assigns the next campaign ID.

### Functions

**`createCampaign(uint256 goal, uint256 duration)`**
Creates a new campaign with `msg.sender` as the creator. Requires `goal > 0` and `duration > 0`. The campaign `deadline` is set from the `duration` argument and `amtRaised` starts at 0. Emits `CampaignCreated`.

**`donate(uint256 campaignID)` (payable)**
Contributes ETH to a campaign. Requires `msg.value > 0` and that the campaign is still open (`block.timestamp < deadline`). Adds the value to both the sender's recorded contribution and the campaign's `amtRaised`. Emits `Donated`.

**`withdraw(uint256 campaignID)`**
Lets the creator pull the raised funds. Requires that the caller is the creator, the campaign is still open (`block.timestamp < deadline`), and the goal has been met (`amtRaised >= goal`). Transfers `amtRaised` to the creator. Emits `Withdrawn`.

**`refund(uint256 campaignID)`**
Lets a contributor reclaim their ETH. Requires that the campaign has ended (`block.timestamp > deadline`) and the goal was not met (`amtRaised < goal`). Sends the caller's recorded contribution back via a low-level `call`. Emits `Refunded`.

### Events

| Event | Parameters |
| --- | --- |
| `CampaignCreated` | `campaignID`, `creator`, `goal`, `deadline` |
| `Donated` | `campaignID`, `donor`, `amount` |
| `Withdrawn` | `campaignID`, `creator`, `amount` |
| `Refunded` | `campaignID`, `donor`, `amount` |

## Features

- Create campaigns with a custom funding goal and deadline
- Accept ETH contributions while a campaign is active
- Per-address contribution tracking for accurate refunds
- Creator withdrawal gated on reaching the goal before the deadline
- Contributor refunds when a campaign ends below its goal
- Event emission for every state-changing action
- Foundry test suite covering both success and revert paths

## Tech stack

- **Solidity** `^0.8.19`
- **Foundry** (Forge for build, test, and scripting)
- **forge-std** test and scripting utilities

## Getting started

### Prerequisites

Install Foundry if you do not have it:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Install dependencies

```bash
forge install
```

### Build

```bash
forge build
```

### Test

```bash
forge test
```

### Deploy

A deployment script is provided at `script/deply.s.sol` (contract `DeployCrowdfunding`). It broadcasts a single `CrowdFunding` deployment:

```bash
forge script script/deply.s.sol:DeployCrowdfunding \
  --rpc-url <RPC_URL> \
  --private-key <PRIVATE_KEY> \
  --broadcast
```

Replace `<RPC_URL>` with your target network endpoint (for example a Sepolia RPC) and `<PRIVATE_KEY>` with the deployer key. In real use, load secrets from a `.env` file rather than passing them inline.

## Testing

Tests live in `test/CrowdFunding.t.sol` and use `forge-std/Test.sol`. `setUp()` deploys a fresh `CrowdFunding` instance before each test. Foundry cheatcodes (`vm.prank`, `vm.deal`, `vm.warp`, `vm.expectRevert`) are used to simulate different callers, fund accounts, advance time, and assert reverts.

- **`testCreateCampaign`** confirms the creator, goal, and zero starting `amtRaised` are stored correctly, and asserts reverts when `goal == 0` and when `duration == 0`.
- **`testDonate`** creates a campaign, funds a donor, donates, and checks that both `amtRaised` and the contract balance increase by the donated amount. Also asserts a revert on a zero-value donation.
- **`testWithdraw`** has two donors fund a campaign up to its goal, confirms a non-creator withdrawal reverts, and verifies the creator's balance increases by the full raised amount on a successful withdrawal.
- **`testRefund`** donates to a campaign, warps past the deadline, and confirms the donor reclaims their contribution. It then sets up a second, still-active campaign and asserts that calling `refund` on it reverts with `"Campaign is Active"`.

## License

Released under the MIT License.

Author: Krish Ojha
