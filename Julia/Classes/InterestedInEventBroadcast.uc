interface InterestedInEventBroadcast;

/**
 * The implemented method is called to signal about a game event broadcast (Say, SwatKill, Caption, etc)
 *
 * @param   class'Player' Player
 *          Player instance of the sender (or None)
 * @param   class'Actor' Sender
 *          The original sender instance
 * @param   name Type
 *          Event type (Say, TeamSay,...)
 * @param   string Msg
 *          Optional message (Player1\tPlayer2\t9mm SMG, hi all,...)
 * @param   class'PlayerController' Receiver (optional)
 *          Optional receiver
 * @param   bool bHidden (optional)
 *          Indicate whether the event has been set to ignored by broadcast handler
 * @return  bool
 *          Return false to mark the event hidden, i.e. to stop it from appearing in game
 */
public function bool OnEventBroadcast(Player Player, Actor Sender, name Type, out string Msg, optional PlayerController Receiver, optional bool bHidden);
