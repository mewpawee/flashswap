// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {FlashSwap} from "../src/FlashSwap.sol";
import {IERC20} from "../interfaces/IERC20.sol";

contract FlashSwapTest is Test {
    FlashSwap public flashSwap;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    uint256 public constant swapAmount = 1 ether;

    function setUp() public {
        uint256 mainnetFork = vm.createFork("https://eth.llamarpc.com");
        vm.selectFork(mainnetFork);
        flashSwap = new FlashSwap();
        deal(WETH, address(flashSwap), swapAmount);
    }

    function testFlash() public {
        uint256 amountOut = flashSwap.getAmount0Out(swapAmount);
        flashSwap.swapExactToken1In(swapAmount);
        uint256 currentBalance = IERC20(DAI).balanceOf(address(flashSwap));
        assertEq(amountOut, currentBalance);
    }
}
