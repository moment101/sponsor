// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {Errors} from "./Errors.sol";
import {LTokenDelegate} from "./LTokenDelegate.sol";
import {LTokenDelegator} from "./LTokenDelegator.sol";

struct Project {
    string sponsoredName;
    address delegatorAddr;
    uint96 sponsorCount;
    uint128 totalSupplyAmount;
    uint128 totalGivebackAmount;
}

/**
 * @title Sponsor's Factory Contract
 * @notice Concrete Factory for LTokens
 * @author Jon
 */
contract Factory {
    address public immutable admin;
    address[] public allProjects;
    mapping(address => bool) public projectStatus;

    event ProjectCreated(address indexed creator, address indexed projectAddr);
    event ProjectStatusChanged(
        address indexed projectAddr,
        bool indexed status
    );

    constructor() {
        admin = msg.sender;
    }

    function createProject(
        string calldata name_,
        string calldata symbol_,
        address sponsoredAddr_,
        string calldata sponseredName_,
        string calldata sponseredURI_
    ) external returns (address delegatorAddr) {
        LTokenDelegate delegate = new LTokenDelegate();
        LTokenDelegator delegator = new LTokenDelegator(
            address(delegate),
            name_,
            symbol_,
            sponsoredAddr_,
            sponseredName_,
            sponseredURI_
        );
        allProjects.push(address(delegator));
        projectStatus[address(delegator)] = true;
        emit ProjectCreated(msg.sender, address(delegator));
        return address(delegator);
    }

    function projectNumber() external view returns (uint) {
        return allProjects.length;
    }

    function isProjectOpen(address addr_) external view returns (bool) {
        return projectStatus[addr_];
    }

    function setProjectStatus(address addr_, bool status_) external {
        require(msg.sender == admin, Errors.CHANGE_STATUS_NOT_ADMIN);
        projectStatus[addr_] = status_;
        emit ProjectStatusChanged(addr_, status_);
    }

    function upProjectImplement(
        address delegatorAddr,
        address newImplement
    ) external {
        require(msg.sender == admin, Errors.UPGRADE_IMPLEMENT_NOT_ADMIN);
        LTokenDelegator delegator = LTokenDelegator(payable(delegatorAddr));
        delegator.upgrade(newImplement);
    }

    function updateProjectConfig(
        address delegatorAddr,
        address wethAddr,
        address aavePoolAddr,
        address aWETHAddr
    ) external {
        require(msg.sender == admin, Errors.SET_CONFIG_NOT_ADMIN);
        LTokenDelegator delegator = LTokenDelegator(payable(delegatorAddr));
        delegator.updateProjectConfig(wethAddr, aavePoolAddr, aWETHAddr);
    }

    function withdrawAllSupply(address delegatorAddr) external {
        require(msg.sender == admin, Errors.CALLER_NOT_ADMIN);
        LTokenDelegator delegator = LTokenDelegator(payable(delegatorAddr));
        delegator.withdrawAllFundBack();
    }

    function summaryAllProjects() external view returns (Project[] memory) {
        Project[] memory projects = new Project[](allProjects.length);
        for (uint i = 0; i < allProjects.length; i++) {
            LTokenDelegator delegator = LTokenDelegator(
                payable(allProjects[i])
            );

            projects[i] = Project({
                sponsoredName: delegator.sponseredName(),
                delegatorAddr: allProjects[i],
                sponsorCount: uint96(delegator.getSponsorCount()),
                totalSupplyAmount: uint128(delegator.totalSupply()),
                totalGivebackAmount: uint128(delegator.totalGiveBackAmount())
            });
        }
        return projects;
    }
}
