import React from 'react';
import TileMap from '../components/TileMap';
import GameInfo from '../components/GameInfo';
import { PlayerResourcesPanel } from '../components/PlayerResources';
import ReactLoading from 'react-loading';

const exports = {};

// Player views must be extended.
// It does not have its own Wrapper view.

exports.GetHand = class extends React.Component {
  render() {
    const { parent, playable, hand } = this.props;
    return (
      <div>
        {hand ? 'It was a draw! Pick again.' : ''}
        <br />
        {!playable ? 'Please wait...' : ''}
        <br />
        <button
          disabled={!playable}
          onClick={() => parent.playHand('ROCK')}
        >Rock</button>
        <button
          disabled={!playable}
          onClick={() => parent.playHand('PAPER')}
        >Paper</button>
        <button
          disabled={!playable}
          onClick={() => parent.playHand('SCISSORS')}
        >Scissors</button>
      </div>
    );
  }
}

exports.WaitingForResults = class extends React.Component {
  render() {
    return (
      <div>
        Waiting for results...
      </div>
    );
  }
}

exports.Done = class extends React.Component {
  render() {
    const { outcome } = this.props;
    return (
      <div>
        Thank you for playing. The outcome of this game was:
        <br />{outcome || 'Unknown'}
      </div>
    );
  }
}

exports.Timeout = class extends React.Component {
  render() {
    return (
      <div>
        There's been a timeout. (Someone took too long.)
      </div>
    );
  }
}

exports.Generating = class extends React.Component {
  render() {
    return (
      <div>
        <h3>Please wait...</h3>
        <ReactLoading type='spin' height='20%' width='20%' className='spinloader' />
        <p>
          The contract is generating the world.
          Please accept any new transactions to continue the process.
      </p>
      </div>
    );
  }
}

exports.MapDisplay = class extends React.Component {
  render() {
    // creates a list of tiles to add
    const tiles = this.props.tiles;
    const resources = this.props.resources;
    const roll = this.props.roll;
    const phase = this.props.phase;
    const turn = this.props.turn;
    const player = this.props.playerNum;

    console.log("Map Display Props:", this.props);

    const instructions = !this.props.bPlayable ? null :
      <div>
        <div>Choose a tile to build on (for 1 ore, 1 wood, 1 brick) or cancel.</div>
        <button onClick={() => {
          this.props.parent.playBuilding({
            skip: true, tile: 0
          })
        }}>
          Cancel
        </button>
      </div>;

    return (
      <div>
        <h1>Map Display</h1>
        <PlayerResourcesPanel resources={resources} roll={roll ?? 0} />
        <GameInfo phase={phase} turn={turn} playerNum={player} instructions={instructions} />
        <div>
          <TileMap tileSize={100} tileData={tiles} />
        </div>
      </div>
    );
  }
}

export default exports;
