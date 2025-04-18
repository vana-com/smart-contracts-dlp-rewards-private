# Data Liquidity Pool (DLP)

## Table of Contents
1. [Introduction](#introduction)
2. [Installation](#installation)
3. [DLP Contracts](#contracts)
   - [Multisend](#multisend)
   - [DataLiquidityPool](#dataliquiditypool)
   - [DAT (Data Access Token)](#dat-data-access-token)


## 1. Introduction

This repository is private and contains all Vana Protocol contracts.

## 2. Installation

#### 1. Environment Setup

Before deploying or interacting with the contracts, you need to set up your environment variables. Follow these steps:
- Copy the `.env.example` file and rename it to `.env`.
- Open the `.env` file and update the following parameters:

`DEPLOYER_PRIVATE_KEY`: The private key of the account that will deploy the contracts. Make sure to keep this private and never share it.

`OWNER_ADDRESS`: The Ethereum address that will be set as the owner of the deployed contracts. This address will have special privileges in the contracts.


#### 2. Install dependencies
```bash
yarn install
```

#### 3. Run tests
- run tests specific to a smart contract: ```npx hardhat test test/<file_name>.ts```
- all tests (including dependencies): ```npx hardhat test```

## 5. Contracts

### Multisend
#### Description
A smart contract is useful for sending VANA tokens to multiple addresses at once.

#### Deployment addresses:
Moksha: [0x8807e8BCDFbaA8c2761760f3FBA37F6f7F2C5b2d](https://moksha.vanascan.io/address/0x8807e8BCDFbaA8c2761760f3FBA37F6f7F2C5b2d)

Satori: [0x8807e8BCDFbaA8c2761760f3FBA37F6f7F2C5b2d](https://satori.vanascan.io/address/0x8807e8BCDFbaA8c2761760f3FBA37F6f7F2C5b2d)

#### How to use it
Multisend Vana on vanascan: [multisendVana(amount, recipientAddresses[])](https://moksha.vanascan.io/address/0x8807e8BCDFbaA8c2761760f3FBA37F6f7F2C5b2d?tab=write_proxy#79b9add0)

Multisend Token on vanascan: [multisendToken(tokenAddress, amount, recipientAddresses[])](https://moksha.vanascan.io/address/0x8807e8BCDFbaA8c2761760f3FBA37F6f7F2C5b2d?tab=write_proxy#98035f4b)
(Don't forgot to approve transfer before calling this function)

Multisend Vana code example:
```typescript
const sponsorWallet = new ethers.Wallet('0x123', ethers.provider);
const recipientAddresses = ['0x456', '0x789', '0xabc'];
const amount = parseEther('0.5');
const multisend = await ethers.getContractAt('MultisendImplementation', '0x8807e8BCDFbaA8c2761760f3FBA37F6f7F2C5b2d');
await multisend.connect(sponsorWallet).multisendVana(amount, recipientAddresses, {value: amount * recipientAddresses.length});
```

Multisend Token code example:
```typescript
const sponsorWallet = new ethers.Wallet('0x123', ethers.provider);
const recipientAddresses = ['0x456', '0x789', '0xabc'];
const amount = parseEther('0.5');
const multisend = await ethers.getContractAt('MultisendImplementation', '0x8807e8BCDFbaA8c2761760f3FBA37F6f7F2C5b2d');
const token = await ethers.getContractAt('Token', 'tokensAddress');
await token.connect(sponsorWallet).approve(multisend.address, amount * recipientAddresses.length);
await multisend.connect(sponsorWallet).multisendVana(amount, recipientAddresses, {value: amount * recipientAddresses.length});
```


### DataLiquidityPool

See the [DataLiquidityPool repository](https://github.com/vana-com/vana-dlp-smart-contracts) for more details.


1	1.1	Trusted Forwarder/Relayer can steal everything and take over the protocol	High
fixed by overriding _checkRole
    function _checkRole(bytes32 role) internal view override {
        _checkRole(role, msg.sender);
    }

2	1.2	Inconsistency in Performance Rating Calculations	High
- fixed topDlps accepts a list of dlps for which the ranking is calculated
3	2.1	Incorrect Rating Scale in Reward Calculations	Medium
- fixed
4	2.2	Incorrect Division by totalTopDlpsRatingAmount	Medium
- fixed
5	2.3	Incorrect Use of stakersPercentage in epy Calculation	Medium
- not fixed. APY and EPY are for stakers and not for DLPs
6	2.4	Lack of whenNotPaused() modifier in Treasury contract	Medium
- fixed
7	2.5	Incorrect EPY Calculation	Medium
- fixed
8	3.1	Default Admin Role Not Updated in updateDlpRoot	Low
- fixed
9	3.2	Unchecked Low-Level Calls Across the Contract	Low
- fixed
10	3.3	Fixed 80/20 Staking-to-Performance Ratio Misleading Users	Low
- fixed
11	3.4	Rewards Calculation for Non-Eligible DLPs	Low
- not fixed. we want to estimate rewards even for DLPs that are not in the TOP
12	4.1	Unnecessary Allocation of Large bool Array	Informational
- fixed - removed that logic
13	4.2	minTopDlpStake variable is declared but not used.	Informational
- fixed
14	4.3	DLPRootMetricsStorageV1 of Mock contract has incorrect storage.	Informational
- fixed