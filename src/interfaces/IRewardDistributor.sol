// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IRewardDistributor {
    event GovSettled(address gov);
    event Distributed(uint256 rewardAmount);
    event RewardTrackerSettled(address rewardTracker);
    event LastDistributionTimeSettled(uint256 time);
    event TokensPerIntervalSettled(uint256 rewardSpeed);

    function setGov(address _gov) external;

    function rewardToken() external view returns (address);

    function tokensPerInterval() external view returns (uint256);


    function setRewardTracker(address _rewardTracker) external;

    function setLastDistributionTime() external;

    function setTokensPerInterval(uint256 rewardSpeed) external;

    function pendingRewards() external view returns (uint256);

    function distribute(uint256 supply) external returns (uint256);
}
