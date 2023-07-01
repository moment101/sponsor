// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./LTokenInterface.sol";
import "./LTokenStorage.sol";

contract LTokenDelegate is LTokenStorage, LTokenInterface {
    function initialize(string memory name_, string memory symbol_) public {
        require(msg.sender == admin, "Only admin may initialize the project");
        name = name_;
        symbol = symbol_;
        console.log("LTokenDelegate initialize");
    }

    function giveBack() external override returns (uint) {
        console.log("LTokenDelegate giveBack");
        return 0;
    }

    function balanceOf(address account) external view returns (uint256) {
        console.log("LTokenDelegate balanceOf");
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        console.log("LTokenDelegate transfer");
        require(_balances[msg.sender] >= amount, "balance insuffice");
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256) {
        console.log("LTokenDelegate allowance");
        return 0;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        console.log("LTokenDelegate transferFrom");
        return true;
    }

    function mint() external payable returns (uint256) {
        require(msg.value > 0, "Mint value must great than zero");
        _balances[msg.sender] += msg.value;
        totalSupply += msg.value;
        return msg.value;
    }

    function redeem(uint256 amount) external returns (uint256) {
        require(_balances[msg.sender] >= amount, "Balance < withdraw amount");
        _balances[msg.sender] -= amount;
        totalSupply -= amount;
        (bool success, bytes memory data) = address(msg.sender).call{
            value: amount
        }("");
        require(success, "Redeem failed");
        return amount;
    }

    receive() external payable {}

    fallback() external payable {}
}
