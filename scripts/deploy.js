const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy CourseFactory
  console.log("Deploying CourseFactory...");
  const CourseFactory = await ethers.getContractFactory("CourseFactory");
  const courseFactory = await CourseFactory.deploy();
  await courseFactory.waitForDeployment();

  const factoryAddress = await courseFactory.getAddress();
  console.log("CourseFactory deployed to:", factoryAddress);

  // Register as lecturer
  const tx1 = await courseFactory.registerUser("Bambo", "", true, "");
  await tx1.wait();
  console.log("Lecturer registered.");

  // Create course
  const tx2 = await courseFactory.createCourse(
    "Blockchain 101",
    "Intro to Blockchain"
  );
  await tx2.wait();
  console.log("Course created.");

  // Create exam
  const tx3 = await courseFactory.createExam(1, "Midterm Exam", 3600); // 1 hour duration
  await tx3.wait();

  const examAddress = await courseFactory.getExamAddress(1, 0); // first course, first exam
  console.log("Exam deployed to:", examAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

// CourseFactory deployed to: 0xB94988fe226a2Ee1574C3335E69bac25f38a960C

// Exam deployed to: 0x8E090bE859C4d96665854Ae2787990573889F19C
