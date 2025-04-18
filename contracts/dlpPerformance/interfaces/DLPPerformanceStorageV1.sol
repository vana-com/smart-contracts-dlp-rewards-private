// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./IDLPPerformance.sol";

abstract contract DLPPerformanceStorageV1 is IDLPPerformance {
    IDLPRegistry public override dlpRegistry;

    mapping(uint256 epochId => Epoch) internal _epochs;

    mapping(RatingType ratingType => uint256 percentage) public override ratingPercentages;
}
