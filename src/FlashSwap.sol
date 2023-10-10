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

contract FlashSwap is IUniswapV2Callee {
  using SafeERC20 for IERC20;
  // DAI token0, WETH token1
  // uniswap use fee 0.3%
  // 30/10000 -> 0.003 in decimals which is 0.3%

  error NotV2Pair();
  error NotFromThisContract();

  // ================== constants ==================
  address private constant UNI_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address private constant UNI_V2_PAIR = 0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11;

  modifier onlyV2Pair() {
    if (msg.sender != UNI_V2_PAIR) {
      revert NotV2Pair();
    }
    _;
  }

  modifier onlyFromThisContract(address _sender) {
    if (_sender != address(this)) {
      revert NotFromThisContract();
    }
    _;
  }

  function getAmountOut(
    uint _amountIn,
    address _tokenIn,
    address _tokenOut
  ) public view returns (uint[] memory amounts) {
    address[] memory path = new address[](2);
    path[0] = _tokenIn;
    path[1] = _tokenOut;
    (, bytes memory amountOutData) = UNI_V2_ROUTER.staticcall(
      abi.encodeWithSignature('getAmountsOut(uint256,address[])', _amountIn, path)
    );
    amounts = abi.decode(amountOutData, (uint[]));
  }

  //slippage control
  function swapExactTokenIn(uint _amountIn, address _tokenIn, address _tokenOut) external {
    uint[] memory amounts = getAmountOut(_amountIn, _tokenIn, _tokenOut);
    bytes memory data = abi.encode(amounts[0], _tokenIn);
    IUniswapV2Pair(UNI_V2_PAIR).swap(amounts[1], 0, address(this), data);
  }

  function uniswapV2Call(
    address _sender,
    uint _amount0,
    uint _amount1,
    bytes calldata data
  ) external onlyV2Pair onlyFromThisContract(_sender) {
    (uint amountIn, address tokenIn) = abi.decode(data, (uint, address));
    IERC20(tokenIn).safeTransfer(UNI_V2_PAIR, amountIn);
  }
}
