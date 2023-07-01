// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {LTokenDelegate} from "./LTokenDelegate.sol";
import {LTokenDelegator} from "./LTokenDelegator.sol";

/**
 * @title Sponsor's Factory Contract
 * @notice Concrete Factory for LTokens
 * @author Jon
 */
contract Factory {
    address public admin;
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

    function isProjectOpen(address addr_) external view returns (bool) {
        return projectStatus[addr_];
    }

    function setProjectStatus(address addr_, bool status_) external {
        require(msg.sender == admin, "Only admin can modify project status");
        projectStatus[addr_] = status_;
        emit ProjectStatusChanged(addr_, status_);
    }
}
