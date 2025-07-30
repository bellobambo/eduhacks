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

// CourseFactory deployed to: 0x18051371A6F270491fB042FaeA762446898827eF

// Exam deployed to: 0x51Ae025a060AFaf1B1e745Bb2AF5d07DF44AD836
