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
     * @type class'Pawn'
     */
    var Pawn Pawn;

    /**
     * Time the actor was hit at (Level.TimeSeconds)
     * @type float
     */
    var float Time;

    /**
     * Hit type
     * @type enum'eHitType'
     */
    var eHitType Type;

    /**
     * Indicate whether the hit pawn was a threat to the player
     * @type bool
     */
    var bool bThreat;
};

struct sStun
{
    /**
     * Stun type
     * @type name
     */
    var name Type;

    /**
     * Time player was stunned at (Level.TimeSeconds)
     * @type float
     */
    var float TimeStun;

    /**
     * Reference to the damager
     * @type class'Player'
     */
    var Player Damager;

    /**
     * Time the damager fired their weapon (Level.TimeSeconds)
     * @type float
     */
    var float TimeFired;

    /**
     * Indicate whether a stun entry is no longer relevant
     * @type bool
     */
    var bool bIrrelevant;
};

/**
 * List of pawns the player has recently shot at
 * @type array<struct'sHit'>
 */
var protected array<sHit> Hits;

/**
 * List of registered stuns that the player has experienced recently
 * @type array<struct'sStun'>
 */
var protected array<sStun> Stuns;

/**
 * List of Weapon instances corresponding
 * to equipment items the player has used since the level start
 * @type array<class'Weapon'>
 */
var protected array<Weapon> Weapons;

/**
 * Referenc to the Core instance
 * @type class'Core'
 */
var protected Core Core;

/**
 * Reference to the Core's Server instance
 * @type class'Server'
 */
var protected Server Server;

/**
 * Reference to the tied PlayerController instance
 * @type class'PlayerController'
 */
var protected PlayerController PC;

/**
 * Reference to the Pawn instance
 * @type class'Pawn'
 */
var protected Pawn LastPawn;

/**
 * Reference to the last non-None Pawn instance
 * @type class'Pawn'
 */
var protected Pawn LastValidPawn;

/**
 * Reference to the last fired weapon
 * @type class'Weapon'
 */
var protected Weapon LastFiredWeapon;

/**
 * Last saved player voice type
 * @type enum'eVoiceType'
 */
var protected eVoiceType LastVoiceType;

/**
 * Last saved player name
 * @type string
 */
var protected string LastName;

/**
 * Player IP address
 * @type string
 */
var protected string IpAddr;

/**
 * Indicate whether this player has joined game
 * @type bool
 */
var protected bool bWasLoaded;

/**
 * Indicate whether the player is an admin
 * @type bool
 */
var protected bool bWasAdmin;

/**
 * Indicate whether the player has disconnected
 * @type bool
 */
var protected bool bWasDropped;

/**
 * Whether this player was the VIP at the latest tick
 * @type bool
 */
var protected bool bWasVIP;

/**
 * Indicate whether the player was dead at the previous tick
 * @type bool
 */
var protected bool bWasDead;

/**
 * Time in seconds this player has spent playing
 * @type float
 */
var protected float TimePlayed;

/**
 * Time in seconds this player has spent on the server
 * @type float
 */
var protected float TimeTotal;

/**
 * Current number of suicides (0)
 * @type int
 */
var protected int Suicides;

/**
 * Last saved player team
 * @type int
 */
var protected int LastTeam;

/**
 * Last saved score
 * @type int
 */
var protected int LastScore;

/**
 * Last saved number of kills (1)
 * @type int
 */
var protected int LastKills;

/**
 * Last saved number of teamkills (-3)
 * @type int
 */
var protected int LastTeamKills;

/**
 * Last saved number of deaths (0)
 * @type int
 */
var protected int LastDeaths;

/**
 * Last saved number of arrests (5)
 * @type int
 */
var protected int LastArrests;

/**
 * Last saved number of times arrested (0)
 * @type int
 */
var protected int LastArrested;

/**
 * Last saved number of VIP arrests (10)
 * @type int
 */
var protected int LastVIPCaptures;

/**
 * Last saved number of VIP rescues (10)
 * @type int
 */
var protected int LastVIPRescues;

/**
 * Last saved number of VIP escapes (10)
 * @type int
 */
var protected int LastVIPEscapes;

/**
 * Last saved number of valid VIP kills (10)
 * @type int
 */
var protected int LastVIPKillsValid;

/**
 * Last saved number of invalid VIP kills (-51)
 * @type int
 */
var protected int LastVIPKillsInvalid;

/**
 * Last saved number of bombs defused (10)
 * @type int
 */
var protected int LastBombsDefused;

/**
 * Last saved number of rapid Deployment suspect wins (10)
 * @type int
 */
var protected int LastRDCryBaby;

/**
 * Last saved number of smash and Grab swat wins (10)
 * @type int
 */
var protected int LastSGCryBaby;

/**
 * Last saved number of Smash and Grab case escapes (10)
 * @type int
 */
var protected int LastSGEscapes;

/**
 * Last saved number of Smash and Grab case kills (2)
 * @type int
 */
var protected int LastSGKills;

/**
 * Last saved COOP player status
 * @type enum'COOPStatus'
 */
var protected COOPStatus LastCOOPStatus;

/**
 * Last saved number of reported characters
 * @type int
 */
var protected int CharacterReports;

/**
 * Last saved number of civilian arrests
 * @type int
 */
var protected int CivilianArrests;

/**
 * Last saved number of civilian hits
 * @type int
 */
var protected int CivilianHits;

/**
 * Last saved number of civilian incaps
 * @type int
 */
var protected int CivilianIncaps;

/**
 * Last saved number of civlian kills
 * @type int
 */
var protected int CivilianKills;

/**
 * Last saved number of civilian arrests
 * @type int
 */
var protected int EnemyArrests;

/**
 * Last saved number of enemy incaps
 * @type int
 */
var protected int EnemyIncaps;

/**
 * Last saved number of invalid enemy incaps
 * @type int
 */
var protected int EnemyIncapsInvalid;

/**
 * Last saved umber of enemy kills
 * @type int
 */
var protected int EnemyKills;

/**
 * Last saved number of invalid enemy kills
 * @type int
 */
var protected int EnemyKillsInvalid;

/**
 * Current kill streak
 * @type int
 */
var protected int CurrentKillStreak;

/**
 * Last best kill streak
 * @type int
 */
var protected int BestKillStreak;

/**
 * Current arrest streak
 * @type int
 */
var protected int CurrentArrestStreak;

/**
 * Last best arrest streak
 * @type int
 */
var protected int BestArrestStreak;

/**
 * Current death streak
 * @type int
 */
var protected int CurrentDeathStreak;

/**
 * Last best death streak
 * @type int
 */
var protected int BestDeathStreak;

/**
 * Time the player was last flashed at (Level.TimeSeconds)
 * @type float
 */
var protected float LastFlashbangedTime;

/**
 * Time the player was last gassed at (Level.TimeSeconds)
 * @type float
 */
var protected float LastGassedTime;

/**
 * Time the player was last tased at (Level.TimeSeconds)
 * @type float
 */
var protected float LastPepperedTime;

/**
 * Time the player was last tased at (Level.TimeSeconds)
 * @type float
 */
var protected float LastTasedTime;

/**
 * Time the player was last stung at (Level.TimeSeconds)
 * @type float
 */
var protected float LastStungTime;

/**
 * Set properties to their default values
 *
 * @return  void
 */
public function PreBeginPlay()
{
    Super.PreBeginPlay();
    self.Disable('Tick');

    self.LastTeam = -1;
}

/**
 * Initialize the instance
 *
 * @param   class'Server' Server
 *          Reference to the server instance
 * @param   class'PlayerController' PC
 *          Reference to a PlayerController instance that should be tied with the instance
 * @return  void
 */
public function Init(PlayerController PC, Server Server, Core Core)
{
    self.IpAddr = class'Utils.StringUtils'.static.ParseIP(PC.GetPlayerNetworkAddress());

    self.Core = Core;
    self.Server = Server;
    self.PC = PC;

    log(self $ " has been initialized");

    self.SetTimer(class'Core'.const.DELTA, false);
}

/**
 * Check whether player is still online.
 * If he/she is, then update their stats. Otherwise trigger the Core.OnPlayerDisconnected signal
 */
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
 *
 * @return  void
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
 *
 * @return  void
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
 *
 * @return  void
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
 * Attempt to detect a change of team
 *
 * @return  void
 */
protected function CheckTeam()
{
    if (self.LastTeam != self.GetTeam())
    {
        self.LastTeam = self.GetTeam();
        self.Core.TriggerOnPlayerTeamSwitched(self);
    }
}

/**
 * Attempt to detect a name change
 *
 * @return  void
 */
protected function CheckName()
{
    local string OldName, NewName;

    NewName = self.GetName();

    if (NewName != self.LastName)
    {
        OldName = self.LastName;
        self.LastName = NewName;
        self.Core.TriggerOnPlayerNameChanged(self, OldName);
    }
}

/**
 * Check whether player has just joined game
 *
 * @return  void
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
 *
 * @return  void
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
 *
 * @return  void
 */
protected function CheckVIP()
{
    if (self.Server.GetGameState() != GAMESTATE_MidGame)
    {
        return;
    }
    if (self.IsVIP())
    {
        if (!self.bWasVIP)
        {
            self.Core.TriggerOnPlayerVIPSet(self);
        }
    }
    self.bWasVIP = self.IsVIP();
}

/**
 * Save intermediate player stats
 *
 * @return  void
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
 *
 * @return  void
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
 *
 * @return  void
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
            DamagerWeapon = Damager.GetLastFiredWeapon();
            // See if the player has already been stun with the same item
            if (self.HasAlreadyBeenStun(self.Stuns[i].Type, Damager, DamagerWeapon.GetLastFiredTime()))
            {
                log(self $ ": " $ self.Stuns[i].Type $ " of " $ self.GetName() $ " has already been processed");
                self.Stuns[i].bIrrelevant = true;
                continue;
            }
            log(self $ ": found damager for " $ self.Stuns[i].Type $ " stun of " $ self.GetName() $ " (" $ Damager.GetLastName() $ ", " $ DamagerWeapon.GetClassName() $ ")");

            // Dont handle stuns if the player is arrested
            if (!NetPlayer(self.PC.Pawn).IsBeingArrestedNow() && !NetPlayer(self.PC.Pawn).IsArrested())
            {
                // This player has been stun by an enemy player
                if (self.IsEnemyTo(Damager))
                {
                    // Increment hit count of the enemy's weapon
                    DamagerWeapon.IncrementHits();
                    self.Core.TriggerOnInternalEventBroadcast('PlayerHit', DamagerWeapon.GetFriendlyName(), Damager, self);
                }
                else if (Damager != self)
                {
                    DamagerWeapon.IncrementTeamHits();
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
            self.Stuns[i].TimeFired = DamagerWeapon.GetLastFiredTime();
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
 *
 * @return  void
 */
protected function CheckHits()
{
    local int i;
    local float LastFiredTime;
    local Weapon LastFiredWeapon;

    LastFiredWeapon = self.GetLastFiredWeapon();

    // This player hasn't fired anything yet..
    if (LastFiredWeapon == None)
    {
        return;
    }

    LastFiredTime = LastFiredWeapon.GetLastFiredTime();

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
 * @param   enum'eHitType' Type
 *          Hit type
 * @param   class'Pawn' Pawn
 *          Hit pawn
 * @param   class'Weapon' Weapon (optional)
 *          The weapon the player has hit with
 * @param   bool bThreat (optional)
 *          Indicate whether the hit pawn was a threat
 * @return  void
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
 *
 * @param   class'Pawn' InjuredPawn
 * @param   class'Weapon' Weapon
 * @return  void
 */
protected function HandleInjuryHit(Pawn InjuredPawn, Weapon Weapon)
{
    local Player Injured;

    if (InjuredPawn.IsA('SwatHostage'))
    {
        self.IncrementCivilianHits();
        // Trigger an internal event whenever a player hits a hostage
        self.Core.TriggerOnInternalEventBroadcast('PlayerHostageHit', Weapon.GetFriendlyName(), self);
    }
    else if (InjuredPawn.IsA('SwatEnemy'))
    {
        Weapon.IncrementHits();
        // Trigger an internal event whenever a player hits a suspect
        self.Core.TriggerOnInternalEventBroadcast('PlayerEnemyHit', Weapon.GetFriendlyName(), self);
    }
    // Handle a player-to-player injury
    else if (InjuredPawn.IsA('SwatPlayer'))
    {
        // Ignore grenade hits, because they are detected elsewhere in this class
        if (Weapon.IsGrenade())
        {
            log(self $ ": ignoring a grenade hit for " $ self.GetLastName());
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
            Weapon.IncrementHits();
            // Trigger an internal event whenever a player hits an enemy player
            self.Core.TriggerOnInternalEventBroadcast('PlayerHit', Weapon.GetFriendlyName(), self, Injured);
        }
        else if (Injured != self)
        {
            Weapon.IncrementTeamHits();
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
 *
 * @param   class'Pawn' InjuredPawn
 * @param   class'Weapon' Weapon
 * @param   bool bThreat
 * @return  void
 */
protected function HandleIncapHit(Pawn InjuredPawn, Weapon Weapon, optional bool bThreat)
{
    if (InjuredPawn.IsA('SwatHostage'))
    {
        self.IncrementCivilianIncaps();
        // Trigger an internal event whenever a player incapacitates a hostage
        self.Core.TriggerOnInternalEventBroadcast('PlayerHostageIncap', Weapon.GetFriendlyName(), self);
    }
    else if (InjuredPawn.IsA('SwatEnemy'))
    {
        if (bThreat)
        {
            self.IncrementEnemyIncaps();
            // Trigger an internal event whenever a player incapacitates a suspect
            self.Core.TriggerOnInternalEventBroadcast('PlayerEnemyIncap', Weapon.GetFriendlyName(), self);
        }
        else
        {
            self.IncrementEnemyIncapsInvalid();
            // Trigger an internal event whenever the player
            // incapacitates a suspect without a reason
            self.Core.TriggerOnInternalEventBroadcast('PlayerEnemyIncapInvalid', Weapon.GetFriendlyName(), self);
        }
        // Since this is also a hit, update the item hits
        Weapon.IncrementHits();
    }
}

/**
 * Handle a killing blow
 *
 * @param   class'Pawn' VictimPawn
 * @param   class'Weapon' Weapon
 * @param   bool bThreat
 * @return  void
 */
protected function HandleKillHit(Pawn VictimPawn, Weapon Weapon, optional bool bThreat)
{
    local Player Victim;

    if (VictimPawn.IsA('SwatHostage'))
    {
        self.IncrementCivilianKills();
        // Trigger an internal event whenever a player kills a hostage
        self.Core.TriggerOnInternalEventBroadcast('PlayerHostageKill', Weapon.GetFriendlyName(), self);
    }
    else if (VictimPawn.IsA('SwatEnemy'))
    {
        Weapon.IncrementKills();
        // Check if the kill distance beats the previous record
        Weapon.CheckKillDistance(VDist(self.LastValidPawn.Location, VictimPawn.Location));

        if (bThreat)
        {
            self.IncrementEnemyKills();
            // Trigger an event whenever a player kills a suspect
            self.Core.TriggerOnInternalEventBroadcast('PlayerEnemyKill', Weapon.GetFriendlyName(), self);
        }
        else
        {
            self.IncrementEnemyKillsInvalid();
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
            Weapon.IncrementKills();
            Weapon.CheckKillDistance(VDist(self.LastValidPawn.Location, VictimPawn.Location));
            // Trigger an internal event whenever a player hits another player
            self.Core.TriggerOnInternalEventBroadcast('PlayerKill', Weapon.GetFriendlyName(), self, Victim);
        }
        else if (Victim != self)
        {
            Weapon.IncrementTeamKills();
            // Trigger an internal event whenever a player hits a team mate
            self.Core.TriggerOnInternalEventBroadcast('PlayerTeamKill', Weapon.GetFriendlyName(), self, Victim);
        }
        else
        {
            self.IncrementSuicides();
            // Trigger an internal event whenever a player suicides
            self.Core.TriggerOnInternalEventBroadcast('PlayerSuicide', Weapon.GetFriendlyName(), self);
        }
    }
}

/**
 * Reset the instance properties
 *
 * @return  void
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
 *
 * @return  void
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
 * Return the PlayerController instance
 *
 * @return  class'PlayerController'
 */
public function PlayerController GetPC()
{
    return self.PC;
}

/**
 * Return the current Pawn
 *
 * @return  class'Pawn'
 */
public function Pawn GetPawn()
{
    return self.PC.Pawn;
}

/**
 * Return the last saved Pawn instance
 *
 * @return  class'Pawn'
 */
public function Pawn GetLastPawn()
{
    return self.LastPawn;
}

/**
 * Return the last saved non-None Pawn instance
 *
 * @return  class'Pawn'
 */
public function Pawn GetLastValidPawn()
{
    return self.LastValidPawn;
}

/**
 * Return the reference to the last fired weapon
 *
 * @return  class'Weapon'
 */
public function Weapon GetLastFiredWeapon()
{
    return self.LastFiredWeapon;
}

/**
 * Store a reference to the given Weapon as the last fired weapon
 *
 * @param   class'Weapon' Weapon
 * @return  void
 */
public function SetLastFiredWeapon(Weapon Weapon)
{
    self.LastFiredWeapon = Weapon;
}

/**
 * Return the list of used weapons
 *
 * @return  array<class'Weapon'>
 */
public function array<Weapon> GetWeapons()
{
    return self.Weapons;
}

/**
 * Return the player's current voice type
 *
 * @return  enum'eVoiceType'
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
 * Set the player's voicetype to VoiceType
 *
 * @param   enum'eVoiceType' VoiceType
 *          New voicetype
 * @return  void
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
 * Return the last saved voice type value
 *
 * @return  enum'eVoiceType'
 */
public function eVoiceType GetLastVoiceType()
{
    return self.LastVoiceType;
}

/**
 * Return ip address of the player
 *
 * @return  string
 */
public function string GetIPAddr()
{
    return self.IpAddr;
}

/**
 * Return the player's team
 *
 * @return  int
 */
public function int GetTeam()
{
    return NetTeam(self.PC.PlayerReplicationInfo.Team).GetTeamNumber();
}

/**
 * Return the player's last saved team
 *
 * @return int
 */
public function int GetLastTeam()
{
    return self.LastTeam;
}

/**
 * Return the player's name
 *
 * @return  string
 */
public function string GetName()
{
    return self.PC.PlayerReplicationInfo.PlayerName;
}

/**
 * Return the last saved name
 *
 * @return  string
 */
public function string GetLastName()
{
    return self.LastName;
}

/**
 * Tell whether the player has dropped
 *
 * @return  bool
 */
public function bool WasDropped()
{
    return self.bWasDropped;
}

/**
 * Tell whether the player is dead
 *
 * @return  bool
 */
public function bool IsDead()
{
    return SwatGamePlayerController(self.PC).IsDead();
}

/**
 * Tell whether the player was dead at the previous tick
 *
 * @return  bool
 */
public function bool WasDead()
{
    return self.bWasDead;
}

/**
 * Tell whether the player is the VIP
 *
 * @return  bool
 */
public function bool IsVIP()
{
    return SwatGamePlayerController(self.PC).ThisPlayerIsTheVIP;
}

/**
 * Tell whether the player wss the VIP the last time
 *
 * @return  bool
 */
public function bool WasVIP()
{
    return self.bWasVIP;
}

/**
 * Tell whether the player has joined game
 *
 * @return  bool
 */
public function bool HasLoaded()
{
    return (NetConnection(self.PC.Player) != None && self.PC.PlayerReplicationInfo.Ping > 0 && self.PC.PlayerReplicationInfo.Ping < 999);
}

/**
 * Tell whether the player had joined the game at the last tick
 *
 * @return  void
 */
public function bool WasLoaded()
{
    return self.bWasLoaded;
}

/**
 * Tell whether the player is an admin
 *
 * @return  bool
 */
public function bool IsAdmin()
{
    return SwatGameInfo(Level.Game).Admin.IsAdmin(self.PC);
}

/**
 * Tell whetther the player was an admin at the latest tick
 *
 * @return  bool
 */
public function bool WasAdmin()
{
    return self.bWasAdmin;
}

/**
 * Tell whether the player is in spec/view mode
 *
 * @return  bool
 */
public function bool IsSpectator()
{
    return (
        class'Julia.Utils'.static.IsAMEnabled(Level) &&
        class'Julia.Utils'.static.IsSpectatorName(self.GetName())
    );
}

/**
 * Return the current number of teamkills
 *
 * @return  int
 */
public function int GetTeamKills()
{
    return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetFriendlyKills();
}

/**
 * Return the last saved number of teamkills
 *
 * @return  int
 */
public function int GetLastTeamKills()
{
    return self.LastTeamKills;
}

/**
 * Return the number of times arrested
 *
 * @return  int
 */
public function int GetArrested()
{
    return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetTimesArrested();
}

/**
 * Return the last saved number of times arrested
 *
 * @return  int
 */
public function int GetLastArrested()
{
    return self.LastArrested;
}

/**
 * Return the number of VIP captures
 *
 * @return  int
 */
public function int GetVIPCaptures()
{
    return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetArrestedVIP();
}

/**
 * Return the last number of VIP captures
 *
 * @return  int
 */
public function int GetLastVIPCaptures()
{
    return self.LastVIPCaptures;
}

/**
 * Return the last number of vip rescues
 *
 * @return  int
 */
public function int GetVIPRescues()
{
    return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetUnarrestedVIP();
}

/**
 * Return the last saved number of vip rescues
 *
 * @return  int
 */
public function int GetLastVIPRescues()
{
    return self.LastVIPRescues;
}

/**
 * Return the number of vip escapes
 *
 * @return  int
 */
public function int GetVIPEscapes()
{
    return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetVIPPlayerEscaped();
}

/**
 * Return the last saved number of vip escapes
 *
 * @return  int
 */
public function int GetLastVIPEscapes()
{
    return self.LastVIPEscapes;
}

/**
 * Return the number of valid VIP kills
 *
 * @return  int
 */
public function int GetVIPKillsValid()
{
    return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetKilledVIPValid();
}

/**
 * Return the last saved number of VIP kills
 *
 * @return  int
 */
public function int GetLastVIPKillsValid()
{
    return self.LastVIPKillsValid;
}

/**
 * Return the number of invalid VIP kills
 *
 * @return  int
 */
public function int GetVIPKillsInvalid()
{
    return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetKilledVIPInvalid();
}

/**
 * Return the last saved number of invalid VIP kills
 *
 * @return  int
 */
public function int GetLastVIPKillsInvalid()
{
    return self.LastVIPKillsInvalid;
}

/**
 * Return the number of defused bombs
 *
 * @return  int
 */
public function int GetBombsDefused()
{
    return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetBombsDiffused();
}

/**
 * Return the last saved number of defused bombs
 *
 * @return  int
 */
public function int GetLastBombsDefused()
{
    return self.LastBombsDefused;
}

/**
 * Return the RD crybaby points (1)
 *
 * @return  int
 */
public function int GetRDCryBaby()
{
    return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetRDCrybaby();
}

/**
 * Return the last saved RD crybaby points
 *
 * @return  int
 */
public function int GetLastRDCryBaby()
{
    return self.LastRDCryBaby;
}

/**
 * Return the SG crybaby points (1)
 *
 * @return  int
 */
public function int GetSGCrybaby()
{
    #if IG_SPEECH_RECOGNITION
        return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetSGCrybaby();
    #else
        return 0;
    #endif
}

/**
 * Return the last saved SG crybaby points
 *
 * @return  int
 */
public function int GetLastSGCryBaby()
{
    return self.LastSGCryBaby;
}

/**
 * Return the number of case escapes
 *
 * @return  int
 */
public function int GetSGEscapes()
{
    #if IG_SPEECH_RECOGNITION
        return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetEscapedSG();
    #else
        return 0;
    #endif
}

/**
 * Return the last saved number of case escapes
 *
 * @return  int
 */
public function int GetLastSGEscapes()
{
    return self.LastSGEscapes;
}

/**
 * Return the number of case carrier kills
 *
 * @return  int
 */
public function int GetSGKills()
{
    #if IG_SPEECH_RECOGNITION
        return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetKilledSG();
    #else
        return 0;
    #endif
}

/**
 * Return the last saved number of case carrier kills
 *
 * @return  int
 */
public function int GetLastSGKills()
{
    return self.LastSGKills;
}

/**
 * Return the current player COOP status
 *
 * @return  enum'COOPStatus'
 */
public function COOPStatus GetCOOPStatus()
{
    return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).COOPPlayerStatus;
}

/**
 * Return the last saved coop status
 *
 * @return  enum'COOPStatus'
 */
public function COOPStatus GetLastCOOPStatus()
{
    return self.LastCOOPStatus;
}

/**
 * Return the time played since the last reset
 *
 * @return  float
 */
public function float GetTimePlayed()
{
    return self.TimePlayed;
}

/**
 * Return time the player has spent on the server
 *
 * @return  float
 */
public function float GetTimeTotal()
{
    return self.TimeTotal;
}

/**
 * Return the player score
 *
 * @return  int
 */
public function int GetScore()
{
    return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetScore();
}

/**
 * Return the last saved score
 *
 * @return  int
 */
public function int GetLastScore()
{
    return self.LastScore;
}

/**
 * Return number of player kills
 *
 * @return  int
 */
public function int GetKills()
{
    return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetEnemyKills();
}

/**
 * Return last saved number of kills
 *
 * @return  int
 */
public function int GetLastKills()
{
    return self.LastKills;
}

/**
 * Return the number of arrests
 *
 * @return  int
 */
public function int GetArrests()
{
    return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetArrests();
}

/**
 * Return the last saved number of arrests
 *
 * @return  int
 */
public function int GetLastArrests()
{
    return self.LastArrests;
}

/**
 * Return the current number of deaths
 *
 * @return  int
 */
public function int GetDeaths()
{
    return SwatPlayerReplicationInfo(self.PC.PlayerReplicationInfo).netScoreInfo.GetTimesDied();
}

/**
 * Return the last saved number of deaths
 *
 * @return  int
 */
public function int GetLastDeaths()
{
    return self.LastDeaths;
}

/**
 * Return the number of suicides
 *
 * @return  int
 */
public function int GetSuicides()
{
    return self.Suicides;
}

/**
 * Increment suicide count
 *
 * @return  void
 */
public function IncrementSuicides()
{
    self.Suicides++;
}

/**
 * Return the number of reported characters
 *
 * @return  int
 */
public function int GetCharacterReports()
{
    return self.CharacterReports;
}

/**
 * Increment the reported characters count
 *
 * @return  void
 */
public function IncrementCharacterReports()
{
    self.CharacterReports++;
}

/**
 * Return the number of civlian arrests
 *
 * @return  int
 */
public function int GetCivilianArrests()
{
    return self.CivilianArrests;
}

/**
 * Increment the civilian arrests count
 *
 * @return  void
 */
public function IncrementCivilianArrests()
{
    self.CivilianArrests++;
}

/**
 * Get the number of civilian hits
 *
 * @return  int
 */
public function int GetCivilianHits()
{
    return self.CivilianHits;
}

/**
 * Increment the civilian hits counter
 *
 * @return  void
 */
public function IncrementCivilianHits()
{
    self.CivilianHits++;
}

/**
 * Return the number of civilian incaps
 *
 * @return  int
 */
public function int GetCivilianIncaps()
{
    return self.CivilianIncaps;
}

/**
 * Increment the civilian incaps counter
 *
 * @return  void
 */
public function IncrementCivilianIncaps()
{
    self.CivilianIncaps++;
}

/**
 * Retur the number of civilian kills
 *
 * @return  int
 */
public function int GetCivilianKills()
{
    return self.CivilianKills;
}

/**
 * Increment the civilian kills counter
 *
 * @return  void
 */
public function IncrementCivilianKills()
{
    self.CivilianKills++;
}

/**
 * Return the number of enemy (AI suspects) arrests
 *
 * @return  int
 */
public function int GetEnemyArrests()
{
    return self.EnemyArrests;
}

/**
 * Increment the enemy arrests counter
 *
 * @return  void
 */
public function IncrementEnemyArrests()
{
    self.EnemyArrests++;
}

/**
 * Return the number of enemy incaps (valid)
 *
 * @return  int
 */
public function int GetEnemyIncaps()
{
    return self.EnemyIncaps;
}

/**
 * Increment the enemy incaps counter
 *
 * @return  void
 */
public function IncrementEnemyIncaps()
{
    self.EnemyIncaps++;
}

/**
 * Return the number of enemy invalid incaps
 *
 * @return  int
 */
public function int GetEnemyIncapsInvalid()
{
    return self.EnemyIncapsInvalid;
}

/**
 * Increment the enemy invalid incaps counter
 *
 * @return  void
 */
public function IncrementEnemyIncapsInvalid()
{
    self.EnemyIncapsInvalid++;
}

/**
 * Return the number of AI enemy kills
 *
 * @return  int
 */
public function int GetEnemyKills()
{
    return self.EnemyKills;
}

/**
 * Incremement the enemy kills counter
 *
 * @return  void
 */
public function IncrementEnemyKills()
{
    self.EnemyKills++;
}

/**
 * Return the number of enemy invalid kills
 *
 * @return  int
 */
public function int GetEnemyKillsInvalid()
{
    return self.EnemyKillsInvalid;
}

/**
 * Increment the invalid enemy kills counter
 *
 * @return  void
 */
public function IncrementEnemyKillsInvalid()
{
    self.EnemyKillsInvalid++;
}

/**
 * Return the current killstreak (since the last death)
 *
 * @return  int
 */
public function int GetCurrentKillStreak()
{
    return self.CurrentKillStreak;
}

/**
 * Return the best kill streak
 *
 * @return  int
 */
public function int GetBestKillStreak()
{
    return self.BestKillStreak;
}

/**
 * Return the current arrest streak (since the last death)
 *
 * @return  int
 */
public function int GetCurrentArrestStreak()
{
    return self.CurrentArrestStreak;
}

/**
 * Return the best arrest strreak
 *
 * @return  int
 */
public function int GetBestArrestStreak()
{
    return self.BestArrestStreak;
}

/**
 * Return the current death streak (since the last kill/arrest)
 *
 * @return  int
 */
public function int GetCurrentDeathStreak()
{
    return self.CurrentDeathStreak;
}

/**
 * Return the best death streak
 *
 * @return  int
 */
public function int GetBestDeathStreak()
{
    return self.BestDeathStreak;
}

/**
 * Return a Weapon class instance corresponding to the given weapon class name
 *
 * @param   string ClassName
 *          Weapon class name (e.g. M4A1MG)
 * @param   optional bool bForceCreate
 *          Indicate whether a new instance should be created on a lookup failure
 * @return  class'Weapon'
 */
public function Weapon GetWeaponByClassName(coerce string ClassName, optional bool bForceCreate)
{
    local int i;

    for (i = 0; i < self.Weapons.Length; i++)
    {
        if (self.Weapons[i].GetClassName() == ClassName)
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
 *
 * @param   string ClassName
 * @return  class'Weapon'
 */
protected function Weapon CreateWeapon(string ClassName)
{
    local Weapon Weapon;

    Weapon = Spawn(class'Weapon');
    Weapon.SetClassName(ClassName);
    Weapon.Init(self);

    self.Weapons[self.Weapons.Length] = Weapon;

    return Weapon;
}

/**
 * Queue a pawn hit
 *
 * @param   class'Pawn' Pawn
 *          Pawn instance of the hit actor
 * @param   name Type
 *          Hit type (incap, kill, etc)
 * @param   bool bThreat
 *          Indicate whether the hit AI actor was a threat
 * @return  void
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
 *
 * @param   class'Pawn' Pawn
 * @param   name Type
 * @return  bool
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
 * Queue a new stun of the type Type
 *
 * @param   name Type
 * @return  void
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
 *
 * @param   name Type
 * @param   class'Player' Damager
 * @param   float Time
 * @return  bool
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
 *
 * @param   class'Player' Other
 * @return  bool
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
