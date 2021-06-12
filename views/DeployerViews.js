import React from 'react';
import PlayerViews from './PlayerViews';
import ReactLoading from 'react-loading';
import Enums from '../Enums.json';
import { ContextConsumer } from '../AppContext';
import TradeModal from '../components/TradeModal';

const exports = { ...PlayerViews };

const sleep = (milliseconds) => new Promise(resolve => setTimeout(resolve, milliseconds));

exports.Wrapper = class extends React.Component {
  render() {
    const { content } = this.props;
    return (
      <div className="Deployer">
        <div className={"devData"}>
          <p>Deployer</p>
        </div>
        {content}
      </div>
    );
  }
}

exports.SetWager = class extends React.Component {
  render() {
    const { parent, defaultWager, standardUnit } = this.props;
    const wager = (this.state || {}).wager || defaultWager;
    return (
      <div>
        <input
          type='number'
          placeholder={defaultWager}
          onChange={(e) => this.setState({ wager: e.currentTarget.value })}
        /> {standardUnit}
        <br />
        <button
          onClick={() => parent.setWager(wager)}
        >Set wager</button>
      </div>
    );
  }
}

exports.Deploy = class extends React.Component {
  render() {
    const { parent, wager, standardUnit } = this.props;
    return (
      <ContextConsumer>
        {appContext => {
          return (
            <div>
              Wager (pay to deploy): <strong>{wager}</strong> {standardUnit}
              <br />
              <button
                onClick={() => parent.deploy()}
              >Deploy</button>
              <TradeModal tPlayable={true} oPlayable={false} />
            </div>
          )
        }}
      </ContextConsumer>
    );
  }
}

exports.Deploying = class extends React.Component {
  render() {
    return (
      <>
        <div>Deploying the game... please wait.</div>
        <ReactLoading type='spin' height='20%' width='20%' className='spinloader' />
      </>
    );
  }
}

exports.WaitingForAttacher = class extends React.Component {
  async copyToClipborad(button) {
    const { ctcInfoStr } = this.props;
    navigator.clipboard.writeText(ctcInfoStr);
    const origInnerHTML = button.innerHTML;
    button.innerHTML = 'Copied!';
    button.disabled = true;
    await sleep(1000);
    button.innerHTML = origInnerHTML;
    button.disabled = false;
  }

  render() {
    const { ctcInfoStr } = this.props;
    return (
      <div>
        <p>Waiting for other players to join...</p>
        <ReactLoading type='spin' height='20%' width='20%' className='spinloader' />
        <br /> Please give them this contract info:
        <pre className='ContractInfo'>
          {ctcInfoStr}
        </pre>
        <button
          onClick={(e) => this.copyToClipborad(e.currentTarget)}
        >Copy to clipboard</button>
      </div>
    )
  }
}

export default exports;
