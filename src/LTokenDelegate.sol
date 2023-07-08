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

    function decimals() public pure returns (uint8) {
        return 18;
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

    /**
     * @notice Sponsor send ether to mint LToken, contract supply these to AAVe landing platform
     * @dev Now only WETH sponsorship and serial loans are provided, and more options can be provided in the future
     * @return The return value is the increased liquidity this time
     */

    function mint() external payable returns (uint256) {
        require(msg.value > 0, Errors.MINT_ZERO_AMOUNT);
        _updateSponsorShare(msg.sender);
        _balances[msg.sender] += msg.value;
        totalSupply += msg.value;
        require(_supply(msg.value), Errors.SUPPLY_TO_AVVE_FAIL);
        emit Mint(msg.sender, msg.value);
        return msg.value;
    }

    /**
     * @notice Sponsor redeem their LToken back to ETH
     * @dev Need to withdraw aToken from AAVe first, then send ETH back to sponsor
     * @param amount need to redeem
     * @return The return value is the decreased liquidity this time
     */

    function redeem(uint256 amount) external returns (uint256) {
        require(amount > 0, Errors.REDEEM_ZERO_AMOUNT);
        require(_balances[msg.sender] >= amount, Errors.BALANCE_INSUFFICIENT);
        _updateSponsorShare(msg.sender);
        _balances[msg.sender] -= amount;
        totalSupply -= amount;
        require(_withdraw(amount), Errors.WITHDRAW_FROM_AVVE_FAIL);
        (bool success, ) = address(msg.sender).call{value: amount}("");
        require(success, Errors.SEND_ETH_BACK_TO_USER_FAIL);
        emit Redeem(msg.sender, amount);
        return amount;
    }

    /**
     * @notice Admin can withdraw all supply of AAVe back to sponsors (emergency situations)
     * @dev Send ether to sponsors cost huge gas, maybe added to waitForClaim mapping is better
     * @return Result of this emergency operations
     */

    function withdrawAllFundBack() external returns (bool) {
        require(msg.sender == admin, Errors.CALLER_NOT_ADMIN);
        uint256 supplyAmount = supplyBalance();
        IPool(WETHPOOLADDR).withdraw(WETHADDR, supplyAmount, address(this));
        IWETH wETH = IWETH(WETHADDR);
        wETH.withdraw(supplyAmount);

        for (uint i = 0; i < sponsors.length; i++) {
            address sponsor = sponsors[i];
            uint256 amount = _balances[sponsor];
            _balances[sponsor] = 0;
            totalSupply -= amount;
            (bool success, ) = address(sponsor).call{value: amount}("");
            require(success, Errors.SEND_ETH_BACK_TO_USER_FAIL);
        }

        emit AdminWithdrawAllSupplyOfAAVeBackToPool(admin, supplyAmount);
        return true;
    }

    /**
     * @notice Sponsor mint Ltoken, contract add weth to AAve aWETH pool
     * @param amount to add supply of AAVe aWETH Pool
     * @return Result of this supply operation
     */
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

    /**
     * @notice Sponsor redeem Ltoken, contract need to withdraw WETH from AAve aWETH pool
     * @param amount to withdraw from AAVe aWETH Pool
     * @return Result of this withdraw operation
     */
    function _withdraw(uint amount) private returns (bool) {
        IPool(WETHPOOLADDR).withdraw(WETHADDR, amount, address(this));
        IWETH wETH = IWETH(WETHADDR);
        wETH.withdraw(amount);
        return true;
    }

    /**
     * @notice Query the total supply of this contract on AAVe aWETH pool
     * @return Supply amount on AAVe WETH Pool
     */
    function supplyBalance() public view returns (uint256) {
        return IERC20(AWETHADDR).balanceOf(address(this));
    }

    /**
     * @notice Anyone can contribute back to the sponsors who supported this project
     * @dev Update all of the sponsors's share status, keep ether in contract, wait for them to claim
     * @return The returned is this time give back total amount, Some amounts may not be divided equally
     */
    function giveback() external payable returns (uint) {
        uint amount = msg.value;
        require(amount > 0, Errors.GIVEBACK_ZERO_AMOUNT);
        require(sponsors.length > 0, Errors.ZERO_SPONSOR_NUMBER);

        for (uint i = 0; i < sponsors.length; i++) {
            _updateSponsorShare(sponsors[i]);
        }

        uint totalShare = 0;
        for (uint i = 0; i < sponsors.length; i++) {
            totalShare += sponsorAccumulationShare[sponsors[i]];
        }

        require(totalShare > 0, Errors.ZERO_TOTAL_SHARE);
        uint givebackTotal = 0;
        for (uint i = 0; i < sponsors.length; i++) {
            uint receiveGiveback = (amount *
                sponsorAccumulationShare[sponsors[i]]) / totalShare;
            waitForGiverClaimAmount[sponsors[i]] += receiveGiveback;
            givebackTotal += receiveGiveback;
        }

        uint delta = amount - givebackTotal;
        if (delta > 0) {
            (bool success, ) = address(msg.sender).call{value: delta}("");
            require(success, Errors.SEND_ETH_BACK_TO_SPONSORED_FAIL);
        }

        totalGiveBackAmount += givebackTotal;
        emit GiveBack(msg.sender, givebackTotal);
        return givebackTotal;
    }

    /**
     * @notice Sponsor claim the reward from Sponsored
     * @dev Calculate the interest should great than gas fee (TODO)
     * @return The returned amount is interest so far
     */
    function sponsorClaimWaitGiveBackAmount() external returns (uint) {
        uint rewardAmount = waitForGiverClaimAmount[msg.sender];
        require(rewardAmount > 0, Errors.REWARD_AMOUNT_IS_ZERO);
        waitForGiverClaimAmount[msg.sender] = 0;
        (bool success, ) = address(msg.sender).call{value: rewardAmount}("");
        require(success, Errors.SEND_REWARD_BACK_TO_SPONSOR_FAIL);
        emit SponsorClaimReward(msg.sender, rewardAmount);
        return rewardAmount;
    }

    /**
     * @notice Sponsored claim back the interest accrued from AAVe
     * @dev Calculate the interest should great than gas fee (TODO)
     * @return The returned amount is interest so far
     */

    function claimInterest() external returns (uint) {
        require(msg.sender == sponsoredAddr, Errors.CALLER_NOT_SPONSORED);
        require(supplyBalance() > 0, Errors.ZERO_AAVE_SUPPLY);
        uint256 interest = supplyBalance() - totalSupply;
        require(interest > 0, Errors.NO_INTEREST);
        require(_withdraw(interest), Errors.WITHDRAW_FROM_AVVE_FAIL);
        (bool success, ) = address(msg.sender).call{value: interest}("");
        require(success, Errors.SEND_ETH_BACK_TO_SPONSORED_FAIL);
        totalSponsorshipAmount += interest;
        emit SponsoredClaimInterest(msg.sender, interest);
        return interest;
    }

    /**
     * @notice Update the sponsor share status when mint/redeem/transfer,
     * Each sponsor's share affects the amount of rewards that can be obtained later
     * @dev At present, the time is multiplied by the amount, there may be deviations, and the weight needs to be adjusted later
     * @param sponsor the address
     */

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
}
