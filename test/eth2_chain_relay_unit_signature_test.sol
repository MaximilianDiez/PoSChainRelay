// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

// This import is automatically injected by Remix
//import "remix_tests.sol"; 


// This import is required to use custom transaction context
// Although it may fail compilation in 'Solidity Compiler' plugin
// But it will work fine in 'Solidity Unit Testing' plugin
//import "remix_accounts.sol";
import "../contracts/Eth2ChainRelay_2.sol";

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "bytes/AssertBytes.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract TestEth2ChainRelayUnitSignature {

    Eth2ChainRelay_2 chainRelay;

    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function beforeAll() public {
        // <instantiate contract>
        bytes[2] memory current_validator_set = [bytes(hex"00"), bytes(hex"00")];
        bytes memory current_validator_set_aggregate = bytes(hex"00");
        bytes[2] memory next_validator_set = [bytes(hex"00"), bytes(hex"00")];
        bytes memory next_validator_set_aggregate = bytes(hex"00");
        bytes32 finalized_block_root = bytes32(hex"00");
        bytes32 finalized_state_root = bytes32(hex"00");
        chainRelay = new Eth2ChainRelay_2(0, 0, current_validator_set, current_validator_set_aggregate, next_validator_set, next_validator_set_aggregate, finalized_block_root, finalized_state_root, 0, 0, 0);
    }
    
    function testSerializeAggregateSignature() public {
        bytes32 message = bytes32(0x3332427974654d657373616765466f725369676e696e67476f6f6f646e657373);
        bytes[] memory pubkeys = new bytes[](2);
        bytes[2] memory pubkeys_to_assign = [bytes(hex"915022b83374b2f9fb412a2be16d5a0341a49142d49c55b08efffb4be1e85c79c5acbe8c4b1889d2f765a49d67cf2410"),bytes(hex"8692865b0ceb08f7aafd3fd0413786c4c9f600648a038db12bebec60bb033348846c27fbcf4388993b79a90029390e44")];        
        for (uint i = 0; i < 2; i++) {
            pubkeys[i] = pubkeys_to_assign[i];
        }
        bytes memory signature = bytes(hex"b11e805e390b811a9ab219b9cc54f2081d012979488d46cc7ab62030e6fd606f0955889517bfda0cb00ff523cc70b5fa0f34770903a2e1180f5c2f4d0a399df86e3fbc2c5aee0f351aedfc695c92f4b21451d248a3c37b6dd5765a5805cbc06a");
        bytes memory expectedSerialized = bytes(hex"3332427974654d657373616765466f725369676e696e67476f6f6f646e657373b11e805e390b811a9ab219b9cc54f2081d012979488d46cc7ab62030e6fd606f0955889517bfda0cb00ff523cc70b5fa0f34770903a2e1180f5c2f4d0a399df86e3fbc2c5aee0f351aedfc695c92f4b21451d248a3c37b6dd5765a5805cbc06a0002915022b83374b2f9fb412a2be16d5a0341a49142d49c55b08efffb4be1e85c79c5acbe8c4b1889d2f765a49d67cf24108692865b0ceb08f7aafd3fd0413786c4c9f600648a038db12bebec60bb033348846c27fbcf4388993b79a90029390e44");
        bytes memory actualSerialized = chainRelay.serializeAggregateSignature(message, signature, pubkeys);
        AssertBytes.equal(actualSerialized, expectedSerialized, "serializeAggregateSignature should correctly serialize");
        /* fallback w/o library
        for (uint i = 0; i < actualSerialized.length; i+=9) { // for efficiency reasons, don't check all
            // only fixed length parts can be checked with Assert, therefore check single bytes' equality
            Assert.equal(actualSerialized[i], expectedSerialized[i], "serializeAggregateSignature should correctly serialize"); 
        }*/
    }

    function testFastAggregateVerify() public{
        bytes memory payload = bytes(hex"3332427974654d657373616765466f725369676e696e67476f6f6f646e657373b11e805e390b811a9ab219b9cc54f2081d012979488d46cc7ab62030e6fd606f0955889517bfda0cb00ff523cc70b5fa0f34770903a2e1180f5c2f4d0a399df86e3fbc2c5aee0f351aedfc695c92f4b21451d248a3c37b6dd5765a5805cbc06a0002915022b83374b2f9fb412a2be16d5a0341a49142d49c55b08efffb4be1e85c79c5acbe8c4b1889d2f765a49d67cf24108692865b0ceb08f7aafd3fd0413786c4c9f600648a038db12bebec60bb033348846c27fbcf4388993b79a90029390e44");
        Assert.isTrue(chainRelay.fastAggregateVerify(payload), "fastAggregateVerify should return true");
    }
    
}
