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

    //@TODO: Remove these seeds because they conflict with the generated ones
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
        if (isPlayer(player)) {
          const playerAdaptedToArray = player - 1;
          return (
            localGameState.resources[playerAdaptedToArray][0] >= resources[0] &&
            localGameState.resources[playerAdaptedToArray][1] >= resources[1] &&
            localGameState.resources[playerAdaptedToArray][2] >= resources[2] &&
            localGameState.resources[playerAdaptedToArray][3] >= resources[3]
          );
        } else {
          return false;
        }
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

          // yeah... right now it's just giving resources to each player
          resources: array(Array(UInt, 4), [
            array(UInt, [
              localGameState.resources[0][0] + 1,
              localGameState.resources[0][1] + 1,
              localGameState.resources[0][2] + 1,
              localGameState.resources[0][3] + 1
            ]),
            array(UInt, [
              localGameState.resources[1][0] + 1,
              localGameState.resources[1][1] + 1,
              localGameState.resources[1][2] + 1,
              localGameState.resources[1][3] + 1
            ]),
            array(UInt, [
              localGameState.resources[2][0] + 1,
              localGameState.resources[2][1] + 1,
              localGameState.resources[2][2] + 1,
              localGameState.resources[2][3] + 1
            ]),
          ])
        };
      }

      // returns the game state when attempting to build a building
      function attemptBuildingPhase(localGameState, player, buildCmd) {

        // returns 3 if there is no building space, otherwise it returns the empty space
        function tileHasBuildingSpace(tile) {
          const result = 3
            - (tile[0] == pNONE ? 1 : 0)
            - (tile[1] == pNONE ? 1 : 0)
            - (tile[2] == pNONE ? 1 : 0);
          return result;
        }

        /*@BUG-186
         * After updating reach on 6/14/2021 at 6:00 PST, the unhandled rejection disappeared,
         * but strange behaviour associated with it continued. 
         * 
         * To demonstrate, run the program as it is now. Click on a tile as player 1, and 
         * click build. After a few smart contract interactions, it should appear as built.
         * Then, redo the process but this time remove all of the "A.interact" calls within
         * this function. Doing the same as before will not result in the same output.
         * 
         * I have noticed that this functionality relies on the "A.interact" being within the
         * if/else statements.
         * 
         * I still recieve an unhandled rejection further down the line, after the build phase.
         * To see it, first compile with the "A.interact" lines uncommented. During the build
         * phase, build a building. Then, during the trade phase, cancel the trade.
         * 
         * Note that for some reason this will not occur when then user opts to "cancel" the
         * building phase (skipping the conditional "A.interact" lines).
         */

        // skips if that's what the player wants to do
        if (buildCmd.skip) {
          A.interact.log("It got within the skip, so it should be returning winner as 2.");
          return {
            winner: localGameState.winner,
            roll: localGameState.roll,
            round: localGameState.round,
            turn: player,
            phase: TRADE, // transitions to the next phase, which is trade
            resources: localGameState.resources,
            buildings: localGameState.buildings,
          };
        }

        // issues the command if that's what the player wants to do
        else if (buildCmd.tile >= 0 && buildCmd.tile < MAP_SIZE) {

          A.interact.log("It got within the second if condition.");
          const buildingSpace = tileHasBuildingSpace(localGameState.buildings[buildCmd.tile]);
          A.interact.log(buildingSpace);
          A.interact.log(MAXIMUM_BUILDINGS_ON_TILE);

          // if the tile to build on has space
          if (buildingSpace < MAXIMUM_BUILDINGS_ON_TILE) {
            A.interact.log("It got within the third if condition.");

            return {
              winner: localGameState.winner,
              roll: localGameState.roll,
              round: localGameState.round,
              turn: player,
              phase: TRADE, // transitions to the next phase, which is trade
              resources: localGameState.resources,
              buildings: localGameState.buildings.set(buildCmd.tile, array(UInt, [
                buildingSpace == 0 ? player : localGameState.buildings[buildCmd.tile][0],
                buildingSpace == 1 ? player : localGameState.buildings[buildCmd.tile][1],
                buildingSpace == 2 ? player : localGameState.buildings[buildCmd.tile][2],
              ]))
            };
          }
        }

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
      }

      function calculateRSSDifference(currentVal, tradePlayer, tradeOffer, examinedPlayer, rssIndex) {
        const result = tradePlayer == examinedPlayer ?
          ((currentVal + tradeOffer.payment[rssIndex]) - tradeOffer.offer[rssIndex]) :
          tradeOffer.recievePlayer == examinedPlayer ?
            ((currentVal + tradeOffer.offer[rssIndex]) - tradeOffer.payment[rssIndex]) : currentVal;
        return result;
      }

      // returns the game state after an attempted trade offer
      function attemptTradeOffer(localGameState, player, nextPlayer, tradeResponse, tradeOffer) {
        B.interact.log(localGameState);
        B.interact.log(tradeOffer);
        B.interact.log(player);

        // this doesn't work because of compiler errors but it's how it should work
        if (!tradeResponse) {
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
          const aliceRss = array(UInt, [
            calculateRSSDifference(localGameState.resources[0][WHEAT], player, tradeOffer, pALICE, WHEAT),
            calculateRSSDifference(localGameState.resources[0][ORE], player, tradeOffer, pALICE, ORE),
            calculateRSSDifference(localGameState.resources[0][WOOD], player, tradeOffer, pALICE, WOOD),
            calculateRSSDifference(localGameState.resources[0][BRICK], player, tradeOffer, pALICE, BRICK),
          ]);
          const bobRss = array(UInt, [
            calculateRSSDifference(localGameState.resources[1][WHEAT], player, tradeOffer, pBOB, WHEAT),
            calculateRSSDifference(localGameState.resources[1][ORE], player, tradeOffer, pBOB, ORE),
            calculateRSSDifference(localGameState.resources[1][WOOD], player, tradeOffer, pBOB, WOOD),
            calculateRSSDifference(localGameState.resources[1][BRICK], player, tradeOffer, pBOB, BRICK),
          ]);
          const carlRss = array(UInt, [
            calculateRSSDifference(localGameState.resources[2][WHEAT], player, tradeOffer, pCARL, WHEAT),
            calculateRSSDifference(localGameState.resources[2][ORE], player, tradeOffer, pCARL, ORE),
            calculateRSSDifference(localGameState.resources[2][WOOD], player, tradeOffer, pCARL, WOOD),
            calculateRSSDifference(localGameState.resources[2][BRICK], player, tradeOffer, pCARL, BRICK),
          ]);

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



      // ALICE: Dice Roll Phase
      A.interact.log("Dice Roll Phase");
      const gameState1 = diceRollPhase(gameState, pALICE);
      letPlayersSeeGameState(gameState1);


      // ALICE: Building Phase
      A.interact.log("Building Phase");
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
      const carlCanTradeA = aTrade.recievePlayer == pCARL;
      commit();

      B.only(() => {
        const _bTradeResponseA = aTradeAllowed && bobCanTrade ? interact.recieveTradeOffer({
          offerPlayer: pALICE,
          offer: aTrade.offer,
          payment: aTrade.payment
        }) : false;
        const bTradeResponseA = declassify(_bTradeResponseA);
      });
      B.publish(bTradeResponseA);

      const aGameState3B = attemptTradeOffer(
        gameState2,
        pALICE, // the person who offered it
        pBOB, // the next player
        aTradeAllowed && bobCanTrade ? bTradeResponseA : false,
        aTrade);
      commit();

      C.only(() => {
        const _cTradeResponseA = aTradeAllowed && carlCanTradeA ? interact.recieveTradeOffer({
          offerPlayer: pALICE,
          offer: aTrade.offer,
          payment: aTrade.payment
        }) : false;
        const cTradeResponseA = declassify(_cTradeResponseA);
      });
      C.publish(cTradeResponseA);

      const aGameState3C = attemptTradeOffer(
        gameState2,
        pALICE,  // the person who offered it
        pBOB, // the next player
        aTradeAllowed && carlCanTradeA ? cTradeResponseA : false,
        aTrade);
      commit();

      const gameState3 = bobCanTrade ? aGameState3B : aGameState3C;
      letPlayersSeeGameState(gameState3);





      // BOB: Dice Roll Phase
      A.interact.log("Dice Roll Phase");
      const gameState4 = diceRollPhase(gameState3, pBOB);
      letPlayersSeeGameState(gameState4);

      // BOB: Building Phase
      B.only(() => {
        const bBuilding = declassify(interact.placeBuilding());
      });
      B.publish(bBuilding);
      commit();
      const gameState5 = attemptBuildingPhase(gameState4, pBOB, bBuilding);
      letPlayersSeeGameState(gameState5);

      // BOB: Trading Phase
      B.only(() => {
        const bTrade = declassify(interact.offerTrade());
        interact.log(bTrade);
      });
      B.publish(bTrade);

      const bTradeAllowed =
        !bTrade.skip &&
        isPlayer(bTrade.recievePlayer) &&
        ensurePlayerHasResources(gameState5, pBOB, bTrade.offer) &&
        ensurePlayerHasResources(gameState5, bTrade.recievePlayer, bTrade.payment);
      const aliceCanTradeB = bTrade.recievePlayer == pALICE;
      const carlCanTradeB = bTrade.recievePlayer == pCARL;
      B.interact.log(bTradeAllowed);
      B.interact.log(aliceCanTradeB);
      B.interact.log(carlCanTradeB);
      commit();

      A.only(() => {
        const _aTradeResponseB = bTradeAllowed && aliceCanTradeB ? interact.recieveTradeOffer({
          offerPlayer: pBOB,
          offer: bTrade.offer,
          payment: aTrade.payment
        }) : false;
        const aTradeResponseB = declassify(_aTradeResponseB);
      });
      A.publish(aTradeResponseB);

      const bGameState6B = attemptTradeOffer(
        gameState5,
        pBOB, // the person who offered it
        pCARL, // the next player
        bTradeAllowed && aliceCanTradeB ? aTradeResponseB : false,
        bTrade);
      commit();

      C.only(() => {
        const _cTradeResponseB = bTradeAllowed && carlCanTradeB ? interact.recieveTradeOffer({
          offerPlayer: pBOB,
          offer: bTrade.offer,
          payment: bTrade.payment
        }) : false;
        const cTradeResponseB = declassify(_cTradeResponseB);
      });
      C.publish(cTradeResponseB);

      const bGameState6C = attemptTradeOffer(
        gameState5,
        pBOB,  // the person who offered it
        pCARL, // the next player
        aTradeAllowed && carlCanTradeB ? cTradeResponseB : false,
        aTrade);
      commit();

      const gameState6 = aliceCanTradeB ? bGameState6B : bGameState6C;
      letPlayersSeeGameState(gameState6);



      // repeat again with carl

      // CARL: Dice Roll Phase
      const gameState7 = diceRollPhase(gameState6, pCARL);
      letPlayersSeeGameState(gameState7);

      // CARL: Building Phase
      C.only(() => {
        const cBuilding = declassify(interact.placeBuilding());
      });
      C.publish(cBuilding);
      commit();
      const gameState8 = attemptBuildingPhase(gameState7, pCARL, cBuilding);
      letPlayersSeeGameState(gameState8);

      // CARL: Trading Phase
      C.only(() => {
        const cTrade = declassify(interact.offerTrade());
        interact.log(cTrade);
      });
      C.publish(cTrade);

      const cTradeAllowed =
        !cTrade.skip &&
        isPlayer(cTrade.recievePlayer) &&
        ensurePlayerHasResources(gameState8, pCARL, cTrade.offer) &&
        ensurePlayerHasResources(gameState8, cTrade.recievePlayer, cTrade.payment);
      const aliceCanTradeC = cTrade.recievePlayer == pALICE;
      const bobCanTradeC = cTrade.recievePlayer == pBOB;
      commit();

      A.only(() => {
        const _aTradeResponseC = cTradeAllowed && aliceCanTradeC ? interact.recieveTradeOffer({
          offerPlayer: pCARL,
          offer: cTrade.offer,
          payment: cTrade.payment
        }) : false;
        const aTradeResponseC = declassify(_aTradeResponseC);
      });
      A.publish(aTradeResponseC);

      const cGameState9A = attemptTradeOffer(
        gameState8,
        pCARL, // the person who offered it
        pALICE, // the next player
        cTradeAllowed && aliceCanTradeB ? aTradeResponseC : false,
        cTrade);
      commit();

      B.only(() => {
        const _bTradeResponseC = cTradeAllowed && bobCanTradeC ? interact.recieveTradeOffer({
          offerPlayer: pCARL,
          offer: cTrade.offer,
          payment: cTrade.payment
        }) : false;
        const bTradeResponseC = declassify(_bTradeResponseC);
      });
      B.publish(bTradeResponseC);

      const cGameState9B = attemptTradeOffer(
        gameState8,
        pCARL,  // the person who offered it
        pALICE, // the next player
        cTradeAllowed && bobCanTradeC ? bTradeResponseC : false,
        cTrade);
      commit();

      const gameState9 = aliceCanTradeC ? cGameState9A : cGameState9B;
      letPlayersSeeGameState(gameState9);





      // check to see if anyone is a winner (haven't finished yet)
      // probably will just check for a summation of buildings
      const gameState10 = {
        winner: gameState9.resources[0][0] >= 12 ?
          pALICE : gameState9.resources[1][0] >= 12 ?
            pBOB : gameState9.resources[0][0] >= 12 ?
              pCARL : pNONE,
        roll: gameState9.roll,
        round: gameState9.round,
        turn: gameState9.turn,
        phase: gameState9.phase, // transitions to the next phase, which is trade
        resources: gameState9.resources,
        buildings: gameState9.buildings,
      }
      A.publish();

      gameState = gameState10;

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
