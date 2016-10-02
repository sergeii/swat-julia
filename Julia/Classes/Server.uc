class Server extends SwatGame.SwatMutator
 implements IInterested_GameEvent_PawnDamaged,
            IInterested_GameEvent_PawnIncapacitated,
            IInterested_GameEvent_PawnDied,
            IInterested_GameEvent_PawnArrested,
            IInterested_GameEvent_ReportableReportedToTOC,
            IInterested_GameEvent_GrenadeDetonated,
            InterestedInEventBroadcast,
            InterestedInMissionStarted;

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

var Core Core;
var array<Player> Players;

/**
 * Time in seconds since the state reset
 */
var float TimeTotal;

/**
 * Time in seconds spent on playing in the current state
 */
var float TimePlayed;

/**
 * Round outcome (should only be seen during a GAMESTATE_PostGame state)
 */
var eSwatRoundOutcome Outcome;

/**
 * Last saved game state (e.g. GAMESTATE_MidGame)
 */
var eSwatGameState LastGameState;


public function PreBeginPlay()
{
    Super.PreBeginPlay();
    self.Disable('Tick');
}

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
    self.Core.RegisterInterestedInMissionStarted(self);

    // Use custom tick rate
    self.SetTimer(class'Core'.const.DELTA, true);
}

/**
 * Queue a hit whenever a pawn gets incapacitated
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
        Player.CharacterReports++;
    }
}

/**
 * Register an arrest performed by a player
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
        PlayerOne.EnemyArrests++;
    }
    // Increment COOP civilian arrests
    else if (Pawn.IsA('SwatHostage'))
    {
        PlayerOne.CivilianArrests++;
    }
    else if (Pawn.IsA('SwatPlayer'))
    {
        PlayerTwo = self.GetPlayerByPawn(Pawn);
    }
    self.Core.TriggerOnInternalEventBroadcast('PlayerArrest', Pawn.GetHumanReadableName(), PlayerOne, PlayerTwo);
}

/**
 * Register detonation of a grenade owned by a player
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

/**
 * Enforce player score reset (along with kills, deaths, etc) upon a round start.
 * This is ought to fix a problem where scores are not properly reset on servers with 16+ players.
 */
public function OnMissionStarted()
{
    local int i;

    for (i = 0; i < self.Players.Length; i++)
    {
        SwatPlayerReplicationInfo(self.Players[i].PC.PlayerReplicationInfo).netScoreInfo.ResetForMPQuickRestart();
    }
}

event Timer()
{
    self.CheckGameState();
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
 */
protected function CheckGameState()
{
    local eSwatGameState CurrentGameState, OldGameState;

    CurrentGameState = self.GetGameState();
    OldGameState = self.LastGameState;

    if (CurrentGameState != OldGameState)
    {
        // Change gamestate before triggering a signal
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
        if (self.Players[i].bWasDropped)
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
 */
public function Player GetPlayerByPC(PlayerController PC)
{
    local int i;

    if (PC != None)
    {
        for (i = 0; i < Players.Length; i++)
        {
            if (Players[i].PC == PC)
            {
                return Players[i];
            }
        }
    }
    return None;
}

/**
 * Return a Player instance corresponding to given Pawn
 */
public function Player GetPlayerByPawn(Pawn Pawn)
{
    local int i;

    if (Pawn != None)
    {
        for (i = 0; i < self.Players.Length; i++)
        {
            if (self.Players[i].PC != None && self.Players[i].PC.Pawn == Pawn)
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
 */
public function Player GetPlayerByAnyPawn(Pawn Pawn)
{
    local int i;

    if (Pawn != None)
    {
        for (i = 0; i < Players.Length; i++)
        {
            if ((Players[i].PC != None && Players[i].PC.Pawn == Pawn) || Players[i].LastValidPawn == Pawn)
            {
                return Players[i];
            }
        }
    }

    return None;
}

/**
 * Return a Player instance corresponding to given array index
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
 */
public function Player GetPlayerByName(string Name)
{
    local int i;

    for (i = 0; i < Players.Length; i++)
    {
        if (Players[i].PC == None)
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
 * Return an array of Player instances whose names match wildcard pattern
 */
public function array<Player> GetPlayersByWildName(string Criteria)
{
    local array<Player> Matched;
    local int i;

    for (i = 0; i < self.Players.Length; i++)
    {
        if (self.Players[i].PC == None)
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
 * @param   Weapons
 *          List of weapons
 * @param   Time
 *          Fire time (Level.TimeSeconds)
 * @param   Precision
 *          Precision error
 */
public function Player GetPlayerByLastFiredWeapon(array<string> Weapons, float Time, optional array<float> Precision)
{
    local int i;
    local Weapon LastFiredWeapon;

    for (i = 0; i < self.Players.Length; i++)
    {
        // We're not interrested in disconnected players
        if (self.Players[i].PC == None)
        {
            continue;
        }

        LastFiredWeapon = self.Players[i].LastFiredWeapon;
        // If this player hasn't fired yet, ignore them
        if (self.Players[i].LastFiredWeapon == None)
        {
            continue;
        }
        // The player has fired, but not with an item of the interest
        if (class'Utils.ArrayUtils'.static.Search(Weapons, LastFiredWeapon.ClassName) == -1)
        {
            continue;
        }
        // Check the item last firing time
        if (Time-LastFiredWeapon.LastFiredTime >= Precision[0] &&
            Time-LastFiredWeapon.LastFiredTime <= Precision[1])
        {
            return self.Players[i];
        }
    }
    return None;
}

/**
 * Tell whether a player name is unique to specific PlayerController's owner
 */
public function bool IsNameUniqueTo(string Name, PlayerController PC)
{
    local int i;

    for (i = 0; i < self.Players.Length; i++)
    {
        if (self.Players[i].PC == None || self.Players[i].PC == PC)
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

public function eSwatGameState GetGameState()
{
    return SwatRepo(Level.GetRepo()).GuiConfig.SwatGameState;
}

public function string GetHostname()
{
    return ServerSettings(Level.CurrentServerSettings).ServerName;
}

public function int GetPort()
{
    return SwatGameInfo(Level.Game).GetServerPort();
}

public function bool IsPassworded()
{
    return ServerSettings(Level.CurrentServerSettings).bPassworded;
}

public function string GetGame()
{
    return Level.ModName;
}

public function string GetGameVer()
{
    return Level.BuildVersion;
}

public function EMPMode GetGameType()
{
    return ServerSettings(Level.CurrentServerSettings).GameType;
}

/**
 * Check whether the current gametype is COOP
 */
public function bool IsCOOP()
{
    return Level.IsCOOPServer;
}

/**
 * Return the friendly map name
 */
public function string GetMap()
{
    return Level.Title;
}

/**
 * Return the current player count
 */
public function int GetPlayerCount()
{
    return SwatGameInfo(Level.Game).GetNumPlayers();
}

/**
 * Return the player limit
 */
public function int GetPlayerLimit()
{
    return ServerSettings(Level.CurrentServerSettings).MaxPlayers;
}

public function int GetSwatScore()
{
    return SwatGameInfo(Level.Game).GetTeamFromID(0).NetScoreInfo.GetScore();
}

public function int GetSuspectsScore()
{
    return SwatGameInfo(Level.Game).GetTeamFromID(1).NetScoreInfo.GetScore();
}

public function int GetSwatVictories()
{
    return SwatGameInfo(Level.Game).GetTeamFromID(0).NetScoreInfo.GetRoundsWon();
}

public function int GetSuspectsVictories()
{
    return SwatGameInfo(Level.Game).GetTeamFromID(1).NetScoreInfo.GetRoundsWon();
}

public function int GetBombsDefused()
{
    return SwatGameReplicationInfo(Level.Game.GameReplicationInfo).DiffusedBombs;
}

public function int GetBombsTotal()
{
    return SwatGameReplicationInfo(Level.Game.GameReplicationInfo).TotalNumberOfBombs;
}

/**
 * Return current zero based round index
 */
public function int GetRoundIndex()
{
    return ServerSettings(Level.CurrentServerSettings).RoundNumber;
}

public function int GetRoundLimit()
{
    return ServerSettings(Level.CurrentServerSettings).NumRounds;
}

/**
 * Return the round remaining time
 */
public function int GetRoundRemainingTime()
{
    return SwatGameReplicationInfo(Level.Game.GameReplicationInfo).RoundTime;
}

/**
 * Return the round special time
 */
public function int GetRoundSpecialTime()
{
    return SwatGameReplicationInfo(Level.Game.GameReplicationInfo).SpecialTime;
}

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
    self.Core.UnregisterInterestedInMissionStarted(self);
    self.Core = None;

    while (self.Players.Length > 0)
    {
        self.Players[0].Destroy();
        self.Players.Remove(0, 1);
    }

    log(self $ " has been destroyed");

    Super.Destroyed();
}
