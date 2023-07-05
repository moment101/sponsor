// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {Factory} from "../src/Factory.sol";
import {LTokenDelegate} from "../src/LTokenDelegate.sol";
import {LTokenDelegateV2} from "../src/LTokenDelegateV2.sol";
import {LTokenDelegator} from "../src/LTokenDelegator.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IWETH} from "../src/Interfaces/IWETH.sol";
import {IPool} from "../src/Interfaces/IPool.sol";

contract LTokenDelegateTest is Test {
    uint256 mainnetFork;
    uint256 blockNumber = 17_506_081; // 100000 block before
    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

    address public constant WETHADDR =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant WETHPOOLADDR =
        0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address public constant AWETHADDR =
        0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8;

    address public user1 = address(0x0167656);
    address public user2 = address(0x02938029);
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
        mainnetFork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(mainnetFork);
        vm.rollFork(blockNumber);

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

    function test_Upgrade() public {
        LTokenDelegateV2 v2 = new LTokenDelegateV2();
        factory.upProjectImplement(address(tokenDelegator), address(v2));

        vm.startPrank(user1);
        (, bytes memory data) = address(payable(tokenDelegator)).call(
            abi.encodeWithSignature("v2()")
        );
        assertEq(abi.decode(data, (string)), "v2");

        LTokenDelegateV2 v3 = new LTokenDelegateV2();
        vm.expectRevert(); // Only admin can upgrade implement contract
        factory.upProjectImplement(address(tokenDelegator), address(v3));

        vm.stopPrank();
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
        summary("Before mint");
        tokenDelegator.mint{value: 10 ether}();
        assertEq(tokenDelegator.balanceOf(user1), 10 ether);
        summary("After mint");

        vm.warp(block.timestamp + 60 * 60 * 24 * 365);
        summary("After one year");

        tokenDelegator.transfer(user2, 5 ether);
        summary("Transfer to user2 5 Ltoken");

        uint redeemAmount = tokenDelegator.redeem(5 ether);
        assertEq(redeemAmount, 5 ether);
        summary("After redeem");

        vm.stopPrank();

        vm.startPrank(user2);
        tokenDelegator.redeem(5 ether);
        summary("User2 redeem 5 Ltoken");
        vm.stopPrank();
    }

    function test_approve() public {
        vm.startPrank(user1);
        tokenDelegator.mint{value: 5 ether}();
        tokenDelegator.approve(user2, 2 ether);
        assertEq(tokenDelegator.allowance(user1, user2), 2 ether);
        vm.stopPrank();

        vm.startPrank(user2);
        tokenDelegator.transferFrom(user1, user2, 2 ether);
        assertEq(tokenDelegator.allowance(user1, user2), 0);
        assertEq(tokenDelegator.balanceOf(user2), 2 ether);
        vm.stopPrank();
    }

    function test_claim_Interest() public {
        vm.startPrank(user1);
        summary("Before mint");
        tokenDelegator.mint{value: 10 ether}();
        assertEq(tokenDelegator.balanceOf(user1), 10 ether);
        summary("After mint");
        vm.stopPrank();

        vm.warp(block.timestamp + 60 * 60 * 24 * 365);
        summary("After one year");

        vm.startPrank(sponsorAddr);
        tokenDelegator.claimInterest();
        vm.stopPrank();
        summary("After sponsored claim interest");

        vm.startPrank(user1);
        tokenDelegator.redeem(10 ether);
        summary("After User1 redeem all LToken");
        vm.stopPrank();
    }

    function test_admin_withdraw() public {
        vm.startPrank(user1);
        summary("Before mint");
        tokenDelegator.mint{value: 10 ether}();
        assertEq(tokenDelegator.balanceOf(user1), 10 ether);
        summary("After mint");

        vm.warp(block.timestamp + 60 * 60 * 24 * 365);
        summary("After one year");

        vm.expectRevert();
        factory.withdrawAllSupply(address(tokenDelegator));
        vm.stopPrank();

        factory.withdrawAllSupply(address(tokenDelegator));
        summary("Admin withdraw all supply from AAve");
    }

    function summary(string memory description) public view {
        console.log(description);
        console.log("User1 ETH balance:", user1.balance);
        console.log("User1 LToken balance:", tokenDelegator.balanceOf(user1));
        console.log("User1 WETH balance", IWETH(WETHADDR).balanceOf(user1));
        console.log("User2 ETH balance:", user2.balance);
        console.log("User2 LToken balance:", tokenDelegator.balanceOf(user2));
        console.log("User2 WETH balance", IWETH(WETHADDR).balanceOf(user2));
        console.log("Sponsered ETH balance:", sponsorAddr.balance);
        console.log(
            "Sponsered LToken balance:",
            tokenDelegator.balanceOf(sponsorAddr)
        );
        console.log(
            "Sponsered WETH balance",
            IWETH(WETHADDR).balanceOf(sponsorAddr)
        );

        console.log(
            "Delegator WETH balance",
            IWETH(WETHADDR).balanceOf(address(tokenDelegator))
        );
        console.log(
            "Delegate WETH balance",
            IWETH(WETHADDR).balanceOf(tokenDelegator.implementation())
        );
        console.log(
            "Delegator aWETH balance",
            IWETH(AWETHADDR).balanceOf(address(tokenDelegator))
        );
        console.log(
            "Delegate aWETH balance",
            IWETH(AWETHADDR).balanceOf(tokenDelegator.implementation())
        );

        console.log("------------------------------------");
    }
}
