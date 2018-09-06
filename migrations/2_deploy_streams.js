const Stream = artifacts.require("./Stream.sol");

const params = {
	recipient: "0x4C50A4CF1bd11Ed1DE4A3f66171aa3906cBc2590",
	price: "10000000000000000",
	interval: "240",
	duration: "17280"
};

module.exports = deployer => {
	deployer.deploy(Stream, params.recipient, params.price, params.interval, params.duration, {
		value: "720000000000000000"
	});
};
