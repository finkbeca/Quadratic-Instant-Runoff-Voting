const votingToken = artifacts.require("Votingtoken");

module.exports = function (deployer) {
  deployer.deploy(votingToken);
};