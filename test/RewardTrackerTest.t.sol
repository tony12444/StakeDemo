// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import {RewardDistributor} from "../src/RewardDistributor.sol";
import {RewardTracker} from "../src/RewardTracker.sol";
import {AZT} from "../src/tokens/AZT.sol";
import {sAZP} from "../src/tokens/sAZP.sol";
import {sAZT} from "../src/tokens/sAZT.sol";
import {Governable} from "../src/gov/Governable.sol";

contract RewardTrackerTest is Test {
    using stdStorage for StdStorage;

    Governable public gov;
    RewardDistributor public distributor;
    RewardTracker public tracker;
    AZT public azt;
    sAZP public sAzp;
    sAZT public sAzt;

    function setUp() public {
        address admin = address(0x1234);
        gov = new Governable(admin);
        azt = new AZT(10000 * 1e18, address(gov), "AZT", "AZT");
        sAzp = new sAZP(address(gov), "AZT", "AZT");
        sAzt = new sAZT(address(gov), "AZT", "AZT");
        tracker = new RewardTracker(address(gov), address(sAzp));
        distributor = new RewardDistributor(address(gov), address(sAzt), address(tracker));
        // update config
        vm.startPrank(admin);

        gov.addAZPMinter(address(tracker));
        gov.addAZTMinter(address(distributor));

        sAzp.setInPrivateTransferMode(true);
        sAzp.setHandler(address(tracker), true);

        sAzt.setInPrivateTransferMode(true);
        sAzt.setHandler(address(tracker), true);
        sAzt.setHandler(address(distributor), true);

        tracker.setRewardDistributor(address(distributor));
        tracker.addStakeToken(address(azt));
        tracker.addStakeToken(address(sAzt));

        vm.stopPrank();
    }

    function test_SetGov() external {
        address admin = address(0x1234);
        vm.prank(admin);
        tracker.setGov(address(1));
        address newGovFromContract = tracker.gov();

        assertEq(newGovFromContract, address(1), "test result: fail1");
    }

    function testFail_SetGov() external {
        tracker.setGov(address(1));
        address newGovFromContract = tracker.gov();

        assertEq(newGovFromContract, address(1), "test result: fail2");
    }

    function test_WithdrawToken() external {
        address admin = address(0x1234);
        vm.startPrank(admin);
        uint256 mintAmount = 10 * 1e18;
        azt.mint(address(tracker), 10 * 1e18);
        tracker.withdrawToken(address(azt), address(1), mintAmount);
        uint256 balanceOfAddress1 = azt.balanceOf(address(1));

        assertEq(mintAmount, balanceOfAddress1, "test result: fail3");
    }

    function testFail_WithdrawToken() external {
        address admin = address(0x1234);
        vm.prank(admin);
        uint256 mintAmount = 10 * 1e18;
        azt.mint(address(tracker), 10 * 1e18);
        tracker.withdrawToken(address(azt), address(1), mintAmount);
        uint256 balanceOfAddress1 = azt.balanceOf(address(1));

        assertEq(mintAmount, balanceOfAddress1, "test result: fail4");
    }

    function test_SetRewardDistributor() external {
        address admin = address(0x1234);
        vm.prank(admin);
        tracker.setRewardDistributor(address(1));
        address newDistributorFromContract = tracker.distributor();

        assertEq(newDistributorFromContract, address(1), "test result: fail5");
    }

    function testFail_SetRewardDistributor() external {
        tracker.setRewardDistributor(address(1));
        address newDistributorFromContract = tracker.distributor();

        assertEq(newDistributorFromContract, address(1), "test result: fail6");
    }

    function test_AddStakeToken() external {
        address admin = address(0x1234);
        vm.prank(admin);
        tracker.addStakeToken(address(sAzp));

        require(tracker.isStakeToken(address(sAzp)), "test result: fail7");
    }

    function testFail_AddStakeToken() external {
        tracker.addStakeToken(address(sAzp));

        require(tracker.isStakeToken(address(sAzp)), "test result: fail8");
    }

    function test_RemoveStakeToken() external {
        address admin = address(0x1234);
        vm.prank(admin);
        tracker.removeStakeToken(address(azt));

        require(!tracker.isStakeToken(address(azt)), "test result: fail9");
    }

    function testFail_RemoveStakeToken() external {
        address admin = address(0x1234);
        vm.prank(admin);
        tracker.addStakeToken(address(azt));

        tracker.removeStakeToken(address(azt));

        require(tracker.isStakeToken(address(azt)), "test result: fail10");
    }

    function test_Stake() external {
        uint256 stakeAmountOfAZT = 1000 * 1e18;
        address admin = address(0x1234);
        vm.startPrank(admin);
        azt.mint(admin, stakeAmountOfAZT);

        azt.approve(address(tracker), stakeAmountOfAZT);
        tracker.stake(address(azt), stakeAmountOfAZT);
        uint256 stakedBalanceOfAZT = tracker.stakedBalances(admin, address(azt));
        uint256 mintedBalanceOfsAZP = sAzp.balanceOf(admin);

        assertEq(stakeAmountOfAZT, stakedBalanceOfAZT, "test result: fail11");
        assertEq(stakeAmountOfAZT, mintedBalanceOfsAZP, "test result: fail12");
    }

    function test_StakeMultiToken() external {
        address admin = address(0x1234);
        uint256 stakeAmountOfAZT = 1000 * 1e18;
        uint256 stakeAmountOfsAZT = 1000 * 1e18;

        vm.prank(address(distributor));
        sAzt.mint(admin, stakeAmountOfsAZT);

        vm.startPrank(admin);
        azt.mint(admin, stakeAmountOfAZT);

        azt.approve(address(tracker), stakeAmountOfAZT);
        sAzt.approve(address(tracker), stakeAmountOfsAZT);

        tracker.stake(address(azt), stakeAmountOfAZT);
        tracker.stake(address(sAzt), stakeAmountOfsAZT);

        uint256 stakedBalanceOfAZT = tracker.stakedBalances(admin, address(azt));
        uint256 stakedBalanceOfsAZT = tracker.stakedBalances(admin, address(sAzt));

        uint256 mintedBalanceOfsAZP = sAzp.balanceOf(admin);

        assertEq(stakeAmountOfAZT, stakedBalanceOfAZT, "test result: fail13");
        assertEq(stakeAmountOfsAZT, stakedBalanceOfsAZT, "test result: fail14");
        assertEq(stakeAmountOfAZT + stakedBalanceOfsAZT, mintedBalanceOfsAZP, "test result: fail15");
    }

    function testFail_Stake() external {
        address admin = address(0x1234);
        uint256 stakeAmountOfsAZP = 1000 * 1e18;

        vm.prank(address(tracker));
        sAzp.mint(admin, stakeAmountOfsAZP);

        vm.startPrank(admin);
        sAzp.approve(address(tracker), stakeAmountOfsAZP);
        tracker.stake(address(sAzt), stakeAmountOfsAZP);

        uint256 stakedBalanceOfsAZP = tracker.stakedBalances(admin, address(sAzp));

        assertEq(stakeAmountOfsAZP, stakedBalanceOfsAZP, "test result: fail16");
    }

    function test_unStake() external {
        address admin = address(0x1234);
        uint256 stakeAmountOfAZT = 1000 * 1e18;

        vm.startPrank(admin);
        azt.mint(admin, stakeAmountOfAZT);

        azt.approve(address(tracker), stakeAmountOfAZT);
        tracker.stake(address(azt), stakeAmountOfAZT);

        uint256 stakedBalanceOfAZT = tracker.stakedBalances(admin, address(azt));

        assertEq(stakeAmountOfAZT, stakedBalanceOfAZT, "test result: fail16");

        // unStake
        tracker.unStake(address(azt), stakeAmountOfAZT);
        stakedBalanceOfAZT = tracker.stakedBalances(admin, address(azt));
        require(stakedBalanceOfAZT == 0, "test result: fail17");

        uint256 unStakeBalanceOfAdmin = azt.balanceOf(admin);

        assertEq(unStakeBalanceOfAdmin, stakeAmountOfAZT, "test result: fail18");
    }

    function test_unStakeMultiToken() external {
        address admin = address(0x1234);
        uint256 stakeAmountOfAZT = 1000 * 1e18;
        uint256 stakeAmountOfsAZT = 1000 * 1e18;

        vm.prank(address(distributor));
        sAzt.mint(admin, stakeAmountOfsAZT);

        vm.startPrank(admin);
        azt.mint(admin, stakeAmountOfAZT);

        azt.approve(address(tracker), stakeAmountOfAZT);
        sAzt.approve(address(tracker), stakeAmountOfsAZT);

        tracker.stake(address(azt), stakeAmountOfAZT);
        tracker.stake(address(sAzt), stakeAmountOfsAZT);

        uint256 stakedBalanceOfAZT = tracker.stakedBalances(admin, address(azt));
        uint256 stakedBalanceOfsAZT = tracker.stakedBalances(admin, address(sAzt));

        uint256 mintedBalanceOfsAZP = sAzp.balanceOf(admin);

        assertEq(stakeAmountOfAZT, stakedBalanceOfAZT, "test result: fail18");
        assertEq(stakeAmountOfsAZT, stakedBalanceOfsAZT, "test result: fail19");
        assertEq(stakeAmountOfAZT + stakedBalanceOfsAZT, mintedBalanceOfsAZP, "test result: fail20");

        // unStake
        tracker.unStake(address(azt), stakeAmountOfAZT);
        tracker.unStake(address(sAzt), stakeAmountOfsAZT);

        stakedBalanceOfAZT = tracker.stakedBalances(admin, address(azt));
        stakedBalanceOfsAZT = tracker.stakedBalances(admin, address(sAzt));
        require(stakedBalanceOfAZT == 0, "test result: fail21");
        require(stakedBalanceOfsAZT == 0, "test result: fail22");

        uint256 unStakeBalanceOfAdminAZT = azt.balanceOf(admin);
        uint256 unStakeBalanceOfAdminsAZT = sAzt.balanceOf(admin);

        assertEq(unStakeBalanceOfAdminAZT, stakeAmountOfAZT, "test result: fail23");
        assertEq(unStakeBalanceOfAdminsAZT, stakeAmountOfsAZT, "test result: fail24");
    }

    function testFail_unStakeGreaterThanPrincipal() external {
        address admin = address(0x1234);
        uint256 stakeAmountOfAZT = 1000 * 1e18;
        uint256 stakeAmountOfsAZT = 1000 * 1e18;

        vm.prank(address(distributor));
        sAzt.mint(admin, stakeAmountOfsAZT);

        vm.startPrank(admin);
        azt.mint(admin, stakeAmountOfAZT);

        azt.approve(address(tracker), stakeAmountOfAZT);
        sAzt.approve(address(tracker), stakeAmountOfsAZT);

        tracker.stake(address(azt), stakeAmountOfAZT);
        tracker.stake(address(sAzt), stakeAmountOfsAZT);

        uint256 stakedBalanceOfAZT = tracker.stakedBalances(admin, address(azt));
        uint256 stakedBalanceOfsAZT = tracker.stakedBalances(admin, address(sAzt));

        uint256 mintedBalanceOfsAZP = sAzp.balanceOf(admin);

        assertEq(stakeAmountOfAZT, stakedBalanceOfAZT, "test result: fail25");
        assertEq(stakeAmountOfsAZT, stakedBalanceOfsAZT, "test result: fail26");
        assertEq(stakeAmountOfAZT + stakedBalanceOfsAZT, mintedBalanceOfsAZP, "test result: fail27");

        // unStake
        tracker.unStake(address(azt), stakeAmountOfAZT + 1e18);
        tracker.unStake(address(sAzt), stakeAmountOfsAZT - 1e18);

        stakedBalanceOfAZT = tracker.stakedBalances(admin, address(azt));
        stakedBalanceOfsAZT = tracker.stakedBalances(admin, address(sAzt));
        require(stakedBalanceOfAZT == 0, "test result: fail28");
        require(stakedBalanceOfsAZT == 0, "test result: fail29");

        uint256 unStakeBalanceOfAdminAZT = azt.balanceOf(admin);
        uint256 unStakeBalanceOfAdminsAZT = sAzt.balanceOf(admin);

        assertEq(unStakeBalanceOfAdminAZT, stakeAmountOfAZT, "test result: fail30");
        assertEq(unStakeBalanceOfAdminsAZT, stakeAmountOfsAZT, "test result: fail31");
    }

    function testFail_unStakeByNotOwner() external {
        address admin = address(0x1234);
        uint256 stakeAmountOfAZT = 1000 * 1e18;

        vm.startPrank(admin);
        azt.mint(admin, stakeAmountOfAZT);

        azt.approve(address(tracker), stakeAmountOfAZT);

        tracker.stake(address(azt), stakeAmountOfAZT);

        uint256 stakedBalanceOfAZT = tracker.stakedBalances(admin, address(azt));
        uint256 mintedBalanceOfsAZP = sAzp.balanceOf(admin);

        assertEq(stakeAmountOfAZT, stakedBalanceOfAZT, "test result: fail32");
        assertEq(stakeAmountOfAZT, mintedBalanceOfsAZP, "test result: fail33");

        vm.stopPrank();

        // unStake
        address hacker = address(1);
        vm.prank(hacker);
        tracker.unStake(address(azt), stakeAmountOfAZT);

        stakedBalanceOfAZT = tracker.stakedBalances(admin, address(azt));
        require(stakedBalanceOfAZT == 0, "test result: fail34");

        uint256 unStakeBalanceOfAdminAZT = azt.balanceOf(admin);

        assertEq(unStakeBalanceOfAdminAZT, stakeAmountOfAZT, "test result: fail35");
    }

    function test_ClaimMultiToken() external {
        address admin = address(0x1234);
        vm.startPrank(admin);
        distributor.setLastDistributionTime();
        uint256 newSpeed = 10e18;
        uint256 diffTime = 100;
        distributor.setTokensPerInterval(newSpeed);
        vm.stopPrank();

        // stake
        uint256 stakeAmountOfAZT = 600 * 1e18;
        uint256 stakeAmountOfsAZT = 400 * 1e18;

        vm.prank(address(distributor));
        sAzt.mint(admin, stakeAmountOfsAZT);

        vm.startPrank(admin);
        azt.mint(admin, stakeAmountOfAZT);

        azt.approve(address(tracker), stakeAmountOfAZT);
        sAzt.approve(address(tracker), stakeAmountOfsAZT);

        tracker.stake(address(azt), stakeAmountOfAZT);
        tracker.stake(address(sAzt), stakeAmountOfsAZT);

        vm.warp(block.timestamp + diffTime);

        uint256 pendingReward = tracker.claimable(admin);
        assertEq(pendingReward, newSpeed * diffTime, "test result: fail36");

        // claim
        uint256 claimBefore = sAzt.balanceOf(admin);
        tracker.claim(admin);
        uint256 claimAfter = sAzt.balanceOf(admin);

        assertEq(claimBefore + (newSpeed * diffTime), claimAfter, "test result: fail37");
    }

    function testFail_ClaimByNotOwner() external {
        address admin = address(0x1234);
        vm.startPrank(admin);
        distributor.setLastDistributionTime();
        uint256 newSpeed = 10e18;
        uint256 diffTime = 100;
        distributor.setTokensPerInterval(newSpeed);
        vm.stopPrank();

        // stake
        uint256 stakeAmountOfAZT = 600 * 1e18;
        uint256 stakeAmountOfsAZT = 400 * 1e18;

        vm.prank(address(distributor));
        sAzt.mint(admin, stakeAmountOfsAZT);

        vm.startPrank(admin);
        azt.mint(admin, stakeAmountOfAZT);

        azt.approve(address(tracker), stakeAmountOfAZT);
        sAzt.approve(address(tracker), stakeAmountOfsAZT);

        tracker.stake(address(azt), stakeAmountOfAZT);
        tracker.stake(address(sAzt), stakeAmountOfsAZT);

        vm.warp(block.timestamp + diffTime);

        uint256 pendingReward = tracker.claimable(admin);
        assertEq(pendingReward, newSpeed * diffTime, "test result: fail36");

        // claim
        uint256 claimBefore = sAzt.balanceOf(admin);
        vm.stopPrank();
        address hacker = address(1);
        vm.prank(hacker);
        tracker.claim(admin);
        uint256 claimAfter = sAzt.balanceOf(admin);

        assertEq(claimBefore + (newSpeed * diffTime), claimAfter, "test result: fail37");
    }
}
