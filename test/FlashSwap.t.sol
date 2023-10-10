// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console2} from 'forge-std/Test.sol';
import {FlashSwap} from '../src/FlashSwap.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract FlashSwapTest is Test {
  FlashSwap public flashSwap;
  address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address public constant USDC = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
  uint256 public constant swapAmount = 1 ether;

  function setUp() public {
    uint256 mainnetFork = vm.createFork('https://eth.llamarpc.com');
    vm.selectFork(mainnetFork);
    flashSwap = new FlashSwap();
  }

  function testSwapWETHToDAI() public {
    deal(WETH, address(flashSwap), swapAmount);
    address[] memory path = new address[](2);
    path[0] = WETH;
    path[1] = DAI;
    uint256[] memory amounts = flashSwap.getAmountsOut(swapAmount, path);
    flashSwap.swapExactTokenIn(swapAmount, path);
    uint256 currentBalance = IERC20(DAI).balanceOf(address(flashSwap));
    console2.log('expectedDAIBalance', amounts[1]);
    console2.log('currentDAIBalance', currentBalance);
    assertEq(amounts[1], currentBalance);
  }

  function testSwapDAIToWETH() public {
    deal(DAI, address(flashSwap), swapAmount);
    address[] memory path = new address[](2);
    path[0] = DAI;
    path[1] = WETH;
    uint256[] memory amounts = flashSwap.getAmountsOut(swapAmount, path);
    flashSwap.swapExactTokenIn(swapAmount, path);
    uint256 currentBalance = IERC20(WETH).balanceOf(address(flashSwap));
    console2.log('expectedWETHBalance', amounts[1]);
    console2.log('currentWETHBalance', currentBalance);
    assertEq(amounts[1], currentBalance);
  }

  function testSwapWETHToUSDCToDAI() public {
    deal(WETH, address(flashSwap), swapAmount);
    address[] memory path = new address[](3);
    path[0] = WETH;
    path[1] = USDC;
    path[2] = DAI;
    // uint256[] memory amounts = flashSwap.getAmountOut(swapAmount, path);
    flashSwap.swapExactTokenIn(swapAmount, path);
    // uint256 currentBalance = IERC20(DAI).balanceOf(address(flashSwap));
    // console2.log('expectedDAIBalance', amounts[2]);
    // console2.log('currentDAIBalance', currentBalance);
    // assertEq(amounts[1], currentBalance);
  }
}
