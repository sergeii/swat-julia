class Weapon extends SwatGame.SwatMutator;

/**
 * Reference to the weapon owner
 * @type class'Player'
 */
var protected Player Player;

/**
 * Weapon class name (M4A1MG, Glock9mmHG, etc)
 * @type string
 */
var protected string ClassName;

/**
 * Number of ammo fired
 * @type int
 */
var protected int Shots;

/**
 * Number of enemy hits
 * @type int
 */
var protected int Hits;

/**
 * Number of team hits
 * @type int
 */
var protected int TeamHits;

/**
 * Number of enemy kills
 * @type int
 */
var protected int Kills;

/**
 * Number of team kills
 * @type int
 */
var protected int TeamKills;

/**
 * Time in use (seconds)
 * @type float
 */
var protected float TimeUsed;

/**
 * Time the weapon was last fired (Level.TimeSeconds)
 * @type float
 */
var protected float LastFiredTime;

/**
 * Best kill distance for this weapon
 * @type float
 */
var protected float BestKillDistance;

/**
 * Last ammo count
 * @type int
 */
var protected int LastAmmoCount;

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
 * Initialize the instance
 *
 * @param   class'Player' Player
 *          Reference to the owner
 * @return  void
 */
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
 * @return  void
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
 *
 * @return  void
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
 *
 * @return  void
 */
public function PreserveInstance()
{
    log(self $ ".PreserveInstance() has been invoked");

    self.Player = None;
}

/**
 * Return the last firing time
 *
 * @return  float
 */
public function float GetLastFiredTime()
{
    return self.LastFiredTime;
}

/**
 * Attempt to set a new kill distance record
 *
 * @param   float Distance
 * @return  void
 */
public function CheckKillDistance(float Distance)
{
    if (Distance > self.BestKillDistance)
    {
        self.BestKillDistance = Distance;
    }
}

/**
 * Return the best kill distance value
 *
 * @return  float
 */
public function float GetBestKillDistance()
{
    return self.BestKillDistance;
}

/**
 * Return the weapon class name
 *
 * @return  string
 */
public function string GetClassName()
{
    return self.ClassName;
}

/**
 * Return the weapon's friendly name (such as 9mm SMG or Colt M4A1 Carbine)
 *
 * @return  string
 */
public function string GetFriendlyName()
{
    return class'Utils'.static.GetItemFriendlyName(self.ClassName);
}

/**
 * Tell whether the instance weapon belongs to the grenade class
 *
 * @return bool
 */
public function bool IsGrenade()
{
    return class'Utils'.static.IsGrenade(self.ClassName);
}

/**
 * Return the time in use value
 *
 * @return  float
 */
public function float GetTimeUsed()
{
    return self.TimeUsed;
}

/**
 * Return the number of ammo fired
 *
 * @return  int
 */
public function int GetShots()
{
    return self.Shots;
}

/**
 * Return the number of weapon enemy hits
 *
 * @return  int
 */
public function int GetHits()
{
    return self.Hits;
}

/**
 * Return the number of team hits performed with the weapon
 *
 * @return  int
 */
public function int GetTeamHits()
{
    return self.TeamHits;
}

/**
 * Return the number of kills performed with the weapon
 *
 * @return  int
 */
public function int GetKills()
{
    return self.Kills;
}

/**
 * Return the number of teamkills performed with the weapon
 *
 * @return  int
 */
public function int GetTeamKills()
{
    return self.TeamKills;
}

/**
 * Set the weapon class name (e.g. M4A1MG)
 *
 * @param   string Name
 * @return  void
 */
public function SetClassName(string Name)
{
    self.ClassName = Name;
}

/**
 * Increment the number of shots fired
 *
 * @return  void
 */
public function IncrementHits()
{
    self.Hits++;
}

/**
 * Increment the teamhits property
 *
 * @return  void
 */
public function IncrementTeamHits()
{
    self.TeamHits++;
}

/**
 * Incremenent the weapon kills property
 *
 * @return  void
 */
public function IncrementKills()
{
    self.Kills++;
}

/**
 * Increment the TeamKills property
 *
 * @return  void
 */
public function IncrementTeamKills()
{
    self.TeamKills++;
}

/**
 * Increment the ammo fired count by Value
 * Also attempt to update the owner's reference to the last fired weapon
 *
 * @param   int Value
 * @return  void
 */
public function IncrementShots(int Value)
{
    self.Shots += Value;
    // Update firing time
    self.LastFiredTime = Level.TimeSeconds;
    self.Player.SetLastFiredWeapon(self);
    log(self $ ": " $ self.ClassName $ " of " $ self.Player.GetName() $ " fired");
}

event Destroyed()
{
    self.Player = None;

    log(self $ " is about to be destroyed");

    Super.Destroyed();
}
