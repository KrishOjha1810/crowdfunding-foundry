# CrowdFunding – Simple Campaign-Based Crowdfunding (Foundry + Solidity)

A simple crowdfunding platform built in **Solidity** using the **Foundry** framework.

This contract lets users:

- Create crowdfunding campaigns with a funding goal and duration  
- Donate ETH to campaigns while they are active  
- Allow the campaign creator to withdraw funds if the goal is met before the deadline  
- Allow donors to claim refunds if the goal is not met before the deadline

---

## 🧩 Contract Overview

### Contract: `CrowdFunding`

```solidity
struct Campaign {
    address payable creator;
    uint256 goal;
    uint256 deadline;
    uint256 amtRaised;
    mapping(address => uint256) donors;
}
```

- campaignCount: Used to assign incremental IDs for each new campaign.

- Campaigns: Mapping from campaignID => Campaign.

```createCampaign(uint256 goal, uint256 duration)```

- Requirements:

  - goal > 0

  - duration > 0

- Creates a new campaign:

  - creator = msg.sender

  - goal set from input

  - deadline is set from duration (you can interpret this as a timestamp or a relative duration in seconds)

  - amtRaised starts at 0

- Emits CampaignCreated(campaignID, creator, goal, deadline).

Example intent:
Alice creates a campaign with goal 10 ETH and duration 1 day.

```donate(uint256 campaignID) payable```

- Requirements:

  - msg.value > 0

  - block.timestamp < campaign.deadline (campaign is still active)

- Effects:

  - Increases campaign.donors[msg.sender] by msg.value

  - Increases campaign.amtRaised by msg.value

- Emits Donated(campaignID, donor, amount).

Example:
Bob and Charlie donate 3 ETH and 7 ETH respectively to Alice's campaign, raising 10 ETH total.

```withdraw(uint256 campaignID)```

- Requirements:

  - msg.sender is the campaign creator

  - block.timestamp < campaign.deadline (still within campaign window)

  - campaign.amtRaised >= campaign.goal (goal achieved)

- Transfers all raised funds to the creator.

- Emits Withdrawn(campaignID, creator, amount).

Example:
Since Alice's campaign reached 10 ETH before the deadline, she can withdraw the funds.

```refund(uint256 campaignID)```

- Requirements:

  - block.timestamp > campaign.deadline (campaign ended)

  - campaign.amtRaised < campaign.goal (goal not met)

- Donor can get back their contribution:

  - Reads campaign.donors[msg.sender]

  - Transfers that amount back to msg.sender

- Emits Refunded(campaignID, donor, amount).

Example:
If Bob and Charlie donate but goal is not met before the deadline, each can call refund to get their ETH back.

## 🧪 Testing (Foundry)

Tests are in ```test/CrowdFunding.t.sol``` and use ```forge-std/Test.sol```.

```setUp()```
- Deploys a fresh CrowdFunding contract before each test.

```testCreateCampaign()```
- Uses vm.prank(creator) to simulate the creator.

- Checks:

  - creator is correctly stored

  - goal is stored

  - amtRaised is 0

- Also verifies failures:

  - Reverts when goal == 0

  - Reverts when duration == 0

```testDonate()```
- Creates a campaign.

- Funds donor1 with ETH using vm.deal.

- Donates 5 wei/ETH to the campaign.

- Asserts:

  - amtRaised increased.

  - Contract balance increased.

- Checks revert when msg.value == 0.

```testWithdraw()```

- Creates a campaign with goal = 10.

- Two donors each donate 5.

- Ensures:

  - Non-creator calling withdraw reverts.

  - Creator can withdraw when goal is met.

  - Creator’s balance increases by the raised amount.

```testRefund()```

- Creates a campaign with goal = 10 and short duration.

- Donor donates 5.

- Warps time with vm.warp past the deadline.

- Ensures:

  - Donor is able to get a refund when goal is not met.

  - Attempting refund while campaign is still active reverts.

Running tests
```bash
forge test
```

### Coverage (target 85%+)

You can run coverage with:
```bash
forge test --coverage
# or
forge coverage
```

(Configure foundry.toml for more detailed coverage reports if needed.)

## 🛠 Development Setup
### Prerequisites

- Foundry installed

If you don’t have it yet:
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
---
## 🚀 Deployment

Deployment script: ```script/DeployCrowdfunding.s.sol```
```solidity
contract DeployCrowdfunding is Script {
    function run() external {
        vm.startBroadcast();
        new CrowdFunding();
        vm.stopBroadcast();
    }
}
```

### Example deployment command
```bash
forge script script/DeployCrowdfunding.s.sol:DeployCrowdfunding \
  --rpc-url <RPC_URL> \
  --private-key <PRIVATE_KEY> \
  --broadcast
```

Replace:

```<RPC_URL>``` – your network RPC (e.g. Sepolia)

```<PRIVATE_KEY>``` – the deployer private key (prefer loading via .env in real use)

### Optional: Verification

If you configure Etherscan (or other explorer) API key in foundry.toml, you can add:
```bash
forge script script/DeployCrowdfunding.s.sol:DeployCrowdfunding \
  --rpc-url <RPC_URL> \
  --private-key <PRIVATE_KEY> \
  --broadcast \
  --verify \
  --verifier etherscan \
  --verifier-url <VERIFIER_URL_IF_NEEDED>
```