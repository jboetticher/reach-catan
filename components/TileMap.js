import React from 'react';
import Polygon from './Polygon';
import Enums from '../Enums.json';
import ReactModal from 'react-modal';
import { ContextConsumer } from '../AppContext';

// potato, ore, wood, brick
const RSS_COLORS = Enums.RESOURCE_COLORS;
const RSS_NAMES = Enums.RESOUCE_NAMES;
const PLAYER_NAMES = Enums.PLAYER_NAMES;
const MAP_SIZE = 7;

let bigToNum = val => { return Number.parseInt(val['_hex']); }

/**
 * tile: obj{resource: int, roll: int}
 * tileSize: int
 */
class Tile extends React.Component {
  constructor() {
    super();
    this.state = { isOpen: false };
  }

  render() {
    const tileSize = this.props.tileSize;
    const tileData = this.props.tile;
    const buildings = this.props.buildings;
    const bPlayable = this.props.bPlayable && 
      buildings != null && 
      !(bigToNum(buildings[0]) != 0 && bigToNum(buildings[1]) != 0 && bigToNum(buildings[2]) != 0);
    const playBuilding = this.props.playBuilding;

    const divSpacer = { marginBottom: tileSize / 2 };

    let [resource, roll] = [Math.floor(Math.random() * (1000)) % 4, 0];
    if (tileData != null) {
      resource = tileData.rss;
      roll = bigToNum(tileData.roll);
    }
    else { console.log("No tile data was found, so random images were requested.") }

    function BuildingInfo(props) {
      let playerNumArr = [
        bigToNum(buildings?.[0]) - 1,
        bigToNum(buildings?.[1]) - 1,
        bigToNum(buildings?.[2]) - 1
      ];
      let playerNameArr = [];
      for (let i = 0; i < playerNumArr.length; i++) {
        if (playerNumArr[i] >= 0) playerNameArr[i] = PLAYER_NAMES[playerNumArr[i]];
        else playerNameArr[i] = "No building.";
      }
    
      return (
        <>
          <div>Building Slot 1: {playerNameArr[0]}</div>
          <div>Building Slot 2: {playerNameArr[1]}</div>
          <div>Building Slot 3: {playerNameArr[2]}</div>
        </>
      );
    }
    

    return (
      <ContextConsumer>
        {appContext => {
          return (
            <div style={divSpacer}>
              <Polygon
                n={6}
                size={tileSize}
                fill={RSS_COLORS[resource]}
                onClick={() => {
                  console.log("TileData:", tileData);
                  this.setState({ isOpen: true });
                  //this.state.isOpen = true;
                }}
              />
              <div style={{ position: 'relative', top: `-${tileSize}px` }}>
                {roll}
              </div>
              <ReactModal
                isOpen={this.state.isOpen}
                shouldCloseOnEsc={true}
                preventScroll={true}
                contentLabel={"Tile Information"}
              >
                <div>Resource: {RSS_NAMES[resource]}</div>
                <div>Roll: {roll}</div>
                {buildings != null ?
                  <BuildingInfo />
                  : <></>
                }
                <div style={{ display: 'flex' }} >
                  <button onClick={() => { this.setState({ isOpen: false }); }}>
                    Close
                </button>
                {bPlayable ?
                  <button onClick={() => {
                    playBuilding({
                      skip: false, tile: this.props.tileNum
                    });
                  }}>
                    Build
                </button> : <></>
                }
                </div>
              </ReactModal>
            </div>
          );
        }}
      </ContextConsumer>
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
    const buildings = this.props.buildings;
    const bPlayable = this.props.bPlayable ?? false;

    const TopSpacer = <div style={{ marginTop: (tileSize / 0.95) + "px" }} />;
    const TileComponents = {}

    for (let i = 0; i < MAP_SIZE; i++) {
      TileComponents[i] =
        <Tile
          tile={tileData != null ? tileData[i] : null}
          buildings={tileData != null ? tileData[i] : null}
          tileSize={tileSize}
          buildings={buildings != null ? buildings[i] : null}
          bPlayable={bPlayable}
          playBuilding={this.props.playBuilding}
          tileNum={i}
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