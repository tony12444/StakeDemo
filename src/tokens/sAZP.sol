// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IBaseToken} from "../interfaces/IBaseToken.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IGovernable} from "../interfaces/IGovernable.sol";

/**
    test token
*/
contract sAZP is ERC20, IBaseToken {
    address public gov;                                                     // manager address
    bool public inPrivateTransferMode;                                      // private model turn
    mapping(address => bool) public isHandler;                              // white list address

    constructor(address gov_, string memory name_, string memory symbol_) ERC20(name_, symbol_){
        gov = gov_;
    }

    modifier onlyGov() {
        require(msg.sender == IGovernable(gov).gov(), "S_O0");
        _;
    }

    modifier onlyMinter() {
        require(IGovernable(gov).sAZPMinters(msg.sender), "S_O1");
        _;
    }

    /// @notice change gov contract address ,only manager
    /// @param _gov new gov contract address
    function setGov(address _gov) external override onlyGov {
        gov = _gov;

        emit GovSettled(_gov);
    }

    /// @notice transfer turn，if true transfer token only by whitelist user
    /// @param _inPrivateTransferMode true or false
    function setInPrivateTransferMode(bool _inPrivateTransferMode) external override onlyGov {
        inPrivateTransferMode = _inPrivateTransferMode;
        emit InPrivateTransferModeSettled(_inPrivateTransferMode);
    }

    /// @notice whitelist for token
    /// @param _handler whitelist address
    /// @param _isActive true or false
    function setHandler(address _handler, bool _isActive) external override onlyGov {
        isHandler[_handler] = _isActive;
        emit HandlerSettled(_handler, _isActive);
    }

    /// @notice overridden the transfer method in the ERC20 contract
    /// @param to transfer dst address
    /// @param value transfer amount
    function transfer(address to, uint256 value) public override returns (bool) {
        address owner = _msgSender();

        if (inPrivateTransferMode) {
            require(isHandler[owner], "SP_T0");
        }

        _transfer(owner, to, value);

        return true;
    }

    /// @notice overridden the transferFrom method in the ERC20 contract
    /// @param from transfer asset from address
    /// @param to transfer dst address
    /// @param value transfer value
    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        address spender = _msgSender();

        // white list address can ...
        if (isHandler[spender]) {
            _transfer(from, to, value);
            return true;
        }

        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /// @notice mint token , only mint by gov
    /// @param account  mint to account address
    /// @param value mint amount
    function mint(address account, uint256 value) external override onlyMinter {
        _mint(account, value);
    }

    /// @notice burn token
    /// @param value burn amount
    function burn(uint256 value) external override {
        _burn(msg.sender, value);
    }

    /// @notice burn token for account
    /// @param account from address
    /// @param value burn amount
    function burn(address account, uint256 value) external override onlyMinter{
        _burn(account, value);
    }
}
