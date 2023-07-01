// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/LTokenDelegate.sol";
import "../src/LTokenDelegator.sol";

contract LTokenDelegateTest is Test {
    LTokenDelegator public tokenDelegator;
    LTokenDelegate public tokenDelegate;

    address public user1 = address(0x01);
    address public user2 = address(0x02);

    function setUp() public {
        tokenDelegate = new LTokenDelegate();
        tokenDelegator = new LTokenDelegator(
            address(tokenDelegate),
            "Triple AAA",
            "AAA"
        );
        vm.deal(user1, 10 ether);
        vm.label(user1, "User1");
        vm.label(user2, "User2");
    }

    function test_setUpState() public {
        assertEq(tokenDelegator.name(), "Triple AAA");
        assertEq(tokenDelegator.symbol(), "AAA");
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
