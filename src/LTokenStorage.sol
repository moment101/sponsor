// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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

    // Investment

    uint256 public reservedPercent = 2e17;

    /**
     * @notice the address of WETH
     */
    address public constant WETHADDR =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /**
     * @notice the address of WETH POOL over AVVe landing platform
     */
    address public constant WETHPOOLADDR =
        0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;

    /**
     * @notice the address of aWETH token over AVVe landing platform
     */
    address public constant AWETHADDR =
        0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8;

    /**
     * @notice the block index for calculate sponsor share
     */
    mapping(address => uint) public sponsorCurrentBlockIndex;

    /**
     * @notice the addresses of all sponsors
     */
    address[] public sponsors;

    /**
     * @notice the accmulation of share, need to update when mint / redeem / transfer / giveback
     */
    mapping(address => uint) public sponsorAccumulationShare;
}
