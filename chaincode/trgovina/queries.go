package main

import (
	"encoding/json"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

func queryProizvodi(ctx contractapi.TransactionContextInterface, queryString string) ([]*Proizvod, error) {
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var proizvodi []*Proizvod
	for resultsIterator.HasNext() {
		queryResult, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}
		var proizvod Proizvod
		err = json.Unmarshal(queryResult.Value, &proizvod)
		if err != nil {
			return nil, err
		}
		proizvodi = append(proizvodi, &proizvod)
	}
	return proizvodi, nil
}

func queryTrgovci(ctx contractapi.TransactionContextInterface, queryString string) ([]*Trgovac, error) {
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var trgovci []*Trgovac
	for resultsIterator.HasNext() {
		queryResult, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}
		var trgovac Trgovac
		err = json.Unmarshal(queryResult.Value, &trgovac)
		if err != nil {
			return nil, err
		}
		trgovci = append(trgovci, &trgovac)
	}
	return trgovci, nil
}

func queryKorisnici(ctx contractapi.TransactionContextInterface, queryString string) ([]*Korisnik, error) {
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var korisnici []*Korisnik
	for resultsIterator.HasNext() {
		queryResult, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}
		var korisnik Korisnik
		err = json.Unmarshal(queryResult.Value, &korisnik)
		if err != nil {
			return nil, err
		}
		korisnici = append(korisnici, &korisnik)
	}
	return korisnici, nil
}

func queryRacuni(ctx contractapi.TransactionContextInterface, queryString string) ([]*Racun, error) {
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var racuni []*Racun
	for resultsIterator.HasNext() {
		queryResult, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}
		var racun Racun
		err = json.Unmarshal(queryResult.Value, &racun)
		if err != nil {
			return nil, err
		}
		racuni = append(racuni, &racun)
	}
	return racuni, nil
}
