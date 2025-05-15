// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "./IVanaEpoch.sol";

abstract contract VanaEpochStorageV1 is IVanaEpoch {
    IDLPRegistry public override dlpRegistry;
    IDLPPerformance public override dlpPerformance;

    uint256 public override epochRewardAmount;
    uint256 public override daySize;
    uint256 public override epochSize; //in days

    // Epoch tracking
    uint256 public override epochsCount;
    mapping(uint256 epochId => Epoch epoch) internal _epochs;

}
