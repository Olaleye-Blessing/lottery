// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {Lottery} from "./../src/Lottery.sol";
import {HelperConfig} from "./../script/HelperConfig.s.sol";

contract DeployLottery is Script {
    uint256 public BASE_SEPOLIA_CHAINID = 84532;
    address immutable i_deployer;

    constructor() {
        i_deployer = msg.sender;
    }

    function run() external returns (Lottery, HelperConfig.Config memory) {
        HelperConfig helperConfig = new HelperConfig(i_deployer);

        HelperConfig.Config memory config = helperConfig.getConfig();

        if (block.chainid == BASE_SEPOLIA_CHAINID) {
            vm.startBroadcast();
        } else {
            vm.startBroadcast(i_deployer);
        }

        Lottery lottery = new Lottery(config.minimumRoundTicket, config.vrfCoordinator, config.vrfSubId, config.keyHash);

        vm.stopBroadcast();

        return (lottery, config);
    }
}
