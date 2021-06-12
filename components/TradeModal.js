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
  const [oWheat, setOfferWheat] = useState(0);
  const [oOre, setOfferOre] = useState(0);
  const [oWood, setOfferWood] = useState(0);
  const [oBrick, setOfferBrick] = useState(0);

  const offer = props.offer;
  let resources = props.resources ?? [
    [1, 2, 3, 4], [1, 3, 4, 2], [3, 4, 2, 1]
  ];
  console.log(resources);
  const tPlayable = props.tPlayable;
  const oPlayable = props.oPlayable;

  const recievedOffer = offer != null && oPlayable;

  console.log(props);
  const three = [0, 1, 2];


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
              <h3>Offer a Trade</h3>
              <div>Offer a trade to a specific player.</div>
              <div style={{ display: 'flex', marginTop: '25px' }}>
                {three.map(i => (
                  <div style={{ margin: 'auto' }} >
                    <PlayerResources playerNum={i} resources={resources[i]} />
                    {tPlayable && appContext.playerNum != i ?
                      <button disabled={
                        resources[i][0] < pWheat ||
                        resources[i][1] < pOre ||
                        resources[i][2] < pWood ||
                        resources[i][3] < pBrick ||
                        resources[appContext.playerNum][0] < oWheat ||
                        resources[appContext.playerNum][1] < oOre ||
                        resources[appContext.playerNum][2] < oWood ||
                        resources[appContext.playerNum][3] < oBrick
                      } onClick={() => {
                        props.playOfferTrade({
                          skip: false,
                          recievePlayer: i + 1,
                          offer: [oWheat, oOre, oWood, oBrick],
                          payment: [pWheat, pOre, pWood, pBrick]
                        });
                      }}>
                        Send Offer to {Enums.PLAYER_NAMES[i]}
                      </button> : <></>
                    }
                  </div>
                ))
                }
              </div>
              {tPlayable ?
                <>
                  <div>What you get:</div>
                  <div style={{ display: 'flex', marginTop: '25px' }}>
                    <TradeInput rssName={Enums.RESOUCE_NAMES[0]} rssChangeCallback={setPriceWheat} />
                    <TradeInput rssName={Enums.RESOUCE_NAMES[1]} rssChangeCallback={setPriceOre} />
                    <TradeInput rssName={Enums.RESOUCE_NAMES[2]} rssChangeCallback={setPriceWood} />
                    <TradeInput rssName={Enums.RESOUCE_NAMES[3]} rssChangeCallback={setPriceBrick} />
                  </div>
                  <div>What you pay:</div>
                  <div style={{ display: 'flex', marginTop: '25px' }}>
                    <TradeInput rssName={Enums.RESOUCE_NAMES[0]} rssChangeCallback={setOfferWheat} />
                    <TradeInput rssName={Enums.RESOUCE_NAMES[1]} rssChangeCallback={setOfferOre} />
                    <TradeInput rssName={Enums.RESOUCE_NAMES[2]} rssChangeCallback={setOfferWood} />
                    <TradeInput rssName={Enums.RESOUCE_NAMES[3]} rssChangeCallback={setOfferBrick} />
                  </div>
                  <button onClick={() => {
                    props.playOfferTrade({
                      skip: true,
                      recievePlayer: 0,
                      offer: [0, 0, 0, 0],
                      payment: [0, 0, 0, 0]
                    });
                    setIsOpen(false);
                  }}>
                    Cancel Trading Phase
                  </button>
                </> : recievedOffer ?
                  <>
                    <div>
                      <h3>You recieved a trade offer.</h3>
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
                          props.playOfferReply(true);
                          setIsOpen(false);
                        }}>Accept</button>
                        <button onClick={() => {
                          props.playOfferReply(false);
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
    <div style={{ width: '200px', height: '100px', margin: 'auto' }}>
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