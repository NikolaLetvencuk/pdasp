package main

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

func (s *SmartContract) AddProizvod(ctx contractapi.TransactionContextInterface, proizvodID string, ime string, rokTrajanja string, cena float64, kolicina int, trgovacID string) error {
	trgovacJSON, err := ctx.GetStub().GetState(trgovacID)
	if err != nil {
		return fmt.Errorf("greska pri citanju trgovca: %v", err)
	}
	if trgovacJSON == nil {
		return fmt.Errorf("trgovac sa ID %s ne postoji", trgovacID)
	}

	existing, err := ctx.GetStub().GetState(proizvodID)
	if err != nil {
		return fmt.Errorf("greska pri citanju proizvoda: %v", err)
	}
	if existing != nil {
		return fmt.Errorf("proizvod sa ID %s vec postoji", proizvodID)
	}

	proizvod := Proizvod{
		DocType:     "proizvod",
		ID:          proizvodID,
		Ime:         ime,
		RokTrajanja: rokTrajanja,
		Cena:        cena,
		Kolicina:    kolicina,
		TrgovacID:   trgovacID,
	}
	pJSON, err := json.Marshal(proizvod)
	if err != nil {
		return err
	}
	err = ctx.GetStub().PutState(proizvodID, pJSON)
	if err != nil {
		return err
	}

	var trgovac Trgovac
	err = json.Unmarshal(trgovacJSON, &trgovac)
	if err != nil {
		return err
	}
	trgovac.Proizvodi = append(trgovac.Proizvodi, proizvodID)
	updatedJSON, err := json.Marshal(trgovac)
	if err != nil {
		return err
	}
	return ctx.GetStub().PutState(trgovacID, updatedJSON)
}

func (s *SmartContract) GetProizvod(ctx contractapi.TransactionContextInterface, id string) (*Proizvod, error) {
	pJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return nil, fmt.Errorf("greska pri citanju proizvoda: %v", err)
	}
	if pJSON == nil {
		return nil, fmt.Errorf("proizvod sa ID %s ne postoji", id)
	}
	var proizvod Proizvod
	err = json.Unmarshal(pJSON, &proizvod)
	if err != nil {
		return nil, err
	}
	return &proizvod, nil
}

func (s *SmartContract) GetAllProizvodi(ctx contractapi.TransactionContextInterface) ([]*Proizvod, error) {
	queryString := `{"selector":{"docType":"proizvod"}}`
	return queryProizvodi(ctx, queryString)
}

func (s *SmartContract) QueryProizvodiByIme(ctx contractapi.TransactionContextInterface, ime string) ([]*Proizvod, error) {
	queryString := fmt.Sprintf(`{"selector":{"docType":"proizvod","ime":{"$regex":"(?i)%s"}}}`, ime)
	return queryProizvodi(ctx, queryString)
}

func (s *SmartContract) QueryProizvodiByTipTrgovca(ctx contractapi.TransactionContextInterface, tipTrgovca string) ([]*Proizvod, error) {
	merchantQuery := fmt.Sprintf(`{"selector":{"docType":"trgovac","tipTrgovca":"%s"}}`, tipTrgovca)
	trgovci, err := queryTrgovci(ctx, merchantQuery)
	if err != nil {
		return nil, err
	}

	var sviProizvodi []*Proizvod
	for _, t := range trgovci {
		for _, pid := range t.Proizvodi {
			p, err := s.GetProizvod(ctx, pid)
			if err == nil {
				sviProizvodi = append(sviProizvodi, p)
			}
		}
	}
	return sviProizvodi, nil
}

func (s *SmartContract) QueryProizvodiByMaxCena(ctx contractapi.TransactionContextInterface, maxCena float64) ([]*Proizvod, error) {
	queryString := fmt.Sprintf(`{"selector":{"docType":"proizvod","cena":{"$lte":%f}}}`, maxCena)
	return queryProizvodi(ctx, queryString)
}

func (s *SmartContract) QueryProizvodiByMinCena(ctx contractapi.TransactionContextInterface, minCena float64) ([]*Proizvod, error) {
	queryString := fmt.Sprintf(`{"selector":{"docType":"proizvod","cena":{"$gte":%f}}}`, minCena)
	return queryProizvodi(ctx, queryString)
}

func (s *SmartContract) QueryProizvodiCenaRange(ctx contractapi.TransactionContextInterface, minCena float64, maxCena float64) ([]*Proizvod, error) {
	queryString := fmt.Sprintf(`{"selector":{"docType":"proizvod","cena":{"$gte":%f,"$lte":%f}}}`, minCena, maxCena)
	return queryProizvodi(ctx, queryString)
}

func (s *SmartContract) QueryProizvodiAdvanced(ctx contractapi.TransactionContextInterface, queryJSON string) ([]*Proizvod, error) {
	var params map[string]interface{}
	err := json.Unmarshal([]byte(queryJSON), &params)
	if err != nil {
		return nil, fmt.Errorf("neispravan JSON upit: %v", err)
	}

	selector := map[string]interface{}{
		"docType": "proizvod",
	}

	if ime, ok := params["ime"].(string); ok && ime != "" {
		selector["ime"] = map[string]interface{}{"$regex": "(?i)" + ime}
	}
	if minCena, ok := params["minCena"].(float64); ok {
		if cenaMap, exists := selector["cena"]; exists {
			cenaMap.(map[string]interface{})["$gte"] = minCena
		} else {
			selector["cena"] = map[string]interface{}{"$gte": minCena}
		}
	}
	if maxCena, ok := params["maxCena"].(float64); ok {
		if cenaMap, exists := selector["cena"]; exists {
			cenaMap.(map[string]interface{})["$lte"] = maxCena
		} else {
			selector["cena"] = map[string]interface{}{"$lte": maxCena}
		}
	}

	query := map[string]interface{}{
		"selector": selector,
	}
	queryBytes, err := json.Marshal(query)
	if err != nil {
		return nil, err
	}

	results, err := queryProizvodi(ctx, string(queryBytes))
	if err != nil {
		return nil, err
	}

	if tipTrgovca, ok := params["tipTrgovca"].(string); ok && tipTrgovca != "" {
		merchantQuery := fmt.Sprintf(`{"selector":{"docType":"trgovac","tipTrgovca":{"$regex":"(?i)%s"}}}`, tipTrgovca)
		trgovci, err := queryTrgovci(ctx, merchantQuery)
		if err != nil {
			return nil, err
		}
		merchantIDs := make(map[string]bool)
		for _, t := range trgovci {
			merchantIDs[t.ID] = true
		}
		var filtered []*Proizvod
		for _, p := range results {
			if merchantIDs[p.TrgovacID] {
				filtered = append(filtered, p)
			}
		}
		return filtered, nil
	}

	return results, nil
}

func (s *SmartContract) QueryProizvodiSortByCena(ctx contractapi.TransactionContextInterface, ascending bool) ([]*Proizvod, error) {
	queryString := `{"selector":{"docType":"proizvod","cena":{"$gt":0}}}`
	return queryProizvodi(ctx, queryString)
}

func (s *SmartContract) QueryProizvodiWithPagination(ctx contractapi.TransactionContextInterface, pageSize int32, bookmark string) (string, error) {
	queryString := `{"selector":{"docType":"proizvod"}}`
	resultsIterator, responseMetadata, err := ctx.GetStub().GetQueryResultWithPagination(queryString, pageSize, bookmark)
	if err != nil {
		return "", err
	}
	defer resultsIterator.Close()

	var proizvodi []*Proizvod
	for resultsIterator.HasNext() {
		queryResult, err := resultsIterator.Next()
		if err != nil {
			return "", err
		}
		var proizvod Proizvod
		err = json.Unmarshal(queryResult.Value, &proizvod)
		if err != nil {
			return "", err
		}
		proizvodi = append(proizvodi, &proizvod)
	}

	result := map[string]interface{}{
		"proizvodi":   proizvodi,
		"recordCount": responseMetadata.FetchedRecordsCount,
		"bookmark":    responseMetadata.Bookmark,
	}
	resultJSON, err := json.Marshal(result)
	if err != nil {
		return "", err
	}
	return string(resultJSON), nil
}
