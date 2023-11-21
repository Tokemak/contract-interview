// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

/// @notice An oracle that can provide spot prices for tokens using specific liquidity pools
interface ISpotPriceOracle {
    /**
     * @notice Retrieve the spot price for a token in a specified quote currency utilizing a specific liquidity pool
     * @param token The token to get the spot price of
     * @param pool The liquidity pool to use for the price retrieval
     * @param quoteToken Quote token
     * @return price The spot price of the token     
     */
    function getSpotPrice(
        address token,
        address pool,
        address quoteToken
    ) external returns (uint256 price);
}