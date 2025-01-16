// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {Lottery} from "./../src/Lottery.sol";
import {HelperConfig} from "./../script/HelperConfig.s.sol";

contract DeployLottery is Script {
    function run() external returns (Lottery) {
        HelperConfig helperConfig = new HelperConfig();

        HelperConfig.Config memory config = helperConfig.getConfig();

        vm.startBroadcast();

        Lottery lottery = new Lottery(config.minimumRoundTicket);

        vm.stopBroadcast();

        return lottery;
    }
}
