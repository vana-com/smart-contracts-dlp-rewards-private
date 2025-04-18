# Data Liquidity Pool (DLP)

## Table of Contents
1. [Introduction](#introduction)
2. [Installation](#installation)


## 1. Introduction

This repository is private and contains part of Vana Protocol contracts.

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