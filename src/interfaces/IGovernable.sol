// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IGovernable {

    event GovSettled(address newGov);
    event AZPMinterAdded(address minter);
    event AZPMinterRemoved(address minter);
    event AZTMinterAdded(address minter);
    event AZTMinterRemoved(address minter);

    function gov() external view returns (address);

    function sAZPMinters(address minter) external view returns (bool);

    function sAZTMinters(address minter) external view returns (bool);

    function transferGov(address newGov) external;

    function addAZPMinter(address minter) external;

    function removeAZPMinter(address minter) external;

    function addAZTMinter(address minter) external;

    function removeAZTMinter(address minter) external;
}
