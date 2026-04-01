package main

import (
	"log"
	"os"

	"github.com/hyperledger/fabric-chaincode-go/shim"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SmartContract struct {
	contractapi.Contract
}

func main() {
	chaincode, err := contractapi.NewChaincode(&SmartContract{})
	if err != nil {
		log.Panicf("Greska pri kreiranju chaincode-a: %v", err)
	}

	ccAddr := os.Getenv("CHAINCODE_SERVER_ADDRESS")
	ccID := os.Getenv("CHAINCODE_ID")
	if ccAddr != "" {
		server := &shim.ChaincodeServer{
			CCID:    ccID,
			Address: ccAddr,
			CC:      chaincode,
			TLSProps: shim.TLSProperties{
				Disabled: true,
			},
		}
		log.Printf("Starting chaincode as service at %s with CCID %s", ccAddr, ccID)
		if err := server.Start(); err != nil {
			log.Panicf("Greska pri pokretanju chaincode servera: %v", err)
		}
	} else {
		if err := chaincode.Start(); err != nil {
			log.Panicf("Greska pri pokretanju chaincode-a: %v", err)
		}
	}
}
