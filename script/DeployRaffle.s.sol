// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CreateSubscription, FundSubscription, AddConsumer} from "../script/interactions.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";

contract DeployRaffle is Script {
    function run() public {
        deployContract();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            // create a subscription
            CreateSubscription createSubscription = new CreateSubscription();
            (uint256 subId, address vrfCoordinator) = createSubscription
                .createSubscription(config.vrfCoordinator, config.account);

            config.subscriptionId = subId;
            config.vrfCoordinator = vrfCoordinator;

            //fund subscription
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                config.vrfCoordinator,
                config.subscriptionId,
                config.link,
                config.account
            );
        }

        vm.startBroadcast(config.account);
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            address(raffle),
            config.vrfCoordinator,
            config.subscriptionId,
            config.account
        );

        return (raffle, helperConfig);
    }
}
