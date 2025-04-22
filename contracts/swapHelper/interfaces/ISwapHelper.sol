// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";
import "./IWVANA.sol";

interface ISwapHelper {
    function WVANA() external view returns (IWVANA);

    function uniswapV3Router() external view returns (address);

    function uniswapV3Quoter() external view returns (IQuoterV2);

    function updateWVANA(IWVANA newWVANA) external;

    function updateUniswapV3Router(address newUniswapV3Router) external;

    function updateUniswapV3Quoter(IQuoterV2 newUniswapV3Quoter) external;

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of `tokenIn` for as much as possible of `tokenOut`. Similar to Uniswap V3's `exactInputSingle`.
    /// @param params The parameters for the swap.
    /// @return amountOut The amount of tokenOut received from the swap.
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct QuoteExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        uint256 amountIn;
    }

    /// @notice Returns the `amountOut` received for a given exact `amountIn` for a swap of a single pool.
    /// @param params The parameters for the quote.
    /// @return amountOut The amount of tokenOut received from the swap.
    function quoteExactInputSingle(QuoteExactInputSingleParams calldata params) external returns (uint256 amountOut);

    struct SlippageSwapParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 maximumSlippagePercentage;
    }

    /// @notice Swaps as much as possible of `amountIn` while maintaining a maximum price slippage.
    /// @param params The parameters for the swap.
    /// @return amountInUsed The amount of tokenIn used for the swap.
    /// @return amountOut The amount of tokenOut received from the swap.
    function slippageExactInputSingle(
        SlippageSwapParams calldata params
    ) external payable returns (uint256 amountInUsed, uint256 amountOut);

    struct QuoteSlippageExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        uint256 amountIn;
        uint256 maximumSlippagePercentage;
    }

    /// @notice Returns the as much as possible `amountInUsed` and `amountOut` while maintaining a maximum price slippage.
    /// @param params The parameters for the quote.
    /// @return amountInUsed The amount of tokenIn used for the swap.
    /// @return amountOut The amount of tokenOut received from the swap.
    function quoteSlippageExactInputSingle(
        QuoteSlippageExactInputSingleParams calldata params
    ) external returns (uint256 amountInUsed, uint256 amountOut);
}
