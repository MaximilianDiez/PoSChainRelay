# A Verifyable Chain Relay for Proof of Stake Blockchains 

This repository contains a proof of concept implementation of a fully verifyable Ethereum 2.0 chain relay for usage on EVM-compatible blockchains. The prototype is work in progress and not intended for production usage. 

## Project Structure & Licenses

The repository contains a customized code forks: 
- https://github.com/ethereum/go-ethereum/ in the folder `verilay-go-ethereum`

All changes are lincensed under the project's original license. 

Please note that this repository contains intermediate files for reference only.  

## Getting Started

This section describes how to get started with running the chain relay prototype.   

### Running a custom Ethereum testnet with Go-Ethereum

Deploying and testing the chain relay prototype requires running a custom version of the [Go Ethereum](https://github.com/ethereum/go-ethereum) client. In order to compile the custom version of Go Ethereum and create and run a custom ephemeral version of the Ethereum blockchain, make sure [Go](https://golang.org/) as well as a C compiler is installed and execute the following commands:

```bash
cd verilay-go-ethereum
make geth 
./build/bin/geth --rpc.gascap 30000000 --datadir test-chain-dir --http --dev --vmdebug --verbosity 3 --rpcapi debug,eth,personal,net,web3
```

The customized files in `verilay-go-ethereum` are 
| File path | Description of changes |
|---|---|
| `go-ethereum/core/genesis.go` | (1) Replacing the block Gas limit of 11,500,000 with 1,150,000,000. (2)  Replacing the _ModExp_ precompile function and contract at the address `0x0000000000000000000000000000000000000005` with a [FastAggregateVerify](https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-bls-signature-04#section-3.3.4) precompile. |
| `go-ethereum/core/vm/contracts.go` | (1) Replacing the _ModExp_ precompile with a [FastAggregateVerify](https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-bls-signature-04#section-3.3.4) precompile based on [Herumi BLS](https://github.com/herumi/bls-eth-go-binary). It verifies a given signature, message and public key array triple. True is returned if valid, false if invalid. (2) Replacing the _ModExp_ precompile Gas cost calculation with an estimation of the Gas cost caused by [EIP-2537](https://eips.ethereum.org/EIPS/eip-2537) operations on the BLS12-381 curve. |

### Deploying chain relay smart contracts and running test scenarios with Truffle

Deploying different versions of the chain relay smart contract and reproducibly testing it is faciliated by [Truffle](https://github.com/trufflesuite/truffle). `contracts` contains the chain relay prototype smart contracts as Solidity source code in different configurations (Eth2 sync committee with 32 members, Eth2 sync committee with 512 members, Eth2 sync committee with 512 members and No-Store optimization). `migrations` contains instructions for Truffle on how to deploy the contracts for testing. `tests` contains test scenarios defined in Solidity (`*.sol`) as well as JavaScript (`*.js`). The file `tests/evaluation.js` contains the test scenarios used for evaluating the chain relay prototype, specifically its Gas consumption.

In order to deploy the smart contracts and run the tests, make sure [Truffle](https://github.com/trufflesuite/truffle) and [NodeJS and NPM](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm) are installed, start the customized Ethereum testnet (see above) and run the following commands:

```bash
npm install
truffle test
```

This deploys the smart contracts and executes all test scenarios. To execute a single test scenario, for example the scenarios relevant for the evaluation of the prototype, run `truffle test test/evaluation.js`. 

The file `recording_test_results.txt` contains a recording of the output of running all tests. 

## Creating custom tests

### Generating BLS aggregate signatures for testing

In order to generate BLS multi-signatures for testing purposes, [compiled binaries of Herumi's BLS library](https://github.com/herumi/bls-eth-go-binary) are used with a Eth2 compatible configuration. Messages are signed with a set of pseudo-random private keys, which are derived from a seed and therefore deterministic. The number of signers (default 512) as well as the message to be signed (default `32BytesMessageForSigningGoodness`) can be adjusted in `test/generate/data/generate_signature_test_data.go`. 

To generate test data and print it to a shell, make sure [Go](https://golang.org/) is installed and run

```bash
go run bls-eth-go-binary/generate_signature_test_data.go
```

### Generating SSZ structures and merkle proofs

All the test data used by the Truffle test scenarios is generated from or similar to the code in the file `test/ssz/generate_ssz_test_data.py`. The file can be run to re-generate lots of test data or can be used as a boilerplate for generating further test data. 

Please note that this file is a log of many commands used for generating test data structures for the evaluation of the prototype and some data might be outdated. For a structured introduction to generating SSZ data structures, please refer to the Ethereum specification.

The file can be run by installing Python 3 (do consider creating a [virtual environment](https://docs.python.org/3/library/venv.html) beforehand) and running the commands

```bash
cd test/ssz
pip3 install -r requirements.txt
python3 generate_ssz_test_data.py
```

For navigating SSZ data structures and generating additional test data, it is also helpful to load the file in an interactive Python shell by running `python3 -i generate_ssz_test_data.py`. 

Note that the file also contains the class `ChainRelayAlpha`, which is an early version of the prototype chain relay written in Python. It was used testing first versions of the application logic and defining helper functions derived from the specification. While it is not up to date with the Solidity version of the chain relay prototype, it may still be used to check generated SSZ test data. 