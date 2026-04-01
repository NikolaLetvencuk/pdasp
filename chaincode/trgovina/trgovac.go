package main

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

func (s *SmartContract) CreateTrgovac(ctx contractapi.TransactionContextInterface, id string, tipTrgovca string, pib string, stanje float64) error {
	exists, err := ctx.GetStub().GetState(id)
	if err != nil {
		return fmt.Errorf("greska pri citanju stanja: %v", err)
	}
	if exists != nil {
		return fmt.Errorf("trgovac sa ID %s vec postoji", id)
	}

	trgovac := Trgovac{
		DocType:    "trgovac",
		ID:         id,
		TipTrgovca: tipTrgovca,
		PIB:        pib,
		Proizvodi:  []string{},
		Racuni:     []string{},
		Stanje:     stanje,
	}
	tJSON, err := json.Marshal(trgovac)
	if err != nil {
		return err
	}
	return ctx.GetStub().PutState(id, tJSON)
}

func (s *SmartContract) GetTrgovac(ctx contractapi.TransactionContextInterface, id string) (*Trgovac, error) {
	tJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return nil, fmt.Errorf("greska pri citanju trgovca: %v", err)
	}
	if tJSON == nil {
		return nil, fmt.Errorf("trgovac sa ID %s ne postoji", id)
	}
	var trgovac Trgovac
	err = json.Unmarshal(tJSON, &trgovac)
	if err != nil {
		return nil, err
	}
	return &trgovac, nil
}

func (s *SmartContract) GetAllTrgovci(ctx contractapi.TransactionContextInterface) ([]*Trgovac, error) {
	queryString := `{"selector":{"docType":"trgovac"}}`
	return queryTrgovci(ctx, queryString)
}
