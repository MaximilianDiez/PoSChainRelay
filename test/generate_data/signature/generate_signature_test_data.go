package main

import (
	"encoding/hex"
	"fmt"

	"github.com/herumi/bls-eth-go-binary/bls"
)

func sampleSignFastAggregateVerify() {
	msg := []byte("32BytesMessageForSigningGoodness")
	fmt.Println("Signing message of length", len(msg))

	numberOfParticipants := 512
	var privKeys []bls.SecretKey
	var pubKeys []bls.PublicKey
	var pubKeysHex []string
	var privKeysHex []string
	var signatures []bls.Sign
	for i := 0; i < numberOfParticipants; i++ {
		var privKey bls.SecretKey
		privKey.SetByCSPRNG()
		privKeys = append(privKeys, privKey)
		pubKeys = append(pubKeys, *privKey.GetPublicKey())
		signatures = append(signatures, *privKey.SignByte(msg))
		pubKeysHex = append(pubKeysHex, string(privKey.GetPublicKey().SerializeToHexStr()))
		privKeysHex = append(privKeysHex, string(privKey.GetDecString()))
	}

	fmt.Println("Signing with", numberOfParticipants, "participants")

	var aggregateSignature bls.Sign
	aggregateSignature.Aggregate(signatures)

	fmt.Println("Message:", hex.EncodeToString(msg))
	fmt.Println("Signature:", aggregateSignature.SerializeToHexStr())
	fmt.Println("Public Keys:", pubKeysHex)
	fmt.Println("Private Keys:", privKeysHex)

	result := aggregateSignature.FastAggregateVerify(pubKeys, msg)
	fmt.Println("Signature valid?", result)
}

func main() {
	bls.Init(bls.BLS12_381)
	bls.SetETHmode(bls.EthModeLatest)
	sampleSignFastAggregateVerify()
}
