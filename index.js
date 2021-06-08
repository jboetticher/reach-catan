import React from 'react';
import AppViews from './views/AppViews';
import DeployerViews from './views/DeployerViews';
import AttacherViews from './views/AttacherViews';
import { renderDOM, renderView } from './views/render';
import './index.css';
import * as backend from './build/index.main.mjs';
import * as reach from '@reach-sh/stdlib/ETH';
import { ContextProvider } from './AppContext';

//#region Enums

const RESOURCES = { 'POTATO': 0, 'ORE': 1, 'WOOD': 2, 'BRICK': 3 };
const PLAYERS = { 'NONE': 0, 'ALICE': 1, 'BOB': 2, 'CARL': 3 };

//#endregion

const { standardUnit } = reach;
const defaults = { defaultFundAmt: '10', defaultWager: '3', standardUnit };

class App extends React.Component {
  constructor(props) {
    super(props);
    this.state = { view: 'ConnectAccount', ...defaults };
  }
  async componentDidMount() {
    const acc = await reach.getDefaultAccount();
    const balAtomic = await reach.balanceOf(acc);
    const bal = reach.formatCurrency(balAtomic, 4);
    this.setState({ acc, bal });
    try {
      const faucet = await reach.getFaucet();
      this.setState({ view: 'FundAccount', faucet });
    } catch (e) {
      this.setState({ view: 'DeployerOrAttacher' });
    }
  }
  async fundAccount(fundAmount) {
    await reach.transfer(this.state.faucet, this.state.acc, reach.parseCurrency(fundAmount));
    this.setState({ view: 'DeployerOrAttacher' });
  }
  async skipFundAccount() { this.setState({ view: 'DeployerOrAttacher' }); }
  selectDeployer() { this.setState({ view: 'Wrapper', ContentView: DeployerAlice }); }
  selectAttacher() { this.setState({ view: 'Wrapper', ContentView: AttacherBob }); }
  selectAttacherTwo() { this.setState({ view: 'Wrapper', ContentView: AttacherCarl }); }
  render() { return renderView(this, AppViews); }
}



//#region Participant Classes

// Each class represents a participant as defined in index.rsh
// Deployer is Alice
// Attacher(s) are Bob and Carl

class Player extends React.Component {
  random() { return reach.hasRandom.random(); }
  informTimeout() {
    console.log("Timeout is being informed.");
    this.setState({ view: 'Timeout' });
  }
  getSeed() {
    let seed = Math.floor(Math.random() * (10000000));
    this.setState({ view: 'Generating' });
    console.log("Seed is being requested.", seed);
    return seed;
  }
  seeMap(tileArray) {
    console.log("Map data is being sent.", tileArray);
    this.setState({
      view: 'MapDisplay',
      tiles: tileArray,
      resources: [
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0]
      ]
    });
  }
  seeGameState(data) {
    console.log("Game state data is being sent.", data);
    this.setState({
      resources: data['resources'],
      roll: data['roll'],
      winner: data['winner'],
      phase: data['phase'],
      turn: data['turn'] - 1, // in the frontend, alice = 0, not 1
      buildings: data['buildings']
    });
  }
  async placeBuilding() {
    const buildPromise = await new Promise(resolveBuildP => {
      this.setState({ bPlayable: true, resolveBuildP: resolveBuildP });
    });

    // i guess you could change the state here if you wanted to
    this.setState({ bPlayable: false });

    /*
    let building = {
      tile: Math.floor(Math.random() * 1000 % 6),
      skip: false
    };
    */

    console.log("Requesting a place building", buildPromise);
    return buildPromise;
  }
  playBuilding(play) {
    console.log("Play building:", this.state)
    this.state.resolveBuildP(play);
  }
  placeBuildingCallback(buildingSuccessful) {
    console.log("Was the placing successful?", buildingSuccessful);
  }

  // this is an example of player input
  // it's asyncronous!
  // not required for the game, its from rock paper scizzors
  async getHand() { // Fun([], UInt)
    const hand = await new Promise(resolveHandP => {
      this.setState({ view: 'GetHand', bPlayable: true, resolveHandP });
    });
    this.setState({ view: 'WaitingForResults', hand });
    return 3;
  }
}

class DeployerAlice extends Player {
  constructor(props) {
    super(props);
    this.state = { view: 'SetWager' };
  }

  // the deployment of the backend & start of the instance
  async deploy() {
    console.log("Starting deployment.");
    console.log("Player: " + this.state.playerNum);

    const ctc = this.props.acc.deploy(backend);
    this.setState({ view: 'Deploying', ctc });

    // preliminary setting of values
    this.wager = reach.parseCurrency(this.state.wager); // UInt
    this.testaroonie = 4;

    backend.Alice(ctc, this);
    const ctcInfoStr = JSON.stringify(await ctc.getInfo(), null, 2);
    this.setState({ view: 'WaitingForAttacher', ctcInfoStr });
  }

  setWager(wager) {
    console.log("Wager being set.", wager);
    this.setState({ view: 'Deploy', wager });
  }

  render() {
    return (
      <ContextProvider value={{ playerNum: 0 }}>
        {renderView(this, DeployerViews)}
      </ContextProvider>
    );
  }
}

class AttacherBob extends Player {
  constructor(props) {
    super(props);
    this.state = { view: 'Attach' };
  }

  // attaching to the specified backend
  attach(ctcInfoStr) {
    console.log("Attaching...");

    const ctc = this.props.acc.attach(backend, JSON.parse(ctcInfoStr));
    this.setState({ view: 'Attaching' });
    backend.Bob(ctc, this);
  }

  async acceptWager(wagerAtomic) { // Fun([UInt], Null)
    console.log("Wager price accepted.", wagerAtomic);

    const wager = reach.formatCurrency(wagerAtomic, 4);
    return await new Promise(resolveAcceptedP => {
      this.setState({ view: 'AcceptTerms', wager, resolveAcceptedP });
    });
  }

  termsAccepted() {
    console.log("Terms accepted");

    this.state.resolveAcceptedP();
    this.setState({ view: 'WaitingForTurn' });
  }

  render() {
    return (
      <ContextProvider value={{ playerNum: 1 }}>
        {renderView(this, AttacherViews)}
      </ContextProvider>
    );
  }
}

class AttacherCarl extends AttacherBob {
  constructor(props) {
    super(props);
    this.state = { view: 'Attach', playerNum: 2 };
  }

  // attaching to the specified backend
  attach(ctcInfoStr) {
    console.log("Attaching...");

    const ctc = this.props.acc.attach(backend, JSON.parse(ctcInfoStr));
    this.setState({ view: 'Attaching' });
    backend.Carl(ctc, this);
  }

  render() {
    return (
      <ContextProvider value={{ playerNum: 2 }}>
        {renderView(this, AttacherViews)}
      </ContextProvider>
    );
  }
}

//#endregion

renderDOM(<App />);
