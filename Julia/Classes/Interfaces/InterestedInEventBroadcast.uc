interface InterestedInEventBroadcast;

/**
 * The implemented method is called to signal about a game event broadcast (Say, SwatKill, Caption, etc)
 * Return false to mark the event hidden, i.e. to stop it from appearing in game
 *
 * @param   Player
 *          Player instance of the sender (or None)
 * @param   Sender
 *          The original sender instance
 * @param   Type
 *          Event type (Say, TeamSay,...)
 * @param   Msg
 *          Optional message (Player1\tPlayer2\t9mm SMG, hi all,...)
 * @param   Receiver (optional)
 *          Optional receiver
 * @param   bHidden (optional)
 *          Indicate whether the event has been set to ignored by broadcast handler
 */
public function bool OnEventBroadcast(Player Player, Actor Sender, name Type, out string Msg, optional PlayerController Receiver, optional bool bHidden);
