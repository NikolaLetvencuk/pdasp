package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

func (s *SmartContract) KupiProizvod(ctx contractapi.TransactionContextInterface, korisnikID string, proizvodID string, kolicina int) error {
	korisnikJSON, err := ctx.GetStub().GetState(korisnikID)
	if err != nil {
		return fmt.Errorf("greska pri citanju korisnika: %v", err)
	}
	if korisnikJSON == nil {
		return fmt.Errorf("korisnik sa ID %s ne postoji", korisnikID)
	}
	var korisnik Korisnik
	err = json.Unmarshal(korisnikJSON, &korisnik)
	if err != nil {
		return err
	}

	proizvodJSON, err := ctx.GetStub().GetState(proizvodID)
	if err != nil {
		return fmt.Errorf("greska pri citanju proizvoda: %v", err)
	}
	if proizvodJSON == nil {
		return fmt.Errorf("proizvod sa ID %s ne postoji", proizvodID)
	}
	var proizvod Proizvod
	err = json.Unmarshal(proizvodJSON, &proizvod)
	if err != nil {
		return err
	}

	if proizvod.Kolicina < kolicina {
		return fmt.Errorf("nedovoljna kolicina proizvoda. Dostupno: %d, Trazeno: %d", proizvod.Kolicina, kolicina)
	}

	ukupnaCena := proizvod.Cena * float64(kolicina)

	if korisnik.Stanje < ukupnaCena {
		return fmt.Errorf("nedovoljno sredstava. Stanje: %.2f, Potrebno: %.2f", korisnik.Stanje, ukupnaCena)
	}

	trgovacJSON, err := ctx.GetStub().GetState(proizvod.TrgovacID)
	if err != nil {
		return fmt.Errorf("greska pri citanju trgovca: %v", err)
	}
	if trgovacJSON == nil {
		return fmt.Errorf("trgovac sa ID %s ne postoji", proizvod.TrgovacID)
	}
	var trgovac Trgovac
	err = json.Unmarshal(trgovacJSON, &trgovac)
	if err != nil {
		return err
	}

	txID := ctx.GetStub().GetTxID()
	racunID := fmt.Sprintf("r_%s_%s_%s", korisnikID, proizvodID, txID[:8])
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	datum := time.Now().Format("2006-01-02 15:04:05")
	if err == nil && txTimestamp != nil {
		datum = time.Unix(txTimestamp.Seconds, 0).Format("2006-01-02 15:04:05")
	}
	racun := Racun{
		DocType:    "racun",
		ID:         racunID,
		TrgovacID:  proizvod.TrgovacID,
		KorisnikID: korisnikID,
		ProizvodID: proizvodID,
		Datum:      datum,
		Iznos:      ukupnaCena,
	}
	racunJSON, err := json.Marshal(racun)
	if err != nil {
		return err
	}
	err = ctx.GetStub().PutState(racunID, racunJSON)
	if err != nil {
		return err
	}

	korisnik.Stanje -= ukupnaCena
	korisnik.Racuni = append(korisnik.Racuni, racunID)
	korisnikUpdated, err := json.Marshal(korisnik)
	if err != nil {
		return err
	}
	err = ctx.GetStub().PutState(korisnikID, korisnikUpdated)
	if err != nil {
		return err
	}

	trgovac.Stanje += ukupnaCena
	trgovac.Racuni = append(trgovac.Racuni, racunID)
	trgovacUpdated, err := json.Marshal(trgovac)
	if err != nil {
		return err
	}
	err = ctx.GetStub().PutState(proizvod.TrgovacID, trgovacUpdated)
	if err != nil {
		return err
	}

	proizvod.Kolicina -= kolicina
	if proizvod.Kolicina == 0 {
		newProizvodi := []string{}
		for _, pid := range trgovac.Proizvodi {
			if pid != proizvodID {
				newProizvodi = append(newProizvodi, pid)
			}
		}
		trgovac.Proizvodi = newProizvodi
		trgovacUpdated2, err := json.Marshal(trgovac)
		if err != nil {
			return err
		}
		err = ctx.GetStub().PutState(proizvod.TrgovacID, trgovacUpdated2)
		if err != nil {
			return err
		}
		err = ctx.GetStub().DelState(proizvodID)
		if err != nil {
			return err
		}
	} else {
		proizvodUpdated, err := json.Marshal(proizvod)
		if err != nil {
			return err
		}
		err = ctx.GetStub().PutState(proizvodID, proizvodUpdated)
		if err != nil {
			return err
		}
	}

	return nil
}

func (s *SmartContract) UplatiNovac(ctx contractapi.TransactionContextInterface, id string, iznos float64) error {
	if iznos <= 0 {
		return fmt.Errorf("iznos mora biti pozitivan broj")
	}

	stateJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return fmt.Errorf("greska pri citanju stanja: %v", err)
	}
	if stateJSON == nil {
		return fmt.Errorf("entitet sa ID %s ne postoji", id)
	}

	var raw map[string]interface{}
	err = json.Unmarshal(stateJSON, &raw)
	if err != nil {
		return err
	}

	docType, ok := raw["docType"].(string)
	if !ok {
		return fmt.Errorf("neispravan tip dokumenta")
	}

	switch docType {
	case "korisnik":
		var korisnik Korisnik
		err = json.Unmarshal(stateJSON, &korisnik)
		if err != nil {
			return err
		}
		korisnik.Stanje += iznos
		updated, err := json.Marshal(korisnik)
		if err != nil {
			return err
		}
		return ctx.GetStub().PutState(id, updated)
	case "trgovac":
		var trgovac Trgovac
		err = json.Unmarshal(stateJSON, &trgovac)
		if err != nil {
			return err
		}
		trgovac.Stanje += iznos
		updated, err := json.Marshal(trgovac)
		if err != nil {
			return err
		}
		return ctx.GetStub().PutState(id, updated)
	default:
		return fmt.Errorf("uplata je moguca samo za korisnika ili trgovca, dobijen tip: %s", docType)
	}
}

func (s *SmartContract) GetHistoryForKey(ctx contractapi.TransactionContextInterface, key string) (string, error) {
	historyIterator, err := ctx.GetStub().GetHistoryForKey(key)
	if err != nil {
		return "", fmt.Errorf("greska pri citanju istorije: %v", err)
	}
	defer historyIterator.Close()

	var history []map[string]interface{}
	for historyIterator.HasNext() {
		modification, err := historyIterator.Next()
		if err != nil {
			return "", err
		}
		entry := map[string]interface{}{
			"txId":      modification.TxId,
			"timestamp": time.Unix(modification.Timestamp.Seconds, int64(modification.Timestamp.Nanos)).Format("2006-01-02 15:04:05"),
			"isDelete":  modification.IsDelete,
		}
		if !modification.IsDelete {
			var value interface{}
			json.Unmarshal(modification.Value, &value)
			entry["value"] = value
		}
		history = append(history, entry)
	}

	historyJSON, err := json.Marshal(history)
	if err != nil {
		return "", err
	}
	return string(historyJSON), nil
}
