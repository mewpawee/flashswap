// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
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
  // DAI token0, WETH token1
  // uniswap use fee 0.3%
  // 30/10000 -> 0.003 in decimals which is 0.3%

  // ================== constants ==================
  address private constant UNI_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address private constant UNI_V2_PAIR = 0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11;
  address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  // uint private constant BPS = 1e4;
  // uint private constant FEE_BPS = 30;

  ///  @dev deltay = FF * y * deltax / x + FFdeltaX
  // function getAmount0Out(uint amountIn) public view returns (uint amountOut) {
  //     (uint reserveOut, uint reserveIn,) = IUniswapV2Pair(UNI_V2_PAIR).getReserves();
  //     uint feeFactor = BPS - FEE_BPS;
  //     uint numerator = feeFactor * reserveOut * amountIn;
  //     uint denominator = BPS * reserveIn + amountIn * feeFactor;
  //     amountOut = numerator / denominator;
  // }
  modifier onlyV2Pair() {
    require(msg.sender == UNI_V2_PAIR, 'Not UniswapV2 Pair');
    _;
  }

  function getAmount0Out(uint _amountIn) public view returns (uint amountOut) {
    address[] memory path = new address[](2);
    path[0] = WETH;
    path[1] = DAI;
    (, bytes memory amountOutData) = UNI_V2_ROUTER.staticcall(
      abi.encodeWithSignature('getAmountsOut(uint256,address[])', _amountIn, path)
    );
    console2.logBytes(amountOutData);
    uint[] memory amounts = abi.decode(amountOutData, (uint[]));
    amountOut = amounts[0];
  }

  function swapExactToken1In(uint _amountIn) external {
    uint amountOut = getAmount0Out(_amountIn);
    bytes memory data = abi.encode(_amountIn);
    IUniswapV2Pair(UNI_V2_PAIR).swap(amountOut, 0, address(this), data);
  }

  function uniswapV2Call(
    address _sender,
    uint _amount0,
    uint _amount1,
    bytes calldata data
  ) external onlyV2Pair {
    uint amountIn = abi.decode(data, (uint));
    IERC20(WETH).transfer(UNI_V2_PAIR, amountIn);
  }
}
