// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {Factory, Project} from "../src/Factory.sol";
import {LTokenDelegate} from "../src/LTokenDelegate.sol";
import {LTokenDelegateV2} from "../src/LTokenDelegateV2.sol";
import {LTokenDelegator} from "../src/LTokenDelegator.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IWETH} from "../src/Interfaces/IWETH.sol";
import {IPool} from "../src/Interfaces/IPool.sol";

contract LTokenDelegateTest is Test {
    uint256 public mainnetFork;
    uint256 public blockNumber = 17_506_081; // 100000 block before
    string public MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

    address public constant WETHADDR =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant WETHPOOLADDR =
        0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address public constant AWETHADDR =
        0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8;

    address public user1 = makeAddr("User1");
    address public user2 = makeAddr("User2");
    address public user3 = makeAddr("User3");
    address public sponsorAddr = makeAddr("Sponsored");

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
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);
        vm.deal(sponsorAddr, 10 ether);
    }

    function test_createProject() public {
        assertEq(tokenDelegator.name(), "JonSmith Token");
        assertEq(tokenDelegator.symbol(), "JST");
        assertEq(tokenDelegator.sponsoredAddr(), sponsorAddr);
        assertEq(tokenDelegator.sponseredName(), "Jon Smith");
        assertEq(tokenDelegator.sponseredURI(), "https://www.js.org");
        assertEq(tokenDelegator.decimals(), 18);

        bytes memory data = tokenDelegator.delegateToViewImplementation(
            abi.encodeWithSignature("decimals()")
        );
        assertEq(abi.decode(data, (uint8)), 18);
    }

    function test_createAnotherProject() public {
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
        assertEq(factory.projectNumber(), 2);

        Project[] memory ps = factory.summaryAllProjects();
        assertEq(ps[0].sponsoredName, "Jon Smith");
        assertEq(ps[1].sponsoredName, "Vitalik Buterin");
    }

    function test_upgrade() public {
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

        factory.updateProjectConfig(
            address(tokenDelegator),
            address(0x2),
            address(0x3),
            address(0x4)
        );
        assertEq(tokenDelegator.WETHADDR(), address(0x2));
    }

    function test_NonAdminModifyProject() public {
        vm.startPrank(user1);
        vm.expectRevert(bytes("13"));
        factory.setProjectStatus(address(tokenDelegator), false);

        vm.expectRevert(bytes("23"));
        factory.updateProjectConfig(
            address(0x1),
            address(0x2),
            address(0x3),
            address(0x4)
        );
        vm.stopPrank();
    }

    function test_mint_redeem() public {
        vm.startPrank(user1);
        summary("Before mint");
        tokenDelegator.mint{value: 10 ether}();
        assertEq(tokenDelegator.balanceOf(user1), 10 ether);
        assertEq(tokenDelegator.supplyBalance(), 10 ether);
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
        assertEq(tokenDelegator.supplyBalance(), 5 ether);
        vm.stopPrank();

        vm.startPrank(user2);
        tokenDelegator.transferFrom(user1, user2, 2 ether);
        assertEq(tokenDelegator.allowance(user1, user2), 0);
        assertEq(tokenDelegator.balanceOf(user2), 2 ether);
        assertEq(tokenDelegator.supplyBalance(), 5 ether);
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

    function test_one_User_share_calculate() public {
        vm.startPrank(user1);
        assertEq(tokenDelegator.sponsorAccumulationShare(user1), 0);
        tokenDelegator.mint{value: 5}();
        assertEq(tokenDelegator.sponsorAccumulationShare(user1), 0);
        vm.warp(block.timestamp + 10);
        tokenDelegator.mint{value: 3}();
        assertEq(tokenDelegator.sponsorAccumulationShare(user1), 50);
        vm.warp(block.timestamp + 20);
        tokenDelegator.redeem(5);
        assertEq(tokenDelegator.sponsorAccumulationShare(user1), 210);
        vm.warp(block.timestamp + 30);
        tokenDelegator.redeem(3);
        assertEq(tokenDelegator.sponsorAccumulationShare(user1), 300);
        vm.warp(block.timestamp + 100);
        tokenDelegator.mint{value: 10}();
        assertEq(tokenDelegator.sponsorAccumulationShare(user1), 300);
        vm.warp(block.timestamp + 10);
        tokenDelegator.mint{value: 1}();
        assertEq(tokenDelegator.sponsorAccumulationShare(user1), 400);
        vm.stopPrank();
    }

    function test_two_users_transfer_share_calculate() public {
        vm.startPrank(user1);
        tokenDelegator.mint{value: 10}();
        assertEq(tokenDelegator.sponsorAccumulationShare(user1), 0);
        vm.warp(block.timestamp + 10);
        tokenDelegator.mint{value: 10}();
        assertEq(tokenDelegator.sponsorAccumulationShare(user1), 100);
        vm.warp(block.timestamp + 10);
        tokenDelegator.transfer(user2, 15);
        assertEq(tokenDelegator.sponsorAccumulationShare(user1), 300);
        assertEq(tokenDelegator.sponsorAccumulationShare(user2), 0);
        vm.stopPrank();

        vm.startPrank(user2);
        vm.warp(block.timestamp + 10);
        tokenDelegator.redeem(15);
        assertEq(tokenDelegator.sponsorAccumulationShare(user2), 150);
        vm.stopPrank();

        vm.startPrank(user1);
        vm.warp(block.timestamp + 100);
        tokenDelegator.redeem(5);
        assertEq(tokenDelegator.sponsorAccumulationShare(user1), 850);
        vm.stopPrank();
    }

    function test_giveback() public {
        vm.prank(user1);
        tokenDelegator.mint{value: 10}();

        vm.prank(user2);
        tokenDelegator.mint{value: 20}();

        vm.warp(block.timestamp + 100);
        assertEq(tokenDelegator.sponsorAccumulationShare(user1), 0);
        assertEq(tokenDelegator.sponsorAccumulationShare(user2), 0);

        vm.prank(sponsorAddr);
        uint totalGivebackAmount = tokenDelegator.giveback{value: 1 ether}();
        console.log("Total Give back amount:", totalGivebackAmount);
        console.log("Sponsored ETH amount:", sponsorAddr.balance);
        console.log(
            "User 1 wait for claim reward:",
            tokenDelegator.waitForGiverClaimAmount(user1)
        );
        assertEq(tokenDelegator.sponsorAccumulationShare(user1), 1000);
        assertEq(tokenDelegator.sponsorAccumulationShare(user2), 2000);
        summaryClaimGiveUp("Sponsored give 1 eth back");

        vm.prank(user1);
        tokenDelegator.sponsorClaimWaitGiveBackAmount();

        assertEq(tokenDelegator.waitForGiverClaimAmount(user1), 0);
        assertEq(
            tokenDelegator.waitForGiverClaimAmount(user2),
            666666666666666666
        );
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

    function summaryShare(string memory description) public view {
        console.log(description);

        console.log(
            "User1 share accumulation:",
            tokenDelegator.sponsorAccumulationShare(user1)
        );
        console.log(
            "User2 share accumulation:",
            tokenDelegator.sponsorAccumulationShare(user2)
        );
    }

    function summaryClaimGiveUp(string memory description) public view {
        console.log(description);

        console.log(
            "User1 share accumulation:",
            tokenDelegator.waitForGiverClaimAmount(user1)
        );
        console.log(
            "User2 share accumulation:",
            tokenDelegator.waitForGiverClaimAmount(user2)
        );
    }
}
