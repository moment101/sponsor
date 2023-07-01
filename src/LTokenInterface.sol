// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./LTokenStorage.sol";

interface LTokenInterface {
    /**
     * @notice Called by the sponsored or else, they wanna give back to those mintor
     * @dev Should increase mintor's profit balance
     */

    function giveBack() external returns (uint);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function mint() external payable returns (uint256);

    function redeem(uint256 amount) external returns (uint256);
}
