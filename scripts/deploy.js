async function main() {
  const EnergySharing = await ethers.getContractFactory("EnergySharing");

  // Start deployment, returning a promise that resolves to a contract object
  const energy_share = await EnergySharing.deploy();
  //const energy_share = await EnergySharing.deploy("EnergySharing");
  console.log("Contract deployed to address:", energy_share.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
