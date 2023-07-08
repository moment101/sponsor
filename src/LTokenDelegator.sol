// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./LTokenInterface.sol";
import "./LTokenStorage.sol";

contract LTokenDelegator is LTokenStorage, LTokenInterface {
    constructor(
        address implementation_,
        string memory name_,
        string memory symbol_,
        address sponsoredAddr_,
        string memory sponseredName_,
        string memory sponseredURI_
    ) {
        admin = msg.sender;
        implementation = implementation_;

        delegateToImplementation(
            abi.encodeWithSignature(
                "initialize(string,string,address,string,string)",
                name_,
                symbol_,
                sponsoredAddr_,
                sponseredName_,
                sponseredURI_
            )
        );
    }

    function upgrade(address newImplementation) external {
        if (msg.sender != admin) revert();
        emit ProjectImplementChanged(implementation, newImplementation);
        implementation = newImplementation;
    }

    function updateProjectConfig(
        address wethAddr,
        address aavePoolAddr,
        address aWETHAddr
    ) external {
        if (msg.sender != admin) revert();
        WETHADDR = wethAddr;
        WETHPOOLADDR = aavePoolAddr;
        AWETHADDR = aWETHAddr;
        emit ProjectConfigChanged(wethAddr, aavePoolAddr, aWETHAddr);
    }

    function decimals() public view returns (uint8) {
        bytes memory data = delegateToViewImplementation(
            abi.encodeWithSignature("decimals()")
        );
        return abi.decode(data, (uint8));
    }

    function balanceOf(address account) external view returns (uint256) {
        bytes memory data = delegateToViewImplementation(
            abi.encodeWithSignature("balanceOf(address)", account)
        );
        return abi.decode(data, (uint256));
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("transfer(address,uint256)", to, amount)
        );
        return abi.decode(data, (bool));
    }

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256) {
        bytes memory data = delegateToViewImplementation(
            abi.encodeWithSignature(
                "allowance(address,address)",
                owner,
                spender
            )
        );
        return abi.decode(data, (uint256));
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("approve(address,uint256)", spender, amount)
        );
        return abi.decode(data, (bool));
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                from,
                to,
                amount
            )
        );
        return abi.decode(data, (bool));
    }

    function mint() external payable returns (uint256) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("mint()")
        );
        return abi.decode(data, (uint256));
    }

    function redeem(uint256 amount) external returns (uint256) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("redeem(uint256)", amount)
        );
        return abi.decode(data, (uint256));
    }

    function claimInterest() external returns (uint) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("claimInterest()")
        );
        return abi.decode(data, (uint256));
    }

    function giveback() external payable returns (uint) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("giveback()")
        );
        return abi.decode(data, (uint256));
    }

    function supplyBalance() external view returns (uint256) {
        bytes memory data = delegateToViewImplementation(
            abi.encodeWithSignature("supplyBalance()")
        );
        return abi.decode(data, (uint256));
    }

    function withdrawAllFundBack() external returns (bool) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("withdrawAllFundBack()")
        );
        return abi.decode(data, (bool));
    }

    function getSponsorCount() public view returns (uint256) {
        return sponsors.length;
    }

    function sponsorClaimWaitGiveBackAmount() external returns (uint) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("sponsorClaimWaitGiveBackAmount()")
        );
        return abi.decode(data, (uint));
    }

    /**
     * @notice Internal method to delegate execution to another contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param callee The contract to delegatecall
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateTo(
        address callee,
        bytes memory data
    ) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

    /**
     * @notice Delegates execution to the implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToImplementation(
        bytes memory data
    ) public returns (bytes memory) {
        return delegateTo(implementation, data);
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     *  There are an additional 2 prefix uints from the wrapper returndata, which we ignore since we make an extra hop.
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToViewImplementation(
        bytes memory data
    ) public view returns (bytes memory) {
        (bool success, bytes memory returnData) = address(this).staticcall(
            abi.encodeWithSignature("delegateToImplementation(bytes)", data)
        );
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return abi.decode(returnData, (bytes));
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     */
    fallback() external payable {
        require(msg.sender != admin, "Transparant Proxy Only");
        require(msg.value == 0, "Fallback: cannot send value to fallback");
        console.log("delegator fallback called");
        // delegate all other functions to current implementation
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 {
                revert(free_mem_ptr, returndatasize())
            }
            default {
                return(free_mem_ptr, returndatasize())
            }
        }
    }

    receive() external payable {}
}
