class Core extends SwatGame.SwatMutator
 implements InterestedInMissionEnded,
            InterestedInCommandDispatched;

import enum eSwatGameState from SwatGame.SwatGUIConfig;

/**
 * Package version
 * @type string
 */
const VERSION = "2.3.1";

/**
 * Fixed tick rate (seconds)
 * @type float
 */
const DELTA = 0.1;

/**
 * Reference to the cache handler instance
 * @type class'Cache'
 */
var protected Cache Cache;

/**
 * Reference to the locale handler instance
 * @type class'Locale'
 */
var protected Locale Locale;

/**
 * Reference to the broadcast handler instance
 * @type class'BroadcastHandler'
 */
var protected BroadcastHandler BroadcastHandler;

/**
 * Reference to the user command dispatcher instance
 * @type class'Dispatcher'
 */
var protected Dispatcher Dispatcher;

/**
 * Reference to the Server instance
 * @type Server
 */
var protected Server Server;

/**
 * List of the OnEventBroadcast signal listeners
 *
 * @type array<interface'InterestedInEventBroadcast'>
 */
var protected array<InterestedInEventBroadcast> InterestedInEventBroadcast;

/**
 * List of the OnInternalEventBroadcast signal listeners
 *
 * @type array<interface'InterestedInInternalEventBroadcast'>
 */
var protected array<InterestedInInternalEventBroadcast> InterestedInInternalEventBroadcast;

/**
 * List of the OnGameStateChanged signal listeners
 *
 * @type array<interface'InterestedInGameStateChanged'>
 */
var protected array<InterestedInGameStateChanged> InterestedInGameStateChanged;

/**
 * List of the OnMissionStarted signal listeners
 *
 * @type array<interface'InterestedInMissionStarted'>
 */
var protected array<InterestedInMissionStarted> InterestedInMissionStarted;

/**
 * List of the OnMissionEnded signal listeners
 *
 * @type array<interface'InterestedInMissionEnded'>
 */
var protected array<InterestedInMissionEnded> InterestedInMissionEnded;

/**
 * List of the OnPlayerConnected signal listeners
 *
 * @type array<interface'InterestedInPlayerConnected'>
 */
var protected array<InterestedInPlayerConnected> InterestedInPlayerConnected;

/**
 * List of the OnPlayerDisonnected signal listeners
 *
 * @type array<interface'InterestedInPlayerDisonnected'>
 */
var protected array<InterestedInPlayerDisconnected> InterestedInPlayerDisconnected;

/**
 * List of the OnPlayerLoaded signal listeners
 *
 * @type array<interface'InterestedInPlayerLoaded'>
 */
var protected array<InterestedInPlayerLoaded> InterestedInPlayerLoaded;

/**
 * List of the OnPlayerAdminLogged signal listeners
 *
 * @type array<interface'InterestedInPlayerAdminLogged'>
 */
var protected array<InterestedInPlayerAdminLogged> InterestedInPlayerAdminLogged;

/**
 * List of the OnPlayerNameChanged signal listeners
 *
 * @type array<interface'InterestedInPlayerNameChanged'>
 */
var protected array<InterestedInPlayerNameChanged> InterestedInPlayerNameChanged;

/**
 * List of the OnPlayerTeamSwitched signal listeners
 *
 * @type array<interface'InterestedInPlayerTeamSwitched'>
 */
var protected array<InterestedInPlayerTeamSwitched> InterestedInPlayerTeamSwitched;

/**
 * List of the OnPlayerVIPSet signal listeners
 *
 * @type array<interface'InterestedInPlayerVIPSet'>
 */
var protected array<InterestedInPlayerVIPSet> InterestedInPlayerVIPSet;

/**
 * List of the OnPlayerPawnChanged signal listeners
 *
 * @type array<interface'InterestedInPlayerPawnChanged'>
 */
var protected array<InterestedInPlayerPawnChanged> InterestedInPlayerPawnChanged;

/**
 * List of the OnPlayerVoiceChanged signal listeners
 *
 * @type array<interface'InterestedInPlayerVoiceChanged'>
 */
var protected array<InterestedInPlayerVoiceChanged> InterestedInPlayerVoiceChanged;

/**
 * Indicate whether the Core instance is enabled
 * @type bool
 */
var config bool Enabled;

/**
 * Don't let the class to be initialized under certain circumstances
 *
 * @return  void
 */
public function PreBeginPlay()
{
    Super.PreBeginPlay();
    self.Disable('Tick');

    if (Level.NetMode == NM_ListenServer || Level.NetMode == NM_DedicatedServer)
    {
        if (Level.Game != None && SwatGameInfo(Level.Game) != None)
        {
            if (self.Enabled)
            {
                return;
            }
        }
    }
    self.Destroy();
}

/**
 * Initialize the core instance
 *
 * @return  void
 */
public function BeginPlay()
{
    Super.BeginPlay();

    self.InitCache();
    self.InitLocale();
    self.InitBroadcastHandler();
    self.InitDispatcher();
    self.InitServer();

    self.RegisterInterestedInMissionEnded(self);
    // Register the !version command
    self.Dispatcher.Bind(
        "version", self, self.Locale.Translate("CoreVersionUsage"), self.Locale.Translate("CoreVersionDescription")
    );

    log("Julia (version " $ class'Core'.const.VERSION $ ") has been initialized");
}

/**
 * Initialize Cache instance
 *
 * @return void
 */
protected function InitCache()
{
    self.Cache = Spawn(class'Cache');
}

/**
 * Initialize Locale instance
 *
 * @return void
 */
protected function InitLocale()
{
    self.Locale = Spawn(class'Locale');
}

/**
 * Initialize BroadcastHandler instance
 *
 * @return  void
 */
protected function InitBroadcastHandler()
{
    self.BroadcastHandler = Spawn(class'BroadcastHandler');
    self.BroadcastHandler.Init(self);
}

/**
 * Initialize Dispatcher instance
 *
 * @return  void
 */
protected function InitDispatcher()
{
    self.Dispatcher = Spawn(class'Dispatcher');
    self.Dispatcher.Init(self);
}

/**
 * Initialize Server instance
 *
 * @return  void
 */
protected function InitServer()
{
    self.Server = Spawn(class'Server');
    self.Server.Init(self);
}

/**
 * Store cache live (memory) data onto disk upon a round end
 *
 * @return  void
 */
public function OnMissionEnded()
{
    self.Cache.Commit();
}

/**
 * Reply with package version details
 *
 * @see InterestedInCommandDispatched.OnCommandDispatched
 */
public function OnCommandDispatched(Dispatcher Dispatcher, string Name, string Id, array<string> Args, Player Player)
{
    local string Response;

    switch (Name)
    {
        case "version":
            Response = class'Utils.StringUtils'.static.Format(
                "\"Julia\" mod by Serge (%1)\\nhttp://github.com/sergeii/swat-julia",
                class'Core'.const.VERSION
            );
            break;
        default:
            return;
    }
    Dispatcher.Respond(Id, Response);
}

/**
 * Return the cache instance
 *
 * @return  class'Cache'
 */
public function Cache GetCache()
{
    return self.Cache;
}

/**
 * Return the Locale instance
 *
 * @return  class'Locale'
 */
public function Locale GetLocale()
{
    return self.Locale;
}

/**
 * Return the BroadcastHandler instance
 *
 * @return  class'BroadcastHandler'
 */
public function BroadcastHandler GetBroadcastHandler()
{
    return self.BroadcastHandler;
}

/**
 * Return the Dispatcher instance
 *
 * @return  class'Dispatcher'
 */
public function Dispatcher GetDispatcher()
{
    return self.Dispatcher;
}

/**
 * Return the Server instance
 *
 * @return  class'Server'
 */
public function Server GetServer()
{
    return self.Server;
}

/**
 * Return the list of player controllers
 *
 * @return  array<class'Player'>
 */
public function array<Player> GetPlayers()
{
    return self.Server.GetPlayers();
}

/**
 * Register an InterestedInEventBroadcast instance with the OnEventBroadcast event signal handler
 *
 * @param   interface'InterestedInEventBroadcast' Interested
 * @return  void
 */
public function RegisterInterestedInEventBroadcast(InterestedInEventBroadcast Interested)
{
    self.InterestedInEventBroadcast[self.InterestedInEventBroadcast.Length] = Interested;
}

/**
 * Unregister an InterestedInEventBroadcast instance from the OnEventBroadcast event signal handler
 *
 * @param   interface'InterestedInEventBroadcast' Uninterested
 * @return  void
 */
public function UnregisterInterestedInEventBroadcast(InterestedInEventBroadcast Uninterested)
{
    local int i;

    for (i = self.InterestedInEventBroadcast.Length-1; i >= 0 ; i--)
    {
        if (self.InterestedInEventBroadcast[i] == Uninterested)
        {
            self.InterestedInEventBroadcast.Remove(i, 1);
        }
    }
}

/**
 * Trigger an OnEventBroadcast event signal
 * Return false if any of receivers prohibit the event from appearing in game
 *
 * Receivers are also allowed to alter the final event message
 *
 * @param   class'Player' Player
 *          Player instance of the sender
 * @param   class'Actor' Sender
 *          Reference to the original sender actor
 * @param   name Type
 *          Event type
 * @param   string Msg (out)
 *          Optional event message
 * @param   class'PlayerController' Receiver (optional)
 *          Optional event target
 * @return  bool
 */
public function bool TriggerOnEventBroadcast(Player Player, Actor Sender, name Type, out string Msg, optional PlayerController Receiver)
{
    local int i;
    local bool bHidden;

    log("OnEventBroadcast triggered: " $ self.InterestedInEventBroadcast.Length $ " interested (" $ Type $ ")");

    for (i = 0; i < self.InterestedInEventBroadcast.Length; i++)
    {
        // If any of the other listeners mark the event hidden, this will be its final status
        // Also let the other listeners know the current status of the event
        if (!self.InterestedInEventBroadcast[i].OnEventBroadcast(Player, Sender, Type, Msg, Receiver, bHidden))
        {
            bHidden = true;
        }
    }
    return !bHidden;
}

/**
 * Register an InterestedInInternalEventBroadcast instance with the OnInternalEventBroadcast event signal handler
 *
 * @param   interface'InterestedInInternalEventBroadcast' Interested
 * @return  void
 */
public function RegisterInterestedInInternalEventBroadcast(InterestedInInternalEventBroadcast Interested)
{
    self.InterestedInInternalEventBroadcast[self.InterestedInInternalEventBroadcast.Length] = Interested;
}

/**
 * Unregister an InterestedInInternalEventBroadcast instance from the OnInternalEventBroadcast event signal handler
 *
 * @param   interface'InterestedInInternalEventBroadcast' Uninterested
 * @return  void
 */
public function UnregisterInterestedInInternalEventBroadcast(InterestedInInternalEventBroadcast Uninterested)
{
    local int i;

    for (i = self.InterestedInInternalEventBroadcast.Length-1; i >= 0 ; i--)
    {
        if (self.InterestedInInternalEventBroadcast[i] == Uninterested)
        {
            self.InterestedInInternalEventBroadcast.Remove(i, 1);
        }
    }
}

/**
 * Trigger an OnInternalEventBroadcast signal
 *
 * @param   name Type
 *          Event type
 * @param   string Message (optional)
 *          Optional event message
 * @param   class'Player' PlayerOne (optional)
 * @param   class'Player' PlayerTwo (optional)
 *          Reference to participating players
 * @return  void
 */

public function TriggerOnInternalEventBroadcast(name Type, optional string Msg, optional Player PlayerOne, optional Player PlayerTwo)
{
    local int i;

    log("OnInternalEventBroadcast triggered: " $ self.InterestedInInternalEventBroadcast.Length $ " interested (" $ Type $ ")");

    for (i = 0; i < self.InterestedInInternalEventBroadcast.Length; i++)
    {
        self.InterestedInInternalEventBroadcast[i].OnInternalEventBroadcast(Type, Msg, PlayerOne, PlayerTwo);
    }
}

/**
 * Register an InterestedInGameStateChanged instance with the OnGameStateChanged event signal handler
 *
 * @param   interface'InterestedInGameStateChanged' Interested
 * @return  void
 */
public function RegisterInterestedInGameStateChanged(InterestedInGameStateChanged Interested)
{
    self.InterestedInGameStateChanged[self.InterestedInGameStateChanged.Length] = Interested;
}

/**
 * Unregister an InterestedInGameStateChanged instance from the OnGameStateChanged event signal handler
 *
 * @param   interface'InterestedInGameStateChanged' Uninterested
 * @return  void
 */
public function UnregisterInterestedInGameStateChanged(InterestedInGameStateChanged Uninterested)
{
    local int i;

    for (i = self.InterestedInGameStateChanged.Length-1; i >= 0 ; i--)
    {
        if (self.InterestedInGameStateChanged[i] == Uninterested)
        {
            self.InterestedInGameStateChanged.Remove(i, 1);
        }
    }
}

/**
 * Trigger an OnGameStateChanged signal
 *
 * @param   enum'ESwatGameState' OldState
 * @param   enum'ESwatGameState' NewState
 * @return  void
 */
public function TriggerOnGameStateChanged(eSwatGameState OldState, eSwatGameState NewState)
{
    local int i;

    log("OnGameStateChanged triggered: " $ self.InterestedInGameStateChanged.Length $ " interested");

    for (i = 0; i < self.InterestedInGameStateChanged.Length; i++)
    {
        self.InterestedInGameStateChanged[i].OnGameStateChanged(OldState, NewState);
    }
}

/**
 * Register an InterestedInMissionStarted instance with the OnMissionStarted event signal handler
 *
 * @param   interface'InterestedInMissionStarted' Interested
 * @return  void
 */
public function RegisterInterestedInMissionStarted(InterestedInMissionStarted Interested)
{
    self.InterestedInMissionStarted[self.InterestedInMissionStarted.Length] = Interested;
}

/**
 * Unregister an InterestedInMissionStarted instance from the OnMissionStarted event signal handler
 *
 * @param   interface'InterestedInMissionStarted' Uninterested
 * @return  void
 */
public function UnregisterInterestedInMissionStarted(InterestedInMissionStarted Uninterested)
{
    local int i;

    for (i = self.InterestedInMissionStarted.Length-1; i >= 0 ; i--)
    {
        if (self.InterestedInMissionStarted[i] == Uninterested)
        {
            self.InterestedInMissionStarted.Remove(i, 1);
        }
    }
}

/**
 * Trigger an OnMissionStarted signal
 *
 * @return  void
 */
public function TriggerOnMissionStarted()
{
    local int i;

    log("OnMissionStarted triggered: " $ self.InterestedInMissionStarted.Length $ " interested");

    for (i = 0; i < self.InterestedInMissionStarted.Length; i++)
    {
        self.InterestedInMissionStarted[i].OnMissionStarted();
    }
}

/**
 * Register an InterestedInMissionEnded instance with the OnMissionEnded event signal handler
 *
 * @param   interface'InterestedInMissionEnded' Interested
 * @return  void
 */
public function RegisterInterestedInMissionEnded(InterestedInMissionEnded Interested)
{
    self.InterestedInMissionEnded[self.InterestedInMissionEnded.Length] = Interested;
}

/**
 * Unregister an InterestedInMissionEnded instance from the OnMissionEnded event signal handler
 *
 * @param   interface'InterestedInMissionEnded' Uninterested
 * @return  void
 */
public function UnregisterInterestedInMissionEnded(InterestedInMissionEnded Uninterested)
{
    local int i;

    for (i = self.InterestedInMissionEnded.Length-1; i >= 0 ; i--)
    {
        if (self.InterestedInMissionEnded[i] == Uninterested)
        {
            self.InterestedInMissionEnded.Remove(i, 1);
        }
    }
}

/**
 * Trigger an OnMissionEnded signal
 *
 * @return  void
 */
public function TriggerOnMissionEnded()
{
    local int i;

    log("OnMissionEnded triggered: " $ self.InterestedInMissionEnded.Length $ " interested");

    for (i = 0; i < self.InterestedInMissionEnded.Length; i++)
    {
        self.InterestedInMissionEnded[i].OnMissionEnded();
    }
}

/**
 * Register an InterestedInPlayerConnected instance with the OnPlayerConnected event signal handler
 *
 * @param   interface'InterestedInPlayerConnected' Interested
 * @return  void
 */
public function RegisterInterestedInPlayerConnected(InterestedInPlayerConnected Interested)
{
    self.InterestedInPlayerConnected[self.InterestedInPlayerConnected.Length] = Interested;
}

/**
 * Unregister an InterestedInPlayerConnected instance from the OnPlayerConnected event signal handler
 *
 * @param   interface'InterestedInPlayerConnected' Uninterested
 * @return  void
 */
public function UnregisterInterestedInPlayerConnected(InterestedInPlayerConnected Uninterested)
{
    local int i;

    for (i = self.InterestedInPlayerConnected.Length-1; i >= 0 ; i--)
    {
        if (self.InterestedInPlayerConnected[i] == Uninterested)
        {
            self.InterestedInPlayerConnected.Remove(i, 1);
        }
    }
}

/**
 * Notify the OnPlayerConnected event listeners
 *
 * @param   class'Player' Player
 *          Reference to the player controller of the connected player
 * @return  void
 */
public function TriggerOnPlayerConnected(Player Player)
{
    local int i;

    log("OnPlayerConnected triggered: " $ self.InterestedInPlayerConnected.Length $ " interested");

    for (i = 0; i < self.InterestedInPlayerConnected.Length; i++)
    {
        self.InterestedInPlayerConnected[i].OnPlayerConnected(Player);
    }
}

/**
 * Register an InterestedInPlayerDisconnected instance with the OnPlayerDisconnected event signal handler
 *
 * @param   interface'InterestedInPlayerDisconnected' Interested
 * @return  void
 */
public function RegisterInterestedInPlayerDisconnected(InterestedInPlayerDisconnected Interested)
{
    self.InterestedInPlayerDisconnected[self.InterestedInPlayerDisconnected.Length] = Interested;
}

/**
 * Unregister an InterestedInPlayerDisconnected instance from the OnPlayerDisconnected event signal handler
 *
 * @param   interface'InterestedInPlayerDisconnected' Uninterested
 * @return  void
 */
public function UnregisterInterestedInPlayerDisconnected(InterestedInPlayerDisconnected Uninterested)
{
    local int i;

    for (i = self.InterestedInPlayerDisconnected.Length-1; i >= 0 ; i--)
    {
        if (self.InterestedInPlayerDisconnected[i] == Uninterested)
        {
            self.InterestedInPlayerDisconnected.Remove(i, 1);
        }
    }
}

/**
 * Notify the OnPlayerDisconnected event listeners
 *
 * @param   class'Player' Player
 *          Reference to the player controller of the disconnected player
 * @return  void
 */
public function TriggerOnPlayerDisconnected(Player Player)
{
    local int i;

    log("OnPlayerDisconnected triggered: " $ self.InterestedInPlayerDisconnected.Length $ " interested");

    for (i = 0; i < self.InterestedInPlayerDisconnected.Length; i++)
    {
        self.InterestedInPlayerDisconnected[i].OnPlayerDisconnected(Player);
    }
}

/**
 * Register an InterestedInPlayerLoaded instance with the OnPlayerLoaded event signal handler
 *
 * @param   interface'InterestedInPlayerLoaded' Interested
 * @return  void
 */
public function RegisterInterestedInPlayerLoaded(InterestedInPlayerLoaded Interested)
{
    self.InterestedInPlayerLoaded[self.InterestedInPlayerLoaded.Length] = Interested;
}

/**
 * Unregister an InterestedInPlayerLoaded instance from the OnPlayerLoaded event signal handler
 *
 * @param   interface'InterestedInPlayerLoaded' Uninterested
 * @return  void
 */
public function UnregisterInterestedInPlayerLoaded(InterestedInPlayerLoaded Uninterested)
{
    local int i;

    for (i = self.InterestedInPlayerLoaded.Length-1; i >= 0 ; i--)
    {
        if (self.InterestedInPlayerLoaded[i] == Uninterested)
        {
            self.InterestedInPlayerLoaded.Remove(i, 1);
        }
    }
}

/**
 * Trigger an OnPlayerLoaded signal
 *
 * @param   class'Player' Player
 *          Reference to the player controller of the loaded player
 * @return  void
 */
public function TriggerOnPlayerLoaded(Player Player)
{
    local int i;

    log("OnPlayerLoaded triggered: " $ self.InterestedInPlayerLoaded.Length $ " interested");

    for (i = 0; i < self.InterestedInPlayerLoaded.Length; i++)
    {
        self.InterestedInPlayerLoaded[i].OnPlayerLoaded(Player);
    }
}

/**
 * Register an InterestedInPlayerAdminLogged instance with the OnPlayerAdminLogged event signal handler
 *
 * @param   interface'InterestedInPlayerAdminLogged' Interested
 * @return  void
 */
public function RegisterInterestedInPlayerAdminLogged(InterestedInPlayerAdminLogged Interested)
{
    self.InterestedInPlayerAdminLogged[self.InterestedInPlayerAdminLogged.Length] = Interested;
}

/**
 * Unregister an InterestedInPlayerAdminLogged instance from the OnPlayerAdminLogged event signal handler
 *
 * @param   interface'InterestedInPlayerAdminLogged' Uninterested
 * @return  void
 */
public function UnregisterInterestedInPlayerAdminLogged(InterestedInPlayerAdminLogged Uninterested)
{
    local int i;

    for (i = self.InterestedInPlayerAdminLogged.Length-1; i >= 0 ; i--)
    {
        if (self.InterestedInPlayerAdminLogged[i] == Uninterested)
        {
            self.InterestedInPlayerAdminLogged.Remove(i, 1);
        }
    }
}

/**
 * Trigger an OnPlayerAdminLogged signal
 *
 * @param   class'Player' Player
 *          Reference to the player controller of the logged in player
 * @return  void
 */
public function TriggerOnPlayerAdminLogged(Player Player)
{
    local int i;

    log("OnPlayerAdminLogged triggered: " $ self.InterestedInPlayerAdminLogged.Length $ " interested");

    for (i = 0; i < self.InterestedInPlayerAdminLogged.Length; i++)
    {
        self.InterestedInPlayerAdminLogged[i].OnPlayerAdminLogged(Player);
    }
}

/**
 * Register an InterestedInPlayerNameChanged instance with the OnPlayerNameChanged event signal handler
 *
 * @param   interface'InterestedInPlayerNameChanged' Interested
 * @return  void
 */
public function RegisterInterestedInPlayerNameChanged(InterestedInPlayerNameChanged Interested)
{
    self.InterestedInPlayerNameChanged[self.InterestedInPlayerNameChanged.Length] = Interested;
}

/**
 * Unregister an InterestedInPlayerNameChanged instance from the OnPlayerNameChanged event signal handler
 *
 * @param   interface'InterestedInPlayerNameChanged' Uninterested
 * @return  void
 */
public function UnregisterInterestedInPlayerNameChanged(InterestedInPlayerNameChanged Uninterested)
{
    local int i;

    for (i = self.InterestedInPlayerNameChanged.Length-1; i >= 0 ; i--)
    {
        if (self.InterestedInPlayerNameChanged[i] == Uninterested)
        {
            self.InterestedInPlayerNameChanged.Remove(i, 1);
        }
    }
}

/**
 * Trigger a OnPlayerNameChanged signal
 *
 * @param   class'Player' Player
 *          Reference to the player controller instance
 * @param   string OldName
 *          Previous player name
 * @return  void
 */
public function TriggerOnPlayerNameChanged(Player Player, string OldName)
{
    local int i;

    log("OnPlayerNameChanged triggered: " $ self.InterestedInPlayerNameChanged.Length $ " interested");

    for (i = 0; i < self.InterestedInPlayerNameChanged.Length; i++)
    {
        self.InterestedInPlayerNameChanged[i].OnPlayerNameChanged(Player, OldName);
    }
}

/**
 * Register an InterestedInPlayerTeamSwitched instance with the OnPlayerTeamSwitched event signal handler
 *
 * @param   interface'InterestedInPlayerTeamSwitched' Interested
 * @return  void
 */
public function RegisterInterestedInPlayerTeamSwitched(InterestedInPlayerTeamSwitched Interested)
{
    self.InterestedInPlayerTeamSwitched[self.InterestedInPlayerTeamSwitched.Length] = Interested;
}

/**
 * Unregister an InterestedInPlayerTeamSwitched instance from the OnPlayerTeamSwitched event signal handler
 *
 * @param   interface'InterestedInPlayerTeamSwitched' Uninterested
 * @return  void
 */
public function UnregisterInterestedInPlayerTeamSwitched(InterestedInPlayerTeamSwitched Uninterested)
{
    local int i;

    for (i = self.InterestedInPlayerTeamSwitched.Length-1; i >= 0 ; i--)
    {
        if (self.InterestedInPlayerTeamSwitched[i] == Uninterested)
        {
            self.InterestedInPlayerTeamSwitched.Remove(i, 1);
        }
    }
}

/**
 * Trigger an OnPlayerTeamSwitched signal
 *
 * @param   class'Player' Player
 *          Reference to the player controller instance
 * @return  void
 */
public function TriggerOnPlayerTeamSwitched(Player Player)
{
    local int i;

    log("OnPlayerTeamSwitched triggered: " $ self.InterestedInPlayerTeamSwitched.Length $ " interested");

    for (i = 0; i < self.InterestedInPlayerTeamSwitched.Length; i++)
    {
        self.InterestedInPlayerTeamSwitched[i].OnPlayerTeamSwitched(Player);
    }
}

/**
 * Register an InterestedInPlayerVIPSet instance with the OnPlayerVIPSet event signal handler
 *
 * @param   interface'InterestedInPlayerVIPSet' Interested
 * @return  void
 */
public function RegisterInterestedInPlayerVIPSet(InterestedInPlayerVIPSet Interested)
{
    self.InterestedInPlayerVIPSet[self.InterestedInPlayerVIPSet.Length] = Interested;
}

/**
 * Unregister an InterestedInPlayerVIPSet instance from the OnPlayerVIPSet event signal handler
 *
 * @param   interface'InterestedInPlayerVIPSet' Uninterested
 * @return  void
 */
public function UnregisterInterestedInPlayerVIPSet(InterestedInPlayerVIPSet Uninterested)
{
    local int i;

    for (i = self.InterestedInPlayerVIPSet.Length-1; i >= 0 ; i--)
    {
        if (self.InterestedInPlayerVIPSet[i] == Uninterested)
        {
            self.InterestedInPlayerVIPSet.Remove(i, 1);
        }
    }
}

/**
 * Trigger an OnPlayerVIPSet signal
 *
 * @param   class'Player' Player
 *          Reference to the player controller instance
 * @return  void
 */
public function TriggerOnPlayerVIPSet(Player Player)
{
    local int i;

    log("OnPlayerVIPSet triggered: " $ self.InterestedInPlayerVIPSet.Length $ " interested");

    for (i = 0; i < self.InterestedInPlayerVIPSet.Length; i++)
    {
        self.InterestedInPlayerVIPSet[i].OnPlayerVIPSet(Player);
    }
}

/**
 * Register an InterestedInPlayerPawnChanged instance with the OnPlayerPawnChanged event signal handler
 *
 * @param   interface'InterestedInPlayerPawnChanged' Interested
 * @return  void
 */
public function RegisterInterestedInPlayerPawnChanged(InterestedInPlayerPawnChanged Interested)
{
    self.InterestedInPlayerPawnChanged[self.InterestedInPlayerPawnChanged.Length] = Interested;
}

/**
 * Unregister an InterestedInPlayerPawnChanged instance from the OnPlayerPawnChanged event signal handler
 *
 * @param   interface'InterestedInPlayerPawnChanged' Uninterested
 * @return  void
 */
public function UnregisterInterestedInPlayerPawnChanged(InterestedInPlayerPawnChanged Uninterested)
{
    local int i;

    for (i = self.InterestedInPlayerPawnChanged.Length-1; i >= 0 ; i--)
    {
        if (self.InterestedInPlayerPawnChanged[i] == Uninterested)
        {
            self.InterestedInPlayerPawnChanged.Remove(i, 1);
        }
    }
}

/**
 * Trigger an OnPlayerPawnSpawned signal
 *
 * @param   class'Player' Player
 *          Reference to the player controller instance
 * @return  void
 */
public function TriggerOnPlayerPawnChanged(Player Player)
{
    local int i;

    log("OnPlayerPawnChanged triggered: " $ self.InterestedInPlayerPawnChanged.Length $ " interested");

    for (i = 0; i < self.InterestedInPlayerPawnChanged.Length; i++)
    {
        self.InterestedInPlayerPawnChanged[i].OnPlayerPawnChanged(Player);
    }
}

/**
 * Register an InterestedInPlayerVoiceChanged instance with the OnPlayerVoiceChanged event signal handler
 *
 * @param   interface'InterestedInPlayerVoiceChanged' Interested
 * @return  void
 */
public function RegisterInterestedInPlayerVoiceChanged(InterestedInPlayerVoiceChanged Interested)
{
    self.InterestedInPlayerVoiceChanged[self.InterestedInPlayerVoiceChanged.Length] = Interested;
}

/**
 * Unregister an InterestedInPlayerVoiceChanged instance from the OnPlayerVoiceChanged event signal handler
 *
 * @param   interface'InterestedInPlayerVoiceChanged' Uninterested
 * @return  void
 */
public function UnregisterInterestedInPlayerVoiceChanged(InterestedInPlayerVoiceChanged Uninterested)
{
    local int i;

    for (i = self.InterestedInPlayerVoiceChanged.Length-1; i >= 0 ; i--)
    {
        if (self.InterestedInPlayerVoiceChanged[i] == Uninterested)
        {
            self.InterestedInPlayerVoiceChanged.Remove(i, 1);
        }
    }
}

/**
 * Trigger an OnPlayerVoiceChanged signal
 *
 * @param   class'Player' Player
 *          Reference to the player controller instance
 * @return  void
 */
public function TriggerOnPlayerVoiceChanged(Player Player)
{
    local int i;

    log("OnPlayerVoiceChanged triggered: " $ self.InterestedInPlayerVoiceChanged.Length $ " interested");

    for (i = 0; i < self.InterestedInPlayerVoiceChanged.Length; i++)
    {
        self.InterestedInPlayerVoiceChanged[i].OnPlayerVoiceChanged(Player);
    }
}

event Destroyed()
{
    self.InterestedInEventBroadcast.Remove(0, self.InterestedInEventBroadcast.Length);
    self.InterestedInInternalEventBroadcast.Remove(0, self.InterestedInInternalEventBroadcast.Length);
    self.InterestedInGameStateChanged.Remove(0, self.InterestedInGameStateChanged.Length);
    self.InterestedInMissionStarted.Remove(0, self.InterestedInMissionStarted.Length);
    self.InterestedInMissionEnded.Remove(0, self.InterestedInMissionEnded.Length);
    self.InterestedInPlayerConnected.Remove(0, self.InterestedInPlayerConnected.Length);
    self.InterestedInPlayerDisconnected.Remove(0, self.InterestedInPlayerDisconnected.Length);
    self.InterestedInPlayerLoaded.Remove(0, self.InterestedInPlayerLoaded.Length);
    self.InterestedInPlayerAdminLogged.Remove(0, self.InterestedInPlayerAdminLogged.Length);
    self.InterestedInPlayerNameChanged.Remove(0, self.InterestedInPlayerNameChanged.Length);
    self.InterestedInPlayerTeamSwitched.Remove(0, self.InterestedInPlayerTeamSwitched.Length);
    self.InterestedInPlayerVIPSet.Remove(0, self.InterestedInPlayerVIPSet.Length);
    self.InterestedInPlayerPawnChanged.Remove(0, self.InterestedInPlayerPawnChanged.Length);
    self.InterestedInPlayerVoiceChanged.Remove(0, self.InterestedInPlayerVoiceChanged.Length);

    if (self.Cache != None)
    {
        self.Cache.Destroy();
        self.Cache = None;
    }

    if (self.Locale != None)
    {
        self.Locale.Destroy();
        self.Locale = None;
    }

    if (self.BroadcastHandler != None)
    {
        self.BroadcastHandler.Destroy();
        self.BroadcastHandler = None;
    }

    if (self.Dispatcher != None)
    {
        self.Dispatcher.Destroy();
        self.Dispatcher = None;
    }

    if (self.Server != None)
    {
        self.Server.Destroy();
        self.Server = None;
    }

    Super.Destroyed();
}
