swat-julia
%%%%%%%%%%

:Version:           2.0.0
:Home page:         https://github.com/sergeii/swat-julia
:Author:            Sergei Khoroshilov <kh.sergei@gmail.com>
:License:           The MIT License (http://opensource.org/licenses/MIT)

Description
===========
Julia is a simple yet powerful UnrealScript framework that helps you to develop SWAT 4 mods easily.

Dependencies
============
* `Utils <https://github.com/sergeii/swat-utils>`_ *>=1.0.0*

Documentation
=============
Cache
-----
Cache is a temporary data manager that makes cached data to persist through levels. 

Cache exposes very simple public API:

* SetValue
  ::

    public function SetValue(string Key, string Value)

    Store a value ``Value`` under a key ``Key``. 

* SetArray
  ::

    public function SetArray(string Key, array<string> Array)

    Store an array of values ``Array`` under same key ``Key``.

* GetValue
  ::

    public function string GetValue(string Key)

    Return value of the first entry matching key ``Key``.

* GetArray
  ::

    public function array<string> GetArray(string Key)

    Return an array of values stored under the same key ``Key``.

To obtain the ``Cache`` instance you must invoke ``GetCache()`` on the ``Core`` object::

  local Julia.Cache Cache;
  local string Value;
  // Obtain the Cache instance
  Cache = self.Core.GetCache();
  // Retrieve a value
  Value = Cache.GetValue("foo");
  // Set a value
  if (Value == "")
  {
    Cache.SetValue("foo", "bar");
  }

By default all cache entries are stored for 86400 seconds (24 hours).
To configure global cache expiration time alter the ``TTL`` value of the ``[Julia.Cache]`` section in ``Swat4DedicatedServer.ini``::

  [Julia.Cache]
  TTL=300

Dispatcher
----------
``Dispatcher`` is a ``Core`` asset that provides an ability to register client commands. A client command is a typical chat/teamchat message that begins with a **!** (exclamation sign). The builtin commands ``!version`` and ``!help`` serve as an example to the dispatcher protocol.


To register a command you have to the following:

1. Implement the ``Julia.InterestedInCommandDispatched`` interface::

    class MyExtension extends Julia.Extension implements InterestedInCommandDispatched;

    public function OnCommandDispatched(Julia.Dispatcher Dispatcher, string Name, string Id, array<string> Args, Julia.Player Player)
    {
      // Handle dispatched commands
    }

2. Obtain the ``Dispatcher`` instance invoking ``GetDispatcher()`` on the ``Core`` object::

    local Julia.Dispatcher Dispatcher;

    Dispatcher = self.Core.GetDispatcher();

3. Register commands::

    Dispatcher.Bind("mycommand", self, "!mycommand argument1 argument2", "This command does something");
    Dispatcher.Bind("myothercommand", self, "!myothercommand argument", "This command does something as well");

4. Unregister commands before the object gets dealloacated:

   ::

    Dispatcher.Unbind("mycommand", self);
    Dispatcher.Unbind("myothercommand", self);

   or

   ::

    Dispatcher.UnbindAll(self);

   to unregister all commands that have been tied to a particular instance.


Once a client command is dispatched, the dispatcher expects a response from the instance that has pledged to handle the command. ``Dispatcher`` provides a plain and simple public API for handling command output:

* Dispatcher.Respond
  ::

    public function Respond(string Id, string Response)

* Dispatcher.ThrowError
  ::

    public function ThrowError(string Id, string Error)

* Dispatcher.ThrowUsageError
  ::

    public function ThrowUsageError(string Id)

* Dispatcher.ThrowPermissionError
  ::

    public function ThrowPermissionError(string Id)

All of the response methods expect an ``Id`` argument. ``Id`` is a unique command identifier that is generated upon the moment a client command is placed into the dispatcher queue.

Suppose you wanted to implement *!time* and *!date* that would display the current server time and date respectively::

  class MyExtension extends Julia.Extension implements InterestedInCommandDispatched;

  function BeginPlay()
  {
      Super.BeginPlay();
      // register self as the "time" command handler
      // providing dispatcher with detailed usage information
      self.Core.GetDispatcher().Bind("time", self, "!time", "Displays the current server time.");
      self.Core.GetDispatcher().Bind("date", self, "!date", "Displays the current server date.");
  }

  public function OnCommandDispatched(Julia.Dispatcher Dispatcher, string Name, string Id, array<string> Args, Julia.Player Player)
  {
      local string TimeFormatted, DateFormatted, Response;

      // A command handler is always passed the lowercase version of a registered command
      switch (Name)
      {
          case "time":

               // Display HH:MM time (eg. 19:47)
              TimeFormatted = class'Utils.LevelUtils'.static.FormatTime(
                class'Utils.LevelUtils'.sttaic.GetTime(self.Level),
                "%H:%M"
              );
              Response = "Current server time is " $ TimeFormatted;

              break;

          case "date":

              DateFormatted = class'Utils.LevelUtils'.static.FormatTime(
                class'Utils.LevelUtils'.sttaic.GetTime(self.Level),
                "%Y:%m:%d"
              );

              Response = "Current server date is " $ DateFormatted;

              break;
      }

      Dispatcher.Respond(Id, Response);
  }

  event Destroyed()
  {
      self.Core.GetDispatcher().UnbindAll(self);
      Super.Destroyed();
  }

In case a designated handler does not respond in a reasonable amount of time (defined with the constant ``COMMAND_TIMEOUT`` in Dispatcher.uc), the dispatcher removes the dispatched command from its queue.


Event Manager
-------------
Julia provides a rich set of subscribable event handlers

* OnEventBroadcast

  ``OnEventBroadcast`` event manager provides an ability to subscribe to all types of broadcast events emitted everywhere across the native and custom game code, be it ``Say`` or ``AdminMsg``.

  ::

    interface InterestedInEventBroadcast;

    public function bool OnEventBroadcast(Julia.Player Player, Actor Sender, name Type, out string Msg, optional PlayerController Receiver, optional bool bHidden);

  * ``Player`` is a reference to the ``Julia.Player`` player controller of the original event broadcaster (where applicable).
  * ``Sender`` is a reference to the original event broadcaster.
  * ``Type`` is an event type such as ``Say`` or ``TeamSay`` which may be any of the following
    ::

      AllBombsDisarmed
      BanReferendumStarted
      BombExploded
      Caption
      CommandGiven
      Connected
      CoopLeaderPromoted
      CoopMessage
      CoopQMM
      DebugMessage
      DisarmBomb
      EquipNotAvailable
      GameTied
      Kick
      KickBan
      KickReferendumStarted
      LeaderReferendumStarted
      LeaderVoteTeamMismatch
      MapReferendumStarted
      MissionCompleted
      MissionEnded
      MissionFailed
      NameChange
      NoVote
      ObjectiveShown
      OneMinWarning
      PlayerConnect
      PlayerDisconnect
      PlayerImmuneFromReferendum
      PreGameWait
      ReferendumAgainstAdmin
      ReferendumAlreadyActive
      ReferendumFailed
      ReferendumsDisabled
      ReferendumStartCooldown
      ReferendumSucceeded
      Say
      SettingsUpdated
      SmashAndGrabArrestTimeDeduction
      SmashAndGrabDroppedItem
      SmashAndGrabGotItem
      SniperAlerted
      Stats
      StatsBadProfileMessage
      StatsValidatedMessage
      SuspectsArrest
      SuspectsKill
      SuspectsRespawnEvent
      SuspectsSuicide
      SuspectsTeamKill
      SuspectsWin
      SuspectsWinSmashAndGrab
      SwatArrest
      SwatKill
      SwatRespawnEvent
      SwatSuicide
      SwatTeamKill
      SwatWin
      SwatWinSmashAndGrab
      SwitchTeams
      TeamSay
      TenSecWarning
      ViewingFromEvent
      ViewingFromNoneEvent
      ViewingFromVIPEvent
      VIPCaptured
      VIPRescued
      VIPSafe
      WinSuspectsBadKill
      WinSuspectsGoodKill
      WinSwatBadKill
      YesVote
      YouAreVIP
  * ``Msg`` is an optional event message, which may be altered before displaying in chat *(out)*.
  * ``Receiver`` is a broadcast target reference *(optional)*.
  * ``bHidden`` indicates whether the event has been hidden by any of the registered Julia extensions *(optional)*.

  An implemented ``OnEventBroadcast`` method must return ``true`` if the extension does not wish to stop a particular event from broadcasting, or ``false`` if it does not wish to interfere with the event visibility at all.

  Consider the following example of an extension that has a sole purpose to stop player messages containing the word "foo" from appearing in chat::

    class MySillyExtension extends Julia.Extension implements Julia.InterestedInEventBroadcast;

    public function BeginPlay()
    {
        Super.BeginPlay();
        // Register MySillyExtension with the Julia event handler
        self.Core.RegisterInterestedInEventBroadcast(self);
    }

    public function bool OnEventBroadcast(Julia.Player Player, Actor Sender, name Type, out string Msg, optional PlayerController Receiver, optional bool bHidden)
    {
      // This event has already been marked hidden by some other Julia extension
        if (bHidden)
        {
            return true;
        }

        // Not interested in this event type
        if (Player == None || !(Type == 'Say' || Type == 'TeamSay'))
        {
            return true;
        }

        // Dont allow the word "foo" to appear anywhere in chat
        if (class'Utils.StringUtils'.static.Match(Msg, "*foo*"))
        {
            return false;
        }

        return true;
    }

    event Destroyed()
    {
        if (self.Core != None)
        {
          // Unregister MySillyExtension before deallocating
          self.Core.UnregisterInterestedInEventBroadcast(self);
        }

        Super.Destroyed();
    }

* OnInternalEventBroadcast

  ``OnInternalEventBroadcast`` allows you to subscribe to the Julia's internal events such as ``PlayerHit`` or ``PlayerArrest``.

  ::

    interface InterestedInInternalEventBroadcast;

    public function OnInternalEventBroadcast(name Type, optional string Msg, optional Player PlayerOne, optional Player PlayerTwo);

  * ``Type`` is an event type that may be any of the following
    ::

      EnemyHostageIncap
      EnemyHostageKill
      EnemyPlayerKill
      PlayerArrest
      PlayerEnemyHit
      PlayerEnemyIncap
      PlayerEnemyIncapInvalid
      PlayerEnemyKill
      PlayerEnemyKillInvalid
      PlayerHit
      PlayerHit
      PlayerHostageHit
      PlayerHostageIncap
      PlayerHostageKill
      PlayerKill
      PlayerReport
      PlayerSelfHit
      PlayerSelfHit
      PlayerSuicide
      PlayerTeamHit
      PlayerTeamHit
      PlayerTeamKill

  * ``Msg`` is an optional event message that holds weapon friendly name (where applicable). *(optional)*
  * ``PlayerOne``, ``PlayerTwo`` hold reference to players affected by the event (where applicable) *(optional)*

* OnGameStateChanged

  ``OnGameStateChanged`` will fire whenether a game changes its state.

  ::

    interface InterestedInGameStateChanged;

    public function OnGameStateChanged(eSwatGameState OldState, eSwatGameState NewState);

  * ``OldState`` is the previous game state code.
  * ``NewState`` is the current game state code.

  Both the ``OldState`` and ``NewState`` arguments may be any of the following::

    GAMESTATE_None              // Not in game at all, GUI only
    GAMESTATE_EntryLoading      // Currently loading the entry level
    GAMESTATE_LevelLoading      // Currently loading a (non-entry) level
    GAMESTATE_PreGame           // Level has loaded but round not yet begun
    GAMESTATE_MidGame           // Game in progress
    GAMESTATE_PostGame          // Level completed
    GAMESTATE_ClientTravel      // Client is travelling to the new map on the server
    GAMESTATE_ConnectionFailed  // Client failed to connect to the server (remote OR local)

* OnMissionStarted
* OnMissionEnded

  ``OnMissionStarted``, ``OnMissionEnded`` are convenient wrappers around ``OnGameStateChanged`` that will fire whenever a game changes its state from ``GAMESTATE_PreGame`` to ``GAMESTATE_MidGame`` or from ``GAMESTATE_MidGame`` to ``GAMESTATE_PostGame`` respectively.

  ::

    interface InterestedInMissionStarted;

    public function OnMissionStarted();

  ::

    interface InterestedInMissionEnded;

    public function OnMissionEnded();

* OnPlayerConnected

  ``OnPlayerConnected`` will be invoked upon player connection.

  ::

    interface InterestedInPlayerConnected;

    public function OnPlayerConnected(Julia.Player Player);

* OnPlayerDisconnected

  ``OnPlayerDisconnected`` will be invoked upon player disconnection.

  ::

    interface InterestedInPlayerDisconnected;

    public function OnPlayerDisconnected(Julia.Player Player);

* OnPlayerAdminLogged

  ``OnPlayerAdminLogged`` will fire whenever a player logs in with admin password.

  ::

    interface InterestedInPlayerAdminLogged;

    public function OnPlayerAdminLogged(Julia.Player Player);

* OnPlayerLoaded

  ``OnPlayerLoaded`` will fire upon the moment a player gets all of the local content loaded (i.e. she is able to see chat and scoreboard).

  ::

    interface InterestedInPlayerLoaded;

    public function OnPlayerLoaded(Player Player);

* OnPlayerNameChanged

  ``OnPlayerNameChanged`` is fired upon a player name change.

  ::

    interface InterestedInPlayerNameChanged;

    public function OnPlayerNameChanged(Julia.Player Player, string OldName);

  * ``OldName`` holds the previous player name.
    The current name can be retrieved with a ``Player.GetName`` method call.

* OnPlayerTeamSwitched

  ``OnPlayerTeamSwitched`` will be fired whenever a player changes their team.

  ::

    interface InterestedInPlayerTeamSwitched;

    public function OnPlayerTeamSwitched(Julia.Player Player);

* OnPlayerVIPSet

  ``OnPlayerVIPSet`` is fired upon the moment a player is assigned to be the VIP.

  ::

    interface InterestedInPlayerVIPSet;

    public function OnPlayerVIPSet(Player Player);

* OnPlayerPawnChanged

  ``OnPlayerPawnChanged`` will fire upon a player Pawn change.

  ::

    interface InterestedInPlayerPawnChanged;

    public function OnPlayerPawnChanged(Julia.Player Player);

* OnPlayerVoiceChanged

  ``OnPlayerVoiceChanged`` will fire whenever a player changes their voice type.

  ::

    interface InterestedInPlayerVoiceChanged;

    public function OnPlayerVoiceChanged(Julia.Player Player);

In order to subscribe to a specific event handler you must call *RegisterInterestedIn%EventType%* on an instance of ``Julia.Core`` providing it with an instance of a class that implements an assotitated *InterestedIn%EventType%* interface.

Suppose you had to listen to all ``OnGameStateChanged`` events. To do so you would do the following:

1. Subclass ``Julia.Extension`` and implement the ``Julia.InterestedInGameStateChanged`` interface
   ::

    class MyExtension extends Julia.Extension implements Julia.InterestedInGameStateChanged;

    import enum eSwatGameState from SwatGame.SwatGUIConfig;

    public function OnGameStateChanged(eSwatGameState OldState, eSwatGameState NewState)
    {
        log("old state: " $ OldState $ " | new state: " $ NewState);
    }

2. Register instances of the extension class with the event handler at ``Julia.Core`` available in your ``Julia.Extension`` derived class as ``self.Core``
   ::

    function BeginPlay()
    {
        Super.BeginPlay();

        self.Core.RegisterInterestedInGameStateChanged(self);
    }

3. Make sure to unregister from the event handler just before object destruction
   ::

    event Destroyed
    {
        self.Core.UnregisterInterestedInGameStateChanged(self);

        Super.Destroyed();
    }

Properties
==========
The framework supports the following ``Swat4DedicatedServer.ini`` options:

[Julia.Core]
------------

.. list-table::
   :widths: 15 40 10 10
   :header-rows: 1

   * - Property
     - Descripion
     - Options
     - Default
   * - Enabled
     - Enables the framework core and all of the ``Julia.Extension`` derived extensions.
     - True/False
     - False

[Julia.Cache]
-------------

.. list-table::
   :widths: 15 40 10 10
   :header-rows: 1

   * - Property
     - Descripion
     - Options
     - Default
   * - TTL
     - Cache entry expiration time (in seconds)
     - Positive integer
     - 86400

Official Extensions
===================
* `swat-julia-tracker <https://github.com/sergeii/swat-julia-tracker>`_
* `swat-julia-admin <https://github.com/sergeii/swat-julia-admin>`_
* `swat-julia-chat <https://github.com/sergeii/swat-julia-chat>`_
* `swat-julia-whois <https://github.com/sergeii/swat-julia-whois>`_
* `swat-julia-stats <https://github.com/sergeii/swat-julia-stats>`_
* `swat-julia-vip <https://github.com/sergeii/swat-julia-vip>`_
* `swat-julia-coop <https://github.com/sergeii/swat-julia-coop>`_
