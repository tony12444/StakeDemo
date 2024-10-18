// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IGovernable} from "../interfaces/IGovernable.sol";

contract Governable is IGovernable {
    address public override gov;                                 // contract manager
    mapping(address => bool) public override sAZPMinters;        // sAZP token minter
    mapping(address => bool) public override sAZTMinters;        // sAZT token minter

    constructor(address _gov) {
        gov = _gov;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "G_O0");
        _;
    }

    /// @notice manager address update func
    /// @param newGov the new manager address
    function transferGov(address newGov) external override onlyGov {
        require(newGov != address(0), "G_T0");
        gov = newGov;

        emit GovSettled(newGov);
    }

    /// @notice add sAZP minter ,only manager
    /// @param minter new minter
    function addAZPMinter(address minter) external override onlyGov {
        require(minter != address(0), "G_A0");
        sAZPMinters[minter] = true;

        emit AZPMinterAdded(minter);
    }

    /// @notice remove sAZP minter ,only manager
    /// @param minter deprecated minter
    function removeAZPMinter(address minter) external override onlyGov {
        require(minter != address(0), "G_R0");
        sAZPMinters[minter] = false;

        emit AZPMinterRemoved(minter);
    }

    /// @notice add sAZT minter ,only manager
    /// @param minter new minter
    function addAZTMinter(address minter) external override onlyGov {
        require(minter != address(0), "G_A1");
        sAZTMinters[minter] = true;

        emit AZTMinterAdded(minter);
    }

    /// @notice remove sAZT minter ,only manager
    /// @param minter deprecated minter
    function removeAZTMinter(address minter) external override onlyGov {
        require(minter != address(0), "G_R1");
        sAZTMinters[minter] = false;

        emit AZTMinterRemoved(minter);
    }
}
