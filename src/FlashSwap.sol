// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external;
}

interface IUniswapV2Pair {
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract FlashSwap is IUniswapV2Callee {
    // DAI token0, WETH token1
    // uniswap use fee 0.3%
    // 30/10000 -> 0.003 in decimals which is 0.3%

    // ================== constants ==================
    address private constant UNI_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant UNI_V2_PAIR = 0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // uint256 private constant BPS = 1e4;
    // uint256 private constant FEE_BPS = 30;

    ///  @dev deltay = FF * y * deltax / x + FFdeltaX
    // function getAmount0Out(uint256 amountIn) public view returns (uint256 amountOut) {
    //     (uint256 reserveOut, uint256 reserveIn,) = IUniswapV2Pair(UNI_V2_PAIR).getReserves();
    //     uint256 feeFactor = BPS - FEE_BPS;
    //     uint256 numerator = feeFactor * reserveOut * amountIn;
    //     uint256 denominator = BPS * reserveIn + amountIn * feeFactor;
    //     amountOut = numerator / denominator;
    // }
    function getAmount0Out(uint256 amountIn) public view returns (uint256 amountOut) {
        (uint256 reserveOut, uint256 reserveIn,) = IUniswapV2Pair(UNI_V2_PAIR).getReserves();
        (, bytes memory data) = UNI_V2_ROUTER.staticcall(
            abi.encodeWithSignature("getAmountOut(uint256,uint256,uint256)", amountIn, reserveIn, reserveOut)
        );
        amountOut = abi.decode(data, (uint256));
    }

    function swapExactToken1In(uint256 amountIn) external {
        uint256 amountOut = getAmount0Out(amountIn);
        bytes memory data = abi.encode(amountIn);
        IUniswapV2Pair(UNI_V2_PAIR).swap(amountOut, 0, address(this), data);
    }

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        (uint256 amountIn) = abi.decode(data, (uint256));
        IERC20(WETH).transfer(UNI_V2_PAIR, amountIn);
    }
}
