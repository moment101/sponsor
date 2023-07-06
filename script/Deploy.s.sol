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

        address tokenDelegatorAddr = factory.createProject(
            "JonSmith Token",
            "JST",
            address(0x1234),
            "Jon Smith",
            "https://www.js.org"
        );

        vm.stopBroadcast();
    }
}

contract OnSepoliaScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("TEST_ACCOUNT_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Factory factory = new Factory();

        address tokenDelegatorAddr = factory.createProject(
            "JonSmith Token",
            "JST",
            address(0x1234),
            "Jon Smith",
            "https://www.js.org"
        );

        vm.stopBroadcast();
    }
}
