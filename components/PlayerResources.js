import React from 'react';
import Polygon from './Polygon';
import Enums from '../Enums.json';

const PLAYER_COLORS = Enums.PLAYER_COLORS;
const RSS_NAMES = Enums.RESOUCE_NAMES;

let bigToNum = val => { 
  return typeof(val) == 'number' ? val : Number.parseInt(val['_hex']); 
}

/**
 * playerNum - int
 * resources - array(UInt, 4)
 */
class PlayerResources extends React.Component {

  render() {
    const playerNum = this.props.playerNum ?? 0;
    const resources = this.props.resources;

    let text = [];
    for (let i = 0; i < RSS_NAMES.length; i++) {
      text[i] =
        <div className="mediumText">
          {RSS_NAMES[i]}: {bigToNum(resources[i])}
        </div>
    }

    return (
      <div style={{ marginLeft: '8px' }}>
        <span>
          <Polygon n={4} fill={PLAYER_COLORS[playerNum]} size={50} />
        </span>
        {text}
      </div>

    );
  }
}

/**
 * resources - array(array(UInt, 4))
 */
class PlayerResourcesPanel extends React.Component {
  render() {
    let resources = this.props.resources ?? [
      [1, 2, 3, 4], [1, 3, 4, 2], [3, 4, 2, 1]
    ];
    console.log("Rendering the player resources panel: ", resources);
    const roll = bigToNum(this.props.roll);

    return (
      <div className="topRight d-flex">
        <div>
          Current Roll:
          <br /> {roll}
        </div>
        <PlayerResources playerNum={0} resources={resources[0]} />
        <PlayerResources playerNum={1} resources={resources[1]} />
        <PlayerResources playerNum={2} resources={resources[2]} />
      </div>
    );
  }
}

export default PlayerResources;
export { PlayerResourcesPanel };