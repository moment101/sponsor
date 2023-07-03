// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./LTokenInterface.sol";
import "./LTokenStorage.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IWETH} from "./Interfaces/IWETH.sol";
import {IPool} from "./Interfaces/IPool.sol";

contract LTokenDelegate is LTokenStorage, LTokenInterface {
    function initialize(
        string memory name_,
        string memory symbol_,
        address sponsoredAddr_,
        string memory sponseredName_,
        string memory sponseredURI_
    ) public {
        require(msg.sender == admin, "Only admin could initialize the project");
        name = name_;
        symbol = symbol_;
        sponsoredAddr = sponsoredAddr_;
        sponseredName = sponseredName_;
        sponseredURI = sponseredURI_;
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
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _allowances[msg.sender][spender] = amount;
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
        require(_supply(msg.value), "Supply LP failed");
        return msg.value;
    }

    function redeem(uint256 amount) external returns (uint256) {
        require(_balances[msg.sender] >= amount, "Balance < withdraw amount");
        _balances[msg.sender] -= amount;
        totalSupply -= amount;
        require(_withdraw(amount), "Remove LP failed");
        (bool success, bytes memory data) = address(msg.sender).call{
            value: amount
        }("");
        require(success, "Redeem failed");
        return amount;
    }

    function withdrawAllFundBack() external returns (bool) {
        require(
            msg.sender == admin,
            "Only admin could withdraw all funds back"
        );

        return true;
    }

    function _supply(uint256 amount) private returns (bool) {
        IWETH WETH = IWETH(WETHADDR);
        IPool wethPool = IPool(WETHPOOLADDR);
        WETH.deposit{value: amount}();
        WETH.approve(WETHPOOLADDR, amount);
        wethPool.supply(
            WETHADDR,
            WETH.balanceOf(address(this)),
            address(this),
            0
        );
        return true;
    }

    function supplyBalance() external returns (uint256) {
        return IERC20(AWETHADDR).balanceOf(address(this));
    }

    function _withdraw(uint amount) private returns (bool) {
        IPool(WETHPOOLADDR).withdraw(WETHADDR, amount, address(this));
        IWETH WETH = IWETH(WETHADDR);
        WETH.withdraw(amount);
        return true;
    }

    receive() external payable {}

    fallback() external payable {}
}
