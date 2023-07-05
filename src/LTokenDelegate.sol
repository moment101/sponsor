// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./LTokenInterface.sol";
import "./LTokenStorage.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IWETH} from "./Interfaces/IWETH.sol";
import {IPool} from "./Interfaces/IPool.sol";
import {Errors} from "./Errors.sol";

contract LTokenDelegate is LTokenStorage, LTokenInterface {
    function initialize(
        string memory name_,
        string memory symbol_,
        address sponsoredAddr_,
        string memory sponseredName_,
        string memory sponseredURI_
    ) public {
        require(msg.sender == admin, Errors.CALLER_NOT_ADMIN);
        name = name_;
        symbol = symbol_;
        sponsoredAddr = sponsoredAddr_;
        sponseredName = sponseredName_;
        sponseredURI = sponseredURI_;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), Errors.TRANSFER_FROM_ZERO_ADDRESS);
        require(to != address(0), Errors.TRANSFER_TO_ZERO_ADDRESS);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, Errors.TRANSFER_AMOUNT_EXCEEDS_BALANCE);
        _updateSponsorShare(from);
        _updateSponsorShare(to);
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }
        emit Transfer(from, to, amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, Errors.ALLOWANCE_INSUFFICIENT);
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), Errors.APPROVE_FROM_ZERO_ADDRESS);
        require(spender != address(0), Errors.APPROVE_TO_ZERO_ADDRESS);

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _allowances[msg.sender][spender] = amount;
        return true;
    }

    function mint() external payable returns (uint256) {
        require(msg.value > 0, Errors.MINT_ZERO_AMOUNT);
        _updateSponsorShare(msg.sender);
        _balances[msg.sender] += msg.value;
        totalSupply += msg.value;
        require(_supply(msg.value), Errors.SUPPLY_TO_AVVE_FAIL);
        return msg.value;
    }

    function redeem(uint256 amount) external returns (uint256) {
        require(amount > 0, Errors.REDEEM_ZERO_AMOUNT);
        require(_balances[msg.sender] >= amount, Errors.BALANCE_INSUFFICIENT);
        _updateSponsorShare(msg.sender);
        _balances[msg.sender] -= amount;
        totalSupply -= amount;
        require(_withdraw(amount), Errors.WITHDRAW_FROM_AVVE_FAIL);
        (bool success, ) = address(msg.sender).call{value: amount}("");
        require(success, Errors.SEND_ETH_BACK_TO_USER_FAIL);
        return amount;
    }

    function withdrawAllFundBack() external returns (bool) {
        require(msg.sender == admin, Errors.CALLER_NOT_ADMIN);
        uint256 supplyAmount = supplyBalance();
        IPool(WETHPOOLADDR).withdraw(WETHADDR, supplyAmount, address(this));
        return true;
    }

    function _supply(uint256 amount) private returns (bool) {
        IWETH wETH = IWETH(WETHADDR);
        IPool wethPool = IPool(WETHPOOLADDR);
        wETH.deposit{value: amount}();
        wETH.approve(WETHPOOLADDR, amount);
        wethPool.supply(
            WETHADDR,
            wETH.balanceOf(address(this)),
            address(this),
            0
        );
        return true;
    }

    function supplyBalance() public view returns (uint256) {
        return IERC20(AWETHADDR).balanceOf(address(this));
    }

    function _withdraw(uint amount) private returns (bool) {
        IPool(WETHPOOLADDR).withdraw(WETHADDR, amount, address(this));
        IWETH wETH = IWETH(WETHADDR);
        wETH.withdraw(amount);
        return true;
    }

    function giveback(uint amount) external view returns (uint) {
        {
            // Silent compiler
            amount;
        }
        console.log("give back");
        return 0;
    }

    function claimInterest() external returns (uint) {
        require(msg.sender == sponsoredAddr, Errors.CALLER_NOT_SPONSORED);
        require(supplyBalance() > 0, Errors.ZERO_AAVE_SUPPLY);
        uint256 interest = supplyBalance() - totalSupply;
        require(interest > 0, Errors.NO_INTEREST);
        require(_withdraw(interest), Errors.WITHDRAW_FROM_AVVE_FAIL);
        (bool success, ) = address(msg.sender).call{value: interest}("");
        require(success, Errors.SEND_ETH_BACK_TO_USER_FAIL);
        totalSponsorshipAmount += interest;
        return interest;
    }

    function _updateSponsorShare(address sponsor) internal {
        uint previousBlockIndex = sponsorCurrentBlockIndex[sponsor];
        uint currentBlockIndex = block.timestamp;
        uint priviousBalance = _balances[sponsor];
        if (previousBlockIndex == 0) {
            sponsors.push(sponsor);
            sponsorCurrentBlockIndex[sponsor] = currentBlockIndex;
        } else {
            if (previousBlockIndex < currentBlockIndex) {
                uint delta = currentBlockIndex - previousBlockIndex;
                sponsorAccumulationShare[sponsor] += (delta * priviousBalance);
                sponsorCurrentBlockIndex[sponsor] = currentBlockIndex;
            }
        }
    }

    receive() external payable {}

    fallback() external payable {}
}
