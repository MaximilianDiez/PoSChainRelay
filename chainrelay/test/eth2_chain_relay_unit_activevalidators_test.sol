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
contract TestEth2ChainRelayUnitActiveValidators {

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

    function testGetActiveValidators1() public {
        bytes[] memory actual = chainRelay.getActiveValidators([bytes(hex"01"), bytes(hex"00")], [true, false], 1);
        bytes[] memory expected = new bytes[](1);
        expected[0] = bytes(hex"01");
        Assert.equal(actual.length, 1, "getActiveValidators should yield correct number of active validators");
        AssertBytes.equal(actual[0], expected[0], "getActiveValidators should yield correct active validators");
        /* fallback w/o library
        for (uint i = 0; i < actual[0].length; i++) {
            // only fixed length parts can be checked with Assert, therefore check single bytes' equality
            Assert.equal(actual[0][i], expected[0][i], "getActiveValidators should yield correct active validators");
        }*/ 
    } 
       
    function testGetActiveValidators2() public {   
        bytes[] memory actual2 = chainRelay.getActiveValidators([bytes(hex"deadbeef"), bytes(hex"beefdead")], [true, true], 2);
        bytes[] memory expected2 = new bytes[](2);
        expected2[0] = bytes(hex"deadbeef");
        expected2[1] = bytes(hex"beefdead");
        Assert.equal(actual2.length, 2, "getActiveValidators should yield correct number of active validators");
        AssertBytes.equal(actual2[0], expected2[0], "getActiveValidators should yield correct active validators");
        AssertBytes.equal(actual2[1], expected2[1], "getActiveValidators should yield correct active validators");
        /* fallback w/o library
        for (uint i = 0; i < actual2[0].length; i++) { 
            // only fixed length parts can be checked with Assert, therefore check single bytes' equality
            Assert.equal(actual2[0][i], expected2[0][i], "getActiveValidators should yield correct active validators");
            Assert.equal(actual2[1][i], expected2[1][i], "getActiveValidators should yield correct active validators");
        }*/
    }
}
