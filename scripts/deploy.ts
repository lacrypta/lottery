// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import hre from "hardhat";
import "console";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  const { deployer } = await hre.getNamedAccounts();

  await hre.deployments.deploy("Lottery", {
    contract: "Lottery",
    from: deployer,
    log: true,
  });
  const lotteryAddress = (await hre.deployments.get("Lottery")).address;
  console.log("Lottery deployed to:", lotteryAddress);

  if (hre.network.name == "matic") {
    await hre.run("verify:verify", { address: lotteryAddress });
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
