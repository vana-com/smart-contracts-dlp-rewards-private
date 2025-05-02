// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IDLPRegistry} from "../../dlpRegistry/interfaces/IDLPRegistry.sol";
import {IVanaEpoch} from "../../vanaEpoch/interfaces/IVanaEpoch.sol";

interface IDLPRewardDeployer {
    struct EpochDlpReward {
        mapping (uint256 dayId => uint256 reward) dayRewards;
    }

    struct EpochPerformance {
        mapping(uint256 dlpId => EpochDlpReward epochDlpReward) epochDlpRewards;
    }

    struct EpochDlpPerformanceInfo {
        uint256 totalScore;
        uint256 tradingVolume;
        uint256 uniqueContributors;
        uint256 dataAccessFees;
    }

    function version() external pure returns (uint256);
    function dlpRegistry() external view returns (IDLPRegistry);
    function vanaEpoch() external view returns (IVanaEpoch);
    function epochDlpPerformances(uint256 epochId, uint256 dlpId) external view returns (EpochDlpPerformanceInfo memory);

    function pause() external;
    function unpause() external;
    function updateDlpRegistry(address dlpRegistryAddress) external;
    function updateVanaEpoch(address vanaEpochAddress) external;
}
