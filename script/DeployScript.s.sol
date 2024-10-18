// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import {RewardDistributor} from "../src/RewardDistributor.sol";
import {RewardTracker} from "../src/RewardTracker.sol";
import {AZT} from "../src/tokens/AZT.sol";
import {sAZP} from "../src/tokens/sAZP.sol";
import {sAZT} from "../src/tokens/sAZT.sol";
import {Governable} from "../src/gov/Governable.sol";

contract DeployScript is Script {
    function run() external {
        address tmpGov = 0x0444C019C90402033fF8246BCeA440CeB9468C88;
        // precision is 18 digits, the same precision as the reward token
        uint256 rewardSpeed = 10000;
        uint256 deployKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployKey);

        // 1.deploy contract
        Governable gov = new Governable(tmpGov);
        AZT azt = new AZT(100000000 * 1e18, address(gov), "AZT", "AZT");
        sAZP sAzp = new sAZP(address(gov), "AZT", "AZT");
        sAZT sAzt = new sAZT(address(gov), "AZT", "AZT");
        RewardTracker tracker = new RewardTracker(address(gov), address(sAzp));
        RewardDistributor distributor = new RewardDistributor(address(gov), address(sAzt), address(tracker));

        // 2.contract config
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

        distributor.setLastDistributionTime();
        distributor.setTokensPerInterval(rewardSpeed);

        vm.stopBroadcast();
    }
}
