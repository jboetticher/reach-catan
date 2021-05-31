'reach 0.1';

//#region Enums

const RSS_ENUM_SIZE = 4;
const PLAYER_COUNT = 3;
const [isResource, WHEAT, ORE, WOOD, BRICK] = makeEnum(RSS_ENUM_SIZE);
const [isPlayer, pNONE, pALICE, pBOB, pCARL] = makeEnum(4);

//#endregion

//#region Player Definitions

const TILE_SIDES = 6;
const MAP_SIZE = 7;
const Player =
{
  ...hasRandom,
  informTimeout: Fun([], Null),
  getSeed: Fun([], UInt),
  seeMap: Fun([Array(Object({
    rss: UInt,
    roll: UInt,
  }), MAP_SIZE)], Null),
  seeRss: Fun([Array(Array(UInt, RSS_ENUM_SIZE), PLAYER_COUNT)], Null),
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

export const main = Reach.App(
  {}, [Participant('Alice', Alice), Participant('Bob', Bob), Participant('Carl', Bob)], (A, B, C) => {

    //#region Alice Presents Wager

    // shows alice's wager
    A.only(() => {
      const wager = declassify(interact.wager);
    });

    // pays + publish wager
    A.publish(wager).pay(wager);
    commit();

    //#endregion

    //#region Bob + Carl Accept Wager

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

    // seed is calculated from the (hopefully random) input of each player
    const seed = seedA + seedB + seedC;

    // decides the world
    // didnt want to make algorithm for good random world bc im lazy so instead you get this
    const map = array(Object({ rss: UInt, roll: UInt }), [
      { rss: (seed + 6) % RSS_ENUM_SIZE, roll: (seed + 9) % 8 },
      { rss: seed % RSS_ENUM_SIZE, roll: seed % 8 },
      { rss: (seed + 18) % RSS_ENUM_SIZE, roll: (seed + 21) % 8 },
      { rss: (seed + 3) % RSS_ENUM_SIZE, roll: (seed + 6) % 8 },
      { rss: (seed + 15) % RSS_ENUM_SIZE, roll: (seed + 18) % 8 },
      { rss: (seed + 12) % RSS_ENUM_SIZE, roll: (seed + 15) % 8 },
      { rss: (seed + 9) % RSS_ENUM_SIZE, roll: (seed + 12) % 8 },
    ]);

    //#endregion

    // ------ GAMEPLAY BEGINS HERE ------

    //#region Resources + Actions

    // show everyone the map before any interactions start
    each([A, B, C], () => {
      interact.seeMap(map);
    });

    function createStarterResourceArray() {
      return array(UInt, [2, 2, 2, 2]);
    }

    var gameState = {
      winner: pNONE,
      // stores the resources of each player.
      // 0 - Alice, 1 - Bob, 2 - Carl
      playerResources: array(Array(UInt, RSS_ENUM_SIZE), [
        createStarterResourceArray(),
        createStarterResourceArray(),
        createStarterResourceArray(),
      ]),
      //buildings
      // not implemented yet so whoops
    };

    invariant(
      isPlayer(gameState.winner) &&
      gameState.playerResources.length == PLAYER_COUNT &&
      balance() == wager * PLAYER_COUNT
    );
    while (gameState.winner == pNONE) {
      each([A, B, C], () => {
        interact.seeRss(gameState.playerResources);
      });
      
      commit();
      A.only(() => {
        const test = "test";
      });
      A.publish(test);

      gameState = {
        winner: pALICE,
        playerResources: gameState.playerResources
      };

      continue;
    }
    commit();

    //#endregion

    // alice always wins in this scenario (pending actual logic)
    A.only(() => {
      const Apotatoes = declassify(interact.testaroonie);
    });
    A.publish(Apotatoes);

    transfer(wager * PLAYER_COUNT).to(
      gameState.winner == pALICE ? A :
      gameState.winner == pBOB ? B : C
    );
    commit();
    exit();
  }
);
