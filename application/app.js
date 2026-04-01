'use strict';

const readlineSync = require('readline-sync');
const { connectToNetwork, getCurrentOrg, getCurrentChannel, closeConnection } = require('./connection');
const { createTrgovac, addProizvod, createKorisnik, kupiProizvod, uplatiNovac } = require('./invoke');
const {
  getTrgovac, getKorisnik, getProizvod, getRacun,
  getAllTrgovci, getAllKorisnici, getAllProizvodi,
  queryProizvodiByIme, queryProizvodiByTip, queryProizvodiCenaRange,
  queryProizvodiAdvanced, queryProizvodiSorted,
  queryRacuniByKorisnik, queryRacuniByTrgovac, getHistoryForKey,
} = require('./query');

function printMenu() {
  console.log(`\n========================================`);
  console.log(`  SISTEM ZA TRGOVANJE - Hyperledger Fabric`);
  console.log(`  Organizacija: ${getCurrentOrg().toUpperCase()} | Kanal: ${getCurrentChannel()}`);
  console.log(`========================================`);
  console.log(`\n--- PRIJAVA ---`);
  console.log(`  1. Promeni organizaciju (login)`);
  console.log(`  2. Promeni kanal`);
  console.log(`\n--- INVOKE (upis) ---`);
  console.log(`  3.  Kreiraj trgovca`);
  console.log(`  4.  Dodaj proizvod trgovcu`);
  console.log(`  5.  Kreiraj korisnika`);
  console.log(`  6.  Kupi proizvod`);
  console.log(`  7.  Uplati novac`);
  console.log(`\n--- QUERY (citanje) ---`);
  console.log(`  8.  Prikazi trgovca po ID`);
  console.log(`  9.  Prikazi korisnika po ID`);
  console.log(`  10. Prikazi proizvod po ID`);
  console.log(`  11. Prikazi racun po ID`);
  console.log(`  12. Svi trgovci`);
  console.log(`  13. Svi korisnici`);
  console.log(`  14. Svi proizvodi`);
  console.log(`  15. Pretraga proizvoda po imenu`);
  console.log(`  16. Pretraga proizvoda po tipu trgovca`);
  console.log(`  17. Pretraga proizvoda po rasponu cene`);
  console.log(`  18. Napredna pretraga proizvoda (kombinovana)`);
  console.log(`  19. Proizvodi sortirani po ceni`);
  console.log(`  20. Racuni korisnika`);
  console.log(`  21. Racuni trgovca`);
  console.log(`  22. Istorija promena (po kljucu)`);
  console.log(`\n  0. Izlaz`);
  console.log(`========================================`);
}

async function main() {
  console.log('Pokretanje aplikacije...');

  const connected = await connectToNetwork('org1', 'channel1');
  if (!connected) {
    console.error('Nije moguce povezati se na mrezu. Proverite da li je mreza pokrenuta.');
    process.exit(1);
  }

  let running = true;
  while (running) {
    printMenu();
    const choice = readlineSync.question('\nIzaberite opciju: ');

    switch (choice) {
      case '1': {
        const org = readlineSync.question('Organizacija (org1/org2): ');
        await connectToNetwork(org, getCurrentChannel());
        break;
      }
      case '2': {
        const ch = readlineSync.question('Kanal (channel1/channel2): ');
        await connectToNetwork(getCurrentOrg(), ch);
        break;
      }
      case '3': await createTrgovac(); break;
      case '4': await addProizvod(); break;
      case '5': await createKorisnik(); break;
      case '6': await kupiProizvod(); break;
      case '7': await uplatiNovac(); break;
      case '8': await getTrgovac(); break;
      case '9': await getKorisnik(); break;
      case '10': await getProizvod(); break;
      case '11': await getRacun(); break;
      case '12': await getAllTrgovci(); break;
      case '13': await getAllKorisnici(); break;
      case '14': await getAllProizvodi(); break;
      case '15': await queryProizvodiByIme(); break;
      case '16': await queryProizvodiByTip(); break;
      case '17': await queryProizvodiCenaRange(); break;
      case '18': await queryProizvodiAdvanced(); break;
      case '19': await queryProizvodiSorted(); break;
      case '20': await queryRacuniByKorisnik(); break;
      case '21': await queryRacuniByTrgovac(); break;
      case '22': await getHistoryForKey(); break;
      case '0':
        running = false;
        break;
      default:
        console.log('Nepoznata opcija!');
    }
  }

  closeConnection();
  console.log('\nAplikacija zavrsena.');
}

main().catch(console.error);
