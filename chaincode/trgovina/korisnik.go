package main

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

func (s *SmartContract) CreateKorisnik(ctx contractapi.TransactionContextInterface, id string, ime string, prezime string, email string, stanje float64) error {
	exists, err := ctx.GetStub().GetState(id)
	if err != nil {
		return fmt.Errorf("greska pri citanju stanja: %v", err)
	}
	if exists != nil {
		return fmt.Errorf("korisnik sa ID %s vec postoji", id)
	}

	korisnik := Korisnik{
		DocType: "korisnik",
		ID:      id,
		Ime:     ime,
		Prezime: prezime,
		Email:   email,
		Racuni:  []string{},
		Stanje:  stanje,
	}
	kJSON, err := json.Marshal(korisnik)
	if err != nil {
		return err
	}
	return ctx.GetStub().PutState(id, kJSON)
}

func (s *SmartContract) GetKorisnik(ctx contractapi.TransactionContextInterface, id string) (*Korisnik, error) {
	kJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return nil, fmt.Errorf("greska pri citanju korisnika: %v", err)
	}
	if kJSON == nil {
		return nil, fmt.Errorf("korisnik sa ID %s ne postoji", id)
	}
	var korisnik Korisnik
	err = json.Unmarshal(kJSON, &korisnik)
	if err != nil {
		return nil, err
	}
	return &korisnik, nil
}

func (s *SmartContract) GetAllKorisnici(ctx contractapi.TransactionContextInterface) ([]*Korisnik, error) {
	queryString := `{"selector":{"docType":"korisnik"}}`
	return queryKorisnici(ctx, queryString)
}
