interface InterestedInPlayerPawnChanged;

/**
 * Implement this method in order to receieve OnPlayerPawnChanged signals
 *
 * @param   class'Player' Player
 *          The player with a new Pawn [Player.GetPawn() or Player.GetPC().Pawm]
 * @return  void
 */
public function OnPlayerPawnChanged(Player Player);
