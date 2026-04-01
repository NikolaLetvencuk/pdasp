package main

type TipTrgovca struct {
	DocType string `json:"docType"`
	ID      string `json:"id"`
	Naziv   string `json:"naziv"`
}

type Proizvod struct {
	DocType     string  `json:"docType"`
	ID          string  `json:"id"`
	Ime         string  `json:"ime"`
	RokTrajanja string  `json:"rokTrajanja"`
	Cena        float64 `json:"cena"`
	Kolicina    int     `json:"kolicina"`
	TrgovacID   string  `json:"trgovacId"`
}

type Trgovac struct {
	DocType    string   `json:"docType"`
	ID         string   `json:"id"`
	TipTrgovca string   `json:"tipTrgovca"`
	PIB        string   `json:"pib"`
	Proizvodi  []string `json:"proizvodi"`
	Racuni     []string `json:"racuni"`
	Stanje     float64  `json:"stanje"`
}

type Korisnik struct {
	DocType string   `json:"docType"`
	ID      string   `json:"id"`
	Ime     string   `json:"ime"`
	Prezime string   `json:"prezime"`
	Email   string   `json:"email"`
	Racuni  []string `json:"racuni"`
	Stanje  float64  `json:"stanje"`
}

type Racun struct {
	DocType    string  `json:"docType"`
	ID         string  `json:"id"`
	TrgovacID  string  `json:"trgovacId"`
	KorisnikID string  `json:"korisnikId"`
	ProizvodID string  `json:"proizvodId"`
	Datum      string  `json:"datum"`
	Iznos      float64 `json:"iznos"`
}
