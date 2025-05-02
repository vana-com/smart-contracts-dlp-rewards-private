// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./IDLPRewardDeployer.sol";

abstract contract DLPRewardDeployerStorageV1 is IDLPRewardDeployer {
    IDLPRegistry public override dlpRegistry;
    IVanaEpoch public override vanaEpoch;
    IVanaEpoch public override vanaEpoch;

    mapping(uint256 epochId => EpochPerformance) internal _epochPerformances;
}
