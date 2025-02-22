// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

import {Script, console} from "forge-std/Script.sol";

contract HelperConfig is Script {
    struct Config {
        uint256 minimumRoundTicket;
        address vrfCoordinator;
        uint256 vrfSubId;
        bytes32 keyHash;
    }

    uint256 public BASE_SEPOLIA_CHAINID = 84532;
    Config private activeConfig;

    address immutable i_deployer;

    constructor(address owner) {
        i_deployer = owner;

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
        return Config({
            minimumRoundTicket: 30,
            vrfCoordinator: 0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE,
            // TODO: Update this after creating the subscription
            vrfSubId: 84612310995526963820256148017357353711657270952980576002847868875380752114553,
            keyHash: 0x9e1344a1247c8a1785d0a4681a27152bffdb43666ae5bf7d14d24a5efd44bf71
        });
    }

    function setAnvilConfig() private returns (Config memory) {
        // Gotten from https://docs.chain.link/vrf/v2-5/subscription/test-locally#testing. Search for "baseFee" to go to the section
        uint96 baseFee = 100000000000000000;
        uint96 gasPrice = 1000000000;
        int256 weiPerUnitLink = 7096345589153800;

        vm.startBroadcast(i_deployer);

        VRFCoordinatorV2_5Mock vrfCoordinator = new VRFCoordinatorV2_5Mock(baseFee, gasPrice, weiPerUnitLink);

        uint256 subId = vrfCoordinator.createSubscription();
        uint256 subAmount = 100000000000000000000;
        vrfCoordinator.fundSubscription(subId, subAmount);

        vm.stopBroadcast();

        return Config({
            minimumRoundTicket: 3,
            vrfCoordinator: address(vrfCoordinator),
            vrfSubId: subId,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae
        });
    }
}
