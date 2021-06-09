'reach 0.1';

//#region Enums

const RSS_ENUM_SIZE = 4;
const PLAYER_COUNT = 3;
const MAXIMUM_BUILDINGS_ON_TILE = 3;
const [isResource, WHEAT, ORE, WOOD, BRICK] = makeEnum(RSS_ENUM_SIZE);
const [isPlayer, pNONE, pALICE, pBOB, pCARL] = makeEnum(4);
const [isGamePhase, RESOUCE_GEN, BUILDING, TRADE] = makeEnum(3);

//#endregion

//#region Player Definitions

const MAP_SIZE = 7;
const Player =
{
  ...hasRandom,
  log: Fun(true, Null),
  informTimeout: Fun([], Null),
  getSeed: Fun([], UInt),
  seeMap: Fun([Array(Object({
    rss: UInt,
    roll: UInt,
  }), MAP_SIZE)], Null),
  seeGameState: Fun([Object({
    winner: UInt,
    roll: UInt,
    round: UInt,
    turn: UInt,
    phase: UInt,
    resources: Array(Array(UInt, RSS_ENUM_SIZE), PLAYER_COUNT),
    buildings: Array(Array(UInt, MAXIMUM_BUILDINGS_ON_TILE), MAP_SIZE)
  })], Null),
  placeBuilding: Fun([], Object({ tile: UInt, skip: Bool })),
  offerTrade: Fun([], Object({
    player: UInt,
    offer: Array(UInt, RSS_ENUM_SIZE),
    payment: Array(UInt, RSS_ENUM_SIZE),
    skip: Bool
  })),
  offerTradeCallback: Fun([Bool], Null)
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

    // try putting first world generation step in with the wager step

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

    // the following is commented out only to make development faster.
    A.only(() => {
      const deleteThisCode = declassify(interact.testaroonie);
    });
    A.publish(deleteThisCode);
    /*
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
    */

    const seedA = 324445;
    const seedB = 164775;
    const seedC = 824649;
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

    function createStarterBuildingArray() {
      return array(UInt, [pNONE, pNONE, pNONE]);
    }

    var gameState = {
      winner: pNONE,
      // stores the resources of each player.
      // 0 - Alice, 1 - Bob, 2 - Carl
      resources: array(Array(UInt, RSS_ENUM_SIZE), [
        createStarterResourceArray(),
        createStarterResourceArray(),
        createStarterResourceArray(),
      ]),
      // stores which round that the gameState is in
      round: 0,
      // stores the roll so that the frontend can be responsive
      roll: 4,
      // stores which player is supposed to be playing
      turn: pALICE,
      // stores the player's phase of the game
      phase: RESOUCE_GEN,
      //buildings
      buildings: array(Array(UInt, MAXIMUM_BUILDINGS_ON_TILE), [
        createStarterBuildingArray(),
        createStarterBuildingArray(),
        createStarterBuildingArray(),
        createStarterBuildingArray(),
        createStarterBuildingArray(),
        createStarterBuildingArray(),
        createStarterBuildingArray(),
      ])
    };

    invariant(
      isPlayer(gameState.winner) &&
      gameState.resources.length == PLAYER_COUNT &&
      gameState.roll >= 2 && gameState.roll <= 12 &&
      gameState.round >= 0 &&
      isPlayer(gameState.turn) &&
      isGamePhase(gameState.phase) &&
      balance() == wager * PLAYER_COUNT
    );

    while (gameState.winner == pNONE) {
      commit();

      // sends the resource data to the frontend
      function letPlayersSeeGameState(localGameState) {
        each([A, B, C], () => {
          interact.seeGameState(localGameState);
        });
      }

      // rolls the dice and gives players the correct amount of resources
      function diceRollPhase(localGameState, player) {
        /**
         * We're being lazy here so this is all deterministic based off of the PUBLIC seed
         * In other words, user front ends can predict future rolls.
         * SOLUTIONS:
         * 1. Make a new seed at the beginning but obfuscate it. Probably won't be safe after first roll.
         * 2. Ask for a new random from each player each round (annoying and cost ineffective).
         * 3. Base rolls calculation off of player interactions to make it different each time (players affect the roll by design).
         */
        const localRoll =
          ((seedA + seedB) * gameState.round) % 6 + ((seedB + seedC) * gameState.round % 6) + 2;

        return {
          winner: localGameState.winner,
          roll: localRoll,
          round: localGameState.round + 1,
          turn: player,
          phase: BUILDING, // transitions to the next phase, which is building
          buildings: localGameState.buildings,

          // yeah... right now it's just giving resources to player 1
          resources: localGameState.resources.set(0, array(UInt, [
            localGameState.resources[0][0] + 1,
            localGameState.resources[0][1] + 1,
            localGameState.resources[0][2] + 1,
            localGameState.resources[0][3] + 1
          ]))
        };
      }

      // returns the game state when attempting to build a building
      function attemptBuildingPhase(localGameState, player, buildCmd) {

        // returns 3 if there is no building space, otherwise it returns the empty space
        function tileHasBuildingSpace(tile) {
          interact.log(tile);
          if (tile[0] == pNONE) return 0;
          if (tile[1] == pNONE) return 1;
          if (tile[2] == pNONE) return 2;
          return 3;
        }

        interact.log(buildCmd);

        // skip if that's what they want to do
        return buildCmd.skip ?
          {
            winner: 2, // localGameState.winner,
            roll: 0, // localGameState.roll,
            round: 0, // localGameState.round,
            turn: 0, // player,
            phase: TRADE, // transitions to the next phase, which is trade
            resources: localGameState.resources,
            buildings: localGameState.buildings,
          }
          : () => {
            return (buildCmd.tile >= 0 && buildCmd.tile < MAP_SIZE) ? () => {
              const buildingSpace = tileHasBuildingSpace(localGameState.buildings[buildCmd.tile]);
              return (buildingSpace < MAXIMUM_BUILDINGS_ON_TILE) ?
                {
                  winner: 3, //localGameState.winner,
                  roll: 0, // localGameState.roll,
                  round: 0, // localGameState.round,
                  turn: 0, // player,
                  phase: TRADE, // transitions to the next phase, which is trade
                  resources: localGameState.resources,
                  buildings: localGameState.buildings.set(buildCmd.tile, array(UInt, [
                    buildingSpace == 0 ? player : localGameState.buildings[buildCmd.tile][0],
                    buildingSpace == 1 ? player : localGameState.buildings[buildCmd.tile][1],
                    buildingSpace == 2 ? player : localGameState.buildings[buildCmd.tile][2],
                  ]))
                }
                :
                {
                  winner: buildCmd.skip ? 1 : 0, //localGameState.winner
                  roll: 0, // localGameState.roll
                  round: 0, // localGameState.round
                  turn: 0, // localGameState.round
                  phase: TRADE, // transitions to the next phase, which is trade
                  resources: localGameState.resources,
                  buildings: localGameState.buildings,
                }
            }
              :
              {
                winner: buildCmd.skip ? 1 : 0, //localGameState.winner
                roll: 0, // localGameState.roll
                round: 0, // localGameState.round
                turn: 0, // localGameState.round
                phase: TRADE, // transitions to the next phase, which is trade
                resources: localGameState.resources,
                buildings: localGameState.buildings,
              }
          }

        /*

      interact.log(buildCmd.tile >= 0 && buildCmd.tile < MAP_SIZE);
      interact.log({ mapSize: MAP_SIZE, tileNum: buildCmd.tile });

        // if it hasn't returned at this point, then a faulty command was given
        return {
          winner: localGameState.winner,
          roll: localGameState.roll,
          round: localGameState.round,
          turn: player,
          phase: TRADE, // transitions to the next phase, which is trade
          resources: localGameState.resources,
          buildings: localGameState.buildings,
        };
        */
      }

      // ALICE: Dice Roll Phase
      const gameState1 = diceRollPhase(gameState, pALICE);
      letPlayersSeeGameState(gameState1);

      // ALICE: Building Phase
      A.only(() => {
        const _aBuilding = interact.placeBuilding();
        interact.log(_aBuilding);
        const gameState2 = declassify(
          attemptBuildingPhase(gameState1, pALICE, _aBuilding)
        );
      });
      A.publish(gameState2);
      commit();
      letPlayersSeeGameState(gameState2);

      // ALICE: Trade Deal Phase

      /*
      A.only(() => {
        const _aTrade = interact.offerTrade();
        interact.log(_aTrade);
        const gameState3 = declassify(

        );
      });
      */


      // let alice make trades if they want
      // lmao lets not do that yet

      // let whoever gets the trade accept or not accept the deal
      // lmao lets not do that yet



      // repeat the last four steps with bob

      // repeat again with carl

      // check to see if anyone is a winner (haven't finished yet)
      // probably will just check for a summation of buildings
      A.only(() => {
        const test = "test";
      });
      A.publish(test);
      gameState = gameState1;

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
