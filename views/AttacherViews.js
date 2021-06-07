import React from 'react';
import PlayerViews from './PlayerViews';
import ReactLoading from 'react-loading';
import Enums from '../Enums.json';

const exports = { ...PlayerViews };

exports.Wrapper = class extends React.Component {
  render() {
    const { content } = this.props;

    return (
      <div className="Attacher">
        <div className={"devData"}>
          <p>Attacher</p>
          {this.props.devOutput}
        </div>
        {content}
      </div>
    );
  }
}

exports.Attach = class extends React.Component {
  render() {
    const { parent } = this.props;
    const { ctcInfoStr } = this.state || {};
    return (
      <div>
        Please paste the contract info to attach to:
        <br />
        <textarea spellcheck="false"
          className='ContractInfo'
          onChange={(e) => this.setState({ ctcInfoStr: e.currentTarget.value })}
          placeholder='{}'
        />
        <br />
        <button
          disabled={!ctcInfoStr}
          onClick={() => parent.attach(ctcInfoStr)}
        >Attach</button>
      </div>
    );
  }
}

exports.Attaching = class extends React.Component {
  render() {
    return (
      <>
        <div>
          Attaching to the game contract, please wait...
        </div>
        <ReactLoading type='spin' height='20%' width='20%' className='spinloader' />
      </>
    );
  }
}

exports.AcceptTerms = class extends React.Component {
  render() {
    const { wager, standardUnit, parent } = this.props;
    const { disabled } = this.state || {};
    return (
      <div>
        The terms of the game are:
        <br /> Wager: {wager} {standardUnit}
        <br />
        <button
          disabled={disabled}
          onClick={() => {
            this.setState({ disabled: true });
            parent.termsAccepted();
          }}
        >Accept terms and pay wager</button>
      </div>
    );
  }
}

exports.WaitingForTurn = class extends React.Component {
  render() {
    return (
      <div>
        <p>Waiting for the other player...</p>
        <ReactLoading type='spin' height='20%' width='20%' className='spinloader' />
        <p>Think about which move you want to play.</p>
      </div>
    );
  }
}

export default exports;
