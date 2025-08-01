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

// contract : 0x94e8ad3B02b1E6C87cb7ecce750d9a8F52fE8307
