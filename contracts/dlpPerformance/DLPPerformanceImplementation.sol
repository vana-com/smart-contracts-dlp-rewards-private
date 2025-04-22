// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "./interfaces/DLPPerformanceStorageV1.sol";

contract DLPPerformanceImplementation is
    UUPSUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
DLPPerformanceStorageV1
{
    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    event EpochFinalised(uint256 indexed epochId);
    event EpochDlpPerformancesSaved(uint256 indexed epochId, uint256 indexed dlpId, uint256 performanceRating);

    error EpochAlreadyFinalised();
    error EpochNotEndedYet();
    error InvalidEpoch();
    error EpochRewardsAlreadyDistributed();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address ownerAddress,
        address dlpRegistryAddress
    ) external initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __Pausable_init();

        dlpRegistry = IDLPRegistry(dlpRegistryAddress);

        _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MANAGER_ROLE, MAINTAINER_ROLE);
        _grantRole(DEFAULT_ADMIN_ROLE, ownerAddress);
        _grantRole(MAINTAINER_ROLE, ownerAddress);
        _grantRole(MANAGER_ROLE, ownerAddress);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function version() external pure virtual override returns (uint256) {
        return 1;
    }

    function epochPerformances(uint256 epochId) external view override returns (EpochPerformanceInfo memory) {
        EpochPerformance storage epochPerformance = _epochPerformances[epochId];

        return
            EpochPerformanceInfo({
                finalized: epochPerformance.finalized
            });

    }

    function epochDlpPerformances(uint256 epochId, uint256 dlpId) external view override returns (EpochDlpPerformanceInfo memory) {
        EpochDlpPerformance storage epochDlpPerformance = _epochPerformances[epochId].epochDlpPerformances[dlpId];

        return
            EpochDlpPerformanceInfo({
                totalScore: epochDlpPerformance.totalScore,
                tradingVolume: epochDlpPerformance.tradingVolume,
                uniqueContributors: epochDlpPerformance.uniqueContributors,
                dataAccessFees: epochDlpPerformance.dataAccessFees
            });
    }

    function updateDlpRegistry(address dlpRegistryAddress) external override onlyRole(MAINTAINER_ROLE) {
        dlpRegistry = IDLPRegistry(dlpRegistryAddress);
    }


    function pause() external override onlyRole(MAINTAINER_ROLE) {
        _pause();
    }

    function unpause() external override onlyRole(MAINTAINER_ROLE) {
        _unpause();
    }

    function saveEpochPerformances(
        uint256 epochId,
        EpochDlpPerformanceInput[] calldata epochDlpPerformances,
        bool finalized
    ) external override onlyRole(MANAGER_ROLE) whenNotPaused {
        if (_epochPerformances[epochId].finalized) {
            revert EpochAlreadyFinalised();
        }

        if (finalized) {
            _epochPerformances[epochId].finalized = true;
            emit EpochFinalised(epochId);
        }

        for (uint256 i = 0; i < epochDlpPerformances.length; i++) {
            EpochDlpPerformanceInput calldata epochDlpPerformance = epochDlpPerformances[i];

            _epochPerformances[epochId].epochDlpPerformances[epochDlpPerformance.dlpId] = EpochDlpPerformance({
                totalScore: epochDlpPerformance.totalScore,
                tradingVolume: epochDlpPerformance.tradingVolume,
                uniqueContributors: epochDlpPerformance.uniqueContributors,
                dataAccessFees: epochDlpPerformance.dataAccessFees
            });

            emit EpochDlpPerformancesSaved(epochId, epochDlpPerformance.dlpId, epochDlpPerformance.totalScore);
        }
    }
}
