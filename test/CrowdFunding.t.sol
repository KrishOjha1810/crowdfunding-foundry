// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CrowdFunding.sol";

contract CrowdFundingTest is Test {
    CrowdFunding crowdfunding;
    address creator = makeAddr("creator");
    address donor1 = makeAddr("donor1");
    address donor2 = makeAddr("donor2");

    function setUp() public {
        crowdfunding = new CrowdFunding();
    }

    function testCreateCampaign() public {
        vm.prank(creator);
        crowdfunding.createCampaign(10, 10);
        (address campaignCreator, uint256 goal,, uint256 amtRaised) = crowdfunding.Campaigns(1);

        assertEq(campaignCreator, creator);
        assertEq(goal, 10);
        assertEq(amtRaised, 0);

        vm.prank(creator);
        vm.expectRevert("goal must be greater than 0");
        crowdfunding.createCampaign(0, 10);

        vm.prank(creator);
        vm.expectRevert("Duration must be greater than 0");
        crowdfunding.createCampaign(10, 0);
    }

    function testDonate() public {
        vm.prank(creator);
        crowdfunding.createCampaign(10, 10);

        vm.deal(donor1, 5);
        uint256 contractBalanceBefore = address(crowdfunding).balance;

        vm.prank(donor1);
        crowdfunding.donate{value: 5}(1);

        (,,, uint256 amtRaised) = crowdfunding.Campaigns(1);
        assertEq(amtRaised, 5);
        assertEq(address(crowdfunding).balance, contractBalanceBefore + 5);

        vm.expectRevert("Donation must be greater than 0");
        vm.prank(donor1);
        crowdfunding.donate{value: 0}(1);
    }

    function testDonateRevertsAfterDeadline() public {
        vm.prank(creator);
        crowdfunding.createCampaign(10, 10);
        vm.warp(11);
        vm.deal(donor1, 5);
        vm.prank(donor1);
        vm.expectRevert("Campaign has ended");
        crowdfunding.donate{value: 5}(1);
    }

    function testWithdraw() public {
        vm.prank(creator);
        crowdfunding.createCampaign(10, 100);

        vm.deal(donor1, 5);
        vm.deal(donor2, 5);

        vm.prank(donor1);
        crowdfunding.donate{value: 5}(1);
        vm.prank(donor2);
        crowdfunding.donate{value: 5}(1);

        vm.prank(donor1);
        vm.expectRevert("Only the Creator can withdraw");
        crowdfunding.withdraw(1);

        uint256 balance = creator.balance;
        vm.prank(creator);
        crowdfunding.withdraw(1);
        assertEq(creator.balance, balance + 10);

        (,,, uint256 amtRaised) = crowdfunding.Campaigns(1);
        assertEq(amtRaised, 0);
    }

    function testWithdrawRevertsWhenGoalNotMet() public {
        vm.prank(creator);
        crowdfunding.createCampaign(10, 100);

        vm.deal(donor1, 5);
        vm.prank(donor1);
        crowdfunding.donate{value: 5}(1);

        vm.prank(creator);
        vm.expectRevert("goal is not achieved yet");
        crowdfunding.withdraw(1);
    }

    function testRefund() public {
        vm.prank(creator);
        crowdfunding.createCampaign(10, 10);

        vm.deal(donor1, 5);
        vm.prank(donor1);
        crowdfunding.donate{value: 5}(1);

        vm.warp(11);
        uint256 balance = donor1.balance;
        vm.prank(donor1);
        crowdfunding.refund(1);
        assertEq(donor1.balance, balance + 5);
    }

    // Proves the double-refund / reentrancy fix: a second refund pays nothing.
    function testCannotRefundTwice() public {
        vm.prank(creator);
        crowdfunding.createCampaign(10, 10);

        vm.deal(donor1, 5);
        vm.prank(donor1);
        crowdfunding.donate{value: 5}(1);

        vm.warp(11);
        vm.prank(donor1);
        crowdfunding.refund(1);

        vm.prank(donor1);
        vm.expectRevert("Nothing to refund");
        crowdfunding.refund(1);
    }

    function testRefundRevertsWhenActive() public {
        vm.prank(creator);
        crowdfunding.createCampaign(10, 100);
        vm.deal(donor1, 5);
        vm.prank(donor1);
        crowdfunding.donate{value: 5}(1);

        vm.expectRevert("Campaign is Active");
        vm.prank(donor1);
        crowdfunding.refund(1);
    }

    function testRefundRevertsWhenGoalMet() public {
        vm.prank(creator);
        crowdfunding.createCampaign(10, 100);
        vm.deal(donor1, 10);
        vm.prank(donor1);
        crowdfunding.donate{value: 10}(1);

        vm.warp(101);
        vm.prank(donor1);
        vm.expectRevert("Goal met, no refunds");
        crowdfunding.refund(1);
    }
}
