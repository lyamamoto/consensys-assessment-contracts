const LendingAndBorrowing = artifacts.require("LendingAndBorrowing");

module.exports = function (deployer) {
  deployer.deploy(LendingAndBorrowing);
};
