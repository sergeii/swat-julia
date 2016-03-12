interface InterestedInInternalEventBroadcast;

/**
 * Implement this method in order to receive OnInternalEventBroadcast
 *
 * @param   name Type
 *          Event type
 * @param   string Msg
 *          Optional message
 * @param   class'Player' PlayerOne (optional)
 * @param   class'Player' PlayerTwo (optional)
 *          Participating players
 * @return  void
 */
public function OnInternalEventBroadcast(name Type, optional string Msg, optional Player PlayerOne, optional Player PlayerTwo);
