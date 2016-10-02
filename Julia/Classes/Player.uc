class Player extends SwatGame.SwatMutator;

import enum eVoiceType from SwatGame.SwatGUIConfig;
import enum COOPStatus from SwatGame.SwatPlayerReplicationInfo;

enum eHitType
{
    HT_INJURED,
    HT_INCAPACITATED,
    HT_KILLED,
};

struct sHit
{
    /**
     * Reference to the Pawn object of the hit actor
     */
    var Pawn Pawn;

    /**
     * Time the actor was hit at (Level.TimeSeconds)
     */
    var float Time;

    /**
     * Hit type
     */
    var eHitType Type;

    /**
     * Indicate whether the hit pawn was a threat to the player
     */
    var bool bThreat;
};

struct sStun
{
    /**
     * Stun type
     */
    var name Type;

    /**
     * Time player was stunned at (Level.TimeSeconds)
     */
    var float TimeStun;

    /**
     * Reference to the damager
     */
    var Player Damager;

    /**
     * Time the damager fired their weapon (Level.TimeSeconds)
     */
    var float TimeFired;

    /**
     * Indicate whether a stun entry is no longer relevant
     */
    var bool bIrrelevant;
};

var Core Core;
var Server Server;

var array<Weapon> Weapons;  // Weapons used in this round
var array<sStun> Stuns;  // Recent stuns (by other actors)
var array<sHit> Hits;  // Recent hits (to other actors)

var PlayerController PC;
var Pawn LastPawn;
var Pawn LastValidPawn;  // Last non None Pawn instance
var Weapon LastFiredWeapon;
var eVoiceType LastVoiceType;
var string LastName;
var string IpAddr;  // IP address string (without the port part)
var bool bWasLoaded;
var bool bWasAdmin;
var bool bWasDropped;
var bool bWasVIP;
var bool bWasDead;
var float TimePlayed;
var float TimeTotal;
var int Suicides;
var int LastTeam;
var int LastScore;
var int LastKills;
var int LastTeamKills;
var int LastDeaths;
var int LastArrests;
var int LastArrested;
var int LastVIPCaptures;
var int LastVIPRescues;
var int LastVIPEscapes;
var int LastVIPKillsValid;
var int LastVIPKillsInvalid;
var int LastBombsDefused;
var int LastRDCryBaby;
var int LastSGCryBaby;
var int LastSGEscapes;
var int LastSGKills;
var COOPStatus LastCOOPStatus;
var int CharacterReports;
var int CivilianArrests;
var int CivilianHits;
var int CivilianIncaps;
var int CivilianKills;
var int EnemyArrests;
var int EnemyIncaps;
var int EnemyIncapsInvalid;
var int EnemyKills;
var int EnemyKillsInvalid;
var int CurrentKillStreak;
var int BestKillStreak;
var int CurrentArrestStreak;
var int BestArrestStreak;
var int CurrentDeathStreak;
var int BestDeathStreak;
var float LastFlashbangedTime;
var float LastGassedTime;
var float LastPepperedTime;
var float LastTasedTime;
var float LastStungTime;


public function PreBeginPlay()
{
    Super.PreBeginPlay();
    self.Disable('Tick');

    self.LastTeam = -1;
}

public function Init(PlayerController PC, Server Server, Core Core)
{
    self.IpAddr = class'Utils.StringUtils'.static.ParseIP(PC.GetPlayerNetworkAddress());

    self.Core = Core;
    self.Server = Server;
    self.PC = PC;

    log(self $ " has been initialized");

    self.SetTimer(class'Core'.const.DELTA, false);
}

event Timer()
{
    // The player has already been processed as disconnected
    if (self.bWasDropped)
    {
        return;
    }
    // He/she has not yet been... but he/she has just disconnected
    else if (!class'Utils'.static.IsOnlinePlayer(Level, self.PC))
    {
        self.bWasDropped = true;
        // Keep intermediate stats along with last vaid Pawn untill a state reset
        self.PreserveInstance();
        self.Core.TriggerOnPlayerDisconnected(self);
    }
    else
    {
        // Only count play time if the player is not a spec or view mode
        if (!self.IsSpectator())
        {
            self.TimePlayed += class'Core'.const.DELTA;
        }
        self.TimeTotal += class'Core'.const.DELTA;
        // Weapon management (goes before the pawn check)
        self.CheckWeapon();
        // Stun management
        self.DetectStuns();
        self.CheckStuns();
        // Hit management
        self.CheckHits();
        // Attempt to trigger respective signals on a property change
        self.CheckPawn();
        self.CheckVoiceType();
        self.CheckTeam();
        self.CheckName();
        // Status management
        self.CheckLoaded();
        self.CheckAdmin();
        self.CheckVIP();
        // Save intermediate player stats (kills, score, etc)
        self.UpdateStats();
        // Do another check in DELTA seconds
        self.SetTimer(class'Core'.const.DELTA, false);
    }
}

/**
 * Update usage details of the currently used weapon/equipment item
 */
protected function CheckWeapon()
{
    local Pawn Pawn;
    local HandheldEquipment ActiveItem;
    local FiredWeapon FiredWeapon;
    local Weapon CurrentWeapon;

    // Weapon usage stats are only relevant during a game
    if (self.Server.GetGameState() != GAMESTATE_MidGame)
    {
        return;
    }

    if (self.PC.Pawn != None)
    {
        Pawn = self.PC.Pawn;
    }
    // The player could have died but their weapon usage should still be updated
    else if (self.LastPawn != None)
    {
        Pawn = self.LastPawn;
    }
    else
    {
        return;
    }

    // Get the Pawn owner's active item
    ActiveItem = class'Utils'.static.GetActiveItem(Pawn);

    if (ActiveItem != None)
    {
        FiredWeapon = FiredWeapon(ActiveItem);
        // Get an appropriate Weapon instance for the active item, or create one if necessary
        CurrentWeapon = self.GetWeaponByClassName(ActiveItem.class.name, true);
        // Update it's usage time and ammo details
        CurrentWeapon.Update(class'Core'.const.DELTA, FiredWeapon);
    }
}

/**
 * Attempt to detect a change of the player's pawn
 */
protected function CheckPawn()
{
    if (self.LastPawn != self.PC.Pawn)
    {
        if (self.PC.Pawn != None)
        {
            self.LastValidPawn = self.PC.Pawn;
        }
        self.LastPawn = self.PC.Pawn;
        self.Core.TriggerOnPlayerPawnChanged(self);
    }
}

/**
 * Attempt to detect a change of the player's voice type
 */
protected function CheckVoiceType()
{
    if (self.LastVoiceType != self.GetVoiceType())
    {
        self.LastVoiceType = self.GetVoiceType();
        self.Core.TriggerOnPlayerVoiceChanged(self);
    }
}

/**
 * Attempt to detect a team change
 */
protected function CheckTeam()
{
    local int CurrentTeam;

    CurrentTeam = self.GetTeam();

    if (self.LastTeam != CurrentTeam)
    {
        self.LastTeam = CurrentTeam;
        self.Core.TriggerOnPlayerTeamSwitched(self);
    }
}

/**
 * Attempt to detect a name change
 */
protected function CheckName()
{
    local string OldName, CurrentName;

    CurrentName = self.GetName();

    if (CurrentName != self.LastName)
    {
        OldName = self.LastName;
        self.LastName = CurrentName;
        self.Core.TriggerOnPlayerNameChanged(self, OldName);
    }
}

/**
 * Check whether player has just joined game
 */
protected function CheckLoaded()
{
    if (!self.bWasLoaded && self.HasLoaded())
    {
        self.bWasLoaded = true;
        self.Core.TriggerOnPlayerLoaded(self);
    }
}

/**
 * Check whether the player has just logged into admin
 */
protected function CheckAdmin()
{
    if (!self.bWasAdmin && self.IsAdmin())
    {
        self.bWasAdmin = true;
        self.Core.TriggerOnPlayerAdminLogged(self);
    }
}

/**
 * Check whether the player has gained or lost VIP status since the last tick
 */
protected function CheckVIP()
{
    local bool IsCurrentlyVIP;

    IsCurrentlyVIP = self.IsVIP();

    if (self.Server.GetGameState() != GAMESTATE_MidGame)
    {
        return;
    }
    if (IsCurrentlyVIP)
    {
        if (!self.bWasVIP)
        {
            self.Core.TriggerOnPlayerVIPSet(self);
        }
    }
    self.bWasVIP = IsCurrentlyVIP;
}

/**
 * Save intermediate player stats
 */
protected function UpdateStats()
{
    local int NewKills, NewArrests, NewDeaths;

    NewKills = self.GetKills();
    NewArrests = self.GetArrests();
    NewDeaths = self.GetDeaths();

    // Update killstreak whenever a player gets a kill
    if (NewKills > self.LastKills)
    {
        self.CurrentKillStreak += NewKills - self.LastKills;
        // Compare this to the currently best streak
        if (self.CurrentKillStreak > self.BestKillStreak)
        {
            self.BestKillStreak = self.CurrentKillStreak;
        }
        self.CurrentDeathStreak = 0;
    }
    // Update arreststreak whenever a player arrests another player
    if (NewArrests > self.LastArrests)
    {
        if (++self.CurrentArrestStreak > self.BestArrestStreak)
        {
            self.BestArrestStreak = self.CurrentArrestStreak;
        }
        self.CurrentDeathStreak = 0;
    }
    // Update deathstreak whenever player dies in succession
    // without perorming either a kill or an arrest
    if (NewDeaths > self.LastDeaths)
    {
        if (NewKills == self.LastKills && NewArrests == self.LastArrests)
        {
            if (++self.CurrentDeathStreak > self.BestDeathStreak)
            {
                self.BestDeathStreak = self.CurrentDeathStreak;
            }
        }
        self.CurrentKillStreak = 0;
        self.CurrentArrestStreak = 0;
    }

    self.LastKills = NewKills;
    self.LastDeaths = NewDeaths;
    self.LastArrests = NewArrests;

    self.bWasDead = self.IsDead();
    self.LastCOOPStatus = self.GetCOOPStatus();

    self.LastScore = self.GetScore();
    self.LastTeamKills = self.GetTeamKills();
    self.LastArrested = self.GetArrested();
    self.LastVIPCaptures = self.GetVIPCaptures();
    self.LastVIPRescues = self.GetVIPRescues();
    self.LastVIPEscapes = self.GetVIPEscapes();
    self.LastVIPKillsValid = self.GetVIPKillsValid();
    self.LastVIPKillsInvalid = self.GetVIPKillsInvalid();
    self.LastBombsDefused = self.GetBombsDefused();
    self.LastRDCryBaby = self.GetRDCryBaby();

    #if IG_SPEECH_RECOGNITION
        self.LastSGCryBaby = self.GetSGCrybaby();
        self.LastSGEscapes = self.GetSGEscapes();
        self.LastSGKills = self.GetSGKills();
    #endif
}

/**
 * Attempt to detect whether the player has recently been stunned
 */
protected function DetectStuns()
{
    if (self.PC.Pawn == None)
    {
        return;
    }
    if (NetPlayer(self.PC.Pawn).IsTased() && NetPlayer(self.PC.Pawn).LastTasedTime > self.LastTasedTime)
    {
        self.QueueStun('Taser');
        self.LastTasedTime = NetPlayer(self.PC.Pawn).LastTasedTime;
    }
    if (NetPlayer(self.PC.Pawn).IsFlashbanged() && NetPlayer(self.PC.Pawn).LastFlashbangedTime > self.LastFlashbangedTime)
    {
        self.QueueStun('Flashbang');
        self.LastFlashbangedTime = NetPlayer(self.PC.Pawn).LastFlashbangedTime;
    }
    if (NetPlayer(self.PC.Pawn).IsStung() && NetPlayer(self.PC.Pawn).LastStungTime > self.LastStungTime)
    {
        switch (NetPlayer(self.PC.Pawn).LastStingWeapon)
        {
            case StingGrenade :
                self.QueueStun('Stinger');
                break;
            case LessLethalShotgun :
                self.QueueStun('LessLethalSG');
                break;
            /*
            #if IG_SPEECH_RECOGNITION
            case TripleBatonRound :
                self.QueueStun('TripleBaton');
                break;
            case DirectGrenadeHit :
                self.QueueStun('GrenadeHit');
                break;
            case MeleeAttack :
                self.QueueStun('Melee');
                break;
            #endif
            */
        }
        self.LastStungTime = NetPlayer(self.PC.Pawn).LastStungTime;
    }
    if (NetPlayer(self.PC.Pawn).IsGassed() && NetPlayer(self.PC.Pawn).LastGassedTime > self.LastGassedTime)
    {
        self.QueueStun('Gas');
        self.LastGassedTime = NetPlayer(self.PC.Pawn).LastGassedTime;
    }
    if (NetPlayer(self.PC.Pawn).IsPepperSprayed() && NetPlayer(self.PC.Pawn).LastPepperedTime > self.LastPepperedTime)
    {
        self.QueueStun('Spray');
        self.LastPepperedTime = NetPlayer(self.PC.Pawn).LastPepperedTime;
    }
}

/**
 * Attempt to find players and their weapons that were the cause of every queued stun in the list
 */
protected function CheckStuns()
{
    local Player Damager;
    local Weapon DamagerWeapon;
    local int i;

    for (i = 0; i < self.Stuns.Length; i++)
    {
        if (self.Stuns[i].bIrrelevant)
        {
            continue;
        }
        // Purge no longer relevant stuns
        if (Level.TimeSeconds - self.Stuns[i].TimeStun >= 10.0)
        {
            log(self $ ": stun " $ self.Stuns[i].Type $ " of " $ self.GetName() $ " has timed out");
            self.Stuns[i].bIrrelevant = true;
            continue;
        }
        // This stun has already been processed
        if (self.Stuns[i].TimeFired > 0)
        {
            continue;
        }
        // Perform a lookup seeking for a player that has recently fired
        // with an item at/close to the stun time
        Damager = self.Server.GetPlayerByLastFiredWeapon(
            class'Utils'.static.GetStunWeapons(self.Stuns[i].Type),
            self.Stuns[i].TimeStun,
            class'Utils'.static.GetHitPrecision(self.Stuns[i].Type)
        );
        if (Damager != None)
        {
            DamagerWeapon = Damager.LastFiredWeapon;
            // See if the player has already been stun with the same item
            if (self.HasAlreadyBeenStun(self.Stuns[i].Type, Damager, DamagerWeapon.LastFiredTime))
            {
                log(self $ ": " $ self.Stuns[i].Type $ " of " $ self.GetName() $ " has already been processed");
                self.Stuns[i].bIrrelevant = true;
                continue;
            }
            log(self $ ": found damager for " $ self.Stuns[i].Type $ " stun of " $ self.GetName() $ " (" $ Damager.LastName $ ", " $ DamagerWeapon.ClassName $ ")");

            // Dont handle stuns if the player is arrested
            if (!NetPlayer(self.PC.Pawn).IsBeingArrestedNow() && !NetPlayer(self.PC.Pawn).IsArrested())
            {
                // This player has been stun by an enemy player
                if (self.IsEnemyTo(Damager))
                {
                    // Increment hit count of the enemy's weapon
                    DamagerWeapon.Hits++;
                    self.Core.TriggerOnInternalEventBroadcast('PlayerHit', DamagerWeapon.GetFriendlyName(), Damager, self);
                }
                else if (Damager != self)
                {
                    DamagerWeapon.TeamHits++;
                    self.Core.TriggerOnInternalEventBroadcast('PlayerTeamHit', DamagerWeapon.GetFriendlyName(), Damager, self);
                }
                else
                {
                    // Trigger an internal event whenever a player hits themself
                    self.Core.TriggerOnInternalEventBroadcast('PlayerSelfHit', DamagerWeapon.GetFriendlyName(), self);
                }
            }
            // Remember the damager
            self.Stuns[i].Damager = Damager;
            // Also store the firing time
            self.Stuns[i].TimeFired = DamagerWeapon.LastFiredTime;
        }
    }

    for (i = self.Stuns.Length-1; i >= 0; i--)
    {
        if (self.Stuns[i].bIrrelevant)
        {
            log(self $ ": removing irrelevant stun " $ self.Stuns[i].Type $ " of " $ self.GetName() $ " (damager: " $ self.Stuns[i].Damager $ ")");
            self.Stuns.Remove(i, 1);
        }
    }
}

/**
 * Attempt to detect a fired weapon for every registered pawn hit
 */
protected function CheckHits()
{
    local int i;
    local float LastFiredTime;

    // This player hasn't fired anything yet..
    if (self.LastFiredWeapon == None)
    {
        return;
    }

    LastFiredTime = self.LastFiredWeapon.LastFiredTime;

    // Check if last fired item actually hit one of the registered actors
    for (i = 0; i < self.Hits.Length; i++)
    {
        if (self.Hits[i].Pawn == None)
        {
            continue;
        }
        if (self.Hits[i].Time - LastFiredTime >= class'Utils'.static.GetHitPrecision('Lethal')[0] &&
            self.Hits[i].Time - LastFiredTime <= class'Utils'.static.GetHitPrecision('Lethal')[1])
        {
            log(self $ ": guessed weapon for " $ self.GetName() $ "'s hit of " $ self.Hits[i].Pawn.GetHumanReadableName());
            self.HandleHit(self.Hits[i].Type, self.Hits[i].Pawn, LastFiredWeapon, self.Hits[i].bThreat);
            self.Hits[i].Pawn = None;
        }
        // Unable to find an item that fired at the actor hit time
        else if (Level.TimeSeconds - self.Hits[i].Time > (abs(class'Utils'.static.GetHitPrecision('Lethal')[1]*2)))
        {
            log(self $ ": was unable to guess weapon for " $ self.GetName() $ "'s hit of " $ self.Hits[i].Pawn.GetHumanReadableName());

            self.HandleHit(self.Hits[i].Type, self.Hits[i].Pawn, None, self.Hits[i].bThreat);
            self.Hits[i].Pawn = None;
        }
    }

    // Dispose detected hits
    for (i = self.Hits.Length-1; i >= 0; i--)
    {
        if (self.Hits[i].Pawn == None)
        {
            log(self $ ": removing " $ self.GetName() $ "'s' " $ self.Hits[i].Type $ " hit");
            self.Hits.Remove(i, 1);
        }
    }
}

/**
 * Handle a processed hit (i.e. a hit with a fired weapon assigned to)
 * Ignore hits made against arrested pawns
 *
 * @param   Type
 *          Hit type
 * @param   Pawn
 *          The hit pawn
 * @param   Weapon (optional)
 *          The weapon the player has hit with
 * @param   bThreat (optional)
 *          Indicate whether the hit pawn was a threat
 */
protected function HandleHit(eHitType Type, Pawn Pawn, optional Weapon Weapon, optional bool bThreat)
{
    // Only handle the hit if the hit pawn wasnt arrested
    if (NetPlayer(Pawn).IsBeingArrestedNow() || NetPlayer(Pawn).IsArrested())
    {
        return;
    }

    switch (Type)
    {
        case HT_INJURED:
            self.HandleInjuryHit(Pawn, Weapon);
            break;
        case HT_INCAPACITATED:
            self.HandleIncapHit(Pawn, Weapon, bThreat);
            break;
        case HT_KILLED:
            self.HandleKillHit(Pawn, Weapon, bThreat);
            break;
    }
}

/**
 * Handle an injury hit
 */
protected function HandleInjuryHit(Pawn InjuredPawn, Weapon Weapon)
{
    local Player Injured;

    if (InjuredPawn.IsA('SwatHostage'))
    {
        self.CivilianHits++;
        // Trigger an internal event whenever a player hits a hostage
        self.Core.TriggerOnInternalEventBroadcast('PlayerHostageHit', Weapon.GetFriendlyName(), self);
    }
    else if (InjuredPawn.IsA('SwatEnemy'))
    {
        Weapon.Hits++;
        // Trigger an internal event whenever a player hits a suspect
        self.Core.TriggerOnInternalEventBroadcast('PlayerEnemyHit', Weapon.GetFriendlyName(), self);
    }
    // Handle a player-to-player injury
    else if (InjuredPawn.IsA('SwatPlayer'))
    {
        // Ignore grenade hits, because they are detected elsewhere in this class
        if (Weapon.IsGrenade())
        {
            log(self $ ": ignoring a grenade hit for " $ self.LastName);
            return;
        }

        Injured = self.Server.GetPlayerByAnyPawn(InjuredPawn);

        if (Injured == None)
        {
            log("Injured player " $ InjuredPawn.GetHumanReadableName() $ " was not found");
            return;
        }

        if (self.IsEnemyTo(Injured))
        {
            Weapon.Hits++;
            // Trigger an internal event whenever a player hits an enemy player
            self.Core.TriggerOnInternalEventBroadcast('PlayerHit', Weapon.GetFriendlyName(), self, Injured);
        }
        else if (Injured != self)
        {
            Weapon.TeamHits++;
            // Trigger an internal event whenever a player hits an enemy
            self.Core.TriggerOnInternalEventBroadcast('PlayerTeamHit', Weapon.GetFriendlyName(), self, Injured);
        }
        else
        {
            // Trigger an internal event whenever a player hits themself
            self.Core.TriggerOnInternalEventBroadcast('PlayerSelfHit', Weapon.GetFriendlyName(), self);
        }
    }
}

/**
 * Handle a hit that has led to a serious injury
 */
protected function HandleIncapHit(Pawn InjuredPawn, Weapon Weapon, optional bool bThreat)
{
    if (InjuredPawn.IsA('SwatHostage'))
    {
        self.CivilianIncaps++;
        // Trigger an internal event whenever a player incapacitates a hostage
        self.Core.TriggerOnInternalEventBroadcast('PlayerHostageIncap', Weapon.GetFriendlyName(), self);
    }
    else if (InjuredPawn.IsA('SwatEnemy'))
    {
        if (bThreat)
        {
            self.EnemyIncaps++;
            // Trigger an internal event whenever a player incapacitates a suspect
            self.Core.TriggerOnInternalEventBroadcast('PlayerEnemyIncap', Weapon.GetFriendlyName(), self);
        }
        else
        {
            self.EnemyIncapsInvalid++;
            // Trigger an internal event whenever the player
            // incapacitates a suspect without a reason
            self.Core.TriggerOnInternalEventBroadcast('PlayerEnemyIncapInvalid', Weapon.GetFriendlyName(), self);
        }
        // Since this is also a hit, update the item hits
        Weapon.Hits++;
    }
}

/**
 * Handle a killing blow
 */
protected function HandleKillHit(Pawn VictimPawn, Weapon Weapon, optional bool bThreat)
{
    local Player Victim;

    if (VictimPawn.IsA('SwatHostage'))
    {
        self.CivilianKills++;
        // Trigger an internal event whenever a player kills a hostage
        self.Core.TriggerOnInternalEventBroadcast('PlayerHostageKill', Weapon.GetFriendlyName(), self);
    }
    else if (VictimPawn.IsA('SwatEnemy'))
    {
        Weapon.Kills++;
        // Check if the kill distance beats the previous record
        Weapon.CheckKillDistance(VDist(self.LastValidPawn.Location, VictimPawn.Location));

        if (bThreat)
        {
            self.EnemyKills++;
            // Trigger an event whenever a player kills a suspect
            self.Core.TriggerOnInternalEventBroadcast('PlayerEnemyKill', Weapon.GetFriendlyName(), self);
        }
        else
        {
            self.EnemyKillsInvalid++;
            // Trigger an internal event whenever a player kills a suspect without a reason
            self.Core.TriggerOnInternalEventBroadcast('PlayerEnemyKillInvalid', Weapon.GetFriendlyName(), self);
        }
    }
    // Handle a player-to-player kill
    else if (VictimPawn.IsA('SwatPlayer'))
    {
        Victim = self.Server.GetPlayerByAnyPawn(VictimPawn);

        if (Victim == None)
        {
            log("Killed player " $ VictimPawn.GetHumanReadableName() $ " was not found");
            return;
        }

        if (self.IsEnemyTo(Victim))
        {
            Weapon.Kills++;
            Weapon.CheckKillDistance(VDist(self.LastValidPawn.Location, VictimPawn.Location));
            // Trigger an internal event whenever a player hits another player
            self.Core.TriggerOnInternalEventBroadcast('PlayerKill', Weapon.GetFriendlyName(), self, Victim);
        }
        else if (Victim != self)
        {
            Weapon.TeamKills++;
            // Trigger an internal event whenever a player hits a team mate
            self.Core.TriggerOnInternalEventBroadcast('PlayerTeamKill', Weapon.GetFriendlyName(), self, Victim);
        }
        else
        {
            self.Suicides++;
            // Trigger an internal event whenever a player suicides
            self.Core.TriggerOnInternalEventBroadcast('PlayerSuicide', Weapon.GetFriendlyName(), self);
        }
    }
}

/**
 * Reset the instance properties
 */
public function ResetInstance()
{
    local int i;

    log(self $ ".ResetInstance() has been invoked");

    self.LastFiredWeapon = None;
    // Reset the player's VIP status,
    // so the OnPlayerVIPSet event is properly triggered on a round start
    self.bWasVIP = false;
    // Reset manually calculated stats
    self.Suicides = 0;
    self.TimePlayed = 0;
    self.TimeTotal = 0;
    self.CharacterReports = 0;
    self.CivilianArrests = 0;
    self.EnemyArrests = 0;
    self.CivilianHits = 0;
    self.CivilianIncaps = 0;
    self.CivilianKills = 0;
    self.EnemyIncaps = 0;
    self.EnemyIncapsInvalid = 0;
    self.EnemyKills = 0;
    self.EnemyKillsInvalid = 0;

    self.CurrentKillStreak = 0;
    self.CurrentArrestStreak = 0;
    self.CurrentDeathStreak = 0;
    self.BestKillStreak = 0;
    self.BestArrestStreak = 0;
    self.BestDeathStreak = 0;

    // reset intermediate stats
    self.bWasDead = false;
    self.LastCOOPStatus = STATUS_NotReady;

    self.LastKills = 0;
    self.LastDeaths = 0;
    self.LastArrests = 0;
    self.LastScore = 0;
    self.LastTeamKills = 0;
    self.LastArrested = 0;
    self.LastVIPCaptures = 0;
    self.LastVIPRescues = 0;;
    self.LastVIPEscapes = 0;
    self.LastVIPKillsValid = 0;
    self.LastVIPKillsInvalid = 0;
    self.LastBombsDefused = 0;
    self.LastRDCryBaby = 0;
    self.LastSGCryBaby = 0;
    self.LastSGEscapes = 0;
    self.LastSGKills = 0;

    for (i = 0; i < self.Weapons.Length; i++)
    {
        self.Weapons[i].ResetInstance();
    }
}

/**
 * Keep the instance along with its game stats properties untill a proper destruction
 */
protected function PreserveInstance()
{
    local int i;

    log(self $ ".PreserveInstance() has been invoked");

    self.LastPawn = None;
    self.PC = None;
    self.LastFiredWeapon = None;

    for (i = 0; i < self.Weapons.Length; i++)
    {
        self.Weapons[i].PreserveInstance();
    }
}

/**
 * Return the player's current voice type
 */
public function eVoiceType GetVoiceType()
{
    if (self.PC.Pawn != None)
    {
        return NetPlayer(self.PC.Pawn).VoiceType;
    }
    return VOICETYPE_Random;
}

/**
 * Set the player's voicetype to given VoiceType
 */
public function SetVoiceType(eVoiceType VoiceType)
{
    if (self.PC.Pawn != None)
    {
        NetPlayer(self.PC.Pawn).VoiceType = VoiceType;
        // Do an extra voicetype check, so the change is registered immediately
        self.CheckVoiceType();
    }
}

/**
 * Return the player's team
 */
public function int GetTeam()
{
    return NetTeam(self.PC.PlayerReplicationInfo.Team).GetTeamNumber();
}

/**
 * Return the player's name
 */
public function string GetName()
{
    return self.PC.PlayerReplicationInfo.PlayerName;
}

/**
 * Tell whether the player is dead
 */
public function bool IsDead()
{
    return SwatGamePlayerController(self.PC).IsDead();
}

/**
 * Tell whether the player is the VIP
 */
public function bool IsVIP()
{
    return SwatGamePlayerController(self.PC).ThisPlayerIsTheVIP;
}

/**
 * Tell whether the player has joined game
 */
public function bool HasLoaded()
{
    return (NetConnection(self.PC.Player) != None && self.PC.PlayerReplicationInfo.Ping > 0 && self.PC.PlayerReplicationInfo.Ping < 999);
}

/**
 * Tell whether the player is an admin
 */
public function bool IsAdmin()
{
    return SwatGameInfo(Level.Game).Admin.IsAdmin(self.PC);
}

/**
 * Tell whether the player is in spec/view mode
 */
public function bool IsSpectator()
{
    return (
        class'Julia.Utils'.static.IsAMEnabled(Level) &&
        class'Julia.Utils'.static.IsSpectatorName(self.GetName())
    );
}


public function int GetScore()
{
    return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetScore();
}

public function int GetKills()
{
    return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetEnemyKills();
}

public function int GetArrests()
{
    return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetArrests();
}

public function int GetDeaths()
{
    return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetTimesDied();
}

public function int GetTeamKills()
{
    return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetFriendlyKills();
}

public function int GetArrested()
{
    return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetTimesArrested();
}

public function int GetVIPCaptures()
{
    return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetArrestedVIP();
}

public function int GetVIPRescues()
{
    return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetUnarrestedVIP();
}

public function int GetVIPEscapes()
{
    return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetVIPPlayerEscaped();
}

public function int GetVIPKillsValid()
{
    return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetKilledVIPValid();
}

public function int GetVIPKillsInvalid()
{
    return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetKilledVIPInvalid();
}

public function int GetBombsDefused()
{
    return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetBombsDiffused();
}

public function int GetRDCryBaby()
{
    return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetRDCrybaby();
}

public function int GetSGCrybaby()
{
    #if IG_SPEECH_RECOGNITION
        return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetSGCrybaby();
    #else
        return 0;
    #endif
}

public function int GetSGEscapes()
{
    #if IG_SPEECH_RECOGNITION
        return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetEscapedSG();
    #else
        return 0;
    #endif
}

public function int GetSGKills()
{
    #if IG_SPEECH_RECOGNITION
        return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetKilledSG();
    #else
        return 0;
    #endif
}

/**
 * Return the current player COOP status
 */
public function COOPStatus GetCOOPStatus()
{
    return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).COOPPlayerStatus;
}

/**
 * Return a Weapon class instance corresponding to the given weapon class name
 */
public function Weapon GetWeaponByClassName(coerce string ClassName, optional bool bForceCreate)
{
    local int i;

    for (i = 0; i < self.Weapons.Length; i++)
    {
        if (self.Weapons[i].ClassName == ClassName)
        {
            return self.Weapons[i];
        }
    }
    if (!bForceCreate)
    {
        return None;
    }
    return self.CreateWeapon(ClassName);
}

/**
 * Create a new Weapon instance according to the given weapon class name
 */
protected function Weapon CreateWeapon(string ClassName)
{
    local Weapon Weapon;

    Weapon = Spawn(class'Weapon');
    Weapon.ClassName = ClassName;
    Weapon.Init(self);

    self.Weapons[self.Weapons.Length] = Weapon;

    return Weapon;
}

/**
 * Queue a pawn hit
 */
public function QueueHit(Pawn Pawn, eHitType Type, optional bool bThreat)
{
    local sHit NewHit;

    log(self $ ": queued a pawn hit (" $ Pawn.GetHumanReadableName() $ ") for " $ self.GetName());

    NewHit.Pawn = Pawn;
    NewHit.Time = Level.TimeSeconds;
    NewHit.Type = Type;
    NewHit.bThreat = bThreat;

    self.Hits[self.Hits.Length] = NewHit;
}

/**
 * Tell whether the given pawn was already hit at this moment
 */
public function bool HasAlreadyHit(Pawn Pawn, eHitType Type)
{
    local int i;

    for (i = self.Hits.Length-1; i >= 0; i--)
    {
        if (self.Hits[i].Pawn == Pawn && self.Hits[i].Time == Level.TimeSeconds && self.Hits[i].Type == Type)
        {
            return true;
        }
    }
    return false;
}

/**
 * Queue a new stun of given type
 */
protected function QueueStun(name Type)
{
    local sStun NewStun;

    log(self $ ": queued a stun (" $ Type $ ") for " $ self.GetName());

    NewStun.Type = Type;
    NewStun.TimeStun = Level.TimeSeconds;

    self.Stuns[self.Stuns.Length] = NewStun;
}

/**
 * Tell whether the player has already been stun by Damager who last fired at given Time
 */
protected function bool HasAlreadyBeenStun(name Type, Player Damager, float Time)
{
    local int i;

    for (i = 0; i < self.Stuns.Length; i++)
    {
        if (self.Stuns[i].Type == Type && self.Stuns[i].Damager == Damager && self.Stuns[i].TimeFired == Time)
        {
            return true;
        }
    }
    return false;
}

/**
 * Tell whether the given Player instance belongs to an enemy player
 */
public function bool IsEnemyTo(Player Other)
{
    // There are no enemy players in COOP
    if (self.Server.IsCOOP())
    {
        return false;
    }
    return !(self.GetTeam() == Other.GetTeam());
}


event Destroyed()
{
    self.Core = None;
    self.Server = None;
    self.PC = None;
    self.LastPawn = None;
    self.LastValidPawn = None;
    self.LastFiredWeapon = None;

    while (self.Stuns.Length > 0)
    {
        self.Stuns[0].Damager = None;
        self.Stuns.Remove(0, 1);
    }

    while (self.Hits.Length > 0)
    {
        self.Hits[0].Pawn = None;
        self.Hits.Remove(0, 1);
    }

    while (self.Weapons.Length > 0)
    {
        if (self.Weapons[0] != None)
        {
            self.Weapons[0].Destroy();
        }
        self.Weapons.Remove(0, 1);
    }

    log(self $ " has been destroyed");

    Super.Destroyed();
}
