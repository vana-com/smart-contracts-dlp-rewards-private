// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/VanaEpochStorageV1.sol";
import {IDLPRootEpoch} from "../rootEpoch/interfaces/IDLPRootEpoch.sol";

contract VanaEpochImplementation is
    UUPSUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    VanaEpochStorageV1
{
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");

    event EpochCreated(uint256 epochId, uint256 startBlock, uint256 endBlock, uint256 rewardAmount);
    event EpochOverridden(uint256 epochId, uint256 startBlock, uint256 endBlock, uint256 rewardAmount);
    event EpochSizeUpdated(uint256 newEpochSize);
    event EpochRewardAmountUpdated(uint256 newEpochRewardAmount);


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    struct InitializeParams {
        address ownerAddress;
        address dlpRegistryAddress;
        uint256 daySize;
        uint256 epochSize;
        uint256 epochRewardAmount;
    }

    function initialize(
        InitializeParams memory params
    ) external initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        dlpRegistry = IDLPRegistry     (params.dlpRegistryAddress);
        daySize = params.daySize;
        epochSize = params.epochSize;
        epochRewardAmount = params.epochRewardAmount;

        _grantRole(DEFAULT_ADMIN_ROLE, params.ownerAddress);
        _grantRole(MAINTAINER_ROLE, params.ownerAddress);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function version() external pure virtual override returns (uint256) {
        return 1;
    }

    function epochs(uint256 epochId) external view override returns (EpochInfo memory) {
        return
            EpochInfo({
                startBlock: _epochs[epochId].startBlock,
                endBlock: _epochs[epochId].endBlock,
                rewardAmount: _epochs[epochId].rewardAmount,
                isFinalised: _epochs[epochId].isFinalised,
                dlpIds: _epochs[epochId].dlpIds.values()
            });
    }

    function epochDlps(uint256 epochId, uint256 dlpId) external view override returns (EpochDlpInfo memory) {
        Epoch storage epoch = _epochs[epochId];
        EpochDlp memory epochDlp = epoch.dlps[dlpId];

        return
            EpochDlpInfo({
                isTopDlp: epoch.dlpIds.contains(dlpId),
                rewardAmount: epochDlp.rewardAmount,
                rewardClaimed: epochDlp.rewardClaimed
            });
    }

    function pause() external override onlyRole(MAINTAINER_ROLE) {
        _pause();
    }

    function unpause() external override onlyRole(MAINTAINER_ROLE) {
        _unpause();
    }

    function updateEpochSize(uint256 newEpochSizeInDays) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        epochSize = newEpochSizeInDays;
        emit EpochSizeUpdated(newEpochSizeInDays);
    }

    function updateEpochRewardAmount(uint256 newEpochRewardAmount) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        epochRewardAmount = newEpochRewardAmount;
        emit EpochRewardAmountUpdated(newEpochRewardAmount);
    }

    function updateDlpRegistry(address newDlpRegistryAddress) external override onlyRole(MAINTAINER_ROLE) {
        dlpRegistry = IDLPRegistry(newDlpRegistryAddress);
    }

    /**
     * @notice Creates epochs up to current block
     */
    function createEpochs() external override nonReentrant whenNotPaused {
        _createEpochsUntilBlockNumber(block.number);
    }

    /**
     * @notice Creates epochs up to specified block
     */
    function createEpochsUntilBlockNumber(uint256 blockNumber) external override nonReentrant whenNotPaused {
        _createEpochsUntilBlockNumber(blockNumber < block.number ? blockNumber : block.number);
    }

    /**
     * @notice Creates and finalises epochs up to target block
     */
    function _createEpochsUntilBlockNumber(uint256 blockNumber) internal {
        Epoch storage lastEpoch = _epochs[epochsCount];

        if (lastEpoch.endBlock > block.number) {
            return;
        }

        while (lastEpoch.endBlock < blockNumber) {
            Epoch storage newEpoch = _epochs[++epochsCount];
            newEpoch.startBlock = lastEpoch.endBlock + 1;
            newEpoch.endBlock = newEpoch.startBlock + epochSize * daySize - 1;
            newEpoch.rewardAmount = epochRewardAmount;

            emit EpochCreated(epochsCount, newEpoch.startBlock, newEpoch.endBlock, newEpoch.rewardAmount);
            lastEpoch = newEpoch;
        }
    }

    function migrateEpochData(address dlpRootEpochAddress, uint256 epochIdStart, uint256 epochIdEnd) external onlyRole(MAINTAINER_ROLE) {
        IDLPRootEpoch dlpRootEpoch = IDLPRootEpoch(dlpRootEpochAddress);

        uint256 dlpsCount = dlpRegistry.dlpsCount();

        for (uint256 epochId = epochIdStart; epochId <= epochIdEnd; ) {
            Epoch storage epoch = _epochs[epochId];
            IDLPRootEpoch.EpochInfo memory epochInfo = dlpRootEpoch.epochs(epochId);

            epoch.startBlock = epochInfo.startBlock;
            epoch.endBlock = epochInfo.endBlock;
            epoch.rewardAmount = epochInfo.rewardAmount;
            epoch.isFinalised = epochInfo.isFinalised;

            uint256 dlpId;
            uint256 epochDlpIdsCount = epochInfo.dlpIds.length;
            for (dlpId = 0; dlpId < epochDlpIdsCount; ) {
                epoch.dlpIds.add(epochInfo.dlpIds[dlpId]);

                unchecked {
                    ++dlpId;
                }
            }

            for (dlpId = 1; dlpId <= dlpsCount; ) {
                IDLPRootEpoch.EpochDlpInfo memory epochDlpOld = dlpRootEpoch.epochDlps(epochId, dlpId);
                EpochDlp storage epochDlp = epoch.dlps[dlpId];

                epochDlp.rewardAmount = epochDlpOld.ownerRewardAmount;
                epochDlp.rewardClaimed = epochDlpOld.ownerRewardAmount;

                unchecked {
                    ++dlpId;
                }
            }

            unchecked {
                ++epochId;
            }
        }
    }
}
