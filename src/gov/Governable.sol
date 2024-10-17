// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract Governable {
    address public gov;

    event GovSettled(address newGov);

    constructor(address _gov) public {
        gov = _gov;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "OG0");
        _;
    }

    function transferGov(address newGov) external onlyGov {
        gov = newGov;

        emit GovSettled(newGov);
    }
}
