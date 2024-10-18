// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import {RewardDistributor} from "../src/RewardDistributor.sol";
import {RewardTracker} from "../src/RewardTracker.sol";
import {AZT} from "../src/tokens/AZT.sol";
import {sAZP} from "../src/tokens/sAZP.sol";
import {sAZT} from "../src/tokens/sAZT.sol";
import {Governable} from "../src/gov/Governable.sol";

contract RewardDistributorTest is Test {
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
        distributor.setGov(address(1));
        address newGovFromContract = distributor.gov();

        assertEq(newGovFromContract, address(1), "test result: fail1");
    }

    function testFail_SetGov() external {
        distributor.setGov(address(1));
        address newGovFromContract = distributor.gov();

        assertEq(newGovFromContract, address(1), "test result: fail2");
    }

    function test_SetRewardTracker() external {
        address admin = address(0x1234);
        vm.startPrank(admin);
        distributor.setRewardTracker(address(1));
        address newTractorFromContract = distributor.rewardTracker();

        assertEq(newTractorFromContract, address(1), "test result: fail3");

    }

    function testFail_SetRewardTracker() external {
        distributor.setRewardTracker(address(1));
        address newTractorFromContract = distributor.gov();

        assertEq(newTractorFromContract, address(1), "test result: fail4");
    }

    function test_SetLastDistributionTime() external {
        address admin = address(0x1234);
        vm.startPrank(admin);
        distributor.setLastDistributionTime();
        uint256 lastTime = distributor.lastDistributionTime();

        assertEq(block.timestamp, lastTime, "test result: fail5");

    }

    function testFail_SetLastDistributionTime() external {
        distributor.setLastDistributionTime();
        uint256 lastTime = distributor.lastDistributionTime();

        assertEq(block.timestamp, lastTime, "test result: fail6");
    }

    function test_SetTokensPerInterval() external {
        address admin = address(0x1234);
        vm.startPrank(admin);
        distributor.setLastDistributionTime();
        uint256 before = distributor.tokensPerInterval();
        uint256 newSpeed = 100;
        distributor.setTokensPerInterval(newSpeed);
        uint256 after1 = distributor.tokensPerInterval();

        assertEq(before + newSpeed, after1, "test result: fail7");
    }

    function test_PendingRewards() external {
        address admin = address(0x1234);
        vm.startPrank(admin);
        distributor.setLastDistributionTime();
        uint256 newSpeed = 100;
        distributor.setTokensPerInterval(newSpeed);
        uint256 diffTime = 100;
        vm.warp(block.timestamp + diffTime);

        uint256 rewardAmount = distributor.pendingRewards();

        assertEq(newSpeed * diffTime, rewardAmount, "test result: fail8");
    }

    function test_Distributor() external {
        address admin = address(0x1234);
        vm.prank(admin);
        distributor.setLastDistributionTime();
        uint256 newSpeed = 100;
        vm.prank(admin);
        distributor.setTokensPerInterval(newSpeed);
        uint256 diffTime = 100;
        vm.warp(block.timestamp + diffTime);

        vm.prank(address(tracker));
        distributor.distribute(10);

        uint256 sAZTBalanceOfTracker = sAzt.balanceOf(address(tracker));
        assertEq(newSpeed * diffTime, sAZTBalanceOfTracker, "test result: fail9");
    }

    function testFail_Distributor() external {
        address admin = address(0x1234);
        vm.prank(admin);
        distributor.setLastDistributionTime();
        uint256 newSpeed = 100;
        vm.prank(admin);
        distributor.setTokensPerInterval(newSpeed);
        uint256 diffTime = 100;
        vm.warp(block.timestamp + diffTime);

        //vm.prank(address(tracker));
        distributor.distribute(10);

        uint256 sAZTBalanceOfTracker = sAzt.balanceOf(address(tracker));
        assertEq(newSpeed * diffTime, sAZTBalanceOfTracker, "test result: fail10");
    }
}
