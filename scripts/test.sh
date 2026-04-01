#!/bin/bash

# Test script for all chaincode functionalities
# This script uses peer CLI commands to test all functions

export PATH=${PWD}/bin:${PWD}/network/../bin:$PATH
export FABRIC_CFG_PATH=${PWD}/config

ORDERER_CA=${PWD}/network/organizations/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem
PEER0_ORG1_CA=${PWD}/network/organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem
PEER0_ORG2_CA=${PWD}/network/organizations/peerOrganizations/org2.example.com/tlsca/tlsca.org2.example.com-cert.pem
PEER0_ORG3_CA=${PWD}/network/organizations/peerOrganizations/org3.example.com/tlsca/tlsca.org3.example.com-cert.pem

CHANNEL_NAME="channel1"
CC_NAME="trgovina"

C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_BLUE='\033[0;34m'
C_YELLOW='\033[1;33m'

successln() { echo -e "${C_GREEN}[PASS] $1${C_RESET}"; }
errorln() { echo -e "${C_RED}[FAIL] $1${C_RESET}"; }
infoln() { echo -e "${C_BLUE}[TEST] $1${C_RESET}"; }
warnln() { echo -e "${C_YELLOW}[INFO] $1${C_RESET}"; }

PASS=0
FAIL=0

runTest() {
  local desc="$1"
  shift
  infoln "$desc"
  OUTPUT=$("$@" 2>&1)
  if [ $? -eq 0 ]; then
    successln "$desc"
    echo "$OUTPUT" | head -5
    PASS=$((PASS + 1))
  else
    errorln "$desc"
    echo "$OUTPUT" | tail -5
    FAIL=$((FAIL + 1))
  fi
  echo ""
}

setOrg1() {
  export CORE_PEER_TLS_ENABLED=true
  export CORE_PEER_LOCALMSPID="Org1MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
  export CORE_PEER_MSPCONFIGPATH=${PWD}/network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
  export CORE_PEER_ADDRESS=localhost:7051
}

setOrg2() {
  export CORE_PEER_TLS_ENABLED=true
  export CORE_PEER_LOCALMSPID="Org2MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
  export CORE_PEER_MSPCONFIGPATH=${PWD}/network/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
  export CORE_PEER_ADDRESS=localhost:9051
}

setOrg3() {
  export CORE_PEER_TLS_ENABLED=true
  export CORE_PEER_LOCALMSPID="Org3MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG3_CA
  export CORE_PEER_MSPCONFIGPATH=${PWD}/network/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
  export CORE_PEER_ADDRESS=localhost:11051
}

INVOKE_ARGS="--ordererTLSHostnameOverride orderer.example.com -o localhost:7050 --tls --cafile $ORDERER_CA --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_ORG1_CA --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_ORG2_CA --peerAddresses localhost:11051 --tlsRootCertFiles $PEER0_ORG3_CA"

echo "============================================"
echo " TESTIRANJE CHAINCODE FUNKCIONALNOSTI"
echo " Kanal: $CHANNEL_NAME"
echo "============================================"
echo ""

# ===================== QUERY TESTS - Initial State =====================
warnln "=== Testiranje pocetnog stanja (Query) ==="

setOrg1
infoln "Koristim sertifikat Org1"

runTest "Query - Svi trgovci" \
  peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"function":"GetAllTrgovci","Args":[]}'

runTest "Query - Svi korisnici" \
  peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"function":"GetAllKorisnici","Args":[]}'

runTest "Query - Svi proizvodi" \
  peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"function":"GetAllProizvodi","Args":[]}'

runTest "Query - Trgovac po ID (t1)" \
  peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"function":"GetTrgovac","Args":["t1"]}'

runTest "Query - Korisnik po ID (k1)" \
  peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"function":"GetKorisnik","Args":["k1"]}'

runTest "Query - Proizvod po ID (p1)" \
  peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"function":"GetProizvod","Args":["p1"]}'

# Switch to Org2 certificate
setOrg2
infoln "Koristim sertifikat Org2"

runTest "Query (Org2) - Svi trgovci" \
  peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"function":"GetAllTrgovci","Args":[]}'

# ===================== INVOKE TESTS =====================
warnln "=== Testiranje unosa (Invoke) ==="

setOrg1

UNIQUE_ID=$RANDOM

runTest "Invoke - Kreiranje novog trgovca (t_${UNIQUE_ID})" \
  peer chaincode invoke $INVOKE_ARGS -C $CHANNEL_NAME -n $CC_NAME \
    -c "{\"function\":\"CreateTrgovac\",\"Args\":[\"t_${UNIQUE_ID}\",\"Apoteka\",\"111222333\",\"10000\"]}"

sleep 2

runTest "Invoke - Dodavanje proizvoda trgovcu t_${UNIQUE_ID}" \
  peer chaincode invoke $INVOKE_ARGS -C $CHANNEL_NAME -n $CC_NAME \
    -c "{\"function\":\"AddProizvod\",\"Args\":[\"p_${UNIQUE_ID}a\",\"Aspirin\",\"2027-06-01\",\"350\",\"200\",\"t_${UNIQUE_ID}\"]}"

sleep 2

runTest "Invoke - Dodavanje jos jednog proizvoda trgovcu t_${UNIQUE_ID}" \
  peer chaincode invoke $INVOKE_ARGS -C $CHANNEL_NAME -n $CC_NAME \
    -c "{\"function\":\"AddProizvod\",\"Args\":[\"p_${UNIQUE_ID}b\",\"Vitamin C\",\"2027-12-01\",\"500\",\"150\",\"t_${UNIQUE_ID}\"]}"

sleep 2

runTest "Invoke - Kreiranje novog korisnika (k_${UNIQUE_ID})" \
  peer chaincode invoke $INVOKE_ARGS -C $CHANNEL_NAME -n $CC_NAME \
    -c "{\"function\":\"CreateKorisnik\",\"Args\":[\"k_${UNIQUE_ID}\",\"Ana\",\"Anic\",\"ana@email.com\",\"75000\"]}"

sleep 2

# ===================== PURCHASE TESTS =====================
warnln "=== Testiranje kupovine ==="

runTest "Invoke - Kupovina proizvoda (k1 kupuje p1 - Hleb)" \
  peer chaincode invoke $INVOKE_ARGS -C $CHANNEL_NAME -n $CC_NAME \
    -c '{"function":"KupiProizvod","Args":["k1","p1","2"]}'

sleep 2

runTest "Query - Provera stanja korisnika k1 posle kupovine" \
  peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"function":"GetKorisnik","Args":["k1"]}'

runTest "Query - Provera stanja trgovca t1 posle kupovine" \
  peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"function":"GetTrgovac","Args":["t1"]}'

runTest "Query - Provera kolicine proizvoda p1" \
  peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"function":"GetProizvod","Args":["p1"]}'

# ===================== DEPOSIT TEST =====================
warnln "=== Testiranje uplate ==="

runTest "Invoke - Uplata novca korisniku k2" \
  peer chaincode invoke $INVOKE_ARGS -C $CHANNEL_NAME -n $CC_NAME \
    -c '{"function":"UplatiNovac","Args":["k2","25000"]}'

sleep 2

runTest "Query - Provera stanja korisnika k2 posle uplate" \
  peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"function":"GetKorisnik","Args":["k2"]}'

runTest "Invoke - Uplata novca trgovcu t1" \
  peer chaincode invoke $INVOKE_ARGS -C $CHANNEL_NAME -n $CC_NAME \
    -c '{"function":"UplatiNovac","Args":["t1","5000"]}'

sleep 2

# ===================== RICH QUERY TESTS (CouchDB) =====================
warnln "=== Testiranje bogatih upita (CouchDB) ==="

runTest "CouchDB Query - Pretraga proizvoda po imenu (Hleb)" \
  peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"function":"QueryProizvodiByIme","Args":["Hleb"]}'

runTest "CouchDB Query - Pretraga proizvoda po tipu trgovca (Elektronika)" \
  peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"function":"QueryProizvodiByTipTrgovca","Args":["Elektronika"]}'

runTest "CouchDB Query - Pretraga proizvoda po rasponu cene (100-5000)" \
  peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"function":"QueryProizvodiCenaRange","Args":["100","5000"]}'

runTest "CouchDB Query - Napredna pretraga (kombinovana)" \
  peer chaincode query -C $CHANNEL_NAME -n $CC_NAME \
    -c '{"function":"QueryProizvodiAdvanced","Args":["{\"minCena\":100,\"maxCena\":5000}"]}'

runTest "CouchDB Query - Proizvodi sortirani po ceni (rastuci)" \
  peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"function":"QueryProizvodiSortByCena","Args":["true"]}'

runTest "CouchDB Query - Racuni korisnika k1" \
  peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"function":"QueryRacuniByKorisnik","Args":["k1"]}'

runTest "CouchDB Query - Racuni trgovca t1" \
  peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"function":"QueryRacuniByTrgovac","Args":["t1"]}'

# ===================== ERROR HANDLING TESTS =====================
warnln "=== Testiranje obrade gresaka ==="

infoln "Test - Kreiranje trgovca sa postojecim ID (ocekuje se greska)"
peer chaincode invoke $INVOKE_ARGS -C $CHANNEL_NAME -n $CC_NAME \
  -c '{"function":"CreateTrgovac","Args":["t1","Test","999","1000"]}' 2>&1
echo ""

infoln "Test - Kupovina sa nedovoljno sredstava (ocekuje se greska)"
peer chaincode invoke $INVOKE_ARGS -C $CHANNEL_NAME -n $CC_NAME \
  -c '{"function":"KupiProizvod","Args":["k2","p3","5"]}' 2>&1
echo ""

infoln "Test - Kupovina nepostojeceg proizvoda (ocekuje se greska)"
peer chaincode invoke $INVOKE_ARGS -C $CHANNEL_NAME -n $CC_NAME \
  -c '{"function":"KupiProizvod","Args":["k1","p999","1"]}' 2>&1
echo ""

infoln "Test - Uplata nepostojecem entitetu (ocekuje se greska)"
peer chaincode invoke $INVOKE_ARGS -C $CHANNEL_NAME -n $CC_NAME \
  -c '{"function":"UplatiNovac","Args":["nepostoji","1000"]}' 2>&1
echo ""

# ===================== HISTORY TEST =====================
warnln "=== Testiranje istorije ==="

runTest "Query - Istorija promena za korisnika k1" \
  peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"function":"GetHistoryForKey","Args":["k1"]}'

# ===================== CROSS-ORG TEST =====================
warnln "=== Testiranje sa razlicitim sertifikatima ==="

setOrg2
infoln "Prebacivanje na Org2 sertifikat"

runTest "Org2 - Invoke kupovina (k3 kupuje p4)" \
  peer chaincode invoke $INVOKE_ARGS -C $CHANNEL_NAME -n $CC_NAME \
    -c '{"function":"KupiProizvod","Args":["k3","p4","1"]}'

sleep 2

runTest "Org2 - Query provera stanja k3" \
  peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"function":"GetKorisnik","Args":["k3"]}'

setOrg3
infoln "Prebacivanje na Org3 sertifikat"

runTest "Org3 - Query svi proizvodi" \
  peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"function":"GetAllProizvodi","Args":[]}'

# ===================== CHANNEL2 TEST =====================
warnln "=== Testiranje na kanalu channel2 ==="
CHANNEL_NAME="channel2"

setOrg1
infoln "Koristim sertifikat Org1 na kanalu channel2"

INVOKE_ARGS_CH2="--ordererTLSHostnameOverride orderer.example.com -o localhost:7050 --tls --cafile $ORDERER_CA --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_ORG1_CA --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_ORG2_CA --peerAddresses localhost:11051 --tlsRootCertFiles $PEER0_ORG3_CA"

runTest "Channel2 - Query svi trgovci" \
  peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"function":"GetAllTrgovci","Args":[]}'

runTest "Channel2 - Query svi proizvodi" \
  peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"function":"GetAllProizvodi","Args":[]}'

# ===================== SUMMARY =====================
echo ""
echo "============================================"
echo " REZULTATI TESTIRANJA"
echo "============================================"
echo -e " ${C_GREEN}Uspesno: $PASS${C_RESET}"
echo -e " ${C_RED}Neuspesno: $FAIL${C_RESET}"
echo " Ukupno: $((PASS + FAIL))"
echo "============================================"
