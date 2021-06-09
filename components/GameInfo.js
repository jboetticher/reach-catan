import React from 'react';
import Enums from '../Enums.json';
import { ContextConsumer } from '../AppContext';

class GameInfo extends React.Component {

  render() {

    const phase = this.props.phase ?? 0;
    const turn = this.props.turn ?? 0;
    const instructions = this.props.instructions;

    const panelStyle = {
      position: 'fixed',
      bottom: '0px',
      right: '0px',
      width: '250px',
      height: '200px',
      borderRadius: '16px',
      background: '#243a4b'
    }

    const textStyle = {
      fontSize: '0.5em'
    };

    return (
      <ContextConsumer>
        {appContext => {
          return (
            <div style={panelStyle}>
              <p style={textStyle}><b>Phase:</b> {Enums.GAME_PHASES[phase]} for {Enums.PLAYER_NAMES[turn]}</p>
              <p style={textStyle}>{instructions ?? Enums.PHASE_DESCRIPTIONS[phase]}</p>
              <p style={textStyle}>You are {Enums.PLAYER_NAMES[appContext.playerNum]}.</p>
            </div>
          );
        }
        }
      </ContextConsumer>
    );
  }
}

export default GameInfo;