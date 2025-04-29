import { deployments, ethers } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { parseEther } from "ethers";
import { getCurrentBlockNumber } from "../utils/timeAndBlockManipulation";
import { deployProxy, verifyProxy } from "./helpers";

const implementationContractName = "DLPPerformanceImplementation";
const proxyContractName = "DLPPerformanceProxy";
const proxyContractPath = "contracts/dlpPerformance/DLPPerformanceProxy.sol:DLPPerformanceProxy";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const [deployer] = await ethers.getSigners();

  const implementationDeploy = await deployments.deploy(
    implementationContractName,
    {
      from: deployer.address,
      args: [],
      log: true,
    },
  );

  const DEFAULT_ADMIN_ROLE =
    "0x0000000000000000000000000000000000000000000000000000000000000000";
  const MAINTAINER_ROLE = ethers.keccak256(
    ethers.toUtf8Bytes("MAINTAINER_ROLE"),
  );
  const MANAGER_ROLE = ethers.keccak256(
    ethers.toUtf8Bytes("MANAGER_ROLE"),
  );

  // Get DLPRegistry address from previous deployment
  const dlpRegistryAddress = (await deployments.get("DLPRegistryProxy")).address;

  const proxyDeploy = await deployProxy(
    deployer,
    proxyContractName,
    implementationContractName,
    [deployer.address, dlpRegistryAddress],
  );

  console.log(``);
  console.log(``);
  console.log(``);
  console.log(`**************************************************************`);
  console.log(`**************************************************************`);
  console.log(`**************************************************************`);
  console.log(`********** DLPPerformance Deployment Completed **********`);

  const proxy = await ethers.getContractAt(
    implementationContractName,
    proxyDeploy.proxyAddress,
  );

  // Configure the contract and assign roles
  await proxy.connect(deployer).grantRole(MAINTAINER_ROLE, deployer);
  await proxy.connect(deployer).grantRole(MANAGER_ROLE, deployer);

  // Get VanaEpoch address from previous deployment
  const vanaEpochAddress = (await deployments.get("VanaEpochProxy")).address;

  await proxy.connect(deployer).updateVanaEpoch(vanaEpochAddress);
  console.log(`DLPPerformance updated with VanaEpoch address`);

  console.log(`DLPPerformance proxy address: ${proxyDeploy.proxyAddress}`);
  console.log(`DLPPerformance implementation address: ${proxyDeploy.implementationAddress}`);

  const vanaEpoch = await ethers.getContractAt(
    "VanaEpochImplementation",
    vanaEpochAddress
  );

  await vanaEpoch.connect(deployer).updateDlpPerformance(proxyDeploy.proxyAddress);

  await verifyProxy(
    proxyDeploy.proxyAddress,
    proxyDeploy.implementationAddress,
    proxyDeploy.initializeData,
    proxyContractPath,
  );

  return;
};

export default func;
func.tags = ["DLPPerformanceProxy"];
