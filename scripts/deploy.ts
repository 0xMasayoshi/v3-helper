import hre from "hardhat";

const RESET = "\x1b[0m";
const GREEN = "\x1b[32m";
const RED = "\x1b[31m";

function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log(`Deployer address: ${GREEN}${deployer.address}${RESET}\n`);

  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log(
    `Deployer balance: ${GREEN}${hre.ethers.formatEther(balance)} ETH${RESET}\n`,
  );

  const contractName = "V3PositionHelper";
  console.log(`Preparing to deploy ${contractName}...\n`);

  const factory = await hre.ethers.getContractFactory(contractName);
  const deployTx = await factory.getDeployTransaction();

  try {
    const estimatedGas = await hre.ethers.provider.estimateGas(deployTx);
    const feeData = await hre.ethers.provider.getFeeData();

    console.log(
      `${GREEN}Estimated Gas: ${estimatedGas.toString()} units${RESET}`,
    );

    if (feeData.maxFeePerGas && feeData.maxPriorityFeePerGas) {
      // EIP-1559
      const totalCostWei = estimatedGas * feeData.maxFeePerGas;
      const costEth = hre.ethers.formatEther(totalCostWei);
      console.log(`Estimated Cost (EIP-1559): ${GREEN}${costEth} ETH${RESET}`);
      console.log(
        `  ↳ Max Fee Per Gas: ${hre.ethers.formatUnits(feeData.maxFeePerGas, "gwei")} gwei`,
      );
      console.log(
        `  ↳ Max Priority Fee: ${hre.ethers.formatUnits(feeData.maxPriorityFeePerGas, "gwei")} gwei`,
      );
    } else if (feeData.gasPrice) {
      // Legacy gas
      const totalCostWei = estimatedGas * feeData.gasPrice;
      const costEth = hre.ethers.formatEther(totalCostWei);
      console.log(`Estimated Cost (Legacy): ${GREEN}${costEth} ETH${RESET}`);
      console.log(
        `  ↳ Gas Price: ${hre.ethers.formatUnits(feeData.gasPrice, "gwei")} gwei`,
      );
    } else {
      console.log(`${RED}Could not determine gas price or fee data${RESET}`);
    }
  } catch (err) {
    console.log(
      `${RED}Gas estimation failed. This can happen on some networks if the constructor would revert or simulation isn't supported.`,
    );
    console.log(
      `Error: ${err instanceof Error ? err.message : String(err)}${RESET}`,
    );
  }

  console.log(`\nDeploying ${contractName}...`);
  const contract = await factory.deploy();
  await contract.waitForDeployment();
  const contractAddress = await contract.getAddress();

  console.log(
    `\n${contractName} deployed to: ${GREEN}${contractAddress}${RESET}\n`,
  );

  console.log("Waiting 30 seconds before verifying...");
  await delay(30000);

  await hre.run("verify:verify", {
    address: contractAddress,
  });

  // Optional: Tenderly verification
  // await hre.tenderly.verify({
  //   name: contractName,
  //   address: contractAddress,
  // });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
