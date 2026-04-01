'use strict';

const readlineSync = require('readline-sync');
const { getContract } = require('./connection');
const { extractErrorMessage } = require('./utils');

async function createTrgovac() {
  const id = readlineSync.question('ID trgovca: ');
  const tipTrgovca = readlineSync.question('Tip trgovca: ');
  const pib = readlineSync.question('PIB: ');
  const stanje = readlineSync.question('Pocetno stanje: ');

  try {
    await getContract().submitTransaction('CreateTrgovac', id, tipTrgovca, pib, stanje);
    console.log('\nTrgovac uspesno kreiran!');
  } catch (error) {
    console.error(`\nGreska: ${extractErrorMessage(error)}`);
  }
}

async function addProizvod() {
  const proizvodID = readlineSync.question('ID proizvoda: ');
  const ime = readlineSync.question('Ime proizvoda: ');
  const rokTrajanja = readlineSync.question('Rok trajanja (YYYY-MM-DD, prazno ako nema): ');
  const cena = readlineSync.question('Cena: ');
  const kolicina = readlineSync.question('Kolicina: ');
  const trgovacID = readlineSync.question('ID trgovca: ');

  try {
    await getContract().submitTransaction('AddProizvod', proizvodID, ime, rokTrajanja, cena, kolicina, trgovacID);
    console.log('\nProizvod uspesno dodat!');
  } catch (error) {
    console.error(`\nGreska: ${extractErrorMessage(error)}`);
  }
}

async function createKorisnik() {
  const id = readlineSync.question('ID korisnika: ');
  const ime = readlineSync.question('Ime: ');
  const prezime = readlineSync.question('Prezime: ');
  const email = readlineSync.question('Email: ');
  const stanje = readlineSync.question('Pocetno stanje: ');

  try {
    await getContract().submitTransaction('CreateKorisnik', id, ime, prezime, email, stanje);
    console.log('\nKorisnik uspesno kreiran!');
  } catch (error) {
    console.error(`\nGreska: ${extractErrorMessage(error)}`);
  }
}

async function kupiProizvod() {
  const korisnikID = readlineSync.question('ID korisnika: ');
  const proizvodID = readlineSync.question('ID proizvoda: ');
  const kolicina = readlineSync.question('Kolicina: ');

  try {
    await getContract().submitTransaction('KupiProizvod', korisnikID, proizvodID, kolicina);
    console.log('\nKupovina uspesno izvrsena!');
  } catch (error) {
    console.error(`\nGreska: ${extractErrorMessage(error)}`);
  }
}

async function uplatiNovac() {
  const id = readlineSync.question('ID korisnika ili trgovca: ');
  const iznos = readlineSync.question('Iznos: ');

  try {
    await getContract().submitTransaction('UplatiNovac', id, iznos);
    console.log('\nUplata uspesno izvrsena!');
  } catch (error) {
    console.error(`\nGreska: ${extractErrorMessage(error)}`);
  }
}

module.exports = {
  createTrgovac,
  addProizvod,
  createKorisnik,
  kupiProizvod,
  uplatiNovac,
};
