interface InterestedInPlayerNameChanged;

/**
 * Implement this method in order to receive OnPlayerNameChanged signals
 *
 * @param   Player
 *          The name changed player
 * @param   OldName
 *          Previous player name. The current name can be retrieved with a Player.GetName() call
 */
public function OnPlayerNameChanged(Player Player, string OldName);
