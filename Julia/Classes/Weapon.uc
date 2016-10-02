class Weapon extends SwatGame.SwatMutator;

var Player Player;  // The weapon owner

var string ClassName;  // M4A1MG, Glock9mmHG, etc

var int Shots;
var int Hits;
var int TeamHits;
var int Kills;
var int TeamKills;
var float TimeUsed;
var float LastFiredTime;
var float BestKillDistance;
var int LastAmmoCount;


public function PreBeginPlay()
{
    Super.PreBeginPlay();
    self.Disable('Tick');
}

public function Init(Player Player)
{
    self.Player = Player;
    log(self $ " has been initialized");
}

/**
 * Update weapon usage details
 *
 * @param   float Delta
 *          Tick rate
 * @param   class'FiredWeapon' FiredWeapon
 *          Reference to the weapon's corresponding FiredWeapon instance
 */
public function Update(float Delta, optional FiredWeapon FiredWeapon)
{
    local int CountCurrent, CountDiff;

    self.TimeUsed += Delta;

    if (FiredWeapon == None)
    {
        return;
    }

    CountCurrent = class'Utils'.static.GetAmmoCount(FiredWeapon);
    // Calculate the difference
    CountDiff = self.LastAmmoCount - CountCurrent;
    // Update firing and ammo details if fired
    if (CountDiff > 0)
    {
        self.IncrementShots(CountDiff);
    }
    self.LastAmmoCount = CountCurrent;
}

/**
 * Reset weapon usage details
 */
public function ResetInstance()
{
    log(self $ ".ResetInstance() has been invoked");

    self.TimeUsed = 0.0;
    self.Shots = 0;
    self.Hits = 0;
    self.TeamHits = 0;
    self.Kills = 0;
    self.TeamKills = 0;
    self.BestKillDistance = 0.0;
    self.LastAmmoCount = 0;
}

/**
 * Preserve the instance for further destruction but keep its stat properties
 */
public function PreserveInstance()
{
    log(self $ ".PreserveInstance() has been invoked");

    self.Player = None;
}

/**
 * Increment the ammo fired count by Value
 * Also attempt to update the owner's reference to the last fired weapon
 */
public function IncrementShots(int Value)
{
    self.Shots += Value;
    // Update firing time
    self.LastFiredTime = Level.TimeSeconds;
    self.Player.LastFiredWeapon = self;
    log(self $ ": " $ self.ClassName $ " of " $ self.Player.GetName() $ " fired");
}

/**
 * Return the weapon's friendly name (such as 9mm SMG or Colt M4A1 Carbine)
 */
public function string GetFriendlyName()
{
    return class'Utils'.static.GetItemFriendlyName(self.ClassName);
}

/**
 * Attempt to set a new kill distance record
 */
public function CheckKillDistance(float Distance)
{
    if (Distance > self.BestKillDistance)
    {
        self.BestKillDistance = Distance;
    }
}

/**
 * Tell whether the instance weapon belongs to the grenade class
 */
public function bool IsGrenade()
{
    return class'Utils'.static.IsGrenade(self.ClassName);
}

event Destroyed()
{
    self.Player = None;

    log(self $ " is about to be destroyed");

    Super.Destroyed();
}
