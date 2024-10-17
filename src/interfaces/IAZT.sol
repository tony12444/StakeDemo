// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IAZT is IERC20{

    event GovSettled(address gov);

    function setGov(address _gov) external;

    function mint(address account, uint256 value) external;

    function burn(uint256 value) external;
}
