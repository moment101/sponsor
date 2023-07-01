// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ControllerInterface.sol";
import "forge-std/Test.sol";

contract ERC20Storage {
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    uint256 public totalSupply;
    string public name;
    string public symbol;
}

contract LTokenStorage is ERC20Storage {
    /**
     * @notice Address of implement contract
     */
    address public implementation;

    /**
     * @notice Admin of this contract
     */
    address public admin;

    /**
     * @notice Address of sponsored
     */
    address public sponsoredAddr;

    /**
     * @notice Name of sponsored
     */
    string public sponseredName;

    /**
     * @notice URI of sponsored
     */
    string public sponseredURI;

    /**
     * @notice Contract all the LToken's operations
     */
    ControllerInterface _controller;

    /**
     * @notice the total interest amount transferd to sponsored
     */
    uint256 public totalSponsorshipAmount;

    /**
     * @notice the amount of interest not yet transfer to sponsored
     */
    uint256 public waitForSponsoredAmount;

    /**
     * @notice the total give back amount from sponsored
     */
    uint256 public totalGiveBackAmount;

    /**
     * @notice the amount of give back from sponsored, wait for giver to claim
     */
    mapping(address => uint256) public waitForGiverClaimAmount;
}
