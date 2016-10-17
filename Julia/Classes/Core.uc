class Core extends SwatGame.SwatMutator
 implements InterestedInMissionEnded,
            InterestedInCommandDispatched;

import enum eSwatGameState from SwatGame.SwatGUIConfig;

/**
 * Package version
 */
const VERSION = "3.0-dev";

/**
 * Fixed tick rate (seconds)
 */
const DELTA = 0.5;


var Cache Cache;
var Locale Locale;
var BroadcastHandler BroadcastHandler;
var Dispatcher Dispatcher;
var Server Server;

var array<Extension> BuiltinExtensions;
var array<InterestedInEventBroadcast> InterestedInEventBroadcast;
var array<InterestedInInternalEventBroadcast> InterestedInInternalEventBroadcast;
var array<InterestedInGameStateChanged> InterestedInGameStateChanged;
var array<InterestedInMissionStarted> InterestedInMissionStarted;
var array<InterestedInMissionEnded> InterestedInMissionEnded;
var array<InterestedInPlayerConnected> InterestedInPlayerConnected;
var array<InterestedInPlayerDisconnected> InterestedInPlayerDisconnected;
var array<InterestedInPlayerLoaded> InterestedInPlayerLoaded;
var array<InterestedInPlayerAdminLogged> InterestedInPlayerAdminLogged;
var array<InterestedInPlayerNameChanged> InterestedInPlayerNameChanged;
var array<InterestedInPlayerTeamSwitched> InterestedInPlayerTeamSwitched;
var array<InterestedInPlayerVIPSet> InterestedInPlayerVIPSet;
var array<InterestedInPlayerPawnChanged> InterestedInPlayerPawnChanged;
var array<InterestedInPlayerVoiceChanged> InterestedInPlayerVoiceChanged;

var config bool Enabled;

/**
 * Don't let the class to be initialized under certain circumstances
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
 */
public function BeginPlay()
{
    Super.BeginPlay();

    self.Cache = Spawn(class'Cache');
    self.BroadcastHandler = Spawn(class'BroadcastHandler');
    self.BroadcastHandler.Init(self);
    self.Locale = Spawn(class'Locale');
    self.Dispatcher = Spawn(class'Dispatcher');
    self.Dispatcher.Init(self);
    self.Server = Spawn(class'Server');
    self.Server.Init(self);

    self.RegisterInterestedInMissionEnded(self);
    // Register the !version command
    self.Dispatcher.Bind(
        "version", self, self.Locale.Translate("CoreVersionUsage"), self.Locale.Translate("CoreVersionDescription")
    );

    // Init builtin extensions
    InitExtension(Spawn(class'Admin'));
    InitExtension(Spawn(class'Chatbot'));
    InitExtension(Spawn(class'Tracker'));
    InitExtension(Spawn(class'Whois'));
    InitExtension(Spawn(class'Stats'));
    InitExtension(Spawn(class'VIP'));
    InitExtension(Spawn(class'COOP'));

    log("Julia (version " $ class'Core'.const.VERSION $ ") has been initialized");
}

function InitExtension(Extension Extension)
{
    BuiltinExtensions[BuiltinExtensions.Length] = Extension;
}

/**
 * Store cache live (memory) data onto disk upon a round end
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

public function RegisterInterestedInEventBroadcast(InterestedInEventBroadcast Interested)
{
    self.InterestedInEventBroadcast[self.InterestedInEventBroadcast.Length] = Interested;
}

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

public function RegisterInterestedInInternalEventBroadcast(InterestedInInternalEventBroadcast Interested)
{
    self.InterestedInInternalEventBroadcast[self.InterestedInInternalEventBroadcast.Length] = Interested;
}

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

public function TriggerOnInternalEventBroadcast(name Type, optional string Msg, optional Player PlayerOne, optional Player PlayerTwo)
{
    local int i;

    log("OnInternalEventBroadcast triggered: " $ self.InterestedInInternalEventBroadcast.Length $ " interested (" $ Type $ ")");

    for (i = 0; i < self.InterestedInInternalEventBroadcast.Length; i++)
    {
        self.InterestedInInternalEventBroadcast[i].OnInternalEventBroadcast(Type, Msg, PlayerOne, PlayerTwo);
    }
}

public function RegisterInterestedInGameStateChanged(InterestedInGameStateChanged Interested)
{
    self.InterestedInGameStateChanged[self.InterestedInGameStateChanged.Length] = Interested;
}

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

public function TriggerOnGameStateChanged(eSwatGameState OldState, eSwatGameState NewState)
{
    local int i;

    log("OnGameStateChanged triggered: " $ self.InterestedInGameStateChanged.Length $ " interested");

    for (i = 0; i < self.InterestedInGameStateChanged.Length; i++)
    {
        self.InterestedInGameStateChanged[i].OnGameStateChanged(OldState, NewState);
    }
}

public function RegisterInterestedInMissionStarted(InterestedInMissionStarted Interested)
{
    self.InterestedInMissionStarted[self.InterestedInMissionStarted.Length] = Interested;
}

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

public function TriggerOnMissionStarted()
{
    local int i;

    log("OnMissionStarted triggered: " $ self.InterestedInMissionStarted.Length $ " interested");

    for (i = 0; i < self.InterestedInMissionStarted.Length; i++)
    {
        self.InterestedInMissionStarted[i].OnMissionStarted();
    }
}

public function RegisterInterestedInMissionEnded(InterestedInMissionEnded Interested)
{
    self.InterestedInMissionEnded[self.InterestedInMissionEnded.Length] = Interested;
}

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

public function TriggerOnMissionEnded()
{
    local int i;

    log("OnMissionEnded triggered: " $ self.InterestedInMissionEnded.Length $ " interested");

    for (i = 0; i < self.InterestedInMissionEnded.Length; i++)
    {
        self.InterestedInMissionEnded[i].OnMissionEnded();
    }
}

public function RegisterInterestedInPlayerConnected(InterestedInPlayerConnected Interested)
{
    self.InterestedInPlayerConnected[self.InterestedInPlayerConnected.Length] = Interested;
}

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

public function TriggerOnPlayerConnected(Player Player)
{
    local int i;

    log("OnPlayerConnected triggered: " $ self.InterestedInPlayerConnected.Length $ " interested");

    for (i = 0; i < self.InterestedInPlayerConnected.Length; i++)
    {
        self.InterestedInPlayerConnected[i].OnPlayerConnected(Player);
    }
}

public function RegisterInterestedInPlayerDisconnected(InterestedInPlayerDisconnected Interested)
{
    self.InterestedInPlayerDisconnected[self.InterestedInPlayerDisconnected.Length] = Interested;
}

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

public function TriggerOnPlayerDisconnected(Player Player)
{
    local int i;

    log("OnPlayerDisconnected triggered: " $ self.InterestedInPlayerDisconnected.Length $ " interested");

    for (i = 0; i < self.InterestedInPlayerDisconnected.Length; i++)
    {
        self.InterestedInPlayerDisconnected[i].OnPlayerDisconnected(Player);
    }
}

public function RegisterInterestedInPlayerLoaded(InterestedInPlayerLoaded Interested)
{
    self.InterestedInPlayerLoaded[self.InterestedInPlayerLoaded.Length] = Interested;
}

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

public function TriggerOnPlayerLoaded(Player Player)
{
    local int i;

    log("OnPlayerLoaded triggered: " $ self.InterestedInPlayerLoaded.Length $ " interested");

    for (i = 0; i < self.InterestedInPlayerLoaded.Length; i++)
    {
        self.InterestedInPlayerLoaded[i].OnPlayerLoaded(Player);
    }
}

public function RegisterInterestedInPlayerAdminLogged(InterestedInPlayerAdminLogged Interested)
{
    self.InterestedInPlayerAdminLogged[self.InterestedInPlayerAdminLogged.Length] = Interested;
}

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

public function TriggerOnPlayerAdminLogged(Player Player)
{
    local int i;

    log("OnPlayerAdminLogged triggered: " $ self.InterestedInPlayerAdminLogged.Length $ " interested");

    for (i = 0; i < self.InterestedInPlayerAdminLogged.Length; i++)
    {
        self.InterestedInPlayerAdminLogged[i].OnPlayerAdminLogged(Player);
    }
}

public function RegisterInterestedInPlayerNameChanged(InterestedInPlayerNameChanged Interested)
{
    self.InterestedInPlayerNameChanged[self.InterestedInPlayerNameChanged.Length] = Interested;
}

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

public function TriggerOnPlayerNameChanged(Player Player, string OldName)
{
    local int i;

    log("OnPlayerNameChanged triggered: " $ self.InterestedInPlayerNameChanged.Length $ " interested");

    for (i = 0; i < self.InterestedInPlayerNameChanged.Length; i++)
    {
        self.InterestedInPlayerNameChanged[i].OnPlayerNameChanged(Player, OldName);
    }
}

public function RegisterInterestedInPlayerTeamSwitched(InterestedInPlayerTeamSwitched Interested)
{
    self.InterestedInPlayerTeamSwitched[self.InterestedInPlayerTeamSwitched.Length] = Interested;
}

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

public function TriggerOnPlayerTeamSwitched(Player Player)
{
    local int i;

    log("OnPlayerTeamSwitched triggered: " $ self.InterestedInPlayerTeamSwitched.Length $ " interested");

    for (i = 0; i < self.InterestedInPlayerTeamSwitched.Length; i++)
    {
        self.InterestedInPlayerTeamSwitched[i].OnPlayerTeamSwitched(Player);
    }
}

public function RegisterInterestedInPlayerVIPSet(InterestedInPlayerVIPSet Interested)
{
    self.InterestedInPlayerVIPSet[self.InterestedInPlayerVIPSet.Length] = Interested;
}

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

public function TriggerOnPlayerVIPSet(Player Player)
{
    local int i;

    log("OnPlayerVIPSet triggered: " $ self.InterestedInPlayerVIPSet.Length $ " interested");

    for (i = 0; i < self.InterestedInPlayerVIPSet.Length; i++)
    {
        self.InterestedInPlayerVIPSet[i].OnPlayerVIPSet(Player);
    }
}

public function RegisterInterestedInPlayerPawnChanged(InterestedInPlayerPawnChanged Interested)
{
    self.InterestedInPlayerPawnChanged[self.InterestedInPlayerPawnChanged.Length] = Interested;
}

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

public function TriggerOnPlayerPawnChanged(Player Player)
{
    local int i;

    log("OnPlayerPawnChanged triggered: " $ self.InterestedInPlayerPawnChanged.Length $ " interested");

    for (i = 0; i < self.InterestedInPlayerPawnChanged.Length; i++)
    {
        self.InterestedInPlayerPawnChanged[i].OnPlayerPawnChanged(Player);
    }
}

public function RegisterInterestedInPlayerVoiceChanged(InterestedInPlayerVoiceChanged Interested)
{
    self.InterestedInPlayerVoiceChanged[self.InterestedInPlayerVoiceChanged.Length] = Interested;
}

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

    while (BuiltinExtensions.Length > 0)
    {
        if (BuiltinExtensions[0] != None)
        {
            BuiltinExtensions[0].Destroy();
        }
        BuiltinExtensions.Remove(0, 1);
    }

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

defaultproperties
{
    Enabled=true;
}
