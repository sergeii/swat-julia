class Server extends SwatGame.SwatMutator
 implements IInterested_GameEvent_PawnDamaged,
            IInterested_GameEvent_PawnIncapacitated,
            IInterested_GameEvent_PawnDied,
            IInterested_GameEvent_PawnArrested,
            IInterested_GameEvent_ReportableReportedToTOC,
            IInterested_GameEvent_GrenadeDetonated,
            InterestedInEventBroadcast;

/**
 * Copyright (c) 2014-2015 Sergei Khoroshilov <kh.sergei@gmail.com>
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import enum EMPMode from Engine.Repo;
import enum eSwatGameState from SwatGame.SwatGUIConfig;

enum eSwatRoundOutcome
{
    SRO_None,
    SRO_SwatVictoriousNormal,
    SRO_SuspectsVictoriousNormal,
    SRO_SwatVictoriousRapidDeployment,
    SRO_SuspectsVictoriousRapidDeployment,
    SRO_RoundEndedInTie,
    SRO_SwatVictoriousVIPEscaped,
    SRO_SuspectsVictoriousKilledVIPValid,
    SRO_SwatVictoriousSuspectsKilledVIPInvalid,
    SRO_SuspectsVictoriousSwatKilledVIP,
    SRO_COOPCompleted,
    SRO_COOPFailed,
    SRO_SwatVictoriousSmashAndGrab,
    SRO_SuspectsVictoriousSmashAndGrab,
};

/**
 * Reference to the Core instance
 * @type class'Core'
 */
var protected Core Core;

/**
 * List of player controllers
 * @type array<class'Player'>
 */
var protected array<Player> Players;

/**
 * Time in seconds since the state reset
 * @type int
 */
var protected float TimeTotal;

/**
 * Time in seconds spent on playing in the current state
 * @type int
 */
var protected float TimePlayed;

/**
 * Round outcome (should only be seen during a GAMESTATE_PostGame state)
 * @type enum'eSwatRoundOutcome'
 */
var protected eSwatRoundOutcome Outcome;

/**
 * Last saved game state (e.g. GAMESTATE_MidGame)
 * @type enum'eSwatGameState'
 */
var protected eSwatGameState LastGameState;

/**
 * Disable the Tick event
 * 
 * @return  void
 */
public function PreBeginPlay()
{
    Super.PreBeginPlay();
    self.Disable('Tick');
}

/**
 * Inialize the instance
 *
 * @param   class'Core' Core
 * @return  void
 */
public function Init(Core Core)
{
    self.Core = Core;

    SwatGameInfo(Level.Game).GameEvents.PawnDamaged.Register(self);
    SwatGameInfo(Level.Game).GameEvents.PawnIncapacitated.Register(self);
    SwatGameInfo(Level.Game).GameEvents.PawnDied.Register(self);
    SwatGameInfo(Level.Game).GameEvents.GrenadeDetonated.Register(self);
    SwatGameInfo(Level.Game).GameEvents.PawnArrested.Register(self);
    SwatGameInfo(Level.Game).GameEvents.ReportableReportedToTOC.Register(self);

    self.Core.RegisterInterestedInEventBroadcast(self);

    // Use custom tick rate
    self.SetTimer(class'Core'.const.DELTA, true);
}

/**
 * Queue a hit whenever a pawn gets incapacitated
 *
 * @param   class'Pawn' Pawn
 *          Reference to the Pawn instance of the hit actor
 * @param   class'Actor' Incapacitator
 *          The incapacitator
 * @param   bool bThreat
 *          Whether the hit AI actor (if it's actually one) was a threat
 * @return  void
 */
public function OnPawnIncapacitated(Pawn Pawn, Actor Incapacitator, bool bThreat)
{
    local Player Player;

    // We are only interested in pawns hit by a player...
    if (Incapacitator.IsA('SwatPlayer'))
    {
        Player = self.GetPlayerByAnyPawn(Pawn(Incapacitator));

        if (Player == None)
        {
            log("Unable to find a player by existing pawn " $ "(" $ Pawn(Incapacitator).GetHumanReadableName() $ ")");
            return;
        }
        Player.QueueHit(Pawn, HT_INCAPACITATED, bThreat);
    }
    // ..as well as in hits made by COOP suspects
    else if (Incapacitator.IsA('SwatEnemy'))
    {
        if (Pawn.IsA('SwatHostage'))
        {
            self.Core.TriggerOnInternalEventBroadcast('EnemyHostageIncap');
        }
    }
}

/**
 * Register a hit whenever a pawn gets injured
 * 
 * @param   class'Pawn' Pawn
 *          Pawn of the damaged actor
 * @param   class'Actor' Damager
 *          Refrence to the damager's actor
 * @return  void
 */
public function OnPawnDamaged(Pawn Pawn, Actor Damager)
{
    local Player Player, Injured;

    // Again, we are only interested in hits made by a player..
    if (Damager.IsA('SwatPlayer'))
    {
        Player = self.GetPlayerByAnyPawn(Pawn(Damager));

        if (Player == None)
        {
            log("Unable to find a player by existing pawn " $ "(" $ Pawn(Damager).GetHumanReadableName() $ ")");
            return;
        }
        // Sometimes when the same projectile hits an actor multiple times
        // (e.g. different parts of its body), then this function is called as many times, accordingly.
        // Since we only want 1 shot = 1 hit (at many), hence the check
        if (Player.HasAlreadyHit(Pawn, HT_INJURED))
        {
            return;
        }
        // When a killer dies before it's victim, the OnPawnDied function call is provided
        // with an invalid Damager argument
        // To avoid such a misfortune we attempt to register deadly hits in the both functions
        if (Pawn.IsA('SwatPlayer'))
        {
            Injured = self.GetPlayerByAnyPawn(Pawn);

            if (Injured == None)
            {
                log("Unable to find a player by existing pawn " $ "(" $ Pawn.GetHumanReadableName() $ ")");
                return;
            }
            if (Pawn.Health <= 0)
            {
                // Only register this killing blow if it has not already been registered in OnPawnDied()
                if (!Player.HasAlreadyHit(Pawn, HT_KILLED))
                {
                    Player.QueueHit(Pawn, HT_KILLED);
                }
            }
        }
        Player.QueueHit(Pawn, HT_INJURED);
    }
}

/**
 * Register a hit whenether an actor gets killed
 * 
 * @param   class'Pawn' Pawn
 *          Reference to the Pawn object of the killed actor
 * @param   class'Actor' Killer
 *          The killer
 * @param   bool bThreat
 *          Whether the killed AI actor was a threat (COOP only)
 * @return  void
 */
public function OnPawnDied(Pawn Pawn, Actor Killer, bool bThreat)
{
    local Player Player;

    if (Killer.IsA('SwatPlayer'))
    {
        Player = self.GetPlayerByAnyPawn(Pawn(Killer));

        if (Player == None)
        {
            log("Unable to find a player by existing pawn " $ "(" $ Pawn(Killer).GetHumanReadableName() $ ")");
            return;
        }
        // This doesn't always evalute to true, but when it does,
        // the deadly hit has alrady been registered in OnPawnDamaged
        if (Player.HasAlreadyHit(Pawn, HT_KILLED))
        {
            return;
        }
        Player.QueueHit(Pawn, HT_KILLED, bThreat);
    }
    else if (Killer.IsA('SwatEnemy'))
    {
        if (Pawn.IsA('SwatPlayer'))
        {
            self.Core.TriggerOnInternalEventBroadcast('EnemyPlayerKill', "", self.GetPlayerByAnyPawn(Pawn));
        }
        else if (Pawn.IsA('SwatHostage'))
        {
            self.Core.TriggerOnInternalEventBroadcast('EnemyHostageKill');
        }
    }
}

/**
 * Register a TOC report
 * 
 * @param   interface'IAmReportableCharacter' ReportedCharacter
 * @param   class'Pawn' Reporter
 * @return  void
 */
public function OnReportableReportedToTOC(IAmReportableCharacter ReportedCharacter, Pawn Reporter)
{
    local Player Player;

    if (!Reporter.IsA('SwatPlayer'))
    {
        return;
    }

    Player = self.GetPlayerByPC(PlayerController(Reporter.Controller));

    if (Player == None)
    {
        return;
    }

    if (
        ReportedCharacter.IsA('SwatEnemy') ||
        ReportedCharacter.IsA('SwatHostage') ||
        ReportedCharacter.IsA('SwatPlayer') ||
        ReportedCharacter.IsA('SwatOfficer')
    )
    {
        self.Core.TriggerOnInternalEventBroadcast('PlayerReport', Pawn(ReportedCharacter).GetHumanReadableName(), Player);
        Player.IncrementCharacterReports();
    }
}

/**
 * Register an arrest performed by a player
 * 
 * @param   class'Pawn' Pawn
 *          Reference to the Pawn object of the arrested actor
 * @param   class'Pawn' Arrester
 *          Reference to the Pawn object of the arrester
 * @return  void
 */
public function OnPawnArrested(Pawn Pawn, Pawn Arrester)
{
    local Player PlayerOne, PlayerTwo;

    if (!Arrester.IsA('SwatPlayer'))
    {
        return;
    }

    PlayerOne = self.GetPlayerByPC(PlayerController(Arrester.Controller));

    if (PlayerOne == None)
    {
        return;
    }
    // Increment COOP enemy arrests
    if (Pawn.IsA('SwatEnemy'))
    {
        PlayerOne.IncrementEnemyArrests();
    }
    // Increment COOP civilian arrests
    else if (Pawn.IsA('SwatHostage'))
    {
        PlayerOne.IncrementCivilianArrests();
    }
    else if (Pawn.IsA('SwatPlayer'))
    {
        PlayerTwo = self.GetPlayerByPawn(Pawn);
    }
    self.Core.TriggerOnInternalEventBroadcast('PlayerArrest', Pawn.GetHumanReadableName(), PlayerOne, PlayerTwo);
}

/**
 * Register detonation of a grenade owned by a player
 * 
 * @param   class'Pawn' GrenadeOwner
 * @param   class'SwatGrenadeProjectile' Grenade
 * @return  void
 */
public function OnGrenadeDetonated(Pawn GrenadeOwner, SwatGrenadeProjectile Grenade)
{
    local Player Player;

    if (!GrenadeOwner.IsA('SwatPlayer'))
    {
        return;
    }

    Player = self.GetPlayerByAnyPawn(GrenadeOwner);

    if (Player == None)
    {
        return;
    }

    Player.GetWeaponByClassName(class'Utils'.static.GetGrenadeClassName(Grenade.class.Name), true).IncrementShots(1);
}

/**
 * Attempt to set the round outcome
 * 
 * @see  InterestedInEventBroadacast.OnEventBroadcast
 */
public function bool OnEventBroadcast(Player Player, Actor Sender, name Type, string Msg, optional PlayerController Receiver, optional bool bHidden)
{
    switch (Type)
    {
        case 'MissionCompleted' :
            self.Outcome = SRO_COOPCompleted;
            break;
        case 'MissionFailed' :
            self.Outcome = SRO_COOPFailed;
            break;
        case 'SuspectsWin' :
            self.Outcome = SRO_SuspectsVictoriousNormal;
            break;
        case 'SwatWin' :
            self.Outcome = SRO_SwatVictoriousNormal;
            break;
        case 'AllBombsDisarmed' :
            self.Outcome = SRO_SwatVictoriousRapidDeployment;
            break;
        case 'BombExploded' :
            self.Outcome = SRO_SuspectsVictoriousRapidDeployment;
            break;
        case 'VIPSafe' :
            self.Outcome = SRO_SwatVictoriousVIPEscaped;
            break;
        case 'WinSuspectsBadKill' :
            self.Outcome = SRO_SuspectsVictoriousKilledVIPValid;
            break;
        case 'WinSwatBadKill' :
            self.Outcome = SRO_SwatVictoriousSuspectsKilledVIPInvalid;
            break;
        case 'WinSuspectsGoodKill' :
            self.Outcome = SRO_SuspectsVictoriousSwatKilledVIP;
            break;
        case 'GameTied' :
            self.Outcome = SRO_RoundEndedInTie;
            break;
        case 'SuspectsWinSmashAndGrab' :
            self.Outcome = SRO_SuspectsVictoriousSmashAndGrab;
            break;
        case 'SwatWinSmashAndGrab' :
            self.Outcome = SRO_SwatVictoriousSmashAndGrab;
            break;
    }
    return true;
}

event Timer()
{
    // Check if game state has changed
    self.CheckGameState();
    // Check for new players _after_ the potential state reset
    self.CheckPlayers();
    // Only increment play time when there are at least one player on server
    if (SwatRepo(Level.GetRepo()).AnyPlayersOnServer())
    {
        self.TimePlayed += class'Core'.const.DELTA;
    }
    self.TimeTotal += class'Core'.const.DELTA;
}

/**
 * Attempt to detect a game state change
 * 
 * @return  void
 */
protected function CheckGameState()
{
    local eSwatGameState CurrentGameState, OldGameState;

    CurrentGameState = self.GetGameState();
    OldGameState = self.LastGameState;

    if (CurrentGameState != OldGameState)
    {
        // Change gamestate _before_ triggering a signal
        self.LastGameState = CurrentGameState;
        // MidGame -> PostGame
        if (OldGameState == GAMESTATE_MidGame)
        {
            self.Core.TriggerOnMissionEnded();
        }
        // PreGame -> MidGame
        else if (CurrentGameState == GAMESTATE_MidGame)
        {
            self.Core.TriggerOnMissionStarted();
        }
        // Trigger the signal _before_ resetting state
        self.Core.TriggerOnGameStateChanged(OldGameState, CurrentGameState);
        // Reset state data
        self.ResetInstance();
    }
}

/**
 * Attempt to detect new players that havent been yet added to the internal player list
 * 
 * @return  void
 */
protected function CheckPlayers()
{
    local Controller C;
    local PlayerController PC;

    for (C = Level.ControllerList; C != None; C = C.nextController)
    {
        PC = PlayerController(C);

        if (class'Utils'.static.IsOnlinePlayer(Level, PC) && self.GetPlayerByPC(PC) == None)
        {
            self.Core.TriggerOnPlayerConnected(self.AddPlayer(PC));
        }
    }
}

/**
 * Reset the instance gamestate-related properties
 * 
 * @return  void
 */
protected function ResetInstance()
{
    local int i;

    log(self $ ".ResetInstance() has been invoked");

    // Set temporary properties to their default values
    self.TimeTotal = 0.0;
    self.TimePlayed = 0.0;
    self.Outcome = SRO_None;
    // Attempt to reset players
    for (i = self.Players.Length-1; i >= 0; i--)
    {
        // Remove disconnected players
        if (self.Players[i].WasDropped())
        {
            self.Players[i].Destroy();
            self.Players.Remove(i, 1);
        }
        else
        {
            self.Players[i].ResetInstance();
        }
    }
}

/**
 * Spawn and return a new Player instance
 * 
 * @param   class'PlayerController' PC
 * @return  class'Player'
 */
protected function Player AddPlayer(PlayerController PC)
{
    local Player Player;

    Player = Spawn(class'Player');
    Player.Init(PC, self, self.Core);

    self.Players[Players.Length] = Player;

    return Player;
}

/**
 * Return a Player instance corresponding to given PlayerController
 * 
 * @param   class'PlayerController' PC
 * @return  class'Player'
 */
public function Player GetPlayerByPC(PlayerController PC)
{
    local int i;

    if (PC != None)
    {
        for (i = 0; i < Players.Length; i++)
        {
            if (Players[i].GetPC() == PC)
            {
                return Players[i];
            }
        }
    }
    return None;
}

/**
 * Return a Player instance corresponding to given Pawn
 * 
 * @param   class'Pawn' Pawn
 * @return  class'Player'
 */
public function Player GetPlayerByPawn(Pawn Pawn)
{
    local int i;

    if (Pawn != None)
    {
        for (i = 0; i < self.Players.Length; i++)
        {
            if (self.Players[i].GetPC() != None && self.Players[i].GetPawn() == Pawn)
            {
                return Players[i];
            }
        }
    }
    return None;
}

/**
 * Return a Player instance corresponding to given Pawn
 * Lookup is performed against both the current player pawn and the last non-None saved instance
 * 
 * @param   class'Pawn' Pawn
 * @return  class'Player'
 */
public function Player GetPlayerByAnyPawn(Pawn Pawn)
{
    local int i;

    if (Pawn != None)
    {
        for (i = 0; i < Players.Length; i++)
        {
            if (Players[i].GetPC() != None && Players[i].GetPawn() == Pawn || Players[i].GetLastValidPawn() == Pawn)
            {
                return Players[i];
            }
        }
    }

    return None;
}

/**
 * Return a Player instance corresponding to given array index
 * 
 * @param   int i
 * @return  class'Player'
 */
public function Player GetPlayerByID(int i)
{
    if (i < self.Players.Length && Players[i] != None)
    {
        return Players[i];
    }
    return None;
}

/**
 * Return the first Player instance matching given name
 * 
 * @param   string Name
 *          Player name (case insensitive)
 * @return  class'Player'
 */
public function Player GetPlayerByName(string Name)
{
    local int i;

    for (i = 0; i < Players.Length; i++)
    {
        if (Players[i].GetPC() == None)
        {
            continue;
        }
        if (Players[i].GetName() ~= Name)
        {
            return Players[i];
        }
    }
    return None;
}

/**
 * Return an array of Player instances whose names match Criteria wildcard pattern
 * 
 * @param   string Criteria
 * @return  array<class'Player'>
 */
public function array<Player> GetPlayersByWildName(string Criteria)
{
    local array<Player> Matched;
    local int i;

    for (i = 0; i < self.Players.Length; i++)
    {
        if (self.Players[i].GetPC() == None)
        {
            continue;
        }
        if (class'Utils.StringUtils'.static.Match(self.Players[i].GetName(), Criteria))
        {
            Matched[Matched.Length] = self.Players[i];
        }
    }
    return Matched;
}

/**
 * Attempt to return the only player instance with the name matching Criteria pattern
 * 
 * @param   string Criteria
 *          Wildcard pattern
 * @return  class'Player'
 */
public function Player GetPlayerByWildName(string Criteria)
{
    local array<Player> Matched;

    // Try the name with wildcard stars on sides
    Matched = self.GetPlayersByWildName("*" $ Criteria $ "*");
    // If many players found, try again with the original criteria
    if (Matched.Length > 1)
    {
        Matched = self.GetPlayersByWildName(Criteria);
    }
    if (Matched.Length != 1)
    {
        return None;
    }
    // Return the only instance found
    return Matched[0];
}

/**
 * Return array index of given Player instance
 * 
 * @param   class'Player' Player
 * @return  int
 */
public function int GetPlayerID(Player Player)
{
    local int i;

    for (i = 0; i < Players.Length; i++)
    {
        if (Players[i] == Player)
        {
            return i;
        }
    }
    return -1;
}

/**
 * Return a Player instance of the player who fired with an item from given Weapons array at the given Time
 * 
 * @param   array<string> Weapons
 *          List of weapons
 * @param   float Time
 *          Fire time (Level.TimeSeconds)
 * @param   array<float[2]> Precision
 *          Precision error
 * @return  class'Player'
 */
public function Player GetPlayerByLastFiredWeapon(array<string> Weapons, float Time, optional array<float> Precision)
{
    local int i;
    local Weapon LastFiredWeapon;

    for (i = 0; i < self.Players.Length; i++)
    {
        // We're not interrested in disconnected players
        if (self.Players[i].GetPC() == None)
        {
            continue;
        }

        LastFiredWeapon = self.Players[i].GetLastFiredWeapon();
        // If this player hasn't fired yet, ignore them
        if (LastFiredWeapon == None)
        {
            continue;
        }
        // The player has fired, but not with an item of the interest
        if (class'Utils.ArrayUtils'.static.Search(Weapons, LastFiredWeapon.GetClassName()) == -1)
        {
            continue;
        }
        // Check the item last firing time
        if (Time-LastFiredWeapon.GetLastFiredTime() >= Precision[0] && 
            Time-LastFiredWeapon.GetLastFiredTime() <= Precision[1])
        {
            return self.Players[i];
        }
    }
    return None;
}

/**
 * Tell whether a player name is unique to specific PlayerController's owner
 * 
 * @param   string Name
 * @param   class'PlayerController' PC
 * @return  bool
 */
public function bool IsNameUniqueTo(string Name, PlayerController PC)
{
    local int i;

    for (i = 0; i < self.Players.Length; i++)
    {
        if (self.Players[i].GetPC() == None || self.Players[i].GetPC() == PC)
        {
            continue;
        }
        if (self.Players[i].GetName() ~= Name)
        {
            return false;
        }
    }

    return true;
}

/**
 * Return the list of player controllers
 * 
 * @return  array<class'Player'>
 */
public function array<Player> GetPlayers()
{
    return self.Players;
}

/**
 * Return round outcome
 * 
 * @return  enum'eSwatRoundOutcome'
 */
public function eSwatRoundOutcome GetOutcome()
{
    return self.Outcome;
}

/**
 * Return time played (in seconds)
 * 
 * @return  float
 */
public function float GetTimePlayed()
{
    return self.TimePlayed;
}

/**
 * Return time elapsed since the last state reset
 * 
 * @return  float
 */
public function float GetTimeTotal()
{
    return self.TimeTotal;
}

/**
 * Return the current game state
 * 
 * @return  enum'eSwatGameState'
 */
public function eSwatGameState GetGameState()
{
    return SwatRepo(Level.GetRepo()).GuiConfig.SwatGameState;
}

/**
 * Return the server name
 * 
 * @return  string
 */
public function string GetHostname()
{
    return ServerSettings(Level.CurrentServerSettings).ServerName;
}

/**
 * Return the join port value
 * 
 * @return  int
 */
public function int GetPort()
{
    return SwatGameInfo(Level.Game).GetServerPort();
}

/**
 * Return whether the server is password protected
 * 
 * @return  bool
 */
public function bool IsPassworded()
{
    return ServerSettings(Level.CurrentServerSettings).bPassworded;
}

/**
 * Return the game name (SWAT 4/SWAT 4X)
 * 
 * @return  string
 */
public function string GetGame()
{
    return Level.ModName;
}

/**
 * Return the game version
 * 
 * @return  string
 */
public function string GetGameVer()
{
    return Level.BuildVersion;
}

/**
 * Return the server gamemode
 * 
 * @return  enum'EMPMode'
 */
public function EMPMode GetGameType()
{
    return ServerSettings(Level.CurrentServerSettings).GameType;
}

/**
 * Tell whether the current gametype is COOP
 * 
 * @return  bool
 */
public function bool IsCOOP()
{
    return Level.IsCOOPServer;
}

/**
 * Return the friendly map name
 * 
 * @return  string
 */
public function string GetMap()
{
    return Level.Title;
}

/**
 * Return current player count
 * 
 * @return  int
 */
public function int GetPlayerCount()
{
    return SwatGameInfo(Level.Game).GetNumPlayers();
}

/**
 * Return the player limit
 * 
 * @return  int
 */
public function int GetPlayerLimit()
{
    return ServerSettings(Level.CurrentServerSettings).MaxPlayers;
}

/**
 * Return the SWAT score
 * 
 * @return  int
 */
public function int GetSwatScore()
{
    return SwatGameInfo(Level.Game).GetTeamFromID(0).NetScoreInfo.GetScore();
}

/**
 * Return the Suspects score
 * 
 * @return  int
 */
public function int GetSuspectsScore()
{
    return SwatGameInfo(Level.Game).GetTeamFromID(1).NetScoreInfo.GetScore();
}

/**
 * Return the number of rounds won by SWAT
 * 
 * @return  int
 */
public function int GetSwatVictories()
{
    return SwatGameInfo(Level.Game).GetTeamFromID(0).NetScoreInfo.GetRoundsWon();
}

/**
 * Return the number of rounds won by suspects
 * 
 * @return  int
 */
public function int GetSuspectsVictories()
{
    return SwatGameInfo(Level.Game).GetTeamFromID(1).NetScoreInfo.GetRoundsWon();
}

/**
 * Return the number of bombs defused
 * 
 * @return  int
 */
public function int GetBombsDefused()
{
    return SwatGameReplicationInfo(Level.Game.GameReplicationInfo).DiffusedBombs;
}

/**
 * Return the total number of bombs
 * 
 */
public function int GetBombsTotal()
{
    return SwatGameReplicationInfo(Level.Game.GameReplicationInfo).TotalNumberOfBombs;
}

/**
 * Return current player index (zero-based)
 * 
 * @return  int
 */
public function int GetRoundIndex()
{
    return ServerSettings(Level.CurrentServerSettings).RoundNumber;
}

/**
 * Return the round limit
 * 
 * @return  int
 */
public function int GetRoundLimit()
{
    return ServerSettings(Level.CurrentServerSettings).NumRounds;
}

/**
 * Return the round remaining time
 * 
 * @return  int
 */
public function int GetRoundRemainingTime()
{
    return SwatGameReplicationInfo(Level.Game.GameReplicationInfo).RoundTime;
}

/**
 * Return the round special time
 * 
 * @return  int
 */
public function int GetRoundSpecialTime()
{
    return SwatGameReplicationInfo(Level.Game.GameReplicationInfo).SpecialTime;
}

/**
 * Return the round time limit
 * 
 * @return  int
 */
public function int GetRoundTimeLimit()
{
    return ServerSettings(Level.CurrentServerSettings).RoundTimeLimit;
}

event Destroyed()
{
    SwatGameInfo(Level.Game).GameEvents.PawnDamaged.UnRegister(self);
    SwatGameInfo(Level.Game).GameEvents.PawnIncapacitated.UnRegister(self);
    SwatGameInfo(Level.Game).GameEvents.PawnDied.UnRegister(self);
    SwatGameInfo(Level.Game).GameEvents.GrenadeDetonated.UnRegister(self);
    SwatGameInfo(Level.Game).GameEvents.PawnArrested.UnRegister(self);
    SwatGameInfo(Level.Game).GameEvents.ReportableReportedToTOC.UnRegister(self);

    self.Core.UnregisterInterestedInEventBroadcast(self);
    self.Core = None;

    while (self.Players.Length > 0)
    {
        self.Players[0].Destroy();
        self.Players.Remove(0, 1);
    }
    
    log(self $ " has been destroyed");

    Super.Destroyed();
}

/* vim: set ft=java: */
