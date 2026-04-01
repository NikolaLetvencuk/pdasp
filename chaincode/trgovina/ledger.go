package main

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	tipovi := []TipTrgovca{
		{DocType: "tipTrgovca", ID: "tip1", Naziv: "Supermarket"},
		{DocType: "tipTrgovca", ID: "tip2", Naziv: "Elektronika"},
		{DocType: "tipTrgovca", ID: "tip3", Naziv: "Auto delovi"},
	}
	for _, tip := range tipovi {
		tipJSON, err := json.Marshal(tip)
		if err != nil {
			return err
		}
		err = ctx.GetStub().PutState(tip.ID, tipJSON)
		if err != nil {
			return fmt.Errorf("greska pri upisu tipa trgovca: %v", err)
		}
	}

	proizvodi := []Proizvod{
		{DocType: "proizvod", ID: "p1", Ime: "Hleb", RokTrajanja: "2026-04-01", Cena: 80, Kolicina: 100, TrgovacID: "t1"},
		{DocType: "proizvod", ID: "p2", Ime: "Mleko", RokTrajanja: "2026-04-15", Cena: 120, Kolicina: 50, TrgovacID: "t1"},
		{DocType: "proizvod", ID: "p3", Ime: "Laptop", RokTrajanja: "", Cena: 85000, Kolicina: 10, TrgovacID: "t2"},
		{DocType: "proizvod", ID: "p4", Ime: "Mis", RokTrajanja: "", Cena: 3500, Kolicina: 30, TrgovacID: "t2"},
		{DocType: "proizvod", ID: "p5", Ime: "Ulje za motor", RokTrajanja: "2027-01-01", Cena: 1500, Kolicina: 25, TrgovacID: "t3"},
		{DocType: "proizvod", ID: "p6", Ime: "Kocioni diskovi", RokTrajanja: "", Cena: 4500, Kolicina: 15, TrgovacID: "t3"},
	}
	for _, p := range proizvodi {
		pJSON, err := json.Marshal(p)
		if err != nil {
			return err
		}
		err = ctx.GetStub().PutState(p.ID, pJSON)
		if err != nil {
			return fmt.Errorf("greska pri upisu proizvoda: %v", err)
		}
	}

	trgovci := []Trgovac{
		{DocType: "trgovac", ID: "t1", TipTrgovca: "Supermarket", PIB: "123456789", Proizvodi: []string{"p1", "p2"}, Racuni: []string{}, Stanje: 50000},
		{DocType: "trgovac", ID: "t2", TipTrgovca: "Elektronika", PIB: "987654321", Proizvodi: []string{"p3", "p4"}, Racuni: []string{}, Stanje: 200000},
		{DocType: "trgovac", ID: "t3", TipTrgovca: "Auto delovi", PIB: "555666777", Proizvodi: []string{"p5", "p6"}, Racuni: []string{}, Stanje: 30000},
	}
	for _, t := range trgovci {
		tJSON, err := json.Marshal(t)
		if err != nil {
			return err
		}
		err = ctx.GetStub().PutState(t.ID, tJSON)
		if err != nil {
			return fmt.Errorf("greska pri upisu trgovca: %v", err)
		}
	}

	korisnici := []Korisnik{
		{DocType: "korisnik", ID: "k1", Ime: "Marko", Prezime: "Markovic", Email: "marko@email.com", Racuni: []string{}, Stanje: 100000},
		{DocType: "korisnik", ID: "k2", Ime: "Jovana", Prezime: "Jovanovic", Email: "jovana@email.com", Racuni: []string{}, Stanje: 50000},
		{DocType: "korisnik", ID: "k3", Ime: "Nikola", Prezime: "Nikolic", Email: "nikola@email.com", Racuni: []string{}, Stanje: 200000},
	}
	for _, k := range korisnici {
		kJSON, err := json.Marshal(k)
		if err != nil {
			return err
		}
		err = ctx.GetStub().PutState(k.ID, kJSON)
		if err != nil {
			return fmt.Errorf("greska pri upisu korisnika: %v", err)
		}
	}

	return nil
}
