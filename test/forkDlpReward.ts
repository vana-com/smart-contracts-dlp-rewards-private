import chai, { should } from "chai";
import chaiAsPromised from "chai-as-promised";
import { ethers, network, upgrades } from "hardhat";
import {
  DLPRegistryImplementation,
  VanaEpochImplementation,
  TreasuryImplementation,
  DLPPerformanceImplementation, DLPRewardSwapImplementation, DLPRewardDeployerImplementation
} from "../typechain-types";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import {
  advanceBlockNTimes,
  advanceToBlockN,
  getCurrentBlockNumber,
} from "../utils/timeAndBlockManipulation";
import { getReceipt, parseEther } from "../utils/helpers";
import * as helpers from "@nomicfoundation/hardhat-network-helpers";
import { setBalance } from "@nomicfoundation/hardhat-network-helpers";

chai.use(chaiAsPromised);
should();

describe("DLP fork tests", () => {
  const vanaEpochAddress = "0xb35480AdB5757Cab703e13c529d8fC0781343516";
  const treasuryAddress = "0x05aa58a6B51446A27a02aA5725c602AEc0E4500d";
  const dlpRegistryAddress = "0xA6dFc0ef21D91F166Ca51c731D1a115a5b715a3F";
  const dlpPerformanceAddress = "0x4FEa7823D2E727F6D1F83422A7FD619070B06832";
  const dlpRewardSwapAddress = "0x011D527151Ae1f80991c07F8AE64350655A4AeA0";
  const dlpRewardDeployerAddress = "0x1066cEA72d975B23c7B43557d468ac8674A452Bd";
  const adminAddress = "0x2AC93684679a5bdA03C6160def908CdB8D46792f";

  enum DlpStatus {
    None,
    Registered,
    Eligible,
    Deregistered
  }

  let admin: HardhatEthersSigner;
  let maintainer: HardhatEthersSigner;
  let manager: HardhatEthersSigner;

  let dlpRegistry: DLPRegistryImplementation;
  let vanaEpoch: VanaEpochImplementation;
  let treasury: TreasuryImplementation;
  let dlpPerformance: DLPPerformanceImplementation;
  let dlpRewardSwap: DLPRewardSwapImplementation;
  let dlpRewardDeployer: DLPRewardDeployerImplementation;


  const DEFAULT_ADMIN_ROLE =
    "0x0000000000000000000000000000000000000000000000000000000000000000";
  const MAINTAINER_ROLE = ethers.keccak256(
    ethers.toUtf8Bytes("MAINTAINER_ROLE"),
  );
  const MANAGER_ROLE = ethers.keccak256(
    ethers.toUtf8Bytes("MANAGER_ROLE"),
  );
  const CUSTODIAN_ROLE = ethers.keccak256(
    ethers.toUtf8Bytes("CUSTODIAN_ROLE"),
  );

  type DlpRegistration = {
    dlpAddress: string;
    ownerAddress: HardhatEthersSigner;
    treasuryAddress: string;
    name: string;
    iconUrl: string;
    website: string;
    metadata: string;
  };

  type DlpPerformanceInput = {
    dlpId: number;
    totalScore: bigint;
    tradingVolume: bigint;
    uniqueContributors: bigint;
    dataAccessFees: bigint;
  };

  let dlp1Info: DlpRegistration;
  let dlp2Info: DlpRegistration;

  const deploy = async () => {
    await helpers.mine();
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [adminAddress],
    });
    admin = await ethers.provider.getSigner(adminAddress);

    dlpRegistry = await ethers.getContractAt("DLPRegistryImplementation", dlpRegistryAddress);
    vanaEpoch = await ethers.getContractAt("VanaEpochImplementation", vanaEpochAddress);
    treasury = await ethers.getContractAt("TreasuryImplementation", treasuryAddress);
    dlpPerformance = await ethers.getContractAt("DLPPerformanceImplementation", dlpPerformanceAddress);
    dlpRewardSwap = await ethers.getContractAt("DLPRewardSwapImplementation", dlpRewardSwapAddress);
    dlpRewardDeployer = await ethers.getContractAt("DLPRewardDeployerImplementation", dlpRewardDeployerAddress);

    await setBalance(adminAddress, parseEther(100));

    console.log("Fork block number: ", await getCurrentBlockNumber());
  };

  async function advanceToEpochN(epochNumber: number) {
  }

  describe("Tests", () => {
    beforeEach(async () => {
      await deploy();
    });

    it("should savePerformance", async function() {
      // await dlpPerformance
      //   .connect(admin)
      //   .upgradeToAndCall(
      //     await ethers.deployContract("DLPPerformanceImplementation"),
      //     "0x",
      //   );
      // await vanaEpoch
      //   .connect(admin)
      //   .upgradeToAndCall(
      //     await ethers.deployContract("VanaEpochImplementation"),
      //     "0x",
      //   );

      const epoch1Performances = [
        {
          dlpId: 1,
          totalScore: parseEther(0.6),
          tradingVolume: parseEther(1000),
          uniqueContributors: 50n,
          dataAccessFees: parseEther(5)
        },
        {
          dlpId: 2,
          totalScore: parseEther(0.4),
          tradingVolume: parseEther(1000),
          uniqueContributors: 50n,
          dataAccessFees: parseEther(5)
        }
      ];

      await dlpPerformance.connect(admin).saveEpochPerformances(1, epoch1Performances, true);
    });

    it("should distributeRewards", async function() {
      await dlpRegistry.connect(admin). updateDlpLpTokenId(1, 86);
      await dlpRegistry.connect(admin). updateDlpToken(1, '0xb95C6ED43B965D1050161a6A6D78170eFEf5dbF2');

      await dlpRewardDeployer.connect(admin).updateDlpRewardSwap('0x7c6862C46830F0fc3bF3FF509EA1bD0EE7267fB0');

      const tokenContract = await ethers.getContractAt("DAT", "0xb95C6ED43B965D1050161a6A6D78170eFEf5dbF2");
      await setBalance((await dlpRewardDeployer.treasury()).toString(), parseEther(10));
      console.log("Balance: ", await tokenContract.balanceOf((await dlpRegistry.dlps(1)).treasuryAddress));
      await dlpRewardDeployer.connect(admin).distributeRewards(1, [1]);
      console.log("Balance: ", await tokenContract.balanceOf((await dlpRegistry.dlps(1)).treasuryAddress));
    });

    it.only("should migrateDlpsData", async function() {
      await dlpRegistry.connect(admin).migrateDlpData('0x0aBa5e28228c323A67712101d61a54d4ff5720FD', 1, 1);

      console.log(await dlpRegistry.dlps(1));
    });
  });
});