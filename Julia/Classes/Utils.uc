class Utils extends Engine.Actor;

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
 * Return Pawn's active item
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
 * Tell whether there are any admins on the server
 */
static function bool AnyAdminsOnServer(Engine.LevelInfo Level)
{
    local array<PlayerController> Admins;

    Admins = class'Utils.LevelUtils'.static.GetAdmins(Level);
    return Admins.Length > 0;
}

/**
 * Tell whether AdminMod is installed on the server
 */
static function bool IsAMEnabled(Engine.LevelInfo Level)
{
    return SwatGameInfo(Level.Game).Admin.IsA('AMAdmin');
}

/**
 * Attempt to issue an admin mod command
 * Return whether the admin command has been successfully issued
 *
 * @param   Level
 *          Reference to the current Level instance
 * @param   Cmd
 *          Admin command
 * @param   AdminName
 *          Admin name the command should be issued with
 * @param   AdminIP
 *          Admin IP the command should be logged with
 * @param   Msg (out, optional)
 *          Message returned by the underlying admin mod command handler
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
 */
static function string GetFriendlyMapName(coerce string Filename)
{
    local int i;
    local string NamePrefix, ShortName;
    // SP-, MP-
    NamePrefix = Caps(Left(Filename, 3));
    // SP and MP names share the same map title
    if (NamePrefix == "SP-" || NamePrefix == "MP-")
    {
        ShortName = Mid(Filename, 3);
    }
    else
    {
        ShortName = Filename;
    }

    i = class'Utils.ArrayUtils'.static.Search(class'Utils'.default.MapFile, ShortName, true);

    if (i >= 0)
    {
        return default.MapTitle[i];
    }

    return Filename;
}

/**
 * Return grenade class name corresponding to the given projectile class name
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
 */
static function bool IsGrenade(string ItemName)
{
    return (class'Utils.ArrayUtils'.static.Search(class'Utils'.default.GrenadeClass, ItemName, true) >= 0);
}

/**
 * Return the equipment item class name corresponding to its equipment item class name
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
 * @param   Name
 *          Original name
 * @param   Team
 *          Team number (0 - SWAT, 1 - Suspects)
 * @param   bVIP (optional)
 *          Whether the name should be painted green
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

    // Custom maps (unordered for a reason)
    // Thanks to ||ESA||RIddIk for all the hard work getting this list done.
    MapFile(24)="";
    MapFile(25)="FAIRFAX-Reloaded";
    MapFile(26)="FinalCrackDown_COOP";
    MapFile(27)="ApartmentNew";
    MapFile(28)="St_Paul_Asylum_v1_0";
    MapFile(29)="ESA_FoodWall";
    MapFile(30)="LA_MINA_15";
    MapFile(31)="Apollo_COOP-FIX";
    MapFile(32)="CaveComplex";
    MapFile(33)="SWAT4Predator2";
    MapFile(34)="EPpower-TSS";
    MapFile(35)="ConvenienceStore-smash2";
    MapFile(36)="BlackWater";
    MapFile(37)="The_Watercrip";
    MapFile(38)="2940_Enemy_Territory";
    MapFile(39)="Newfort24-TSS";
    MapFile(40)="DrugLab-RMX";
    MapFile(41)="Training-smash2";
    MapFile(42)="TheBuilding";
    MapFile(43)="Newfort24";
    MapFile(44)="ArmsDeal-smash2";
    MapFile(45)="Apollo-FIX";
    MapFile(46)="OfficeSpacev2";
    MapFile(47)="Panic-Room";
    MapFile(48)="Mistero18";
    MapFile(49)="PhoenixClub";
    MapFile(50)="Hive";
    MapFile(51)="U273";
    MapFile(52)="TheManor";
    MapFile(53)="Newfort27EXP";
    MapFile(54)="CityStreets";
    MapFile(55)="City_Hall";
    MapFile(56)="Bank-FIX";
    MapFile(57)="CARsDEALER";
    MapFile(58)="MoutMckenna";
    MapFile(59)="DesertOpsVillage";
    MapFile(60)="INTERVAL-17-rmx";
    MapFile(61)="Ashes_And_Ghosts_Night";
    MapFile(62)="Penthouse";
    MapFile(63)="Civil_Unrest";
    MapFile(64)="StormFront";
    MapFile(65)="JohnsonResidence";
    MapFile(66)="Prison";
    MapFile(67)="CBlock1_1";
    MapFile(68)="Hive1_1";
    MapFile(69)="BattleShips";
    MapFile(70)="Tenement-smash2";
    MapFile(71)="FastBreak-Through";
    MapFile(72)="ABomb-smash2";
    MapFile(73)="Ashes_And_Ghosts_Day";
    MapFile(74)="ESA-3or1";
    MapFile(75)="Terminal";
    MapFile(76)="Entrepot";
    MapFile(77)="Eter_trainingcenter";
    MapFile(78)="Sub";
    MapFile(79)="StuckInTheWoods";
    MapFile(80)="SistersofMercy-RMX";
    MapFile(81)="DNA-smash2";
    MapFile(82)="Courthouse-smash2";
    MapFile(83)="StuckInTheWoods";
    MapFile(84)="EPdrugsdeal-TSS";
    MapFile(85)="Snake-loft";
    MapFile(86)="NewfortBetaV2";
    MapFile(87)="BCv1";
    MapFile(88)="FairfaxResidence-smash2";
    MapFile(89)="Construction";
    MapFile(90)="SkyTower";
    MapFile(91)="Foodwall-smash2";
    MapFile(92)="Bank";
    MapFile(93)="DarkWaters";
    MapFile(94)="Apollo_COOP";
    MapFile(95)="FAYAsREFUGEES";
    MapFile(96)="AutoGarage-smash2";
    MapFile(97)="ResidentialOps";
    MapFile(98)="2940_Enemy_Territory";
    MapFile(99)="Clear";
    MapFile(100)="TantiveIV";
    MapFile(101)="RedLibrary-smash2";
    MapFile(102)="Dark_Scarlet";
    MapFile(103)="LA_MINA";
    MapFile(104)="PrecinctHQ";
    MapFile(105)="NOVATECHsBUILDING";
    MapFile(106)="MoutMckennaSnow";
    MapFile(107)="MP2-Desert_Dust";
    MapFile(108)="DesertOps2";
    MapFile(109)="ATLConvention";
    MapFile(110)="GangsterHangout";
    MapFile(111)="Renovate-TSS";
    MapFile(112)="BrentReloaded";
    MapFile(113)="Apollo";
    MapFile(114)="CHINA-HOTEL";
    MapFile(115)="MadShopping";
    MapFile(116)="School";
    MapFile(117)="JewelryHeist-smash2";
    MapFile(118)="Newfort100Sus";
    MapFile(119)="Amityville_Horror";
    MapFile(120)="USTT_Enemy_Territory2";
    MapFile(121)="ProjectSero";
    MapFile(122)="CBlock";
    MapFile(123)="Spedition";
    MapFile(124)="PowerPlant-smash2";
    MapFile(125)="Getts";
    MapFile(126)="CityHall";
    MapFile(127)="MP_Fy_iceworld2005";
    MapFile(128)="ArtCenter";
    MapFile(129)="Wainwright_Offices";
    MapFile(130)="Tenement-RMX";
    MapFile(131)="PoliceStation";
    MapFile(132)="Carlyle2k5v2-0";
    MapFile(133)="TheAsylum";
    MapFile(134)="FinalCrackDown_BARR";
    MapFile(135)="NewLibrary";
    MapFile(136)="StarWars";
    MapFile(137)="JohnsonResidence-FIX";
    MapFile(138)="Carlyle2k5-FIX";
    MapFile(139)="Hotel-smash2";
    MapFile(140)="Massacre";
    MapFile(141)="ClubATL";
    MapFile(142)="DELTA-CENTER";
    MapFile(143)="Mittelplate_Alpha";
    MapFile(144)="PANIC-ROOM-Coop";
    MapFile(145)="Mittelplate_Alpha";
    MapFile(146)="ResidentialOps";
    MapFile(147)="Nova-Corp";
    MapFile(148)="FlashLightTag";
    MapFile(149)="MadButcher";
    MapFile(150)="CREEPY-HOTEL";
    MapFile(151)="SSFNightRescue";
    MapFile(152)="Prison-TSS";
    MapFile(153)="Terminal";
    MapFile(154)="PaintballMadness";
    MapFile(155)="Madmap";
    MapFile(156)="ESA_Training";
    MapFile(157)="BATHS-Of-ANUBIS";
    MapFile(158)="DEAD_END";
    MapFile(159)="KEOWAREHOUSE";
    MapFile(160)="UsedCarLot";
    MapFile(161)="Ventura";
    MapFile(162)="UNDERGROUND";
    MapFile(163)="Hospital-smash2";
    MapFile(164)="Metropol";
    MapFile(165)="LeCamp";
    MapFile(166)="Last-Stop";
    MapFile(167)="KillingHouseSmall";
    MapFile(168)="Reaction_ak_colt";
    MapFile(169)="opfreedom";
    MapFile(170)="Genovese&Feinbloom";
    MapFile(171)="USTT_Enemy_Territory2";
    MapFile(172)="TheBuilding-v1_1";
    MapFile(173)="AssasinationRoom";
    MapFile(174)="DOCJT";
    MapFile(175)="CombatZone";
    MapFile(176)="ESA-Venturav1r1";
    MapFile(177)="EPhosp-TSS";
    MapFile(178)="Trainingcenter";
    MapFile(179)="Dusk";
    MapFile(180)="Rush";
    MapFile(181)="TRANSPORT";
    MapFile(182)="ParkingGarage";
    MapFile(183)="ClubATL";
    MapFile(184)="Terrorista";
    MapFile(185)="MeatBarn-smash2";
    MapFile(186)="Import";
    MapFile(187)="CineparkConflict";
    MapFile(188)="CabinFever";
    MapFile(189)="SwankyMansion";
    MapFile(190)="Apartment525";
    MapFile(191)="Warehouse5thStreet";
    MapFile(192)="DayBreak";
    MapFile(193)="Courthouse";
    MapFile(194)="Foodwall2";
    MapFile(195)="FedesNightmare";
    MapFile(196)="Central_Base";

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

    MapTitle(24)="Untitled";
    MapTitle(25)="Fairfaxe Reloaded";
    MapTitle(26)="Final Crack Down, COOP";
    MapTitle(27)="ApartmentNew";
    MapTitle(28)="Saint-Paul Asylum";
    MapTitle(29)="[c=ffff00]ESA's [c=1e90ff]Foodwall Edit";
    MapTitle(30)="La Mina v.1.5";
    MapTitle(31)="Operation Apollo COOP 1.1 - FIX";
    MapTitle(32)="Cave Complex";
    MapTitle(33)="Predator2";
    MapTitle(34)="{EP}Matt´s  Power Plant TSS";
    MapTitle(35)="Qwik Fuel (Desrat's SAG)";
    MapTitle(36)="Black Water-TTC 1.1";
    MapTitle(37)="The Watercrip";
    MapTitle(38)="2940 Enemy Territory MP";
    MapTitle(39)="Newfort (Revision 24) TSS";
    MapTitle(40)="-EXP- Drug Lab-RMX";
    MapTitle(41)="Riverside Training (Desrat's SAG)";
    MapTitle(42)="The Building";
    MapTitle(43)="Newfort (Revision 24)";
    MapTitle(44)="Wolcott (Desrat's SAG)";
    MapTitle(45)="Operation Apollo 1.1 - FIXED";
    MapTitle(46)="Office Space V2.0";
    MapTitle(47)="panic room";
    MapTitle(48)="mistero18-byilmassacratore";
    MapTitle(49)="The Phoenix Club";
    MapTitle(50)="The Hive (VIP)";
    MapTitle(51)="U-273";
    MapTitle(52)="The Manor - 1.1 - 2013";
    MapTitle(53)="-EXP- Newfort (Revision 27)";
    MapTitle(54)="City Streets 1.0";
    MapTitle(55)="LA City Hall";
    MapTitle(56)="-MODv- California Security Bank - FIXED";
    MapTitle(57)="Car's dealer v1.2";
    MapTitle(58)="Mout McKenna 1.0";
    MapTitle(59)="Desert ops -Village- 1.0";
    MapTitle(60)="INTERVAL - 17 - Rmx";
    MapTitle(61)="Ashes and Ghosts -Night-";
    MapTitle(62)="Penthouse";
    MapTitle(63)="Civil Unrest";
    MapTitle(64)="Storm Front";
    MapTitle(65)="Johnson Residence";
    MapTitle(66)="Operation Prison Break";
    MapTitle(67)="C-Block";
    MapTitle(68)="The Hive 1.1";
    MapTitle(69)="BattleShips";
    MapTitle(70)="Children of Taronne (Desrat's SAG)";
    MapTitle(71)="Fast Break - Through";
    MapTitle(72)="A-Bomb (Desrat's SAG)";
    MapTitle(73)="Ashes and Ghosts -Day-";
    MapTitle(74)="ESA's 3or1";
    MapTitle(75)="MP-Terminal";
    MapTitle(76)="The Entrepot";
    MapTitle(77)="E.T.E.R. Training Center";
    MapTitle(78)="Subway Station v1.0";
    MapTitle(79)="Stuck in the Woods";
    MapTitle(80)="-EXP- Sisters of Mercy-RMX";
    MapTitle(81)="Research Center (Desrat's SAG)";
    MapTitle(82)="Brewer County (Desrat's SAG)";
    MapTitle(83)="Stuck in the woods";
    MapTitle(84)="{EP}Matt´s Drugs Deal TSS";
    MapTitle(85)="Snake's loft";
    MapTitle(86)="NewfortBeta";
    MapTitle(87)="BLUES CLUB";
    MapTitle(88)="Fairfax Residence (Desrat's SAG)";
    MapTitle(89)="Construction";
    MapTitle(90)="Sky Tower";
    MapTitle(91)="Food Wall (Desrat's SAG)";
    MapTitle(92)="California Security Bank";
    MapTitle(93)="Dark Waters";
    MapTitle(94)="Operation Apollo COOP 1.1";
    MapTitle(95)="FAYA's REFUGEES v1.0";
    MapTitle(96)="Victory Imports (Desrat's SAG)";
    MapTitle(97)="Residential Ops.";
    MapTitle(98)="2940 Enemy Territory";
    MapTitle(99)="Clear - Room Service";
    MapTitle(100)="Tantive IV";
    MapTitle(101)="Red Library (Desrat's SAG)";
    MapTitle(102)="Dark Scarlet Restaurant";
    MapTitle(103)="LA MINA";
    MapTitle(104)="Precinct HQ 1.1";
    MapTitle(105)="Novatech's Building";
    MapTitle(106)="Mout McKenna Snow 1.0";
    MapTitle(107)="(SEALMAP)Desert_Dust";
    MapTitle(108)="Mogadishu Mile 1.0";
    MapTitle(109)="ATL Convention Center";
    MapTitle(110)="Gangster_Hangout";
    MapTitle(111)="(SEALMAP)Renovate TSS";
    MapTitle(112)="Brentwood Reloaded";
    MapTitle(113)="Operation Apollo 1.1";
    MapTitle(114)="The China Hotel";
    MapTitle(115)="Mad Shopping";
    MapTitle(116)="(SEALMAP)School";
    MapTitle(117)="Diamond Center (Desrat's SAG)";
    MapTitle(118)="Newfort2xSus";
    MapTitle(119)="Ocean Avenue 112";
    MapTitle(120)="|ustt| Enemy Territory V2";
    MapTitle(121)="Project -SERO- 1.0";
    MapTitle(122)="C-Block Taronne is back";
    MapTitle(123)="Reality Simulation Logistic V1.0";
    MapTitle(124)="Power Plant (Desrat's SAG)";
    MapTitle(125)="5455, Carlton Way";
    MapTitle(126)="Assault On City Hall";
    MapTitle(127)="Fy_Iceworld2005";
    MapTitle(128)="Art Center 1.0";
    MapTitle(129)="Wainwright Offices";
    MapTitle(130)="Children of Tenement-RMX";
    MapTitle(131)="Police Station 1.0 - 2013";
    MapTitle(132)="Hotel Carlyle 2005 v.2.0";
    MapTitle(133)="The Asylum";
    MapTitle(134)="Final Crack Down, Barricaded Suspects";
    MapTitle(135)="New Library 1.0";
    MapTitle(136)="Star Wars";
    MapTitle(137)="-MODv- Johnson Residence - FIXED";
    MapTitle(138)="-MODv- Hotel Carlyle 2005 - FIXED";
    MapTitle(139)="Old Granite Hotel (Desrat's SAG)";
    MapTitle(140)="Section 8 Fairfax Massacre";
    MapTitle(141)="Club ATL";
    MapTitle(142)="DELTA CENTER";
    MapTitle(143)="Mittelplate Alpha 1.1";
    MapTitle(144)="panic room Coop";
    MapTitle(145)="Mittelplate Alpha 1.2";
    MapTitle(146)="Residential Ops VIP";
    MapTitle(147)="Nova Corp.";
    MapTitle(148)="Flash Light Tag";
    MapTitle(149)="Mad Butcher`s Shop";
    MapTitle(150)="CREEPY HOTEL";
    MapTitle(151)="SSF Night Rescue";
    MapTitle(152)="Operation Prison Break TSS";
    MapTitle(153)="Terminal";
    MapTitle(154)="Paintball Madness";
    MapTitle(155)="Madmap";
    MapTitle(156)="[c=ffff00]ESA's [c=1e90ff]Riverside Edit";
    MapTitle(157)="The Baths Of Anubis";
    MapTitle(158)="DEAD_END";
    MapTitle(159)="KEOWAREHOUSE";
    MapTitle(160)="DeAdMaNs UsEd CaR LoT";
    MapTitle(161)="Ventura Hotel";
    MapTitle(162)="SP-UNDERGROUND";
    MapTitle(163)="Medical Center (Desrat's SAG)";
    MapTitle(164)="The Metropol";
    MapTitle(165)="MP-Le Camp";
    MapTitle(166)="SubWay";
    MapTitle(167)="The Killing House -Small-";
    MapTitle(168)="Reaction: Ak/Colt";
    MapTitle(169)="=HT=Operation Freedom";
    MapTitle(170)="Genovese & Feinbloom";
    MapTitle(171)="|ustt| Enemy Territory V2 CoOp";
    MapTitle(172)="The Building v1.1";
    MapTitle(173)="AssasinationRoom, Aupicia:Clan A-T";
    MapTitle(174)="Department Of Criminal Justice V1";
    MapTitle(175)="Combat Zone";
    MapTitle(176)="Ventura Hotel v1r1";
    MapTitle(177)="{EP}Matt´s Medical Center TSS";
    MapTitle(178)="SSF TrainingCenter 1.0";
    MapTitle(179)="Operation Dusk Till Dawn";
    MapTitle(180)="MP Rush";
    MapTitle(181)="SP-TRANSPORT";
    MapTitle(182)="Parking Garage v1.0";
    MapTitle(183)="Club -[*ATL*]-";
    MapTitle(184)="TERRORISTA";
    MapTitle(185)="Meat Barn (Desrat's SAG)";
    MapTitle(186)="Gris Import Export";
    MapTitle(187)="The Cinepark Conflict";
    MapTitle(188)="Cabin Fever";
    MapTitle(189)="Swanky Mansion";
    MapTitle(190)="Apartment 525";
    MapTitle(191)="Warehouse 5th Street";
    MapTitle(192)="Operation DayBreak";
    MapTitle(193)="Brewer County Courthouse COOP";
    MapTitle(194)="Food Wall Restaurant butchered";
    MapTitle(195)="Fede's Nightmare";
    MapTitle(196)="(SEALMAP)Central_Base";

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

    HitPrecision_Lethal=(-0.75,1.5);    // 1.5 is for grenade launcher
    HitPrecision_Taser=(-0.5,0.5);
    HitPrecision_LessLethalSG=(-0.5,0.5);
    HitPrecision_Flashbang=(0.0,0.5);
    HitPrecision_Stinger=(0.0,0.5);
    HitPrecision_Gas=(0.0,0.0);
    HitPrecision_Spray=(-0.5,0.5);
    HitPrecision_TripleBaton=(-0.5,1.5);
}
