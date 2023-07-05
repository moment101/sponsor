// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {LTokenDelegate} from "./LTokenDelegate.sol";
import "forge-std/Test.sol";

contract LTokenDelegateV2 is LTokenDelegate {
    function v2() external view returns (string memory) {
        console.log("V2 Func called");
        return "v2";
    }
}
