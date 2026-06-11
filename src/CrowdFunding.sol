// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Crowdfunding Smart Contract
 * @dev Allows users to create crowdfunding campaigns, contribute funds, withdraw funds if the goal is met,
 * and refund contributors if the goal is not met before the deadline.
 */
contract CrowdFunding {
    uint256 campaignCount = 1;

    struct Campaign {
        address payable creator;
        uint256 goal;
        uint256 deadline;
        uint256 amtRaised;
        mapping(address => uint256) donors;
    }

    mapping(uint256 => Campaign) public Campaigns;

    event CampaignCreated(uint256 campaignID, address creator, uint256 goal, uint256 deadline);
    event Donated(uint256 campaignID, address donor, uint256 amount);
    event Withdrawn(uint256 campaignID, address creator, uint256 amount);
    event Refunded(uint256 campaignID, address donor, uint256 amount);

    /**
     * @notice Creates a new crowdfunding campaign
     * @param goal The funding goal for the campaign (in Wei)
     * @param duration The campaign deadline as an absolute timestamp (in seconds)
     */
    function createCampaign(uint256 goal, uint256 duration) external {
        require(goal > 0, "goal must be greater than 0");
        require(duration > 0, "Duration must be greater than 0");

        uint256 campaignID = campaignCount;
        Campaign storage campaign = Campaigns[campaignID];
        campaign.creator = payable(msg.sender);
        campaign.goal = goal;
        campaign.deadline = duration;
        campaign.amtRaised = 0;
        emit CampaignCreated(campaignID, campaign.creator, campaign.goal, campaign.deadline);
        campaignCount++;
    }

    /**
     * @notice Allows users to donate to a specific campaign
     * @param campaignID The ID of the campaign to donate to
     */
    function donate(uint256 campaignID) external payable {
        Campaign storage campaign = Campaigns[campaignID];
        require(msg.value > 0, "Donation must be greater than 0");
        require(block.timestamp < campaign.deadline, "Campaign has ended");

        campaign.donors[msg.sender] += msg.value;
        campaign.amtRaised += msg.value;

        emit Donated(campaignID, msg.sender, msg.value);
    }

    /**
     * @notice Allows the creator to withdraw funds if the funding goal is met before the deadline
     * @param campaignID The ID of the campaign to withdraw funds from
     */
    function withdraw(uint256 campaignID) external {
        Campaign storage campaign = Campaigns[campaignID];

        require(campaign.creator == msg.sender, "Only the Creator can withdraw");
        require(block.timestamp < campaign.deadline, "Campaign has ended");
        require(campaign.amtRaised >= campaign.goal, "goal is not achieved yet");

        uint256 amount = campaign.amtRaised;
        campaign.amtRaised = 0; // effect before interaction
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawn(campaignID, campaign.creator, amount);
    }

    /**
     * @notice Allows donors to claim a refund if the funding goal is not met before the deadline
     * @param campaignID The ID of the campaign to claim a refund from
     */
    function refund(uint256 campaignID) external {
        Campaign storage campaign = Campaigns[campaignID];
        require(block.timestamp > campaign.deadline, "Campaign is Active");
        require(campaign.amtRaised < campaign.goal, "Goal met, no refunds");

        uint256 contribution = campaign.donors[msg.sender];
        require(contribution > 0, "Nothing to refund");

        // Effects before interaction: zero the balance first so a donor cannot
        // re-enter refund() and be paid out more than once.
        campaign.donors[msg.sender] = 0;
        campaign.amtRaised -= contribution;

        (bool success,) = msg.sender.call{value: contribution}("");
        require(success, "Transfer failed");
        emit Refunded(campaignID, msg.sender, contribution);
    }
}
