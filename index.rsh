'reach 0.1';

//#region Enums

const RSS_ENUM_SIZE = 4;
const PLAYER_COUNT = 3;
const MAXIMUM_BUILDINGS_ON_TILE = 3;
const [isResource, WHEAT, ORE, WOOD, BRICK] = makeEnum(RSS_ENUM_SIZE);
const [isPlayer, pNONE, pALICE, pBOB, pCARL] = makeEnum(4);
const [isGamePhase, RESOURCE_GEN, BUILDING, TRADE] = makeEnum(3);

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
    recievePlayer: UInt,
    offer: Array(UInt, RSS_ENUM_SIZE),
    payment: Array(UInt, RSS_ENUM_SIZE),
    skip: Bool
  })),
  recieveTradeOffer: Fun([Object({
    offerPlayer: UInt,
    offer: Array(UInt, RSS_ENUM_SIZE),
    payment: Array(UInt, RSS_ENUM_SIZE)
  })], Bool),
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

    //@TODO: Try putting first world generation step in with the wager step
    //@TODO: Delete the two statements below and uncomment the true logic
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
      phase: RESOURCE_GEN,
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
      isPlayer(gameState.winner) && //fails
      gameState.resources.length == PLAYER_COUNT &&
      gameState.roll >= 2 && gameState.roll <= 12 && //fails
      gameState.round >= 0 &&
      isPlayer(gameState.turn) && // fails
      isGamePhase(gameState.phase) && //fails
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

      // returns true if the specified player has enough resources in the localGameState
      function ensurePlayerHasResources(localGameState, player, resources) {
        //resources.length != localGameState.resources[player].length ? false :
        return ( //TODO!!: first 0 should be player
          localGameState.resources[0][0] >= resources[0] &&
          localGameState.resources[0][1] >= resources[1] &&
          localGameState.resources[0][2] >= resources[2] &&
          localGameState.resources[0][3] >= resources[3]
        );
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
        assert(localRoll < 12);

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

        //interact.log(buildCmd);

        //@TODO: Uncomment the first comment block below and fix it. This is just to skip the build phase while it doesn't work.
        return {
          winner: localGameState.winner,
          roll: localGameState.roll,
          round: localGameState.round,
          turn: localGameState.turn,
          phase: TRADE, // transitions to the next phase, which is trade
          resources: localGameState.resources,
          buildings: localGameState.buildings,
        }


        /*
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
        */

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

      // returns the game state after an attempted trade offer
      function attemptTradeOffer(localGameState, player, nextPlayer, tradeResponse, tradeOffer) {
        // this doesn't work because of compiler errors but it's how it should work
        if(!tradeResponse) {
          return {
            winner: localGameState.winner,
            roll: localGameState.roll,
            round: localGameState.round,
            turn: nextPlayer, // next player assuming trading is the last step
            phase: RESOURCE_GEN, // transitions to the next phase, which is rss generation
            buildings: localGameState.buildings,
            resources: localGameState.resources,
          };
        }
        else {
          const aliceRss = array(UInt, [0, 0, 0, 0]);
          const bobRss = array(UInt, [0, 0, 0, 0]);
          const carlRss = array(UInt, [0, 0, 0, 0]);

          return {
            winner: localGameState.winner,
            roll: localGameState.roll,
            round: localGameState.round,
            turn: nextPlayer, // next player assuming trading is the last step
            phase: RESOURCE_GEN, // transitions to next phase
            buildings: localGameState.buildings,
            resources: array(Array(UInt, RSS_ENUM_SIZE), [aliceRss, bobRss, carlRss])
          };
        }
      }


      // returns true if the trade deal is allowed, false if otherwise

      // ALICE: Dice Roll Phase
      const gameState1 = diceRollPhase(gameState, pALICE);
      letPlayersSeeGameState(gameState1);
      
      // ALICE: Building Phase
      A.only(() => {
        const aBuilding = declassify(interact.placeBuilding());
      });
      A.publish(aBuilding);
      commit();

      const gameState2 = attemptBuildingPhase(gameState1, pALICE, aBuilding);
      letPlayersSeeGameState(gameState2);

      // ALICE: Trade Deal Phase
      A.only(() => {
        const aTrade = declassify(interact.offerTrade());
        interact.log(aTrade);
      });
      A.publish(aTrade);

      const aTradeAllowed =
        !aTrade.skip &&
        isPlayer(aTrade.recievePlayer) &&
        ensurePlayerHasResources(gameState2, pALICE, aTrade.offer) &&
        ensurePlayerHasResources(gameState2, aTrade.recievePlayer, aTrade.payment);
      const bobCanTrade = aTrade.recievePlayer == pBOB;
      const carlCanTrade = aTrade.recievePlayer == pCARL;
      commit();
      
      B.only(() => {
        const _bTradeResponse = aTradeAllowed && bobCanTrade ? interact.recieveTradeOffer({
          offerPlayer: pALICE,
          offer: aTrade.offer,
          payment: aTrade.payment
        }) : false;
        const bTradeResponse = declassify(_bTradeResponse);
      });
      B.publish(bTradeResponse);

      const gameState3B = attemptTradeOffer(
        gameState2,
        pALICE,
        pBOB,
        aTradeAllowed && bobCanTrade ? bTradeResponse : false,
        aTrade);
      commit();

      C.only(() => {
        const _cTradeResponse = aTradeAllowed && carlCanTrade ? interact.recieveTradeOffer({
          offerPlayer: pALICE,
          offer: aTrade.offer,
          payment: aTrade.payment
        }) : false;
        const cTradeResponse = declassify(_cTradeResponse);
      });
      C.publish(cTradeResponse);

      const gameState3C = attemptTradeOffer(
        gameState2, 
        pALICE, 
        pCARL, 
        aTradeAllowed && carlCanTrade ? cTradeResponse : false, 
        aTrade);
      commit();
      
      const gameState3 = bobCanTrade ? gameState3B : gameState3C;
      letPlayersSeeGameState(gameState3);



      // repeat the last four steps with bob

      // repeat again with carl

      // check to see if anyone is a winner (haven't finished yet)
      // probably will just check for a summation of buildings
      A.only(() => {
        const test = "test";
      });
      A.publish(test);
      gameState = gameState3;

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
