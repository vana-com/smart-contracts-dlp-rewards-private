// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IDLPTreasury} from "./IDLPTreasury.sol";

abstract contract DLPTreasuryStorageV1 is IDLPTreasury {
    address public override custodian;
}
