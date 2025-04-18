// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./IDLPRegistry.sol";

abstract contract DLPRegistryStorageV1 is IDLPRegistry {
    IVanaEpoch public override vanaEpoch;
    IDLPTreasury public override treasury;

    uint256 public override minDlpDepositAmount;

    uint256 public override dlpsCount;
    mapping(uint256 dlpId => Dlp dlp) internal _dlps;
    mapping(address dlpAddress => uint256 dlpId) public override dlpIds;
    mapping(string dlpName => uint256 dlpId) public override dlpNameToId;

    uint256 public override eligibleDlpsLimit;
    EnumerableSet.UintSet internal _eligibleDlpsList;
}
