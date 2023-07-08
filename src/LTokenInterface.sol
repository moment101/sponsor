// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./LTokenStorage.sol";

interface LTokenInterface {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event ProjectImplementChanged(address oldImplement, address newImplement);
    event ProjectConfigChanged(
        address underlyingAddr,
        address poolAddr,
        address aTokenAddr
    );
    event Mint(address indexed from, uint256 indexed amount);
    event Redeem(address indexed from, uint256 indexed amount);
    event GiveBack(address indexed from, uint256 indexed amount);
    event SponsoredClaimInterest(
        address indexed from,
        uint256 indexed interestAmount
    );
    event SponsorClaimReward(
        address indexed from,
        uint256 indexed rewardAmount
    );
    event AdminWithdrawAllSupplyOfAAVeBackToPool(address admin, uint256 amount);

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

    function supplyBalance() external returns (uint256);

    function withdrawAllFundBack() external returns (bool);

    function giveback() external payable returns (uint);

    function claimInterest() external returns (uint);
}
