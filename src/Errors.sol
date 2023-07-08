// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Errors {
    string public constant CALLER_NOT_ADMIN = "1"; // The caller isn't admin
    string public constant BALANCE_INSUFFICIENT = "2"; // The balance of user is not sufficient
    string public constant MINT_ZERO_AMOUNT = "3"; // User mint 0 LToken
    string public constant SUPPLY_TO_AVVE_FAIL = "4"; // Supply to Avve operation failed
    string public constant WITHDRAW_FROM_AVVE_FAIL = "5"; // Withdraw from Avve operation failed
    string public constant SEND_ETH_BACK_TO_USER_FAIL = "6"; // Send ETH back to user failed
    string public constant TRANSFER_FROM_ZERO_ADDRESS = "7"; // Transfer from zero address
    string public constant TRANSFER_TO_ZERO_ADDRESS = "8"; // Transfer to zero address
    string public constant TRANSFER_AMOUNT_EXCEEDS_BALANCE = "9"; // Transfer amount exceeds balance
    string public constant ALLOWANCE_INSUFFICIENT = "10"; // Insufficient allowance
    string public constant APPROVE_FROM_ZERO_ADDRESS = "11"; // Approve from zero address
    string public constant APPROVE_TO_ZERO_ADDRESS = "12"; // Approve to zero address
    string public constant CHANGE_STATUS_NOT_ADMIN = "13"; // Only admin can change project status
    string public constant UPGRADE_IMPLEMENT_NOT_ADMIN = "14"; // Only admin can upgrade project
    string public constant CALLER_NOT_SPONSORED = "15"; // Only sponsored can claim for interest
    string public constant ZERO_AAVE_SUPPLY = "16"; // No one sponsor this project right now
    string public constant NO_INTEREST = "17"; // Interest has not accrued.
    string public constant REDEEM_ZERO_AMOUNT = "18"; // User redeem 0 LToken
    string public constant GIVEBACK_ZERO_AMOUNT = "19"; // Sponsor give back 0 ETH amount
    string public constant ZERO_SPONSOR_NUMBER = "20"; // No one sponsor this project yet
    string public constant ZERO_TOTAL_SHARE = "21"; // sponsors of this project do not accumulate any share
    string public constant SEND_ETH_BACK_TO_SPONSORED_FAIL = "22"; // Send the giveback of ETH to sponsored failed
    string public constant SET_CONFIG_NOT_ADMIN = "23"; // Only admin can update project WETH, AAVe, aToken's addresses
    string public constant REWARD_AMOUNT_IS_ZERO = "24"; // The waiting reward amount of sponsor is zero
    string public constant SEND_REWARD_BACK_TO_SPONSOR_FAIL = "25"; // Send reward (from Sponsored giveback) ETH to sponsor failed
}
