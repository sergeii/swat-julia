interface InterestedInPlayerNameChanged;

/**
 * Implement this method in order to receieve OnPlayerNameChanged signals
 *
 * @param   class'Player' Player
 *          The name changed player
 * @param   string OldName
 *          Previous player name. The current name can be retrieved with a Player.GetName() call
 * @return  void
 */
public function OnPlayerNameChanged(Player Player, string OldName);
