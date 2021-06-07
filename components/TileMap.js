import React from 'react';
import Polygon from './Polygon';
import Enums from '../Enums.json';

// potato, ore, wood, brick
const RSS_COLORS = Enums.RESOURCE_COLORS;
const MAP_SIZE = 7;

let bigToNum = val => { return Number.parseInt(val['_hex']); }

/**
 * tile: obj{resource: int, roll: int}
 * tileSize: int
 */
class Tile extends React.Component {
  render() {
    const tileSize = this.props.tileSize;
    const tileData = this.props.tile;

    const divSpacer = { marginBottom: tileSize / 2 };

    let [resource, roll] = [Math.floor(Math.random() * (1000)) % 4, 0];
    if (tileData != null) {
      resource = tileData.rss;
      roll = bigToNum(tileData.roll);
    }
    else { console.log("No tile data was found, so random images were requested.") }

    return (
      <div style={divSpacer}>
        <Polygon 
          n={6} 
          size={tileSize} 
          fill={RSS_COLORS[resource]} 
          onClick={() => {
            // this does, in fact, work
            console.log("THIS TILE WAS CLICKED");
          }}
        />
        <div style={{position: 'relative', top: `-${tileSize}px`}}>
          {roll}
        </div>
      </div>
    );
  }
}

/**
 * tileData: obj
 * tileSize: int
 */
class TileMap extends React.Component {

  render() {
    const tileSize = this.props.tileSize;
    const tileData = this.props.tileData;

    const TopSpacer = <div style={{ marginTop: (tileSize / 0.95) + "px" }} />;
    const TileComponents = {}

    for (let i = 0; i < MAP_SIZE; i++) {
      TileComponents[i] =
        <Tile
          tile={tileData != null ? tileData[i] : null}
          tileSize={tileSize}
        />
    }

    return (
      <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gridGap: -tileSize * 2 }}>
        <div>
          {TopSpacer}
          {TileComponents[0]}
          {TileComponents[1]}
        </div>
        <div>
          {TileComponents[2]}
          {TileComponents[3]}
          {TileComponents[4]}
        </div>
        <div>
          {TopSpacer}
          {TileComponents[5]}
          {TileComponents[6]}
        </div>
      </div>
    );
  }
}

export default TileMap;