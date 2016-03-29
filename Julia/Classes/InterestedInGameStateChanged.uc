interface InterestedInGameStateChanged;

import enum eSwatGameState from SwatGame.SwatGUIConfig;

/**
 * Implement this method in order to receive OnGameStateChanged signals
 *
 * @param   enum'eSwatGameState' OldState
 *          Previous game state
 * @param   enum'eSwatGameState' NewState
 *          Current game state
 */
public function OnGameStateChanged(eSwatGameState OldState, eSwatGameState NewState);
