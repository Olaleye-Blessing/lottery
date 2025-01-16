// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";

contract HelperConfig is Script {
    struct Config {
        uint256 minimumRoundTicket;
    }

    uint256 public BASE_SEPOLIA_CHAINID = 84532;
    Config private activeConfig;

    constructor() {
        if (block.chainid == BASE_SEPOLIA_CHAINID) {
            activeConfig = setBaseSepoliaConfig();
        } else {
            activeConfig = setAnvilConfig();
        }
    }

    function getConfig() public view returns (Config memory) {
        return activeConfig;
    }

    function setBaseSepoliaConfig() private pure returns (Config memory) {
        return Config({minimumRoundTicket: 30});
    }

    function setAnvilConfig() private pure returns (Config memory) {
        return Config({minimumRoundTicket: 3});
    }
}
