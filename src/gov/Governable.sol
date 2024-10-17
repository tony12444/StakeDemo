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

    function transferGov(address newGov) external override onlyGov {
        require(newGov != address(0), "G_T0");
        gov = newGov;

        emit GovSettled(newGov);
    }

    function addAZPMinter(address minter) external override onlyGov {
        require(minter != address(0), "G_A0");
        sAZPMinters[minter] = true;

        emit AZPMinterAdded(minter);
    }

    function removeAZPMinter(address minter) external override onlyGov {
        require(minter != address(0), "G_R0");
        sAZPMinters[minter] = false;

        emit AZPMinterRemoved(minter);
    }

    function addAZTMinter(address minter) external override onlyGov {
        require(minter != address(0), "G_A1");
        sAZPMinters[minter] = true;

        emit AZTMinterAdded(minter);
    }

    function removeAZTMinter(address minter) external override onlyGov {
        require(minter != address(0), "G_R1");
        sAZPMinters[minter] = false;

        emit AZTMinterRemoved(minter);
    }
}
