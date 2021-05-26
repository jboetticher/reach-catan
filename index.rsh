'reach 0.1';

//#region Player Definitions

const TILE_SIDES = 6;
const MAP_SIZE = 7;
const Player =
{
  ...hasRandom,
  informTimeout: Fun([], Null),
  seeMap: Fun([Array(Object({ 
    rss: UInt, 
    roll: UInt,
  }), MAP_SIZE)], Null),
  getSeed: Fun([], UInt),
  placeBuilding: Fun([], Object({ tile: UInt, side: UInt })),
  placeBuildingCallback: Fun([Bool], Null),
};
const Alice = {
  ...Player,
  wager: UInt,
  testaroonie: UInt,
};
const Bob = {
  ...Player,
  acceptWager: Fun([UInt], Null)
};

//#endregion

//#region Enums

const RSS_ENUM_SIZE = 4;
const [isResource, POTATO, ORE, WOOD, BRICK] = makeEnum(RSS_ENUM_SIZE);
const [isPlayer, pNONE, pALICE, pBOB, pCARL] = makeEnum(4);

//#endregion

export const main = Reach.App(
  {}, [Participant('Alice', Alice), Participant('Bob', Bob), Participant('Carl', Bob)], (A, B, C) => {

    //#region STEP: Alice Presents Wager

    // shows alice's wager
    A.only(() => {
      const wager = declassify(interact.wager);
    });

    // pays + publish wager
    A.publish(wager).pay(wager);
    commit();

    //#endregion

    //#region STEPS: Bob + Carl Accept Wager

    B.only(() => {
      interact.acceptWager(wager);
    });
    B.pay(wager);
    //.timeout(DEADLINE, () => closeTo(A, informTimeout));
    commit();

    C.only(() => {
      interact.acceptWager(wager);
    });
    C.pay(wager);
    //.timeout(DEADLINE, () => closeTo(A, informTimeout));
    commit();

    //#endregion

    //#region World Generation

    A.only(() => {
      const _seedA = interact.getSeed();
      const [_commitA, _saltA] = makeCommitment(interact, _seedA);
      const commitA = declassify(_commitA);
    });
    A.publish(commitA);
    //  .timeout(DEADLINE, () => closeTo(B, informTimeout));
    commit();

    unknowable(B, A(_seedA, _saltA));
    unknowable(C, A(_seedA, _saltA));
    B.only(() => {
      const _seedB = interact.getSeed();
      const [_commitB, _saltB] = makeCommitment(interact, _seedB);
      const commitB = declassify(_commitB);
    });
    B.publish(commitB);
    //  .timeout(DEADLINE, () => closeTo(B, informTimeout));
    commit();

    unknowable(A, B(_seedB, _saltB));
    unknowable(C, B(_seedB, _saltB));
    C.only(() => {
      const seedC = declassify(interact.getSeed());
    });
    C.publish(seedC);
    //  .timeout(DEADLINE, () => closeTo(A, informTimeout));
    commit();

    A.only(() => {
      const [saltA, seedA] = declassify([_saltA, _seedA]);
    });
    A.publish(saltA, seedA);
    checkCommitment(commitA, saltA, seedA);
    commit();

    B.only(() => {
      const [saltB, seedB] = declassify([_saltB, _seedB]);
    });
    B.publish(saltB, seedB);
    checkCommitment(commitB, saltB, seedB);
    commit();

    // seed is calculated from the (hopefully random) input of each player
    const seed = seedA + seedB + seedC;

    // decides the world
    // didnt want to make algorithm for good random world bc im lazy so you get this
    each([A, B, C], () => {
      function noOwner() { 
        return array(UInt, [pNONE, pNONE, pNONE, pNONE, pNONE, pNONE]); 
      }

      const map = array(Object({ rss: UInt, roll: UInt }), [
        { rss: (seed + 6) % RSS_ENUM_SIZE, roll: (seed + 9) % 8 },
        { rss: seed % RSS_ENUM_SIZE, roll: seed % 8 },
        { rss: (seed + 18) % RSS_ENUM_SIZE, roll: (seed + 21) % 8 },
        { rss: (seed + 3) % RSS_ENUM_SIZE, roll: (seed + 6) % 8 },
        { rss: (seed + 15) % RSS_ENUM_SIZE, roll: (seed + 18) % 8 },
        { rss: (seed + 12) % RSS_ENUM_SIZE, roll: (seed + 15) % 8 },
        { rss: (seed + 9) % RSS_ENUM_SIZE, roll: (seed + 12)  % 8 },
      ]);
    });

    //#endregion

    // ------ GAMEPLAY BEGINS HERE ------

    //#region Reusable Functions
    
    function everyoneRefreshMap() {
      each([A, B, C], () => {
        interact.seeMap(map);
      });
    }

    //#endregion

    //#region Resources + Actions

    // show everyone the map before any interactions start
    everyoneRefreshMap();

    A.only(() => {
      const _aInput = interact.placeBuilding();

      if(isPlayer(_aInput.tile) && _aInput.side < TILE_SIDES) {          
          const dog = array(UInt, [3, 3, 3]);
          const newDog = dog.set(1, 2);

          //map[_aInput.tile].owners.set(_aInput.side, pALICE);
          interact.placeBuildingCallback(true);
      } else {
        interact.placeBuildingCallback(false);
      }
    });

    everyoneRefreshMap();

    //#endregion

    // alice always wins in this scenario (pending actual logic)
    A.only(() => {
      const Apotatoes = declassify(interact.testaroonie);
    });
    A.publish(Apotatoes);

    transfer(wager * 3).to(A);
    commit();
    exit();
  }
);
