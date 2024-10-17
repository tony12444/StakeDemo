// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IGovernable} from "./interfaces/IGovernable.sol";
import {IRewardDistributor} from "./interfaces/IRewardDistributor.sol";
import {IRewardTracker} from "./interfaces/IRewardTracker.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IBaseToken} from "./interfaces/IBaseToken.sol";

contract RewardDistributor is IRewardDistributor {
    address public gov;                             // manager contract address
    address public override rewardToken;            // reward token address
    uint256 public override tokensPerInterval;      // reward speed, scale 20
    uint256 public lastDistributionTime;            // last distribution timestamp
    address public rewardTracker;                   // tracker address

    constructor(address gov_, address _rewardToken, address _rewardTracker) {
        require(gov_ != address(0));
        require(_rewardToken != address(0));
        require(_rewardTracker != address(0));
        gov = gov_;
        rewardToken = _rewardToken;
        rewardTracker = _rewardTracker;
    }

    modifier onlyGov() {
        require(msg.sender == IGovernable(gov).gov(), "R_O0");
        _;
    }

    function setGov(address _gov) external override onlyGov {
        gov = _gov;

        emit GovSettled(_gov);
    }

    /// @notice update reward tracker address, only manager
    /// @param _rewardTracker tracker address
    function setRewardTracker(address _rewardTracker) external override onlyGov {
        require(_rewardTracker != address(0), "R_S0");
        rewardTracker = _rewardTracker;

        emit RewardTrackerSettled(_rewardTracker);
    }

    /// @notice set reward start time
    function setLastDistributionTime() external override onlyGov {
        lastDistributionTime = block.timestamp;

        emit LastDistributionTimeSettled(lastDistributionTime);
    }

    /// @notice set reward speed
    /// @param rewardSpeed reward speed , scale 20
    function setTokensPerInterval(uint256 rewardSpeed) external override onlyGov {
        require(lastDistributionTime != 0, "R_ST0");
        // calculate reward until last update time
        IRewardTracker(rewardTracker).updateRewards();
        tokensPerInterval = rewardSpeed;

        emit TokensPerIntervalSettled(rewardSpeed);
    }

    /// @notice calc total reward amount until last update time
    function pendingRewards() public view override returns (uint256) {
        if (block.timestamp == lastDistributionTime) {
            return 0;
        }

        uint256 timeDiff = block.timestamp - lastDistributionTime;
        uint256 rewardAmount = tokensPerInterval * timeDiff;
        // transfer reward to tracker address
        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        // if reward balance is enough ,return all balance
        if (rewardAmount > balance) {rewardAmount = balance;}

        return rewardAmount;
    }

    /// @notice calc reward amount and transfer to tracker when user update
    /// @param supply total staked amount
    function distribute(uint256 supply) external override returns (uint256) {
        require(msg.sender == rewardTracker, "R_D0");

        if (supply == 0) {
            if (lastDistributionTime < block.timestamp) {
                lastDistributionTime = block.timestamp;
            }
            return 0;
        }

        uint256 rewardAmount = pendingRewards();
        if (lastDistributionTime < block.timestamp) {
            lastDistributionTime = block.timestamp;
        }

        if (rewardAmount == 0) {return 0;}

        // mint reward token to tracker, msg.sender is tracker
        IBaseToken(rewardToken).mint(msg.sender, rewardAmount);

        emit Distributed(rewardAmount);

        return rewardAmount;
    }
}
