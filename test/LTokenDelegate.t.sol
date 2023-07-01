// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {Factory} from "../src/Factory.sol";
import {LTokenDelegate} from "../src/LTokenDelegate.sol";
import {LTokenDelegator} from "../src/LTokenDelegator.sol";

contract LTokenDelegateTest is Test {
    address public user1 = address(0x01);
    address public user2 = address(0x02);
    address public sponsorAddr = address(0xcafe);

    Factory public factory;
    LTokenDelegator public tokenDelegator;
    LTokenDelegate public tokenDelegate;

    event ProjectCreated(address indexed creator, address indexed projectAddr);
    event ProjectStatusChanged(
        address indexed projectAddr,
        bool indexed status
    );

    function setUp() public {
        factory = new Factory();

        address tokenDelegatorAddr = factory.createProject(
            "JonSmith Token",
            "JST",
            sponsorAddr,
            "Jon Smith",
            "https://www.js.org"
        );

        tokenDelegator = LTokenDelegator(payable(tokenDelegatorAddr));

        vm.deal(user1, 10 ether);
        vm.label(user1, "User1");
        vm.label(user2, "User2");
    }

    function testCreateProject() public {
        assertEq(tokenDelegator.name(), "JonSmith Token");
        assertEq(tokenDelegator.symbol(), "JST");
        assertEq(tokenDelegator.sponsoredAddr(), sponsorAddr);
        assertEq(tokenDelegator.sponseredName(), "Jon Smith");
        assertEq(tokenDelegator.sponseredURI(), "https://www.js.org");
    }

    function testCreateAnotherProject() public {
        vm.expectEmit(false, false, false, false);
        emit ProjectCreated(address(this), address(1000));
        address tokenDelegatorAddr = factory.createProject(
            "Vitalik Buterin Token",
            "VBT",
            address(0x220866B1A2219f40e72f5c628B65D54268cA3A9D),
            "Vitalik Buterin",
            "https://twitter.com/VitalikButerin"
        );
        LTokenDelegator delegator = LTokenDelegator(
            payable(tokenDelegatorAddr)
        );
        assertEq(factory.isProjectOpen(tokenDelegatorAddr), true);
        assertEq(delegator.sponseredName(), "Vitalik Buterin");
    }

    function test_AdminModifyProject() public {
        assertEq(factory.isProjectOpen(address(tokenDelegator)), true);

        vm.expectEmit();
        emit ProjectStatusChanged(address(tokenDelegator), false);
        factory.setProjectStatus(address(tokenDelegator), false);
        assertEq(factory.isProjectOpen(address(tokenDelegator)), false);
    }

    function testFail_NonAdminModifyProject() public {
        vm.prank(user1);
        factory.setProjectStatus(address(tokenDelegator), false);
    }

    function test_mint_redeem() public {
        vm.startPrank(user1);
        tokenDelegator.mint{value: 1 ether}();
        assertEq(tokenDelegator.balanceOf(user1), 1 ether);

        uint redeemAmount = tokenDelegator.redeem(0.5 ether);
        assertEq(redeemAmount, 0.5 ether);

        tokenDelegator.transfer(user2, 0.1 ether);
        assertEq(tokenDelegator.balanceOf(user2), 0.1 ether);

        vm.stopPrank();
    }
}
