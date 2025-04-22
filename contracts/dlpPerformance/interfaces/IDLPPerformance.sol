// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IDLPRegistry} from "../../dlpRegistry/interfaces/IDLPRegistry.sol";
import {IVanaEpoch} from "../../vanaEpoch/interfaces/IVanaEpoch.sol";

interface IDLPPerformance {
    struct EpochDlpPerformance {
        uint256 totalScore;
        uint256 tradingVolume;
        uint256 uniqueContributors;
        uint256 dataAccessFees;
    }

    struct EpochPerformance {
        bool finalized;
        mapping(uint256 dlpId => EpochDlpPerformance epochDlpPreformance) epochDlpPerformances;
    }


    struct EpochPerformanceInfo {
        bool finalized;
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
    function epochPerformances(uint256 epochId) external view returns (EpochPerformanceInfo memory);
    function epochDlpPerformances(uint256 epochId, uint256 dlpId) external view returns (EpochDlpPerformanceInfo memory);

    function pause() external;
    function unpause() external;
    function updateDlpRegistry(address dlpRegistryAddress) external;

    struct EpochDlpPerformanceInput {
        uint256 dlpId;
        uint256 totalScore;
        uint256 tradingVolume;
        uint256 uniqueContributors;
        uint256 dataAccessFees;
    }
    function saveEpochPerformances(
        uint256 epochId,
        EpochDlpPerformanceInput[] calldata epochDlpPerformances,
        bool finalized
    ) external;
}
