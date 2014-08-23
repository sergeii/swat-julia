class Utils extends Engine.Actor;

/**
 * Copyright (c) 2014 Sergei Khoroshilov <kh.sergei@gmail.com>
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

/**
 * List of map filenames (without extension) 
 * corresponding to their respective titles from the MapTitle array
 * @example "Courthouse", "JewelryHeist"
 * @type array<string>
 */
var array<string> MapFile;

/**
 * List of map user friendly titles
 * corresponding to their respective filenames from the MapFile array
 * @example "Brewer County Courthouse", "DuPlessis Diamond Center"
 * @type array<string>
 */
var array<string> MapTitle;

/**
 * List of equipment class names corresponding
 * to their respective titles from the EquipmentTitle array
 * @example "HeavyBodyArmor", "Glock9mmHG"
 * @type array<string>
 */
var array<string> EquipmentClass;

/**
 * List of user friendly equipment titles corresponding
 * to their respective class names from the EquipmentClass array
 * @example "Heavy Armor", "9mm Handgun"
 * @type array<string>
 */
var array<string> EquipmentTitle;

/**
 * List of grenade class names corresponding
 * to their respective projectile class names from the GrenadeProjectileClass array
 * @type array<string>
 */
var array<string> GrenadeClass;

/**
 * List of grenade projectile class names corresponding
 * to their respective grenade class names from the GrenadeClass array
 * @type array<string>
 */
var array<string> GrenadeProjectileClass;

/**
 * List of unsafe string characters
 * @type array<string>
 */
var array<string> UnsafeChars;

/**
 * List of Taser weapons (class names)
 * @type array<string>
 */
var array<string> StunWeapons_Taser;

/**
 * List of less-lethal weapons (class names)
 * @type array<string>
 */
var array<string> StunWeapons_LessLethalSG;

/**
 * List of Flashbang-like equipment (class names)
 * @type array<string>
 */
var array<string> StunWeapons_Flashbang;

/**
 * List of Stinger-like equipment (class names)
 * @type array<string>
 */
var array<string> StunWeapons_Stinger;

/**
 * List of CS Gas-like equipment (class names)
 * @type array<string>
 */
var array<string> StunWeapons_Gas;

/**
 * List of Pepper spray-like equipment (class names)
 * @type array<string>
 */
var array<string> StunWeapons_Spray;

/**
 * List of Triple Baton-like equipment
 * @type array<string>
 */
var array<string> StunWeapons_TripleBaton;

/**
 * Hit precision for all lethal weapons
 * @type array<float[2]>
 */
var array<float> HitPrecision_Lethal;

/**
 * Hit precision for taser equipment
 * @type array<float[2]>
 */
var array<float> HitPrecision_Taser;

/**
 * Hit precicion for less lethal shotgun weapon class
 * @type array<float[2]>
 */
var array<float> HitPrecision_LessLethalSG;

/**
 * Hit precision for flashbang grenades
 * @type array<float[2]>
 */
var array<float> HitPrecision_Flashbang;

/**
 * Hit precision for stinger grenades
 * @type array<float[2]>
 */
var array<float> HitPrecision_Stinger;

/**
 * Hit precision for cs gas grenades
 * @type array<float[2]>
 */
var array<float> HitPrecision_Gas;

/**
 * Hit precision for pepper spray
 * @type array<float[2]>
 */
var array<float> HitPrecision_Spray;

/**
 * Hit precision for triple baton grenade
 * @type array<float[2]>
 */
var array<float> HitPrecision_TripleBaton;

/**
 * Return the Pawn's active item
 * 
 * @param   class'Pawn' Pawn
 * @return  class'HandheldEquipment'
 */
static function HandheldEquipment GetActiveItem(Pawn Pawn)
{
    if (Pawn != None)
    {
        return NetPlayer(Pawn).GetActiveItem();
    }
    return None;
}

/**
 * Tell whether AdminMod is installed on the server
 *
 * @param   class'LevelInfo' Level
 *          Reference to the current Level instance
 * @return  bool
 */
static function bool IsAMEnabled(Engine.LevelInfo Level)
{
    return SwatGameInfo(Level.Game).Admin.IsA('AMAdmin');
}

/**
 * Attempt to issue an admin mod command
 *
 * @param   class'LevelInfo' Level
 *          Reference to the current Level instance
 * @param   string Cmd 
 *          Admin command
 * @param   string AdminName
 *          Admin name the command should be issued with
 * @param   string AdminIP
 *          Admin IP the command should be logged with
 * @param   string Msg (out, optional)
 *          Message returned by the underlying admin mod command handler
 * @return  bool
 *          Return whether the admin command has been successfully issued
 */
static function bool AdminModCommand(Engine.LevelInfo Level, string Cmd, string AdminName, string AdminIP, out optional string Msg)
{
    if (class'Utils'.static.IsAMEnabled(Level))
    {
        SwatGameInfo(Level.Game).Admin.AdminCommand(Cmd, AdminName, AdminIP, None, Msg);
        return true;
    }
    return false;
}

/**
 * Return ammo count for the given FiredWeapon instance
 * 
 * @return  int
 */
static function int GetAmmoCount(FiredWeapon FiredWeapon)
{
    local int i, AmmoCount;

    if (FiredWeapon != None)
    {
        for (i = 0; i < 10; i++)
        {
            AmmoCount += FiredWeapon.Ammo.GetClip(i);
        }
    }
    return AmmoCount;
}

/**
 * Tell whether the given PlayerController instance belongs to an online player
 * 
 * @param   class'PlayerController' PC
 * @return  bool
 */
static function bool IsOnlinePlayer(Engine.LevelInfo Level, PlayerController PC)
{
    return (
        PC != None && 
        SwatGamePlayerController(PC) != None &&
        (NetConnection(PC.Player) != None || PC == Level.GetLocalPlayerController()) &&
        SwatGamePlayerController(PC).SwatRepoPlayerItem != None
    );
}

/**
 * Return filename of the map next in the rotation list
 * 
 * @return  string
 */
static function string GetNextMap(Engine.LevelInfo Level)
{
    local int i;

    i = ServerSettings(Level.CurrentServerSettings).MapIndex + 1;
    // If current map is the last in rotation, return the first element
    if (i >= ServerSettings(Level.CurrentServerSettings).NumMaps)
    {
        i = 0;
    }
    return ServerSettings(Level.CurrentServerSettings).Maps[i];
}

/**
 * Return friendly map name for the given filename
 * 
 * @param   string Filename
 * @return  string
 */
static function string GetFriendlyMapName(coerce string Filename)
{
    local int i;
    // Cut SP-, MP- prefixes
    i = class'Utils.ArrayUtils'.static.Search(class'Utils'.default.MapFile, Mid(Filename, 3), true);

    if (i >= 0)
    {
        return default.MapTitle[i];
    }

    return Filename;
}

/**
 * Return grenade class name corresponding to the given projectile class name
 * 
 * @param   string ProjectileClassName
 * @return  string
 */
static function string GetGrenadeClassName(coerce string ProjectileClassName)
{
    local int i;

    i = class'Utils.ArrayUtils'.static.Search(class'Utils'.default.GrenadeProjectileClass, ProjectileClassName, true);
    
    if (i >= 0)
    {
        return default.GrenadeClass[i];
    }
    
    return ProjectileClassName;
}

/**
 * Return whether the given equipment item class name belongs to the grenade list
 * 
 * @param   string ItemName
 * @return  bool
 */
static function bool IsGrenade(string ItemName)
{
    return (class'Utils.ArrayUtils'.static.Search(class'Utils'.default.GrenadeClass, ItemName, true) >= 0);
}

/**
 * Return the equipment item class name corresponding to its equipment item class name
 * 
 * @param   string ItemClassName
 * @return  string
 */
static function string GetItemFriendlyName(coerce string ItemClassName)
{
    local int i;

    i = class'Utils.ArrayUtils'.static.Search(class'Utils'.default.EquipmentClass, ItemClassName, true);

    if (i >= 0)
    {
        return default.EquipmentTitle[i];
    }

    return ItemClassName;
}

/**
 * Remove unsafe characters from a string
 * 
 * @param   string String
 * @return  string
 */
static function string EscapeString(string String)
{
    local int i;

    for (i = 0; i < class'Utils'.default.UnsafeChars.Length; i++)
    {
        String = class'Utils.StringUtils'.static.Replace(String, class'Utils'.default.UnsafeChars[i], "_");
    }

    return String;
}

/**
 * Return hit precision error for the given weapon category
 *  
 * @param   name Type
 * @return  array<float[2]>
 */
static function array<float> GetHitPrecision(name Type)
{
    local array<float> Empty;

    switch (Type)
    {
        case 'Lethal' :
            return class'Utils'.default.HitPrecision_Lethal;
        case 'Taser' :
            return class'Utils'.default.HitPrecision_Taser;
        case 'LessLethalSG' :
            return class'Utils'.default.HitPrecision_LessLethalSG;
        case 'Flashbang' :
            return class'Utils'.default.HitPrecision_Flashbang;
        case 'Stinger' :
            return class'Utils'.default.HitPrecision_Stinger;
        case 'Gas' :
            return class'Utils'.default.HitPrecision_Gas;
        case 'Spray' :
            return class'Utils'.default.HitPrecision_Spray;
        case 'TripleBaton' :
            return class'Utils'.default.HitPrecision_TripleBaton;
        default :
            return Empty;
    }
}

/**
 * Return an array of stun weapons corresponding to the given stun type
 * 
 * @param   name Type
 * @return  array<string>
 */
public static function array<string> GetStunWeapons(name Type)
{
    local array<string> Empty;

    switch (Type)
    {
        case 'Taser' :
            return class'Utils'.default.StunWeapons_Taser;
        case 'LessLethalSG' :
            return class'Utils'.default.StunWeapons_LessLethalSG;
        case 'Flashbang' :
            return class'Utils'.default.StunWeapons_Flashbang;
        case 'Stinger' :
            return class'Utils'.default.StunWeapons_Stinger;
        case 'Gas' :
            return class'Utils'.default.StunWeapons_Gas;
        case 'Spray' :
            return class'Utils'.default.StunWeapons_Spray;
        case 'TripleBaton' :
            return class'Utils'.default.StunWeapons_TripleBaton;
        default :
            return Empty;
    }
}

/**
 * Return the player name painted with team matching color
 *
 * @param   string Name
 *          Original name
 * @param   int int Team
 *          Team number (0 - SWAT, 1 - Suspects)
 * @param   bool bVIP (optional)
 *          Indicate whether the name should be painted green
 * @return  string
 */
static function string GetTeamColoredName(string Name, int Team, optional bool bVIP)
{
    // Filter existing color tags
    Name = class'Utils.StringUtils'.static.Filter(Name);
    // Green
    if (bVIP)
    {
        return "[c=00FF00]" $ Name $ "[\\c]";
    }
    // Blue
    else if (Team == 0)
    {
        return "[c=0000FF]" $ Name $ "[\\c]";
    }
    // Red
    return "[c=FF0000]" $ Name $ "[\\c]";
}

/**
 * Tell whether given name contains (SPEC) or (VIEW) suffix
 * 
 * @param   string Name
 * @return  bool
 */
static function bool IsSpectatorName(string Name)
{
    switch (Right(Name, 6))
    {
        case "(SPEC)":
        case "(VIEW)":
            return true;
    }
    return false;
}

defaultproperties
{
    MapFile(0)="ABomb";
    MapFile(1)="Courthouse";
    MapFile(2)="Tenement";
    MapFile(3)="JewelryHeist";
    MapFile(4)="PowerPlant";
    MapFile(5)="FairfaxResidence";
    MapFile(6)="Foodwall";
    MapFile(7)="MeatBarn";
    MapFile(8)="DNA";
    MapFile(9)="Casino";
    MapFile(10)="Hotel";
    MapFile(11)="ConvenienceStore";
    MapFile(12)="RedLibrary";
    MapFile(13)="Training";
    MapFile(14)="Hospital";
    MapFile(15)="ArmsDeal";
    MapFile(16)="AutoGarage";
    MapFile(17)="Arcade";
    MapFile(18)="HalfwayHouse";
    MapFile(19)="Backstage";
    MapFile(20)="Office";
    MapFile(21)="DrugLab";
    MapFile(22)="Subway";
    MapFile(23)="Warehouse";

    MapTitle(0)="A-Bomb Nightclub";
    MapTitle(1)="Brewer County Courthouse";
    MapTitle(2)="Children of Taronne Tenement";
    MapTitle(3)="DuPlessis Diamond Center";
    MapTitle(4)="Enverstar Power Plant";
    MapTitle(5)="Fairfax Residence";
    MapTitle(6)="Food Wall Restaurant";
    MapTitle(7)="Meat Barn Restaurant";
    MapTitle(8)="Mt. Threshold Research Center";
    MapTitle(9)="Northside Vending";
    MapTitle(10)="Old Granite Hotel";
    MapTitle(11)="Qwik Fuel Convenience Store";
    MapTitle(12)="Red Library Offices";
    MapTitle(13)="Riverside Training Facility";
    MapTitle(14)="St. Michael's Medical Center";
    MapTitle(15)="The Wolcott Projects";
    MapTitle(16)="Victory Imports Auto Center";
    MapTitle(17)="-EXP- Department of Agriculture";
    MapTitle(18)="-EXP- Drug Lab";
    MapTitle(19)="-EXP- Fresnal St. Station";
    MapTitle(20)="-EXP- FunTime Amusements";
    MapTitle(21)="-EXP- Sellers Street Auditorium";
    MapTitle(22)="-EXP- Sisters of Mercy Hostel";
    MapTitle(23)="-EXP- Stetchkov Warehouse";

    EquipmentClass(0)="None";
    EquipmentClass(1)="M4Super90SG";                    // M4 Super90
    EquipmentClass(2)="NovaPumpSG";                     // Nova Pump
    EquipmentClass(3)="BreachingSG";                    // Shotgun
    EquipmentClass(4)="LessLethalSG";                   // Less Lethal Shotgun
    EquipmentClass(5)="CSBallLauncher";                 // Pepper-ball
    EquipmentClass(6)="M4A1MG";                         // Colt M4A1 Carbine
    EquipmentClass(7)="AK47MG";                         // AK-47 Machinegun
    EquipmentClass(8)="G36kMG";                         // GB36s Assault Rifle
    EquipmentClass(9)="UZISMG";                         // Gal Sub-machinegun
    EquipmentClass(10)="MP5SMG";                        // 9mm SMG
    EquipmentClass(11)="SilencedMP5SMG";                // Suppressed 9mm SMG
    EquipmentClass(12)="UMP45SMG";                      // .45 SMG
    EquipmentClass(13)="ColtM1911HG";                   // M1911 Handgun
    EquipmentClass(14)="Glock9mmHG";                    // 9mm Handgun
    EquipmentClass(15)="PythonRevolverHG";              // Colt Python
    EquipmentClass(16)="Taser";                         // Taser Stun Gun
    EquipmentClass(17)="VIPColtM1911HG";                // VIP Colt M1911 Handgun
    EquipmentClass(18)="VIPGrenade";                    // CS Gas
    EquipmentClass(19)="LightBodyArmor";                // Light Armor
    EquipmentClass(20)="HeavyBodyArmor";                // Heavy Armor
    EquipmentClass(21)="gasMask";                       // Gas Mask (lower-case)
    EquipmentClass(22)="HelmetAndGoggles";              // Helmet
    EquipmentClass(23)="FlashbangGrenade";              // Flashbang
    EquipmentClass(24)="CSGasGrenade";                  // CS Gas
    EquipmentClass(25)="stingGrenade";                  // Stinger (lower-case)
    EquipmentClass(26)="PepperSpray";                   // Pepper Spray
    EquipmentClass(27)="Optiwand";                      // Optiwand
    EquipmentClass(28)="Toolkit";                       // Toolkit
    EquipmentClass(29)="Wedge";                         // Door Wedge
    EquipmentClass(30)="C2Charge";                      // C2
    EquipmentClass(31)="detonator";                     // The Detonator
    EquipmentClass(32)="Cuffs";                         // Zip-cuffs
    EquipmentClass(33)="IAmCuffed";                     // 
    EquipmentClass(34)="ColtAccurizedRifle";            // Colt Accurized Rifle
    EquipmentClass(35)="HK69GrenadeLauncher";           // 40mm Grenade Launcher
    EquipmentClass(36)="SAWMG";                         // 5.56mm Light Machine Gun
    EquipmentClass(37)="FNP90SMG";                      // 5.7x28mm Submachine Gun
    EquipmentClass(38)="DesertEagleHG";                 // Mark 19 Semi-Automatic Pistol
    EquipmentClass(39)="TEC9SMG";                       // 9mm Machine Pistol
    EquipmentClass(40)="Stingray";                      // Cobra Stun Gun
    EquipmentClass(41)="AmmoBandolier";                 // Ammo Pouch
    EquipmentClass(42)="NoBodyArmor";                   // No Armor
    EquipmentClass(43)="NVGoggles";                     // Night Vision Goggles
    EquipmentClass(44)="HK69GL_StingerGrenadeAmmo";     // Stinger
    EquipmentClass(45)="HK69GL_CSGasGrenadeAmmo";       // CS Gas
    EquipmentClass(46)="HK69GL_FlashbangGrenadeAmmo";   // Flashbang
    EquipmentClass(47)="HK69GL_TripleBatonAmmo";        // Baton

    EquipmentTitle(0)="None";
    EquipmentTitle(1)="M4 Super90";
    EquipmentTitle(2)="Nova Pump";
    EquipmentTitle(3)="Shotgun";
    EquipmentTitle(4)="Less Lethal Shotgun";
    EquipmentTitle(5)="Pepper-ball";
    EquipmentTitle(6)="Colt M4A1 Carbine";
    EquipmentTitle(7)="AK-47 Machinegun";
    EquipmentTitle(8)="GB36s Assault Rifle";
    EquipmentTitle(9)="Gal Sub-machinegun";
    EquipmentTitle(10)="9mm SMG";
    EquipmentTitle(11)="Suppressed 9mm SMG";
    EquipmentTitle(12)=".45 SMG";
    EquipmentTitle(13)="M1911 Handgun";
    EquipmentTitle(14)="9mm Handgun";
    EquipmentTitle(15)="Colt Python";
    EquipmentTitle(16)="Taser Stun Gun";
    EquipmentTitle(17)="VIP Colt M1911 Handgun";
    EquipmentTitle(18)="CS Gas";
    EquipmentTitle(19)="Light Armor";
    EquipmentTitle(20)="Heavy Armor";
    EquipmentTitle(21)="Gas Mask";
    EquipmentTitle(22)="Helmet";
    EquipmentTitle(23)="Flashbang";
    EquipmentTitle(24)="CS Gas";
    EquipmentTitle(25)="Stinger";
    EquipmentTitle(26)="Pepper Spray";
    EquipmentTitle(27)="Optiwand";
    EquipmentTitle(28)="Toolkit";
    EquipmentTitle(29)="Door Wedge";
    EquipmentTitle(30)="C2 (x3)";
    EquipmentTitle(31)="The Detonator";
    EquipmentTitle(32)="Zip-cuffs";
    EquipmentTitle(33)="IAmCuffed";
    EquipmentTitle(34)="Colt Accurized Rifle";
    EquipmentTitle(35)="40mm Grenade Launcher";
    EquipmentTitle(36)="5.56mm Light Machine Gun";
    EquipmentTitle(37)="5.7x28mm Submachine Gun";
    EquipmentTitle(38)="Mark 19 Semi-Automatic Pistol";
    EquipmentTitle(39)="9mm Machine Pistol";
    EquipmentTitle(40)="Cobra Stun Gun";
    EquipmentTitle(41)="Ammo Pouch";
    EquipmentTitle(42)="No Armor";
    EquipmentTitle(43)="Night Vision Goggles";
    EquipmentTitle(44)="Stinger";
    EquipmentTitle(45)="CS Gas";
    EquipmentTitle(46)="Flashbang";
    EquipmentTitle(47)="Baton";

    GrenadeClass(0)="stingGrenade";  //lower-case
    GrenadeClass(1)="CSGasGrenade";
    GrenadeClass(2)="VIPGrenade";
    GrenadeClass(3)="FlashbangGrenade";
    GrenadeClass(4)="HK69GL_StingerGrenadeAmmo";
    GrenadeClass(5)="HK69GL_CSGasGrenadeAmmo";
    GrenadeClass(6)="HK69GL_FlashbangGrenadeAmmo";
    GrenadeClass(7)="HK69GL_TripleBatonAmmo";

    GrenadeProjectileClass(0)="StingGrenadeProjectile";
    GrenadeProjectileClass(1)="CSGasGrenadeProjectile";
    GrenadeProjectileClass(2)="VIPGrenadeProjectile";
    GrenadeProjectileClass(3)="FlashbangGrenadeProjectile";
    GrenadeProjectileClass(4)="StingGrenadeProjectile_HK69";
    GrenadeProjectileClass(5)="CSGasGrenadeProjectile_HK69";
    GrenadeProjectileClass(6)="FlashbangGrenadeProjectile_HK69";
    GrenadeProjectileClass(7)="TripleBatonProjectile_HK69";

    UnsafeChars(0)="\\t";
    UnsafeChars(1)="\\\\";

    StunWeapons_Taser=("Taser","Stingray");
    StunWeapons_LessLethalSG=("LessLethalSG");
    StunWeapons_Flashbang=("FlashbangGrenade","HK69GL_FlashbangGrenadeAmmo");
    StunWeapons_Stinger=("stingGrenade","HK69GL_StingerGrenadeAmmo");
    StunWeapons_Gas=("CSGasGrenade","VIPGrenade","CSBallLauncher","HK69GL_CSGasGrenadeAmmo");
    StunWeapons_Spray=("PepperSpray");
    StunWeapons_TripleBaton=("HK69GrenadeLauncher");

    HitPrecision_Lethal=(-0.25,1.5);    // 1.5 is for grenade launcher
    HitPrecision_Taser=(0.0,0.0);
    HitPrecision_LessLethalSG=(0.0,0.0);
    HitPrecision_Flashbang=(0.0,0.2);
    HitPrecision_Stinger=(0.0,0.2);
    HitPrecision_Gas=(0.0,1.0);
    HitPrecision_Spray=(0.0,0.0);
    HitPrecision_TripleBaton=(0.0,1.5);
}

/* vim: set ft=java: */