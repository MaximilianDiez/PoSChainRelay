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
contract TestEth2ChainRelayUnitSSZ {

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
    
    function testValidateMerkleBranch() public {
        bytes32 root = bytes32(hex"fc4c8a75f3c7d11d1568e982f77a105cf89d973cb21daae22667fb21bea9d013");
        bytes32 leaf = bytes32(hex"84ce28e3ba0c05f9000000000000000000000000000000000000000000000000");
        uint index = 8;
        bytes32[] memory branch = new bytes32[](3);
        bytes32[3] memory branch_to_assign = [bytes32(hex"08bcb2fa3e9c90fa000000000000000000000000000000000000000000000000"), bytes32(hex"1a6a78243e89399bb55534287b099955add8acefe1c586cdb00df9fba28b2fed"), bytes32(hex"3bb51a214d0033297959f7dc1fcc85663ba5fc6ee16579d5456e4d0f11451baf")];
        for (uint i = 0; i < 3; i++) {
            branch[i] = branch_to_assign[i];
        }
        Assert.isTrue(chainRelay.validateMerkleBranch(root, leaf, index, branch), "validateMerkleBranch should return to true for valid branch");
    }
    
    function testHashTreeRootSyncCommittee() public {
        bytes[2] memory sync_committee = [bytes(hex"8bfa00e6e69c18dda4d8d1a456bacc08c0ff229267ed21ac49ac4756b8865b7c70d6d3f1d5bc3584c6975bf0df296a50"), bytes(hex"b09aedb91ec3b366ee71ed0e9e65ee3f216136cdaf1c5943404d110779ef7d489f476b7755e8f26be386c8a06bfdc924")];
        bytes memory aggregate = bytes(hex"a47aefa3ba67b7dc7151c73925a272d5af2201acbe5f821a0219f14415510ae5bfcdb280c1e575a616fe3d1f4965ef85");
        bytes32 expected = bytes32(hex"bf3359ba3eeba8898813562257c0c426f8f33d2d5e7eed2ed5aee6f895da9ade");
        bytes32 actual = chainRelay.hashTreeRootSyncCommittee(sync_committee, aggregate);
        Assert.equal(expected, actual, "merkleize should return correct merkleization root of chunks");
    }
    
    function testMerkleize() public {
        bytes32[2] memory committee_chunks = [bytes32(hex"737ac05e522afcf01126b6914e15d6d418fd6e5c018635ce699744f22900d9a9"), bytes32(hex"39fb96bb1a012ade3f04c7d8ba13c8b6ad50feae2a275502502c3f57f5657d07")];
        bytes32 expected = bytes32(hex"2f6ab4b85c43b3236b154a9853588f6c4b75e24f3903e64f426c95ceb66667ac");
        bytes32 actual = chainRelay.merkleize(committee_chunks);
        Assert.equal(expected, actual, "merkleize should return correct merkleization root of chunks");
    }
    
    function testGetSubtreeIndex() public {
        Assert.equal(chainRelay.getSubtreeIndex(101), 37, "getSubtreeIndex should return correct subtree index");
        Assert.equal(chainRelay.getSubtreeIndex(128), 0, "getSubtreeIndex should return correct subtree index");
    }
    
    function testMerkleizeSlot() public {
        uint64 input = 101;
        bytes32 expected = bytes32(hex"6500000000000000000000000000000000000000000000000000000000000000");
        bytes32 actual = chainRelay.merklelizeSlot(input);
        Assert.equal(expected, actual, "merklelize_slot should correctly merkleize example slot");
    }
    
    function testHashTreeRootBlsPubkey() public {
        bytes memory pubkey = bytes(hex"8bfa00e6e69c18dda4d8d1a456bacc08c0ff229267ed21ac49ac4756b8865b7c70d6d3f1d5bc3584c6975bf0df296a50");
        bytes32 expected = bytes32(hex"737ac05e522afcf01126b6914e15d6d418fd6e5c018635ce699744f22900d9a9");
        bytes32 actual = chainRelay.hashTreeRootBlspubkey(pubkey);
        Assert.equal(actual, expected, "hash tree root blspubkey should hash to the correct value");
    }
    
    function testHashTreeRootPair() public {
        Assert.equal(chainRelay.hashTreeRootPair(bytes32(hex"cc8b8174c1b65c93843bc7e7a86416934292ea430252b4e159cd69bbbd0252bd"), bytes32(hex"d895951676aebde3f9031cb4de38071c8c2446d2edc82065c591b35156cf7886")), bytes32(hex"b0b0d0eb3a1e77cb115e4f1366d7dffb48123c6a83b3daa34c0135cd1d0d7b13"), "pair hash tree root should be correctly generated");
    }
}
