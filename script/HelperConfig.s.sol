// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script,console} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract HelperConfig is Script{
    struct NetworkConfig{
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callBackGasLimit;
        address link;
    }

    NetworkConfig public activeNetworkConfig;
    constructor(){

        if (block.chainid == 11155111)
          activeNetworkConfig = getSepoliaETHConfig();
        else
            activeNetworkConfig = getOrCreateAnvilConfig();

    }   
    function getSepoliaETHConfig() public pure returns(NetworkConfig memory){
        
        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId: 0, //update this with our subId
            callBackGasLimit: 500000, // 500k
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789
        });
    }

    function getOrCreateAnvilConfig() public returns(NetworkConfig memory){

        if(activeNetworkConfig.vrfCoordinator != address(0))
            return activeNetworkConfig;
    
        uint96 baseFee = 0.25 ether;
        uint96 gasPriceLink = 1e9; // 1 gwei

        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinatorMock = new VRFCoordinatorV2Mock(
            baseFee,
            gasPriceLink
        );
        LinkToken inner_link = new LinkToken();
        vm.stopBroadcast();

        return NetworkConfig({
            entranceFee : 0.01 ether,
            interval : 30,
            vrfCoordinator : address(vrfCoordinatorMock),
            gasLane : 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId : 0,      //our script will add this
            callBackGasLimit : 500000, // 500k
            link : address(inner_link)
        });
    }
}