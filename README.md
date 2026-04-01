# Sistem za trgovanje - Hyperledger Fabric

Projektni zadatak iz predmeta PDASP 2025/26.

## Opis

Konzolna aplikacija za trgovanje proizvoljnim dobrima na Hyperledger Fabric blockchain mrezi. Sistem omogucava upravljanje trgovcima, proizvodima, korisnicima i racunima sa podrskom za kupovinu, uplatu novca i napredne pretrage koriscenjem CouchDB bogatih upita.

## Arhitektura mreze

- **3 organizacije** (Org1, Org2, Org3) sa po **3 peer-a** (9 ukupno)
- **3 orderer-a** sa RAFT konsenzusom
- **2 kanala** (channel1, channel2) - svi peer-ovi na oba kanala
- **9 CouchDB** instanci (jedna po peer-u)
- **Fabric verzija 2.5.6**
- Chaincode u **Go** jeziku
- SDK aplikacija u **Node.js** (@hyperledger/fabric-gateway)

## Preduslovi

- Docker Desktop (pokrenut)
- Node.js (v18+)
- Go (v1.21+)
- Git Bash (za pokretanje skripti na Windows-u)

## Pokretanje

### 1. Preuzeti Fabric binarne alate i Docker slike

```bash
curl -sSLO https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh
chmod +x install-fabric.sh
bash install-fabric.sh --fabric-version 2.5.6 --ca-version 1.5.9 binary docker
```

### 2. Instalirati Node.js zavisnosti

```bash
cd application
npm install
```

### 3. Pokrenuti mrezu

```bash
cd network
bash network.sh up
```

### 4. Pokrenuti konzolnu aplikaciju

```bash
cd application
node app.js
```

### 5. Pokrenuti testove

```bash
bash scripts/test.sh
```

### 6. Zaustaviti mrezu

```bash
cd network
bash network.sh down
```

## Struktura projekta

```
├── network/                    # Fabric mreza
│   ├── configtx/configtx.yaml # Konfiguracija kanala i organizacija
│   ├── docker/                 # Docker Compose fajlovi
│   ├── organizations/cryptogen # Kripto konfiguracija
│   ├── scripts/envVar.sh       # Environment varijable
│   └── network.sh              # Glavna skripta za upravljanje
├── chaincode/trgovina/         # Go chaincode
│   ├── chaincode.go            # Poslovna logika
│   ├── Dockerfile              # Za ccaas build
│   └── META-INF/               # CouchDB indeksi
├── application/                # Node.js SDK aplikacija
│   ├── app.js                  # Konzolna aplikacija
│   └── package.json
├── scripts/test.sh             # Test skripta (31 test)
```

