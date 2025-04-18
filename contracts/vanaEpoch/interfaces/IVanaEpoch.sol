// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IDLPRegistry} from "../../dlpRegistry/interfaces/IDLPRegistry.sol";

interface IVanaEpoch {
    struct EpochDlp {
        uint256 rewardAmount;
        uint256 rewardClaimed;
    }

    struct Epoch {
        uint256 startBlock;
        uint256 endBlock;
        uint256 rewardAmount;
        bool isFinalised;
        EnumerableSet.UintSet dlpIds; // Participating DLPs
        mapping(uint256 dlpId => EpochDlp epochDlp) dlps;
    }

    // View functions for contract state and configuration
    function version() external pure returns (uint256);
    function dlpRegistry() external view returns (IDLPRegistry);
    function epochSize() external view returns (uint256);
    function daySize() external view returns (uint256);
    function epochsCount() external view returns (uint256);

    // Read-only struct views
    struct EpochInfo {
        uint256 startBlock;
        uint256 endBlock;
        uint256 rewardAmount;
        bool isFinalised;
        uint256[] dlpIds;
    }
    function epochs(uint256 epochId) external view returns (EpochInfo memory);
    function epochRewardAmount() external view returns (uint256);

    struct EpochDlpInfo {
        bool isTopDlp;
        uint256 rewardAmount;
        uint256 rewardClaimed;
    }
    function epochDlps(uint256 epochId, uint256 dlpId) external view returns (EpochDlpInfo memory);

    // Admin functions
    function pause() external;
    function unpause() external;
    function updateEpochSize(uint256 newEpochSize) external;
    function updateEpochRewardAmount(uint256 newEpochRewardAmount) external;

    function updateDlpRoot(address newDlpRootAddress) external;

    function createEpochs() external;
    function createEpochsUntilBlockNumber(uint256 blockNumber) external;

    struct EpochDlpReward {
        uint256 dlpId;
        uint256 rewardAmount;
    }
}
