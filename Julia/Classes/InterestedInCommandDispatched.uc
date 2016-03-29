interface InterestedInCommandDispatched;

/**
 * Implement this public method as a part of the bind/dispatch Dispatcher API
 *
 * @param   class'Dispatcher' Dispatcher
 *          Reference to the dispatcher
 * @param   string Name
 *          Name the command has been bound with (e.g. "version") (lowercase)
 * @param   string Id
 *          Dispatched command unique id
 * @param   array<string> Args
 *          User provided arguments (e.g. whois 1.2.3.4)
 * @param   class'Player' Player
 *          Owner of the dispatched command
 */
public function OnCommandDispatched(Dispatcher Dispatcher, string Name, string Id, array<string> Args, Player Player);
