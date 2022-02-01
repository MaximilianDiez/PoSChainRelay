// SPDX-License-Identifier: GPL-3.0-or-later

// PLEASE NOTE: This is a prototype. Do not use it in production settings. 

pragma solidity >=0.8.0 <0.9.0;

import "bytes/BytesLib.sol";
import "./libraries/Memory.sol";

// debug settings
bool constant MOCK_BLS_PRECOMPILE = false;

// magic numbers
uint constant FIRST_BEACON_BLOCK_UNIX_TIMESTAMP = 1606824023;

// eth2 mainnet configuration
uint constant SYNC_COMMITTEE_SIZE = 512;
uint constant SECONDS_PER_SLOT = 12;
uint constant SLOTS_PER_EPOCH = 32;
uint constant EPOCHS_PER_SYNC_COMMITTEE_PERIOD = 512;

// SSZ generalized indices
uint constant FINALIZED_ROOT_INDEX = 105;
uint constant FINALIZED_EPOCH_INDEX = 104;
uint constant NEXT_SYNC_COMMITTEE_INDEX = 55;
uint constant NEXT_SYNC_COMMITTEE_PUBKEYS_INDEX = 110;
uint constant NEXT_SYNC_COMMITTEE_AGGREGATE_PUBKEY_INDEX = 111;
uint constant CURRENT_SYNC_COMMITTEE_INDEX = 54;
uint constant CURRENT_SYNC_COMMITTEE_PUBKEYS_INDEX = 108;
uint constant CURRENT_SYNC_COMMITTEE_AGGREGATE_PUBKEY_INDEX = 109;
uint constant SLOT_INDEX = 8;
uint constant STATE_ROOT_INDEX = 11;

struct ChainRelayUpdate {
    bytes signature;
    bool[SYNC_COMMITTEE_SIZE] participants;
    bytes32 latestBlockRoot;
    bytes32 signingDomain;
    bytes32 stateRoot;
    bytes32[] stateRootBranch; 
    uint64 latestSlot;
    bytes32[] latestSlotBranch; 
    bytes32 finalizedBlockRoot; 
    bytes32[] finalizingBranch; 
    uint64 finalizedSlot; 
    bytes32[] finalizedSlotBranch; 
    bytes32 finalizedStateRoot;
    bytes32[] finalizedStateRootBranch;
    bytes[SYNC_COMMITTEE_SIZE] syncCommittee;
    bytes syncCommitteeAggregate;
    bytes32[] syncCommitteeBranch; 
}

/** 
 * @title Chain Relay
 * @dev Implements a chain relay/light client for eth2 consensus post-altair (including sync committees)
 */
contract Eth2ChainRelay_512_NoStorage {
    using BytesLib for bytes;

    uint64 private signatureThreshold; // 0 < signatureThreshold <= 512
    uint64 private trustingPeriod; // validators are trusted for a certain time, ensuring they have not exited the validator set, in unix time
    bytes private currentValidatorSetAggregate;
    bytes private nextValidatorSetAggregate;
    bytes32 private finalizedBlockRoot;
    bytes32 private finalizedStateRoot; 
    uint64 private latestSlot;
    uint64 private latestSlotWithValidatorSetChange;
    uint64 private finalizedSlot;
    bytes[SYNC_COMMITTEE_SIZE] testSyncCommittee;
    bytes testSyncCommitteeAggregate;
    
    constructor(uint64 _signatureThreshold, 
                uint64 _trustingPeriod, 
                bytes32 _finalizedBlockRoot,
                bytes32 _finalizedStateRoot,
                uint64 _finalizedSlot,
                uint64 _latestSlot,
                uint64 _latestSlotWithValidatorSetChange) 
    {
        signatureThreshold=_signatureThreshold;
        trustingPeriod=_trustingPeriod;
        finalizedBlockRoot=_finalizedBlockRoot;
        latestSlot=_latestSlot;
        latestSlotWithValidatorSetChange=_latestSlotWithValidatorSetChange;
        finalizedSlot=_finalizedSlot;
        finalizedStateRoot=_finalizedStateRoot;
    }

    function getLatestSlotWithValidatorSetChange() public view returns (uint64) {
        return latestSlotWithValidatorSetChange;
    }
    
    function getFinalizedBlockRoot() public view returns (bytes32) {
        return finalizedBlockRoot;
    }
    
    function getFinalizedStateRoot() public view returns (bytes32) {
        return finalizedStateRoot;
    }

    function testEncoding(bytes32 message, bytes memory signature, bytes[] memory pubkeys) public view returns (bytes memory) {
        return abi.encode(message, signature, pubkeys);
    }

    function testJustStoreSyncCommittee(bytes[SYNC_COMMITTEE_SIZE] memory committee, bytes memory aggregate) public {
        testSyncCommittee = committee;
        testSyncCommitteeAggregate = aggregate;
    }

    function testJustDoSyncCommitteeMerkleizationFromMemory(bytes[SYNC_COMMITTEE_SIZE] memory committee, bytes memory aggregate) public returns (bytes32) {
        return hashTreeRootSyncCommittee(committee, aggregate);
    }

    function testJustDoSyncCommitteeMerkleizationFromStorage() public returns (bytes32) {
        return hashTreeRootSyncCommittee(testSyncCommittee, testSyncCommitteeAggregate);
    }

    function testJustReadSyncCommitteeFromStorage() public returns (bytes[SYNC_COMMITTEE_SIZE] memory) {
        return testSyncCommittee;
    }

    function testJustSubmitSyncCommitteeViaMemory(bytes[SYNC_COMMITTEE_SIZE] memory) public returns (bool) {
        return true;
    }

    function testJustSubmitSyncCommitteeViaCalldata(bytes[SYNC_COMMITTEE_SIZE] calldata) public returns (bool) {
        return true;
    }

    function testDoNothingWithData(ChainRelayUpdate memory _chainRelayUpdate) public returns (bool) {
        if (_chainRelayUpdate.syncCommittee.length == 512) {
            return true;
        } else {
            return false;
        }
    }
    
    function submitUpdate(ChainRelayUpdate memory _chainRelayUpdate) public returns (bool) {
        bytes32 signingRoot = computeSigningRoot(_chainRelayUpdate.latestBlockRoot, _chainRelayUpdate.signingDomain);
        uint numberOfParticipants = countTrueBools(_chainRelayUpdate.participants);
        require(
            numberOfParticipants >= signatureThreshold, 
            "not enough signature participants");
        require(
            validateMerkleBranch(
                _chainRelayUpdate.latestBlockRoot, 
                _chainRelayUpdate.stateRoot, 
                STATE_ROOT_INDEX, 
                _chainRelayUpdate.stateRootBranch), 
            "merkle proof for latest state root not valid");
        // the following checks are executed but ignored in order to allow for testing with synthetic SSZ/Eth2 data
        /*require(*/
            validateMerkleBranch(
                _chainRelayUpdate.latestBlockRoot, 
                merklelizeSlot(_chainRelayUpdate.latestSlot), 
                SLOT_INDEX, 
                _chainRelayUpdate.latestSlotBranch)/*, "merkle proof for latest slot not valid")*/;
        /*require(*/
            validateMerkleBranch(
                _chainRelayUpdate.stateRoot, 
                _chainRelayUpdate.finalizedBlockRoot, 
                FINALIZED_ROOT_INDEX, 
                _chainRelayUpdate.finalizingBranch)/*, "merkle proof for finalized block root not valid")*/;
        /*require(*/
            validateMerkleBranch(
                _chainRelayUpdate.finalizedBlockRoot, 
                merklelizeSlot(_chainRelayUpdate.finalizedSlot), 
                SLOT_INDEX, 
                _chainRelayUpdate.finalizedSlotBranch)/*, "merkle proof for finalized slot not valid")*/;
        require(
            validateMerkleBranch(
                _chainRelayUpdate.finalizedBlockRoot, 
                _chainRelayUpdate.finalizedStateRoot, 
                STATE_ROOT_INDEX, 
                _chainRelayUpdate.finalizedStateRootBranch), 
            "merkle proof for finalized state root not valid");
        require(
            _chainRelayUpdate.latestSlot >= latestSlot, 
            "latest block older than last latest block seen by chain relay");
        require(
            _chainRelayUpdate.finalizedSlot >= finalizedSlot, 
            "finalized block older than last finalized block seen by chain relay");
        uint slot_distance = _chainRelayUpdate.latestSlot - latestSlotWithValidatorSetChange; 
        if ((slot_distance / (SLOTS_PER_EPOCH * EPOCHS_PER_SYNC_COMMITTEE_PERIOD)) == 0) {
            // the following check is executed but ignored in order to allow for testing with synthetic SSZ/Eth2 data
            /*require(*/validateMerkleBranch(
                finalizedStateRoot, 
                hashTreeRootSyncCommittee(_chainRelayUpdate.syncCommittee, _chainRelayUpdate.syncCommitteeAggregate), 
                CURRENT_SYNC_COMMITTEE_INDEX, 
                _chainRelayUpdate.syncCommitteeBranch)/*, "merkle proof for current sync committee not valid")*/;
           require(
               fastAggregateVerify(serializeAggregateSignature(
                   signingRoot, 
                   _chainRelayUpdate.signature, 
                   getActiveValidators(_chainRelayUpdate.syncCommittee, _chainRelayUpdate.participants, numberOfParticipants))), 
               "signature by current sync committee not valid");
        } else if ((slot_distance / (SLOTS_PER_EPOCH * EPOCHS_PER_SYNC_COMMITTEE_PERIOD)) == 1) {
            // the following check is executed but ignored in order to allow for testing with synthetic SSZ/Eth2 data
            /*require(*/validateMerkleBranch(
                finalizedStateRoot, 
                hashTreeRootSyncCommittee(_chainRelayUpdate.syncCommittee, _chainRelayUpdate.syncCommitteeAggregate), 
                NEXT_SYNC_COMMITTEE_INDEX, 
                _chainRelayUpdate.syncCommitteeBranch)
                /*, "merkle proof for next sync committee not valid")*/;
            require(
                fastAggregateVerify(serializeAggregateSignature(
                    signingRoot, 
                    _chainRelayUpdate.signature, 
                    getActiveValidators(_chainRelayUpdate.syncCommittee, _chainRelayUpdate.participants, numberOfParticipants))), 
                "signature by next sync committee not valid");
            latestSlotWithValidatorSetChange = _chainRelayUpdate.finalizedSlot;
        } else {
            revert("latest slot does not indicate that current or next sync committee is responsible");
        }
        finalizedBlockRoot = _chainRelayUpdate.finalizedBlockRoot; 
        finalizedStateRoot = _chainRelayUpdate.finalizedStateRoot;
        latestSlot = _chainRelayUpdate.latestSlot;
        finalizedSlot = _chainRelayUpdate.finalizedSlot;
        return true;
    }
    
    function getActiveValidators(bytes[SYNC_COMMITTEE_SIZE] memory _pubkeys, bool[SYNC_COMMITTEE_SIZE] memory _isActive, uint _numberOfActive) public pure returns (bytes[] memory) {
        bytes[] memory active_validators = new bytes[](_numberOfActive);
        uint counter = 0;
        for (uint i = 0; i < SYNC_COMMITTEE_SIZE; i++) {
            if (_isActive[i]) {
                active_validators[counter] = _pubkeys[i];
                counter++;
            }
        }
        return active_validators;
    }
    
    function countTrueBools(bool[SYNC_COMMITTEE_SIZE] memory _bools) public pure returns (uint) {
        uint counter = 0;
        for (uint i = 0; i < SYNC_COMMITTEE_SIZE; i++) {
            if (_bools[i] == true) {
                counter++;
            }
        }
        return counter;
    }

    function serializeAggregateSignature(bytes32 _message, bytes memory _signature, bytes[] memory _pubkeys) public pure returns (bytes memory) {
        bytes2 length = bytes2(uint16(_pubkeys.length));
        bytes memory serialized = new bytes(32+96+2+48*_pubkeys.length);
        for (uint i = 0; i < 32; i++) {
            serialized[i] = _message[i];
        }
        for (uint i = 32; i < 128; i++) {
            serialized[i] = _signature[i-32];
        }
        for (uint i = 128; i < 130; i++) {
            serialized[i] = length[i-128];
        }
        for (uint i = 0; i < _pubkeys.length; i++) {
            for (uint j = 0; j < 48; j++) {
                serialized[32+96+2+i*48+j] = _pubkeys[i][j];
            }
        }
       return serialized;
    }
    
    function fastAggregateVerify(bytes memory _input) public view returns (bool o) {
        if (MOCK_BLS_PRECOMPILE) {
            return true;
        }
        bool[1] memory outCache;
        assembly {
            let p := mload(0x40)
            let length := mload(_input)
            if iszero(staticcall(gas(), 0x05, add(_input,32), length, outCache, 32)) { // first 32 yte of _input are length
                revert(0, 0)
            }
        }
        o = outCache[0];
    }
    
    function slotToUnixTimestamp(uint _slot) public pure returns (uint timestamp) {
        return _slot * SECONDS_PER_SLOT + FIRST_BEACON_BLOCK_UNIX_TIMESTAMP;
    }
    
    function bytes32ToBytes(bytes32 _input) public pure returns (bytes memory output) {
        return abi.encodePacked(_input);
    }
    
    function bytes2ToBytes(bytes2 _input) public pure returns (bytes memory output) {
        return abi.encodePacked(_input);
    }
    
    function concat(bytes32 _left, bytes32 _right) public pure returns (bytes memory) {
        return bytes.concat(_left, _right);
        // below is fallback code for older solidity versions
        /*bytes memory concatenated;
        for (uint i = 0; i<32; i++) {
            concatenated[i] = left[i];
        }
        for (uint i = 0; i<32; i++) {
            concatenated[i+32] = right[i];
        }
        return concatenated;*/
    }

    function hashTreeRootPair(bytes32 _left, bytes32 _right) public pure returns (bytes32) {
        return sha256(concat(_left, _right));
    }
    
    function hashTreeRootBlspubkey (bytes memory _blspubkey) public pure returns (bytes32) {
        bytes memory blspubkeyMerkleizedLeft = _blspubkey.slice(0, 32);
        bytes memory blspubkeyMerkleizedRight = _blspubkey.slice(32, 16);
        blspubkeyMerkleizedRight = blspubkeyMerkleizedRight.concat(bytes(hex"00000000000000000000000000000000"));
        /* fallback w/o library
        bytes memory blspubkeyMerkleizedLeft = new bytes(32);
        for (uint i = 0; i<32; i++) {
            blspubkeyMerkleizedLeft[i] = _blspubkey[i];
        }
        bytes memory blspubkeyMerkleizedRight = new bytes(32);
        for (uint i = 0; i<16; i++) { // rest of blspubkeyMerkleizedRight is initialized zero
            blspubkeyMerkleizedRight[i] = _blspubkey[i+32];
        }*/
        return hashTreeRootPair(bytesToBytes32(blspubkeyMerkleizedLeft), bytesToBytes32(blspubkeyMerkleizedRight));
    }
    
    function computeSigningRoot(bytes32 _blockRoot, bytes32 _signingDomain) public pure returns (bytes32) {
        return hashTreeRootPair(_blockRoot, _signingDomain);
    }
    
    function bytesToBytes8(bytes memory _input) public pure returns (bytes8 result) {
        if (_input.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(_input, 32))
        }
    }
    
    function bytesToBytes32(bytes memory _input) public pure returns (bytes32 result) {
        if (_input.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(_input, 32))
        }
    }

    function revertBytes8(bytes8 _input) public pure returns (bytes8) {
        bytes memory reverted = new bytes(8);
        for (uint i = 0; i < 8; i++) {
            reverted[7-i] = _input[i];
        }
        return bytesToBytes8(reverted);
    }

    function merklelizeSlot(uint64 _input) public pure returns (bytes32) {
        return bytes32(revertBytes8(bytes8(_input)));
    }
    
    function bitLength(uint _input) public pure returns (uint) {
        uint length = 0;
        while (_input != 0) 
        {
            _input >>= 1; 
            length++; 
        }
        return length;
    }
    
    function nextPowOfTwo(uint _input) public pure returns (uint) {
        if (_input == 0) {
            return 1;
        } else {
            return 2**(bitLength(_input-1));
        }
    }
    
    function floorLog2 (uint _input) public pure returns (uint) {
        require(_input >= 1, "_input to floorLog2 must be larger or equal than 1");
        return bitLength(_input)-1;
    }
    
    function merkleize(bytes32[SYNC_COMMITTEE_SIZE] memory _chunks) public pure returns (bytes32) {
        uint length_next_pow = nextPowOfTwo(_chunks.length);
        for (uint i = _chunks.length; i < length_next_pow; i++) {
           // filling lowest level not necessary b/c size always 2^n
        }
        for (uint level = 0; level<floorLog2(length_next_pow); level++) {
            uint step = 2**level;
            for (uint current_accumulator = 0; current_accumulator < length_next_pow; current_accumulator += step*2) {
                _chunks[current_accumulator] = hashTreeRootPair(_chunks[current_accumulator], _chunks[current_accumulator+step]);
            }
        }
        return _chunks[0];
    }
    
    function hashTreeRootSyncCommittee(bytes[SYNC_COMMITTEE_SIZE] memory _syncCommittee, bytes memory _syncAggregate) public pure returns (bytes32) {
        bytes32[SYNC_COMMITTEE_SIZE] memory syncCommitteeHashed;
        for (uint i = 0; i < SYNC_COMMITTEE_SIZE; i++) {
            syncCommitteeHashed[i] = hashTreeRootBlspubkey(_syncCommittee[i]);
        }
        bytes32 syncCommitteeHashedMerkleized = merkleize(syncCommitteeHashed);
        bytes32 syncCommitteeRoot = hashTreeRootPair(syncCommitteeHashedMerkleized, hashTreeRootBlspubkey(_syncAggregate));
        return syncCommitteeRoot;
    }
    
    function getSubtreeIndex(uint _generalizedIndex) public pure returns (uint) {
        return _generalizedIndex % 2**(floorLog2(_generalizedIndex));
    }
    
    function validateMerkleBranch(bytes32 _root, bytes32 _leaf, uint _generalizedIndex, bytes32[] memory _branch) public pure returns (bool) {
        uint index = getSubtreeIndex(_generalizedIndex);
        uint depth = floorLog2(_generalizedIndex);
        bytes32 value = _leaf;
        for (uint i = 0; i < depth; i++) {
            if ((index / (2**i) % 2) == 1) {
                value = sha256(concat(_branch[i],value));
            } else {
                value = sha256(concat(value,_branch[i]));
            }
        }
        return value == _root;
    }
    
}