const IRV = artifacts.require("IRV_Votingtoken")

module.exports = function (deployer) {
    deployer.deploy(IRV);
  };