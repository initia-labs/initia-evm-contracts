// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IInitiaERC20 is IERC20, IERC165 {
    function sudoTransfer(address sender, address recipient, uint256 amount) external;

    function sudoMint(address to, uint256 amount) external;
    function sudoBurn(address from, uint256 amount) external;
}
