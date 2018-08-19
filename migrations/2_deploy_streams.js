const Stream = artifacts.require("./Stream.sol");

module.exports = deployer => {
	deployer.deploy(Stream);
};
