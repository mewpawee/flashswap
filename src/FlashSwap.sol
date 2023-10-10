// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {console2} from 'forge-std/Test.sol';

interface IUniswapV2Callee {
  function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

interface IUniswapV2Pair {
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

  function getReserves()
    external
    view
    returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Factory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract FlashSwap is IUniswapV2Callee {
  using SafeERC20 for IERC20;
  // DAI token0, WETH token1
  // uniswap use fee 0.3%
  // 30/10000 -> 0.003 in decimals which is 0.3%

  error NotV2Pair();
  error NotFromThisContract();

  // ================== constants ==================
  address private constant UNI_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address private constant UNI_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

  // modifier onlyV2Pair() {
  //   if (msg.sender != UNI_V2_PAIR) {
  //     revert NotV2Pair();
  //   }
  //   _;
  // }

  modifier onlyFromThisContract(address _sender) {
    if (_sender != address(this)) {
      revert NotFromThisContract();
    }
    _;
  }

  function sortTokens(
    address tokenA,
    address tokenB
  ) internal pure returns (address token0, address token1) {
    require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
  }

  function getAmountsOut(
    uint _amountIn,
    address[] memory path
  ) public view returns (uint[] memory amounts) {
    (, bytes memory amountOutData) = UNI_V2_ROUTER.staticcall(
      abi.encodeWithSignature('getAmountsOut(uint256,address[])', _amountIn, path)
    );
    amounts = abi.decode(amountOutData, (uint[]));
  }

  //token0, token1 might not in the order that we use on path
  function swapExactTokenIn(uint _amountIn, address[] memory path) external {
    uint[] memory amounts = getAmountsOut(_amountIn, path);
    for (uint i = 0; i < path.length - 1; i++) {
      (address tokenIn, address tokenOut) = (path[i], path[i + 1]);
      (address token0, ) = sortTokens(tokenIn, tokenOut);
      uint amountOut = amounts[i + 1];
      (uint amount0Out, uint amount1Out) = tokenIn == token0
        ? (uint(0), amountOut)
        : (amountOut, uint(0));
      bytes memory data = abi.encode(amounts[i], tokenIn, tokenOut);
      address pair = IUniswapV2Factory(UNI_V2_FACTORY).getPair(path[i], path[i + 1]);
      IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
    }
  }

  function uniswapV2Call(
    address _sender,
    uint _amount0,
    uint _amount1,
    bytes calldata data
  ) external onlyFromThisContract(_sender) {
    (uint amountIn, address tokenIn, address tokenOut) = abi.decode(data, (uint, address, address));
    address pair = IUniswapV2Factory(UNI_V2_FACTORY).getPair(tokenIn, tokenOut);
    if (msg.sender != pair) {
      revert NotV2Pair();
    }
    IERC20(tokenIn).safeTransfer(pair, amountIn);
  }
}
