import React from 'react';
import Enums from '../Enums.json';

class GameInfo extends React.Component {

  render() {

    const phase = this.props.phase ?? 0;
    const turn = this.props.turn ?? 0;

    const panelStyle = {
      position: 'fixed',
      bottom: '0px',
      right: '0px',
      width: '250px',
      height: '150px',
      borderRadius: '16px',
      background: '#243a4b'
    }

    const textStyle = {
      fontSize: '0.5em'
    };

    return (
      <div style={panelStyle}>
        <p style={textStyle}><b>Phase:</b> {Enums.GAME_PHASES[phase]} for {Enums.PLAYER_NAMES[turn]}</p>
        <p style={textStyle}>{Enums.PHASE_DESCRIPTIONS[phase]}</p>
      </div>
    );
  }
}

export default GameInfo;