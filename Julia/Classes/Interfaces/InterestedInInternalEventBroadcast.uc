interface InterestedInInternalEventBroadcast;

/**
 * Implement this method in order to receive OnInternalEventBroadcast
 *
 * @param   Type
 *          Event type
 * @param   Msg
 *          Optional message
 * @param   PlayerOne, PlayerTwo (optional)
 *          Participating players
 */
public function OnInternalEventBroadcast(name Type, optional string Msg, optional Player PlayerOne, optional Player PlayerTwo);
