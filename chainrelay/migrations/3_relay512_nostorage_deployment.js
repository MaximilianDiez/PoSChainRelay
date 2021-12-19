const Eth2ChainRelay_512_NoStorage = artifacts.require("Eth2ChainRelay_512_NoStorage");

const zero = '0x0000000000000000000000000000000000000000000000000000000000000000'

module.exports = function (deployer) {
  deployer.deploy(Eth2ChainRelay_512_NoStorage, 16, 0, zero, zero, 0, 0, 0, {gas: 8000000})
  .then(instance => {
  });
};