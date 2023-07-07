// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/LTokenDelegate.sol";
import "../src/LTokenDelegator.sol";
import "../src/Factory.sol";

contract OnAnvilScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("ANVIL_USER0_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Factory factory = new Factory();

        factory.createProject(
            "JonSmith Token",
            "JST",
            address(0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f),
            "Jon Smith",
            "https://www.js.org"
        );

        factory.createProject(
            "Vitalik Buterin Token",
            "VBT",
            address(0x220866B1A2219f40e72f5c628B65D54268cA3A9D),
            "Vitalik Buterin",
            "https://twitter.com/VitalikButerin"
        );

        vm.stopBroadcast();
    }
}

contract OnSepoliaScript is Script {
    address public constant WETHADDR =
        0xD0dF82dE051244f04BfF3A8bB1f62E1cD39eED92;
    address public constant WETHPOOLADDR =
        0xE7EC1B0015eb2ADEedb1B7f9F1Ce82F9DAD6dF08;
    address public constant AWETHADDR =
        0xE1a933729068B0B51452baC510Ce94dd9AB57A11;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("TEST_ACCOUNT_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Factory factory = new Factory();

        address pool1 = factory.createProject(
            "JonSmith Token",
            "JST",
            address(0xb16DE2a898B91CcFe556238ee6Ba534EeE2438c7),
            "Jon Smith",
            "https://www.js.org"
        );
        factory.updateProjectConfig(pool1, WETHADDR, WETHPOOLADDR, AWETHADDR);

        address pool2 = factory.createProject(
            "Vitalik Buterin Token",
            "VBT",
            address(0xb16DE2a898B91CcFe556238ee6Ba534EeE2438c7),
            "Vitalik Buterin",
            "https://twitter.com/VitalikButerin"
        );
        factory.updateProjectConfig(pool2, WETHADDR, WETHPOOLADDR, AWETHADDR);

        vm.stopBroadcast();
    }
}
