// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Address} from "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Allows users to deposit tokens which can later be swapped into the `destinationToken` in bulk and redistributed
contract Transmuter {
    using SafeERC20 for IERC20;
    using Address for address;

    /// @notice Notional address we use to identify raw eth transfers
    address public constant ETH = 0x000000000000000000000000000000000000000E;

    /// @notice Swap router such as 0x or 1inch
    address public immutable swapRouter;

    /// @notice Token that deposits will be swapped into
    address public immutable destinationToken;

    /// @notice Mapping of user -> token -> deposited balance
    mapping(address => mapping(address => uint256)) public userBalances;

    // =================================================================
    // Errors
    // =================================================================

    error InvalidAddress();
    error MismatchLength();
    error InsufficientEth();

    // =================================================================
    // Events
    // =================================================================

    event FundsDeposited(address user, address[] tokens, uint256[] amounts);
    event UserAmountTransmuted(address user, address originalToken, uint256 originalAmount, uint256 destAmount);

    // =================================================================
    // Constructor
    // =================================================================

    constructor(address destinationToken_, address swapRouter_) {
        if (destinationToken_ == address(0)) {
            revert InvalidAddress();
        }
        if (swapRouter_ == address(0)) {
            revert InvalidAddress();
        }
        destinationToken = destinationToken_;
        swapRouter = swapRouter_;
    }

    // =================================================================
    // Public - State Changing
    // =================================================================

    /// @notice Deposit tokens and/or ETH for later swapping
    /// @param tokens Tokens to deposit. Approvals should be made prior to this call
    /// @param amounts Amounts to deposit
    function depositFunds(address[] calldata tokens, uint256[] calldata amounts) external payable {
        uint256 len = tokens.length;
        if (len != amounts.length) {
            revert MismatchLength();
        }

        emit FundsDeposited(msg.sender, tokens, amounts);

        for (uint256 i = 0; i < len; ++i) {
            address token = tokens[i];
            uint256 amount = amounts[i];

            if (token != ETH) {
                IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            } else {
                if (msg.value < amount) {
                    revert InsufficientEth();
                }
            }

            userBalances[msg.sender][token] += amount;
        }
    }

    /// @notice Swap the given token for the given users to the `destinationToken`
    /// @param users Users to swap for
    /// @param token Token to swap out of
    /// @param amount The amount of token to swap out of
    /// @param swapData Call to the swap router to perform to execute the swap
    function transmute(address[] calldata users, address token, uint256 amount, bytes calldata swapData) external {
        // Tally the balances so we know how to distribute later
        uint256 userCnt = users.length;
        uint256 total = 0;
        uint256[] memory balances = new uint256[](userCnt);
        for (uint256 i = 0; i < userCnt; ++i) {
            address user = users[i];
            uint256 amt = userBalances[user][token];
            balances[i] += amt;
            total += amt;
            userBalances[user][token] = 0;
        }

        if (total == 0) {
            return;
        }

        uint256 beforeBalance = IERC20(destinationToken).balanceOf(address(this));

        if (token != ETH) {
            IERC20(token).safeIncreaseAllowance(swapRouter, amount);
            swapRouter.functionCall(swapData);
        } else {
            swapRouter.functionCallWithValue(swapData, amount);
        }

        // Figure out the total amount we received from the swap so we know how much to distribute
        uint256 amountReceived = IERC20(destinationToken).balanceOf(address(this)) - beforeBalance;

        // Distribute the tokens proportionally
        for (uint256 i = 0; i < userCnt; ++i) {
            address user = users[i];
            uint256 originalAmount = balances[i];
            uint256 usersAmount = amountReceived * originalAmount / total;

            emit UserAmountTransmuted(user, token, originalAmount, usersAmount);

            IERC20(destinationToken).safeTransfer(user, usersAmount);
        }
    }
}
