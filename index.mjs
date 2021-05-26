import { loadStdlib } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';

const RSS_ENUM = [
  "Potato", "Ore", "Wood", "Brick", "Coal"
];
const _ENUM = [
  "P"
];

(async () => {
  const stdlib = await loadStdlib();
  const startingBalance = stdlib.parseCurrency(100);

  const alice = await stdlib.newTestAccount(startingBalance);
  const bob = await stdlib.newTestAccount(startingBalance);
  const carl = await stdlib.newTestAccount(startingBalance);

  const ctcAlice = alice.deploy(backend);
  const ctcBob = bob.attach(backend, ctcAlice.getInfo());
  const ctcCarl = carl.attach(backend, ctcAlice.getInfo());

  const fmt = (x) => stdlib.formatCurrency(x, 4);
  const getBalance = async (who) => fmt(await stdlib.balanceOf(who));
  const beforeAlice = await getBalance(alice);

  const startingValues = {
    potatoes: 0,
    ore: 0,
    wood: 0,
    bricks: 0,
  }
  const acceptWager = async (amt, name) => {
    if(Math.random() <= 0) {
      console.log('Taking too long');
      await stdlib.wait(10);
    } else {
      console.log(name + " accepts the wager of " + fmt(amt));
    }
  }

  console.log('Hello everyone!');

  const playerInteract = { 
    ...stdlib.hasRandom
  };

  playerInteract.informTimeout = () => {
    console.log(`${Who} observed a timeout!`);
  };

  playerInteract.seeMap = (obj) => {
    console.log("------------------------------------");
    for(let i = 0; i < 7; i++) {
      console.log(`Tile ${i}: rss is ${RSS_ENUM[obj[i].rss]}, roll is ${obj[i].roll}`);
    }
    console.log("------------------------------------");
  };

  playerInteract.getSeed = () => {
    return Math.floor(Math.random() * (10000000));
  }

  await Promise.all([
    backend.Alice(ctcAlice, {
      ...playerInteract,
      wager: stdlib.parseCurrency(25),
      testaroonie: 4,
      //...startingValues,
    }),
    backend.Bob(ctcBob, {
      ...playerInteract,
      //...startingValues,
      acceptWager: (amt) => { acceptWager(amt, 'bob'); },
    }),
    backend.Carl(ctcCarl, {
      ...playerInteract,
      //...startingValues,
      acceptWager: (amt) => { acceptWager(amt, 'carl'); },
    })
  ]);

  const afterAlice = await getBalance(alice);
  console.log(`Alice went from ${beforeAlice} to ${afterAlice}.`);

})();
