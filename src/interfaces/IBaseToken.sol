// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IBaseToken {
    event GovSettled(address gov);

    event InPrivateTransferModeSettled(bool inPrivateTransferMode);

    event HandlerSettled(address handler, bool isActive);

    function setGov(address _gov) external;

    function setInPrivateTransferMode(bool _inPrivateTransferMode) external;

    function setHandler(address _handler, bool _isActive) external;

    function mint(address account, uint256 value) external;

    function burn(uint256 value) external;

    function burn(address account, uint256 value) external;
}
