#!/bin/bash

# Main network management script
# Usage: ./network.sh up|down|createChannel|deployCC

export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=${PWD}/../config
export VERBOSE=false

. scripts/envVar.sh

CHANNEL_NAME1="channel1"
CHANNEL_NAME2="channel2"
CC_NAME="trgovina"
CC_SRC_PATH="../chaincode/trgovina"
CC_VERSION="1.0"
CC_SEQUENCE=1

C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_BLUE='\033[0;34m'
C_YELLOW='\033[1;33m'

println() {
  echo -e "$1"
}

successln() {
  println "${C_GREEN}$1${C_RESET}"
}

infoln() {
  println "${C_BLUE}$1${C_RESET}"
}

warnln() {
  println "${C_YELLOW}$1${C_RESET}"
}

errorln() {
  println "${C_RED}$1${C_RESET}"
}

fatalln() {
  errorln "$1"
  exit 1
}

# Generate crypto materials using cryptogen
function generateCryptoMaterial() {
  infoln "Generating crypto material using cryptogen..."

  which cryptogen
  if [ "$?" -ne 0 ]; then
    fatalln "cryptogen tool not found. Exiting"
  fi

  mkdir -p organizations

  infoln "Generating crypto material for Orderer org..."
  cryptogen generate --config=./organizations/cryptogen/crypto-config-orderer.yaml --output="organizations"
  if [ $? -ne 0 ]; then
    fatalln "Failed to generate crypto material for orderer"
  fi

  infoln "Generating crypto material for Org1..."
  cryptogen generate --config=./organizations/cryptogen/crypto-config-org1.yaml --output="organizations"
  if [ $? -ne 0 ]; then
    fatalln "Failed to generate crypto material for Org1"
  fi

  infoln "Generating crypto material for Org2..."
  cryptogen generate --config=./organizations/cryptogen/crypto-config-org2.yaml --output="organizations"
  if [ $? -ne 0 ]; then
    fatalln "Failed to generate crypto material for Org2"
  fi

  infoln "Generating crypto material for Org3..."
  cryptogen generate --config=./organizations/cryptogen/crypto-config-org3.yaml --output="organizations"
  if [ $? -ne 0 ]; then
    fatalln "Failed to generate crypto material for Org3"
  fi

  successln "Crypto material generated successfully"
}

# Create channel genesis block
function createChannelGenesisBlock() {
  local CHANNEL_NAME=$1
  infoln "Generating channel genesis block for ${CHANNEL_NAME}..."

  which configtxgen
  if [ "$?" -ne 0 ]; then
    fatalln "configtxgen tool not found. Exiting"
  fi

  mkdir -p channel-artifacts

  FABRIC_CFG_PATH=${PWD}/configtx configtxgen -profile ThreeOrgsChannel -outputBlock ./channel-artifacts/${CHANNEL_NAME}.block -channelID ${CHANNEL_NAME}
  if [ $? -ne 0 ]; then
    fatalln "Failed to generate channel genesis block for ${CHANNEL_NAME}"
  fi

  successln "Channel genesis block for ${CHANNEL_NAME} generated successfully"
}

# Create and join channel
function createChannel() {
  local CHANNEL_NAME=$1

  infoln "Creating channel ${CHANNEL_NAME}..."

  # Create channel using osnadmin
  local ORDERER_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt
  local ORDERER_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key

  osnadmin channel join --channelID ${CHANNEL_NAME} --config-block ./channel-artifacts/${CHANNEL_NAME}.block \
    -o localhost:7053 \
    --ca-file "$ORDERER_CA" \
    --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" \
    --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"

  if [ $? -ne 0 ]; then
    fatalln "Failed to create channel ${CHANNEL_NAME} on orderer1"
  fi

  # Join orderer2
  local ORDERER2_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer2.example.com/tls/server.crt
  local ORDERER2_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer2.example.com/tls/server.key

  osnadmin channel join --channelID ${CHANNEL_NAME} --config-block ./channel-artifacts/${CHANNEL_NAME}.block \
    -o localhost:7055 \
    --ca-file "$ORDERER_CA" \
    --client-cert "$ORDERER2_ADMIN_TLS_SIGN_CERT" \
    --client-key "$ORDERER2_ADMIN_TLS_PRIVATE_KEY"

  # Join orderer3
  local ORDERER3_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer3.example.com/tls/server.crt
  local ORDERER3_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer3.example.com/tls/server.key

  osnadmin channel join --channelID ${CHANNEL_NAME} --config-block ./channel-artifacts/${CHANNEL_NAME}.block \
    -o localhost:7057 \
    --ca-file "$ORDERER_CA" \
    --client-cert "$ORDERER3_ADMIN_TLS_SIGN_CERT" \
    --client-key "$ORDERER3_ADMIN_TLS_PRIVATE_KEY"

  successln "Channel ${CHANNEL_NAME} created on all orderers"

  # Join all peers to the channel
  for ORG in 1 2 3; do
    for PEER in 0 1 2; do
      infoln "Joining peer${PEER}.org${ORG} to ${CHANNEL_NAME}..."
      setGlobalsPeer $ORG $PEER
      peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block
      if [ $? -ne 0 ]; then
        errorln "Failed to join peer${PEER}.org${ORG} to ${CHANNEL_NAME}"
      else
        successln "peer${PEER}.org${ORG} joined ${CHANNEL_NAME}"
      fi
    done
  done

  # Set anchor peers
  for ORG in 1 2 3; do
    infoln "Setting anchor peer for Org${ORG} on ${CHANNEL_NAME}..."
    setGlobals $ORG
    peer channel fetch config channel-artifacts/config_block_${CHANNEL_NAME}.pb -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com -c ${CHANNEL_NAME} --tls --cafile "$ORDERER_CA" 2>/dev/null

    # For simplicity, we skip the anchor peer update config transaction
    # In production, you'd use configtxlator to update the anchor peer
  done

  successln "All peers joined ${CHANNEL_NAME}"
}

# Build chaincode Docker image for ccaas
function buildChaincodeImage() {
  infoln "Building chaincode Docker image..."
  docker build -t trgovina_ccaas:1.0 ../chaincode/trgovina/
  if [ $? -ne 0 ]; then
    fatalln "Failed to build chaincode image"
  fi
  successln "Chaincode Docker image built"
}

# Create ccaas package
function createCcaasPackage() {
  infoln "Creating ccaas chaincode package..."
  local TMPDIR=$(mktemp -d)
  echo '{"address":"trgovina_ccaas:9999","dial_timeout":"10s","tls_required":false}' > ${TMPDIR}/connection.json
  echo '{"type":"ccaas","label":"trgovina_1.0"}' > ${TMPDIR}/metadata.json
  cd ${TMPDIR} && tar cfz code.tar.gz connection.json && tar cfz ${TMPDIR}/trgovina_ccaas.tar.gz code.tar.gz metadata.json
  cd - > /dev/null
  cp ${TMPDIR}/trgovina_ccaas.tar.gz ./trgovina_ccaas.tar.gz
  rm -rf ${TMPDIR}
  successln "Ccaas package created"
}

# Package, install, approve, and commit chaincode using ccaas
function deployChaincode() {
  local CHANNEL_NAME=$1

  infoln "Deploying chaincode to ${CHANNEL_NAME}..."

  # Install on all peers
  for ORG in 1 2 3; do
    for PEER in 0 1 2; do
      infoln "Installing chaincode on peer${PEER}.org${ORG}..."
      setGlobalsPeer $ORG $PEER
      peer lifecycle chaincode install ./trgovina_ccaas.tar.gz 2>&1 | tail -1
    done
  done

  # Get package ID
  setGlobals 1
  peer lifecycle chaincode queryinstalled > log.txt 2>&1
  PACKAGE_ID=$(sed -n "/${CC_NAME}_${CC_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
  if [ -z "$PACKAGE_ID" ]; then
    fatalln "Failed to get chaincode package ID"
  fi
  infoln "Package ID: ${PACKAGE_ID}"

  # Start chaincode container (only once, shared across channels)
  if ! docker ps --format '{{.Names}}' | grep -q 'trgovina_ccaas'; then
    infoln "Starting chaincode ccaas container..."
    docker run -d --name trgovina_ccaas --network fabric_test \
      -e CHAINCODE_SERVER_ADDRESS=0.0.0.0:9999 \
      -e CHAINCODE_ID=${PACKAGE_ID} \
      trgovina_ccaas:1.0
    sleep 2
    successln "Chaincode container started"
  fi

  # Approve for each org
  for ORG in 1 2 3; do
    infoln "Approving chaincode for Org${ORG} on ${CHANNEL_NAME}..."
    setGlobals $ORG
    peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com \
      --channelID ${CHANNEL_NAME} --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} \
      --sequence ${CC_SEQUENCE} --tls --cafile "$ORDERER_CA" --init-required
    if [ $? -ne 0 ]; then
      fatalln "Failed to approve chaincode for Org${ORG}"
    fi
    successln "Chaincode approved for Org${ORG}"
  done

  # Commit chaincode
  infoln "Committing chaincode to ${CHANNEL_NAME}..."
  setGlobals 1
  peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com \
    --channelID ${CHANNEL_NAME} --name ${CC_NAME} --version ${CC_VERSION} --sequence ${CC_SEQUENCE} \
    --tls --cafile "$ORDERER_CA" --init-required \
    --peerAddresses localhost:7051 --tlsRootCertFiles "$PEER0_ORG1_CA" \
    --peerAddresses localhost:9051 --tlsRootCertFiles "$PEER0_ORG2_CA" \
    --peerAddresses localhost:11051 --tlsRootCertFiles "$PEER0_ORG3_CA"
  if [ $? -ne 0 ]; then
    fatalln "Failed to commit chaincode"
  fi
  successln "Chaincode committed to ${CHANNEL_NAME}"

  # Init chaincode
  infoln "Initializing chaincode on ${CHANNEL_NAME}..."
  setGlobals 1
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com \
    --channelID ${CHANNEL_NAME} --name ${CC_NAME} --isInit \
    --tls --cafile "$ORDERER_CA" \
    --peerAddresses localhost:7051 --tlsRootCertFiles "$PEER0_ORG1_CA" \
    --peerAddresses localhost:9051 --tlsRootCertFiles "$PEER0_ORG2_CA" \
    --peerAddresses localhost:11051 --tlsRootCertFiles "$PEER0_ORG3_CA" \
    -c '{"function":"InitLedger","Args":[]}'
  if [ $? -ne 0 ]; then
    fatalln "Failed to initialize chaincode"
  fi
  successln "Chaincode initialized on ${CHANNEL_NAME}"
}

# Bring up the network
function networkUp() {
  # Generate crypto material
  if [ ! -d "organizations/peerOrganizations" ]; then
    generateCryptoMaterial
  fi

  # Start containers
  infoln "Starting Docker containers..."
  docker compose -f docker/docker-compose-net.yaml up -d 2>&1
  if [ $? -ne 0 ]; then
    fatalln "Failed to start Docker containers"
  fi

  # Wait for containers to be ready
  infoln "Waiting for containers to be ready..."
  sleep 5

  successln "Network containers started successfully"
}

# Bring down the network
function networkDown() {
  infoln "Stopping network..."

  docker compose -f docker/docker-compose-net.yaml down --volumes --remove-orphans 2>/dev/null

  # Clean up chaincode ccaas container
  docker rm -f trgovina_ccaas 2>/dev/null

  # Clean up chaincode docker images
  docker rm -f $(docker ps -aq --filter label=service=hyperledger-fabric) 2>/dev/null
  docker rmi -f $(docker images -aq --filter reference='dev-peer*') 2>/dev/null

  # Clean up generated artifacts
  rm -rf organizations/peerOrganizations
  rm -rf organizations/ordererOrganizations
  rm -rf channel-artifacts
  rm -f log.txt ${CC_NAME}.tar.gz

  successln "Network stopped and cleaned up"
}

# Print usage
function printHelp() {
  println "Usage: "
  println "  network.sh <Mode>"
  println "    Modes:"
  println "      up          - Bring up network, create channels, deploy chaincode"
  println "      down        - Bring down the network"
  println "      restart     - Restart the network"
  println "      createChannel - Create channels and join peers"
  println "      deployCC    - Deploy chaincode to both channels"
  println ""
}

# Main
if [ "$1" = "up" ]; then
  networkUp
  sleep 5

  # Build chaincode image and create package
  buildChaincodeImage
  createCcaasPackage

  # Create both channels
  createChannelGenesisBlock $CHANNEL_NAME1
  createChannelGenesisBlock $CHANNEL_NAME2
  sleep 2

  createChannel $CHANNEL_NAME1
  sleep 3
  createChannel $CHANNEL_NAME2
  sleep 3

  # Deploy chaincode to both channels
  deployChaincode $CHANNEL_NAME1
  sleep 2

  CC_SEQUENCE=1
  deployChaincode $CHANNEL_NAME2

  successln "=========================================="
  successln "  Network is UP and chaincode is deployed"
  successln "  Channels: $CHANNEL_NAME1, $CHANNEL_NAME2"
  successln "=========================================="

elif [ "$1" = "down" ]; then
  networkDown

elif [ "$1" = "restart" ]; then
  networkDown
  sleep 2
  $0 up

elif [ "$1" = "createChannel" ]; then
  createChannelGenesisBlock $CHANNEL_NAME1
  createChannelGenesisBlock $CHANNEL_NAME2
  createChannel $CHANNEL_NAME1
  sleep 3
  createChannel $CHANNEL_NAME2

elif [ "$1" = "deployCC" ]; then
  deployChaincode $CHANNEL_NAME1
  sleep 2
  CC_SEQUENCE=1
  deployChaincode $CHANNEL_NAME2

else
  printHelp
  exit 1
fi
