'reach 0.1';

//#region Player Definitions

const Player =
{
  ...hasRandom,
  getHand: Fun([], UInt),
  seeOutcome: Fun([UInt], Null),
  informTimeout: Fun([], Null),

  // gameplay
  potatoes: UInt,
  ore: UInt,
  wood: UInt,
  bricks: UInt,
  coal: UInt,
};
const Alice = {
  ...Player,
  wager: UInt
};
const Bob = {
  ...Player,
  acceptWager: Fun([UInt], Null)
};

//#endregion

//#region Enums

const [isResource, POTATO, ORE, WOOD, BRICK, COAL] = makeEnum(5);

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

    // code to accept the wager
    const acceptingTheWager = (player) => {
      player.only(() => {
        interact.acceptWager(wager);
      });
      player.pay(wager);
        //.timeout(DEADLINE, () => closeTo(A, informTimeout));
      commit();
    }

    // bob + carl accepts wager
    acceptingTheWager(B);
    acceptingTheWager(C);

    //#endregion

    // alice always wins in this scenario lmao
    A.only(() => {
      const Apotatoes = declassify(interact.potatoes);
    });
    A.publish(Apotatoes);

    transfer(wager * 3).to(A);
    commit();
    exit();
  }
);
