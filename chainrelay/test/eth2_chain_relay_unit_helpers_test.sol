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
contract TestEth2ChainRelayUnitHelpers {

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

    function testFinalizedBlockRoot() public {
        Assert.equal(chainRelay.getFinalizedBlockRoot(), bytes32(hex"00"), "getFinalizedBlockRoot should return the finalized block");
    }
    
    function testCountTrueBools() public {
        Assert.equal(chainRelay.countTrueBools([true, false]), 1, "countTrueBools should correctly count trues");
        Assert.equal(chainRelay.countTrueBools([false, false]), 0, "countTrueBools should correctly count trues");
        Assert.equal(chainRelay.countTrueBools([true, true]), 2, "countTrueBools should correctly count trues");
    }
    
    function testFloorlog2() public {
        uint input1 = 16;
        uint expected1  = 4;
        uint actual1 = chainRelay.floorLog2(input1);
        Assert.equal(expected1, actual1, "floorLog2 should return correct floor(log2(input))");
        uint input2 = 31;
        uint expected2  = 4;
        uint actual2 = chainRelay.floorLog2(input2);
        Assert.equal(expected2, actual2, "floorLog2 should return correct floor(log2(input))");
    }
    
    function testNextPowOfTwo() public {
        uint input1 = 16;
        uint expected1  = 16;
        uint actual1 = chainRelay.nextPowOfTwo(input1);
        Assert.equal(expected1, actual1, "checkNextPowOfTwo should return correct next power of two");
        uint input2 = 31;
        uint expected2  = 32;
        uint actual2 = chainRelay.nextPowOfTwo(input2);
        Assert.equal(expected2, actual2, "checkNextPowOfTwo should return correct next power of two");
    }
    
    function testBitLength() public {
        uint input1 = 127;
        uint expected1  = 7;
        uint actual1 = chainRelay.bitLength(input1);
        Assert.equal(expected1, actual1, "bitlength should return correct bitlength");
        uint input2 = 128;
        uint expected2  = 8;
        uint actual2 = chainRelay.bitLength(input2);
        Assert.equal(expected2, actual2, "bitlength should return correct bitlength");
    }
    
    function testRevertBytes8() public {
        bytes8 input = bytes8(hex"deadbeefdeadbeef");
        bytes8 expected = bytes8(hex"efbeaddeefbeadde");
        bytes8 actual = chainRelay.revertBytes8(input);
        Assert.equal(expected, actual, "bytes8 should be correctly reversed");
    }
    
    function testSlotToUnixTimestamp() public {
        Assert.equal(chainRelay.slotToUnixTimestamp(101), 1606825235, "slot should be correctly converted to unix timestamp");
    }
    
    function testConcat() public {
        bytes memory actual = chainRelay.concat(bytes32(hex"cc8b8174c1b65c93843bc7e7a86416934292ea430252b4e159cd69bbbd0252bd"), bytes32(hex"d895951676aebde3f9031cb4de38071c8c2446d2edc82065c591b35156cf7886"));
        bytes memory expected = bytes(hex"cc8b8174c1b65c93843bc7e7a86416934292ea430252b4e159cd69bbbd0252bdd895951676aebde3f9031cb4de38071c8c2446d2edc82065c591b35156cf7886");
        Assert.equal(actual.length, expected.length, "pair hash tree root should be correctly generated");
        AssertBytes.equal(actual, expected, "pair hash tree root should be correctly generated");
        /* fallback w/o library
        for (uint i = 0; i < actual.length; i+=9) { // for efficiency reasons, don't check all
            // only fixed length parts can be checked with Assert, therefore check single bytes' equality
            Assert.equal(actual[i], expected[i], "pair hash tree root should be correctly generated");
        }*/
    }
    
    function testToBytes() public {
        bytes memory actual = chainRelay.bytes32ToBytes(bytes32(hex"cc8b8174c1b65c93843bc7e7a86416934292ea430252b4e159cd69bbbd0252bd"));
        bytes memory expected = bytes(hex"cc8b8174c1b65c93843bc7e7a86416934292ea430252b4e159cd69bbbd0252bd");
        Assert.equal(actual.length, expected.length, "bytes32 to bytes conversion should yield same bytes");
        AssertBytes.equal(actual, expected, "bytes32 to bytes conversion should yield same bytes");
        /* fallback w/o library
        for (uint i = 0; i < actual.length; i+=9) { // for efficiency reasons, don't check all
            // only fixed length parts can be checked with Assert, therefore check single bytes' equality
            Assert.equal(actual[i], expected[i], "bytes32 to bytes conversion should yield same bytes");
        } */
    }
    
    function testSha256() public {
        Assert.equal(sha256(chainRelay.bytes32ToBytes(bytes32(hex"cc8b8174c1b65c93843bc7e7a86416934292ea430252b4e159cd69bbbd0252bd"))), bytes32(hex"f437216ec3394721dbb5e8ec1b539f4fe850824ea7e20562552a55a64ff76396"), "sha256 should create correct digest");
    }
}
