const { ethers } = require("hardhat");

async function main() {
  const LMS = await ethers.getContractFactory("LMS");

  const lms = await LMS.deploy(); // Sends the transaction
  await lms.waitForDeployment(); // Waits for deployment to finish (required!)

  console.log(`✅ LMS contract deployed to: ${await lms.getAddress()}`);
}

main().catch((error) => {
  console.error("❌ Deployment failed:", error);
  process.exitCode = 1;
});

// contract : 0xa4c7c58cF5eacabFe96a7FcB52CBAEe0b272fB22
