'use strict';

const { connect, signers } = require('@hyperledger/fabric-gateway');
const grpc = require('@grpc/grpc-js');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const CHAINCODE_NAME = 'trgovina';

const orgConfigs = {
  org1: {
    mspId: 'Org1MSP',
    cryptoPath: path.resolve(__dirname, '..', 'network', 'organizations', 'peerOrganizations', 'org1.example.com'),
    peerEndpoint: 'localhost:7051',
    peerHostAlias: 'peer0.org1.example.com',
  },
  org2: {
    mspId: 'Org2MSP',
    cryptoPath: path.resolve(__dirname, '..', 'network', 'organizations', 'peerOrganizations', 'org2.example.com'),
    peerEndpoint: 'localhost:9051',
    peerHostAlias: 'peer0.org2.example.com',
  },
};

let gateway = null;
let client = null;
let contract = null;
let currentOrg = 'org1';
let currentChannel = 'channel1';

async function newGrpcConnection(orgConfig) {
  const tlsCertPath = path.resolve(orgConfig.cryptoPath, 'peers', orgConfig.peerHostAlias, 'tls', 'ca.crt');
  const tlsRootCert = fs.readFileSync(tlsCertPath);
  const tlsCredentials = grpc.credentials.createSsl(tlsRootCert);
  return new grpc.Client(orgConfig.peerEndpoint, tlsCredentials, {
    'grpc.ssl_target_name_override': orgConfig.peerHostAlias,
  });
}

function getIdentity(orgConfig) {
  const certDir = path.resolve(orgConfig.cryptoPath, 'users', `Admin@${path.basename(orgConfig.cryptoPath)}`, 'msp', 'signcerts');
  const files = fs.readdirSync(certDir);
  const certPath = path.resolve(certDir, files[0]);
  const credentials = fs.readFileSync(certPath);
  return { mspId: orgConfig.mspId, credentials };
}

function getSigner(orgConfig) {
  const keyDir = path.resolve(orgConfig.cryptoPath, 'users', `Admin@${path.basename(orgConfig.cryptoPath)}`, 'msp', 'keystore');
  const files = fs.readdirSync(keyDir);
  const keyPath = path.resolve(keyDir, files[0]);
  const privateKeyPem = fs.readFileSync(keyPath);
  const privateKey = crypto.createPrivateKey(privateKeyPem);
  return signers.newPrivateKeySigner(privateKey);
}

async function connectToNetwork(org, channel) {
  if (gateway) gateway.close();
  if (client) client.close();

  const orgConfig = orgConfigs[org];
  if (!orgConfig) {
    console.log(`Nepoznata organizacija: ${org}`);
    return false;
  }

  try {
    client = await newGrpcConnection(orgConfig);
    const identity = getIdentity(orgConfig);
    const sign = getSigner(orgConfig);

    gateway = connect({
      client,
      identity,
      signer: sign,
      evaluateOptions: () => ({ deadline: Date.now() + 5000 }),
      endorseOptions: () => ({ deadline: Date.now() + 15000 }),
      submitOptions: () => ({ deadline: Date.now() + 5000 }),
      commitStatusOptions: () => ({ deadline: Date.now() + 60000 }),
    });

    const network = gateway.getNetwork(channel);
    contract = network.getContract(CHAINCODE_NAME);
    currentOrg = org;
    currentChannel = channel;

    console.log(`\nUspesno povezan kao ${orgConfig.mspId} na kanal ${channel}`);
    return true;
  } catch (error) {
    console.error(`Greska pri povezivanju: ${error.message}`);
    return false;
  }
}

function getContract() {
  return contract;
}

function getCurrentOrg() {
  return currentOrg;
}

function getCurrentChannel() {
  return currentChannel;
}

function closeConnection() {
  if (gateway) gateway.close();
  if (client) client.close();
}

module.exports = {
  connectToNetwork,
  getContract,
  getCurrentOrg,
  getCurrentChannel,
  closeConnection,
};
