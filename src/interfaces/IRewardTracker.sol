// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IRewardTracker {
    event GovSettled(address gov);
    event WithdrawToken(address token, address dst, uint256 amount);
    event RewardDistributorSettled(address _distributor);
    event StakeTokenAdded(address token);
    event StakeTokenRemoved(address token);
    event Staked(address stakeToken, address account, uint256 amount);
    event UnStaked(address stakeToken, address account, uint256 amount);
    event Claimed(address account, address receiver, uint256 amount);

    function setGov(address _gov) external;

    function withdrawToken(address token, address dst, uint256 amount) external;

    function setRewardDistributor(address _distributor) external;

    function addStakeToken(address token) external;

    function removeStakeToken(address token) external;

    function stake(address stakeToken, uint256 amount) external;

    function unStake(address stakeToken, uint256 amount) external;

    function claim(address receiver) external;

    function updateRewards() external;

    function claimable(address account) external view returns (uint256);
}
