import React, { useState, useEffect } from 'react';
import ReactModal from 'react-modal';
import { ContextConsumer } from '../AppContext';
import PlayerResources from './PlayerResources';
import Enums from '../Enums.json';

let bigToNum = val => {
  return typeof (val) == 'number' ? val : Number.parseInt(val['_hex']);
}

/*
 * resources (from gameState)
 * offer (trade offer)
*/
let TradeModal = props => {
  const [isOpen, setIsOpen] = useState(false);
  const [pWheat, setPriceWheat] = useState(0);
  const [pOre, setPriceOre] = useState(0);
  const [pWood, setPriceWood] = useState(0);
  const [pBrick, setPriceBrick] = useState(0);

  const offer = props.offer;
  let resources = props.resources ?? [
    [1, 2, 3, 4], [1, 3, 4, 2], [3, 4, 2, 1]
  ];
  console.log(resources);
  const tPlayable = props.tPlayable;
  const oPlayable = props.oPlayable;

  const recievedOffer = offer != null && oPlayable;



  return (
    <ContextConsumer>
      {appContext => {
        return (
          <div>
            <div>
              {recievedOffer ? "Click to open the incoming trade offer." : "Another player recieved a trade offer."}
            </div>
            <div>
              {tPlayable ?
                <button onClick={() => { setIsOpen(true); }}>Offer Trade</button>
                : recievedOffer ?
                  <button onClick={() => { setIsOpen(true); }}>Open Offer</button>
                  : <></>
              }
            </div>
            <ReactModal
              isOpen={isOpen}
              shouldCloseOnEsc={true}
              preventScroll={true}
              contentLabel={"Tile Information"}
            >
              <h4>Offer a Trade</h4>
              <div>Offer a trade to a specific player.</div>
              <div style={{ display: 'flex', marginTop: '25px' }}>
                {() => {
                  for (let i = 0; i < 3; i++) {
                    <div style={{ margin: 'auto' }} >
                      <PlayerResources playerNum={i} resources={resources[i]} />
                      {tPlayable ?
                        <button disabled={
                          resources[i][0] < pWheat ||
                          resources[i][1] < pOre ||
                          resources[i][2] < pWood ||
                          resources[i][3] < pBrick
                        }>
                          Send Offer to {Enums.PLAYER_NAMES[i]}
                        </button> : <></>
                      }
                    </div>
                  }
                }}
              </div>
              {tPlayable ?
                <>
                  <div style={{ display: 'flex', marginTop: '25px' }}>
                    <TradeInput rssName={Enums.RESOUCE_NAMES[0]} rssChangeCallback={setPriceWheat} />
                    <TradeInput rssName={Enums.RESOUCE_NAMES[1]} rssChangeCallback={setPriceOre} />
                    <TradeInput rssName={Enums.RESOUCE_NAMES[2]} rssChangeCallback={setPriceWood} />
                    <TradeInput rssName={Enums.RESOUCE_NAMES[3]} rssChangeCallback={setPriceBrick} />
                  </div>
                  <button onClick={() => { setIsOpen(false); }}>Cancel</button>
                </> : recievedOffer ?
                  <>
                    <div>
                      <h4>You recieved a trade offer.</h4>
                      <div style={{ display: 'flex' }}>
                        <div>
                          <div>Recieve:</div>
                          <div>{Enums.RESOUCE_NAMES[0]}: {bigToNum(offer.offer[0])}</div>
                          <div>{Enums.RESOUCE_NAMES[1]}: {bigToNum(offer.offer[1])}</div>
                          <div>{Enums.RESOUCE_NAMES[2]}: {bigToNum(offer.offer[2])}</div>
                          <div>{Enums.RESOUCE_NAMES[3]}: {bigToNum(offer.offer[3])}</div>
                        </div>
                        <div>
                          <div>Pay:</div>
                          <div>{Enums.RESOUCE_NAMES[0]}: {bigToNum(offer.payment[0])}</div>
                          <div>{Enums.RESOUCE_NAMES[1]}: {bigToNum(offer.payment[1])}</div>
                          <div>{Enums.RESOUCE_NAMES[2]}: {bigToNum(offer.payment[2])}</div>
                          <div>{Enums.RESOUCE_NAMES[3]}: {bigToNum(offer.payment[3])}</div>
                        </div>
                      </div>
                      <div style={{ display: 'flex' }}>
                        <button onClick={() => {
                          // say accept
                          setIsOpen(false);
                        }}>Accept</button>
                        <button onClick={() => {
                          // say cancel
                          setIsOpen(false);
                        }}>Cancel</button>
                      </div>
                    </div>
                  </> : <></>
              }

            </ReactModal>
          </div>
        );
      }}
    </ContextConsumer>
  );
}


/**
 * rssValue
 */
let TradeInput = props => {

  const [rssValue, setRssValue] = useState(0);
  useEffect(() => {
    props?.rssChangeCallback(rssValue);
  }, [rssValue]);

  const midStyle = { width: '100%', textAlign: 'center' }

  return (
    <div style={{ width: '200px', height: '300px', margin: 'auto' }}>
      <div style={midStyle}>{props.rssName}</div>
      <div style={midStyle}>{rssValue}</div>
      <div style={{ display: 'flex' }}>
        <button
          style={{ width: "50%" }}
          onClick={() => { setRssValue(rssValue + 1); }}
        >
          +
        </button>
        <button
          style={{ width: "50%" }}
          onClick={() => { if (rssValue > 0) setRssValue(rssValue - 1); }}
        >
          -
        </button>
      </div>
    </div>
  );
}

export default TradeModal;