// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IGovernable} from "./interfaces/IGovernable.sol";
import {IRewardTracker} from "./interfaces/IRewardTracker.sol";
import {IRewardDistributor} from "./interfaces/IRewardDistributor.sol";
import {IBaseToken} from "./interfaces/IBaseToken.sol";
import {EnumerableSet} from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract RewardTracker is IRewardTracker {
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public constant PRECISION = 1e20;                                               // rewards precision

    address public gov;                                                                     // manager contract address
    address public sAZP;                                                                    // proof of stake AZT token
    address public distributor;                                                             // reward token source
    uint256 public cumulativeRewardPerToken;

    mapping(address => bool) public isStakeToken;                                           // is allow stake
    // user => token => staked amount
    mapping(address => mapping(address => uint256)) public stakedBalances;                  // user stake balances by token
    // user => amount
    mapping(address => uint256) public stakedAmounts;                                       // user total stake amount
    // user => claimable amount
    mapping(address => uint256) public claimableReward;                                     // claimable rewards
    // user => last reward amount per token
    mapping(address => uint256) public previousCumulatedRewardPerToken;                     //  available rewards base per staked

    constructor(address gov_, address sAZP_){
        gov = gov_;
        sAZP = sAZP_;
    }

    modifier onlyGov() {
        require(msg.sender == IGovernable(gov).gov(), "R_O0");
        _;
    }

    function setGov(address _gov) external override onlyGov {
        gov = _gov;

        emit GovSettled(_gov);
    }

    /// @notice withdraw token function
    /// @param token , withdraw token address
    /// @param dst, transfer address
    /// @param amount, transfer amount
    function withdrawToken(address token, address dst, uint256 amount) external override onlyGov {
        IERC20(token).transfer(dst, amount);

        emit WithdrawToken(token, dst, amount);
    }

    /// @notice set distributor address
    /// @param _distributor , address
    function setRewardDistributor(address _distributor) external override onlyGov {
        distributor = _distributor;

        emit RewardDistributorSettled(_distributor);
    }

    /// @notice add stake token
    /// @param token ,token address
    function addStakeToken(address token) external override onlyGov {
        isStakeToken[token] = true;

        emit StakeTokenAdded(token);
    }

    /// @notice remove stake token address
    /// @param token ,token address
    function removeStakeToken(address token) external override onlyGov {
        isStakeToken[token] = false;

        emit StakeTokenRemoved(token);
    }

    /// @notice stake function
    /// @param stakeToken which token stake
    /// @param amount stake amount
    function stake(address stakeToken, uint256 amount) external override {
        _stake(stakeToken, msg.sender, amount);

        emit Staked(stakeToken, msg.sender, amount);
    }

    /// @notice unStake function
    /// @param stakeToken which token withdraw
    /// @param amount withdraw amount
    function unStake(address stakeToken, uint256 amount) external override {
        _unStake(stakeToken, msg.sender, amount);

        emit UnStaked(stakeToken, msg.sender, amount);
    }

    /// @notice claim reward
    /// @param receiver, receiver address
    function claim(address receiver) external override {
        _updateRewards(msg.sender);

        uint256 rewardAmount = claimableReward[msg.sender];
        claimableReward[msg.sender] = 0;

        if (rewardAmount > 0) {
            IERC20(IRewardDistributor(distributor).rewardToken()).transfer(receiver, rewardAmount);
            emit Claimed(msg.sender, receiver, rewardAmount);
        }
    }

    /// @notice calculate available rewards amount
    /// @param account, account address
    function claimable(address account) public override view returns (uint256) {
        uint256 stakedAmount = stakedAmounts[account];
        if (stakedAmount == 0) {
            return claimableReward[account];
        }

        uint256 supply = IERC20(sAZP).totalSupply();
        uint256 pendingRewards = IRewardDistributor(distributor).pendingRewards();
        uint256 nextCumulativeRewardPerToken = cumulativeRewardPerToken + (pendingRewards * PRECISION / supply);
        return claimableReward[account] + (stakedAmount * (nextCumulativeRewardPerToken - previousCumulatedRewardPerToken[account]) / PRECISION);
    }

    function updateRewards() external override {
        _updateRewards(address(0));
    }

    /// @notice stake deposit token for reward
    /// @param stakeToken, deposit token address
    /// @param account, deposit for which account
    /// @param amount, amount
    function _stake(address stakeToken, address account, uint256 amount) internal {
        require(amount > 0, "RT_S0");
        require(isStakeToken[stakeToken], "RT_S1");

        IERC20(stakeToken).transferFrom(account, address(this), amount);

        _updateRewards(account);

        stakedAmounts[account] += amount;
        stakedBalances[account][stakeToken] += amount;

        IBaseToken(sAZP).mint(account, amount);
    }

    /// @notice unStake and withdraw
    /// @param stakeToken, deposit token address
    /// @param account, amount
    /// @param amount, receiver address
    function _unStake(address stakeToken, address account, uint256 amount) internal {
        require(amount > 0, "RT_U0");
        uint256 tokenStakedBalanceByAccount = stakedBalances[account][stakeToken];
        require(tokenStakedBalanceByAccount >= amount, "RT_U1");

        _updateRewards(account);

        stakedBalances[account][stakeToken] -= amount;
        stakedAmounts[account] -= amount;

        IBaseToken(sAZP).burn(amount);
        IERC20(stakeToken).transfer(account, amount);
    }

    /// @notice update reward information
    /// @param account, account address to update personal reward info if the address is not address(0)
    function _updateRewards(address account) internal {
        uint256 supply = IERC20(sAZP).totalSupply();
        uint256 blockReward = IRewardDistributor(distributor).distribute(supply);
        uint256 _cumulativeRewardPerToken = cumulativeRewardPerToken;
        if (supply > 0 && blockReward > 0) {
            _cumulativeRewardPerToken = _cumulativeRewardPerToken + (blockReward * PRECISION / supply);
            cumulativeRewardPerToken = _cumulativeRewardPerToken;
        }

        if (_cumulativeRewardPerToken == 0) {
            return;
        }

        if (account != address(0)) {
            uint256 stakedAmount = stakedAmounts[account];
            uint256 accountReward = stakedAmount * (_cumulativeRewardPerToken - previousCumulatedRewardPerToken[account]) / PRECISION;

            previousCumulatedRewardPerToken[account] = _cumulativeRewardPerToken;
            claimableReward[account] += accountReward;
        }
    }
}
