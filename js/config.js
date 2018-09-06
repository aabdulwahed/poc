/* eslint-disable no-unused-vars */
const path = require("path");

const dotenv = require("dotenv");
dotenv.config(path.join(__dirname, "..", ".env"));

const ganache = {
	accounts: [
		"0xB647a7FBBbCda7F477Ce315c0c2d814467521005",
		"0xe7D6a2a1cbEd37EE7446d78Fd5E6B38AAAe3f3B2",
		"0x9e7264Fe690dAFA282457b4F2fF1994513411228"
	],
	contracts: [
		"0xA54C7bF3811FFBD125b52f7D140911F20a57Ed56"
	],
	host: "http://localhost:7545",
	private: "ab030672f2f3da2d187f27e71a4b3564d98af64024340ba582a44e348f922817"
};

const infura = {
	accounts: [
		"0x98c0047400dA37d278E76e78c6F60A7882Ae064d",
		"0x19149798f777a3D738777334CCBf0063a04fCA3b"
	],
	contracts: [
		"0xdb9a535f8c43cb87b7c2a3019dc24a9b1edd6c31",
		"0xa2dc80a1e7de6ec5285c7af289c6e1e0efd4127e",
		"0x1f1c18a3e029f29b7eee064b223fe23d25d643db"
	],
	host: "https://rinkeby.infura.io/" + process.env.INFURA_API_KEY,
	private: process.env.INFURA_PRIVATE_KEY
};

const cli = {
	accounts: [
		"0x627306090abab3a6e1400e9345bc60c78a8bef57",
		"0xf17f52151ebef6c7334fad080c5704d77216b732"
	],
	contracts: [
		"0x345ca3e014aaf5dca488057592ee47305d9b3e10"
	],
	host: "http://localhost:8545",
	private: "ec8f4f5c599e912dd4956e72c1b6309703f8c0712006d1bc0a5f40b837aad36d"
};

module.exports = cli;
