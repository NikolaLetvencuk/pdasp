'use strict';

const readlineSync = require('readline-sync');
const { getContract } = require('./connection');
const { printJSON, extractErrorMessage } = require('./utils');

async function getTrgovac() {
  const id = readlineSync.question('ID trgovca: ');
  try {
    const result = await getContract().evaluateTransaction('GetTrgovac', id);
    printJSON(result);
  } catch (error) {
    console.error(`\nGreska: ${extractErrorMessage(error)}`);
  }
}

async function getKorisnik() {
  const id = readlineSync.question('ID korisnika: ');
  try {
    const result = await getContract().evaluateTransaction('GetKorisnik', id);
    printJSON(result);
  } catch (error) {
    console.error(`\nGreska: ${extractErrorMessage(error)}`);
  }
}

async function getProizvod() {
  const id = readlineSync.question('ID proizvoda: ');
  try {
    const result = await getContract().evaluateTransaction('GetProizvod', id);
    printJSON(result);
  } catch (error) {
    console.error(`\nGreska: ${extractErrorMessage(error)}`);
  }
}

async function getRacun() {
  const id = readlineSync.question('ID racuna: ');
  try {
    const result = await getContract().evaluateTransaction('GetRacun', id);
    printJSON(result);
  } catch (error) {
    console.error(`\nGreska: ${extractErrorMessage(error)}`);
  }
}

async function getAllTrgovci() {
  try {
    const result = await getContract().evaluateTransaction('GetAllTrgovci');
    printJSON(result);
  } catch (error) {
    console.error(`\nGreska: ${extractErrorMessage(error)}`);
  }
}

async function getAllKorisnici() {
  try {
    const result = await getContract().evaluateTransaction('GetAllKorisnici');
    printJSON(result);
  } catch (error) {
    console.error(`\nGreska: ${extractErrorMessage(error)}`);
  }
}

async function getAllProizvodi() {
  try {
    const result = await getContract().evaluateTransaction('GetAllProizvodi');
    printJSON(result);
  } catch (error) {
    console.error(`\nGreska: ${extractErrorMessage(error)}`);
  }
}

async function queryProizvodiByIme() {
  const ime = readlineSync.question('Ime proizvoda (ili deo imena): ');
  try {
    const result = await getContract().evaluateTransaction('QueryProizvodiByIme', ime);
    printJSON(result);
  } catch (error) {
    console.error(`\nGreska: ${extractErrorMessage(error)}`);
  }
}

async function queryProizvodiByTip() {
  const tip = readlineSync.question('Tip trgovca: ');
  try {
    const result = await getContract().evaluateTransaction('QueryProizvodiByTipTrgovca', tip);
    printJSON(result);
  } catch (error) {
    console.error(`\nGreska: ${extractErrorMessage(error)}`);
  }
}

async function queryProizvodiCenaRange() {
  const minCena = readlineSync.question('Minimalna cena: ');
  const maxCena = readlineSync.question('Maksimalna cena: ');
  try {
    const result = await getContract().evaluateTransaction('QueryProizvodiCenaRange', minCena, maxCena);
    printJSON(result);
  } catch (error) {
    console.error(`\nGreska: ${extractErrorMessage(error)}`);
  }
}

async function queryProizvodiAdvanced() {
  console.log('\nNapredna pretraga - unesite kriterijume (prazno za preskakanje):');
  const ime = readlineSync.question('  Ime: ');
  const tipTrgovca = readlineSync.question('  Tip trgovca: ');
  const minCena = readlineSync.question('  Minimalna cena: ');
  const maxCena = readlineSync.question('  Maksimalna cena: ');

  const query = {};
  if (ime) query.ime = ime;
  if (tipTrgovca) query.tipTrgovca = tipTrgovca;
  if (minCena) query.minCena = parseFloat(minCena);
  if (maxCena) query.maxCena = parseFloat(maxCena);

  try {
    const result = await getContract().evaluateTransaction('QueryProizvodiAdvanced', JSON.stringify(query));
    printJSON(result);
  } catch (error) {
    console.error(`\nGreska: ${extractErrorMessage(error)}`);
  }
}

async function queryProizvodiSorted() {
  const ascending = readlineSync.keyInYNStrict('Rastuci redosled po ceni?');
  try {
    const result = await getContract().evaluateTransaction('QueryProizvodiSortByCena', ascending.toString());
    printJSON(result);
  } catch (error) {
    console.error(`\nGreska: ${extractErrorMessage(error)}`);
  }
}

async function queryRacuniByKorisnik() {
  const id = readlineSync.question('ID korisnika: ');
  try {
    const result = await getContract().evaluateTransaction('QueryRacuniByKorisnik', id);
    printJSON(result);
  } catch (error) {
    console.error(`\nGreska: ${extractErrorMessage(error)}`);
  }
}

async function queryRacuniByTrgovac() {
  const id = readlineSync.question('ID trgovca: ');
  try {
    const result = await getContract().evaluateTransaction('QueryRacuniByTrgovac', id);
    printJSON(result);
  } catch (error) {
    console.error(`\nGreska: ${extractErrorMessage(error)}`);
  }
}

async function getHistoryForKey() {
  const key = readlineSync.question('Kljuc (ID entiteta): ');
  try {
    const result = await getContract().evaluateTransaction('GetHistoryForKey', key);
    printJSON(result);
  } catch (error) {
    console.error(`\nGreska: ${extractErrorMessage(error)}`);
  }
}

module.exports = {
  getTrgovac,
  getKorisnik,
  getProizvod,
  getRacun,
  getAllTrgovci,
  getAllKorisnici,
  getAllProizvodi,
  queryProizvodiByIme,
  queryProizvodiByTip,
  queryProizvodiCenaRange,
  queryProizvodiAdvanced,
  queryProizvodiSorted,
  queryRacuniByKorisnik,
  queryRacuniByTrgovac,
  getHistoryForKey,
};
