// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/CrowdFunding.sol";

contract DeployCrowdfunding is Script {
    function run() external {
        vm.startBroadcast();
        new CrowdFunding();
        vm.stopBroadcast();
    }
}
