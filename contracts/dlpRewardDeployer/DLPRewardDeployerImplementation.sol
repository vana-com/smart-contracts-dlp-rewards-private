// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "./interfaces/DLPRewardDeployerStorageV1.sol";

contract DLPRewardDeployerImplementation is
    UUPSUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    DLPRewardDeployerStorageV1
{
    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");
    bytes32 public constant REWARD_DEPLOYER_ROLE = keccak256("REWARD_DEPLOYER_ROLE");

    error EpochNotFinalized();
    error EpochNotEndedYet();
    error InvalidEpoch();
    error EpochRewardsAlreadyDistributed();
    error NothingToDistribute(uint256 dlpId);

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
        _setRoleAdmin(REWARD_DEPLOYER_ROLE, MAINTAINER_ROLE);
        _grantRole(DEFAULT_ADMIN_ROLE, ownerAddress);
        _grantRole(MAINTAINER_ROLE, ownerAddress);
        _grantRole(REWARD_DEPLOYER_ROLE, ownerAddress);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function version() external pure virtual override returns (uint256) {
        return 1;
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

    function distributeRewards(uint256[] calldata dlpIds) external override onlyRole(REWARD_DEPLOYER_ROLE) whenNotPaused {
        uint256 epochId = vanaEpoch.epochsCount() - 1;
        IVanaEpoch.Epoch memory epoch = vanaEpoch.epochs(epochId);

        if (!epoch.isFinalized) {
            revert EpochNotFinalized();
        }

        for (uint256 i = 0; i < dlpIds.length; i++) {
            IVanaEpoch.EpochDlpInfo memory epochDlp = vanaEpoch.epochDlps(epochId, dlpIds[i]);

            if (epochDlp.rewardClaimed >= epoch.rewardAmount) {
                revert NothingToDistribute(dlpIds[i]);
            }


        }
    }
}
