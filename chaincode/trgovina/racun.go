package main

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

func (s *SmartContract) GetRacun(ctx contractapi.TransactionContextInterface, id string) (*Racun, error) {
	rJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return nil, fmt.Errorf("greska pri citanju racuna: %v", err)
	}
	if rJSON == nil {
		return nil, fmt.Errorf("racun sa ID %s ne postoji", id)
	}
	var racun Racun
	err = json.Unmarshal(rJSON, &racun)
	if err != nil {
		return nil, err
	}
	return &racun, nil
}

func (s *SmartContract) QueryRacuniByKorisnik(ctx contractapi.TransactionContextInterface, korisnikID string) ([]*Racun, error) {
	queryString := fmt.Sprintf(`{"selector":{"docType":"racun","korisnikId":"%s"}}`, korisnikID)
	return queryRacuni(ctx, queryString)
}

func (s *SmartContract) QueryRacuniByTrgovac(ctx contractapi.TransactionContextInterface, trgovacID string) ([]*Racun, error) {
	queryString := fmt.Sprintf(`{"selector":{"docType":"racun","trgovacId":"%s"}}`, trgovacID)
	return queryRacuni(ctx, queryString)
}
