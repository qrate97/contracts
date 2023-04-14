import { ethers } from "hardhat";

async function main() {
  // get contract and deploy to blockchain
  const Qrate = await ethers.getContractFactory("Qrate");
  const qrate = await Qrate.deploy();

  await qrate.deployed();

  console.log("Deployed qrate contract to:", qrate.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
