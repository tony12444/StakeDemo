// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IAZT} from "../interfaces/IAZT.sol";
import {IGovernable} from "../interfaces/IGovernable.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/**
    test token
*/
contract AZT is ERC20, IAZT {
    address public gov;                                     // manager address
    uint256 public cap;                                     // max total supply

    constructor(uint256 cap_, address gov_, string memory name_, string memory symbol_) ERC20(name_, symbol_){
        cap = cap_;
        gov = gov_;
    }

    modifier onlyGov() {
        require(msg.sender == IGovernable(gov).gov(), "A_O0");
        _;
    }

    /// @notice change gov contract address ,only manager
    /// @param _gov new gov contract address
    function setGov(address _gov) external override onlyGov{
        gov = _gov;

        emit GovSettled(_gov);
    }

    /// @notice mint token , only mint by gov
    /// @param account  mint to account address
    /// @param value mint amount
    function mint(address account, uint256 value) external override onlyGov {
        _mint(account, value);
        if (totalSupply() > cap) {
            revert("A_M0");
        }
    }

    /// @notice burn token
    /// @param value burn amount
    function burn(uint256 value) external override {
        _burn(msg.sender, value);
    }
}
