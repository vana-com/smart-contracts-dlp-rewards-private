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

    event EpochDlpPerformancesSaved(
        uint256 indexed epochId,
        uint256 indexed dlpId,
        uint256 performanceRating,
        uint256 tradingVolume,
        uint256 uniqueContributors,
        uint256 dataAccessFees
    );

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

    function updateVanaEpoch(address vanaEpochAddress) external override onlyRole(MAINTAINER_ROLE) {
        vanaEpoch = IVanaEpoch(vanaEpochAddress);
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
        bool finalScores
    ) external override onlyRole(MANAGER_ROLE) whenNotPaused {
        uint256 dlpRewardsCount = 0;
        for (uint256 i = 0; i < epochDlpPerformances.length;) {
            EpochDlpPerformanceInput calldata epochDlpPerformance = epochDlpPerformances[i];

            _epochPerformances[epochId].epochDlpPerformances[epochDlpPerformance.dlpId] = EpochDlpPerformance({
                totalScore: epochDlpPerformance.totalScore,
                tradingVolume: epochDlpPerformance.tradingVolume,
                uniqueContributors: epochDlpPerformance.uniqueContributors,
                dataAccessFees: epochDlpPerformance.dataAccessFees
            });

            if (epochDlpPerformance.totalScore > 0) {
                dlpRewardsCount++;
            }


            emit EpochDlpPerformancesSaved(epochId, epochDlpPerformance.dlpId, epochDlpPerformance.totalScore, epochDlpPerformance.tradingVolume, epochDlpPerformance.uniqueContributors, epochDlpPerformance.dataAccessFees);

            unchecked {
                ++i;
            }
        }

        if (dlpRewardsCount == 0) {
            return;
        }

        IVanaEpoch.Rewards [] memory dlpRewards = new IVanaEpoch.Rewards[](dlpRewardsCount);

        uint256 epochRewardAmount = vanaEpoch.epochs(epochId).rewardAmount;
        uint256 rewardIndex = 0;
        for (uint256 i = 0; i < epochDlpPerformances.length;) {
            EpochDlpPerformanceInput calldata epochDlpPerformance = epochDlpPerformances[i];

            if (epochDlpPerformance.totalScore > 0) {
                dlpRewards[rewardIndex] = IVanaEpoch.Rewards({
                    dlpId: epochDlpPerformance.dlpId,
                    rewardAmount: epochDlpPerformance.totalScore * epochRewardAmount / 1e18
                });

                unchecked {
                    ++rewardIndex;
                }
            }

            unchecked {
                ++i;
            }
        }

        vanaEpoch.saveEpochDlpRewards(epochId, dlpRewards, finalScores);
    }
}
