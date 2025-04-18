// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/DLPRegistryStorageV1.sol";
import {IDLPRoot} from "../root/interfaces/IDLPRoot.sol";
import {IDLPTreasury} from "../dlpTreasury/interfaces/IDLPTreasury.sol";
import {IDLPRootCore} from "../rootCore/interfaces/IDLPRootCore.sol";

contract DLPRegistryImplementation is
    UUPSUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
DLPRegistryStorageV1
{
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using Checkpoints for Checkpoints.Trace208;

    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");

    // Key events for DLP lifecycle and operations
    event DlpRegistered(
        uint256 indexed dlpId,
        address indexed dlpAddress,
        address ownerAddress,
        address treasuryAddress,
        string name,
        string iconUrl,
        string website,
        string metadata
    );

    event DlpUpdated(
        uint256 indexed dlpId,
        address indexed dlpAddress,
        address ownerAddress,
        address treasuryAddress,
        string name,
        string iconUrl,
        string website,
        string metadata
    );

    event DlpStatusUpdated(uint256 indexed dlpId, DlpStatus newStatus);
    event DlpVerificationUpdated(uint256 indexed dlpId, bool verified);
    event DlpSubEligibilityThresholdUpdated(uint256 newDlpSubEligibilityThreshold);
    event MinDlpDepositAmountUpdated(uint256 newMinDlpDepositAmount);
    event DLPTokenUpdated(uint256 indexed dlpId, address tokenAddress);

    // Custom errors
    error InvalidParam();
    error InvalidDlpId();
    error InvalidDlpStatus();
    error DlpAlreadyVerified();
    error DlpTokenNotSet();
    error InvalidAddress();
    error InvalidName();
    error NotDlpOwner();
    error InvalidDepositAmount();
    error DlpAddressCannotBeChanged();
    error TransferFailed();
    error EpochNotEnded();
    error EpochDlpScoreAlreadySaved();
    error EpochRewardsAlreadyDistributed();
    error LastEpochMustBeFinalised();

    modifier onlyDlpOwner(uint256 dlpId) {
        if (_dlps[dlpId].ownerAddress != msg.sender) {
            revert NotDlpOwner();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address ownerAddress) external initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, ownerAddress);
        _grantRole(MAINTAINER_ROLE, ownerAddress);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function version() external pure virtual override returns (uint256) {
        return 1;
    }

    function dlps(uint256 dlpId) public view override returns (DlpInfo memory) {
        Dlp storage dlp = _dlps[dlpId];

        uint256 epochsCount = vanaEpoch.epochsCount();
        return
            DlpInfo({
                id: dlp.id,
                dlpAddress: dlp.dlpAddress,
                ownerAddress: dlp.ownerAddress,
                tokenAddress: dlp.tokenAddress,
                treasuryAddress: dlp.treasuryAddress,
                name: dlp.name,
                iconUrl: dlp.iconUrl,
                website: dlp.website,
                metadata: dlp.metadata,
                status: dlp.status,
                registrationBlockNumber: dlp.registrationBlockNumber,
                depositAmount: dlp.depositAmount,
                isVerified: dlp.isVerified
            });
    }

    function dlpsByAddress(address dlpAddress) external view override returns (DlpInfo memory) {
        return dlps(dlpIds[dlpAddress]);
    }

    function dlpsByName(string calldata dlpName) external view override returns (DlpInfo memory) {
        return dlps(dlpNameToId[dlpName]);
    }

    function eligibleDlpsListValues() external view override returns (uint256[] memory) {
        return _eligibleDlpsList.values();
    }

    function eligibleDlpsListCount() external view override returns (uint256) {
        return _eligibleDlpsList.length();
    }

    function eligibleDlpsListAt(uint256 index) external view override returns (uint256) {
        return _eligibleDlpsList.at(index);
    }

    function pause() external override onlyRole(MAINTAINER_ROLE) {
        _pause();
    }

    function unpause() external override onlyRole(MAINTAINER_ROLE) {
        _unpause();
    }

    function updateMinDlpDepositAmount(
        uint256 newMinDlpDepositAmount
    ) external override onlyRole(MAINTAINER_ROLE) {
        minDlpDepositAmount = newMinDlpDepositAmount;
        emit MinDlpDepositAmountUpdated(newMinDlpDepositAmount);
    }

    function updateVanaEpoch(address newVanaEpochAddress) external override onlyRole(MAINTAINER_ROLE) {
        vanaEpoch = IVanaEpoch(newVanaEpochAddress);
    }

    function updateTreasury(
        address newTreasuryAddress
    ) external override onlyRole(MAINTAINER_ROLE) {
        treasury = IDLPTreasury(newTreasuryAddress);
    }

    function registerDlp(
        DlpRegistration calldata registrationInfo
    ) external payable override whenNotPaused nonReentrant {
        vanaEpoch.createEpochs();
        _registerDlp(registrationInfo);
    }

    function updateDlpVerification(uint256 dlpId, bool isVerified) external override onlyRole(MAINTAINER_ROLE) {
        Dlp storage dlp = _dlps[dlpId];

        if (dlp.status == DlpStatus.None) {
            revert InvalidDlpStatus();
        }

        if (dlp.status == DlpStatus.Deregistered) {
            revert InvalidDlpStatus();
        }

        if (dlp.isVerified == isVerified) {
            revert DlpAlreadyVerified();
        }

        if (dlp.tokenAddress == address(0)) {
            revert DlpTokenNotSet();
        }

        dlp.isVerified = isVerified;

        emit DlpVerificationUpdated(dlpId, isVerified);

        _setDlpEligibility(dlp);
    }

    function updateDlpToken(uint256 dlpId, address tokenAddress) external override onlyRole(MAINTAINER_ROLE) {
        Dlp storage dlp = _dlps[dlpId];
        dlp.tokenAddress = tokenAddress;

        emit DLPTokenUpdated(dlpId, tokenAddress);
    }

    /**
     * @notice Updates DLP information
     * @dev Only DLP owner can update
     */
    function updateDlp(
        uint256 dlpId,
        DlpRegistration calldata dlpUpdateInfo
    ) external override whenNotPaused nonReentrant onlyDlpOwner(dlpId) {
        vanaEpoch.createEpochs();

        if (dlpUpdateInfo.ownerAddress == address(0) || dlpUpdateInfo.treasuryAddress == address(0)) {
            revert InvalidAddress();
        }

        Dlp storage dlp = _dlps[dlpId];

        //this validation will be removed in the future
        if (dlp.dlpAddress != dlpUpdateInfo.dlpAddress) {
            revert DlpAddressCannotBeChanged();
        }

        dlp.ownerAddress = dlpUpdateInfo.ownerAddress;
        dlp.treasuryAddress = dlpUpdateInfo.treasuryAddress;

        if (keccak256(bytes(dlpUpdateInfo.name)) != keccak256(bytes(dlp.name))) {
            if (dlpNameToId[dlpUpdateInfo.name] != 0 || !_validateDlpNameLength(dlpUpdateInfo.name)) {
                revert InvalidName();
            }

            dlpNameToId[dlp.name] = 0;
            dlpNameToId[dlpUpdateInfo.name] = dlpId;
        }

        dlp.name = dlpUpdateInfo.name;
        dlp.iconUrl = dlpUpdateInfo.iconUrl;
        dlp.website = dlpUpdateInfo.website;
        dlp.metadata = dlpUpdateInfo.metadata;

        dlpIds[dlpUpdateInfo.dlpAddress] = dlpId;

        emit DlpUpdated(
            dlpId,
            dlpUpdateInfo.dlpAddress,
            dlpUpdateInfo.ownerAddress,
            dlpUpdateInfo.treasuryAddress,
            dlpUpdateInfo.name,
            dlpUpdateInfo.iconUrl,
            dlpUpdateInfo.website,
            dlpUpdateInfo.metadata
        );
    }

    function deregisterDlp(uint256 dlpId) external override whenNotPaused nonReentrant onlyDlpOwner(dlpId) {
        vanaEpoch.createEpochs();

        uint256 epochsCount = vanaEpoch.epochsCount();
        if (epochsCount > 1 && !vanaEpoch.epochs(epochsCount - 1).isFinalised) {
            revert LastEpochMustBeFinalised();
        }

        Dlp storage dlp = _dlps[dlpId];

        if (dlp.status == DlpStatus.None || dlp.status == DlpStatus.Deregistered) {
            revert InvalidDlpStatus();
        }

        dlp.status = DlpStatus.Deregistered;
        _eligibleDlpsList.remove(dlpId);


        emit DlpStatusUpdated(dlpId, DlpStatus.Deregistered);
    }

    /**
     * @notice Internal function to register a new DLP
     */
    function _registerDlp(DlpRegistration calldata registrationInfo) internal {
        if (registrationInfo.ownerAddress == address(0) || registrationInfo.treasuryAddress == address(0)) {
            revert InvalidAddress();
        }

        if (dlpIds[registrationInfo.dlpAddress] != 0) {
            revert InvalidDlpStatus();
        }

        if (dlpNameToId[registrationInfo.name] != 0 || !_validateDlpNameLength(registrationInfo.name)) {
            revert InvalidName();
        }

        if (msg.value < minDlpDepositAmount) {
            revert InvalidDepositAmount();
        }

        uint256 dlpId = ++dlpsCount;
        Dlp storage dlp = _dlps[dlpId];

        uint256 epochsCount = vanaEpoch.epochsCount();

        dlp.id = dlpId;
        dlp.dlpAddress = registrationInfo.dlpAddress;
        dlp.ownerAddress = registrationInfo.ownerAddress;
        dlp.treasuryAddress = registrationInfo.treasuryAddress;
        dlp.name = registrationInfo.name;
        dlp.iconUrl = registrationInfo.iconUrl;
        dlp.website = registrationInfo.website;
        dlp.metadata = registrationInfo.metadata;
        dlp.registrationBlockNumber = block.number;
        dlp.depositAmount = msg.value;
        dlp.status = DlpStatus.Registered;

        dlpIds[registrationInfo.dlpAddress] = dlpId;

        dlpNameToId[registrationInfo.name] = dlpId;

        emit DlpRegistered(
            dlpId,
            registrationInfo.dlpAddress,
            registrationInfo.ownerAddress,
            registrationInfo.treasuryAddress,
            registrationInfo.name,
            registrationInfo.iconUrl,
            registrationInfo.website,
            registrationInfo.metadata
        );

        emit DlpStatusUpdated(dlpId, DlpStatus.Registered);

        (bool success, ) = payable(address(treasury)).call{value: msg.value}("");
        if (!success) {
            revert TransferFailed();
        }
    }


    function _validateDlpNameLength(string memory str) internal pure returns (bool) {
        bytes memory strBytes = bytes(str);
        uint256 count = 0;

        for (uint256 i = 0; i < strBytes.length; i++) {
            if (strBytes[i] != 0x20) {
                // 0x20 is the ASCII space character
                count++;
            }
        }

        return count > 3;
    }

    function migrateDlpData(address dlpRootCoreAddress, uint256 startDlpId, uint256 endDlpId) external onlyRole(MAINTAINER_ROLE) {
        IDLPRootCore dlpRootCore = IDLPRootCore(dlpRootCoreAddress);

        for (uint256 dlpId = startDlpId; dlpId <= endDlpId; ) {
            IDLPRootCore.DlpInfo memory dlpInfo = dlpRootCore.dlps(dlpId);
            Dlp storage dlp = _dlps[dlpId];

            dlp.id = dlpInfo.id;
            dlp.dlpAddress = dlpInfo.dlpAddress;
            dlp.ownerAddress = dlpInfo.ownerAddress;
            dlp.treasuryAddress = payable(dlpInfo.treasuryAddress);
            dlp.name = dlpInfo.name;
            dlp.iconUrl = dlpInfo.iconUrl;
            dlp.website = dlpInfo.website;
            dlp.metadata = dlpInfo.metadata;
            dlp.status = DlpStatus(uint256(dlpInfo.status));
            dlp.registrationBlockNumber = dlpInfo.registrationBlockNumber;
            dlp.isVerified = dlpInfo.isVerified;

            dlpIds[dlpInfo.dlpAddress] = dlpId;
            dlpNameToId[dlpInfo.name] = dlpId;

            if (DlpStatus(uint256(dlpInfo.status)) == DlpStatus.Eligible) {
                _eligibleDlpsList.add(dlpId);
            }

            dlpsCount++;

            unchecked {
                ++dlpId;
            }
        }
    }

    function _setDlpEligibility(Dlp storage dlp) internal {
        if (dlp.status == DlpStatus.Registered) {
            if (dlp.isVerified && dlp.tokenAddress != address(0)) {
                dlp.status = DlpStatus.Eligible;
                _eligibleDlpsList.add(dlp.id);
                emit DlpStatusUpdated(dlp.id, DlpStatus.Eligible);
            }
        } else if (dlp.status == DlpStatus.Eligible) {
            if (!dlp.isVerified || dlp.tokenAddress == address(0)) {
                dlp.status = DlpStatus.Registered;
                _eligibleDlpsList.remove(dlp.id);
                emit DlpStatusUpdated(dlp.id, DlpStatus.Registered);
            }
        }
    }
}
