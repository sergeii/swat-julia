class Tracker extends Extension
  implements InterestedInMissionEnded,
             HTTP.ClientOwner;

import enum Pocket from Engine.HandheldEquipment;
import enum ObjectiveStatus from SwatGame.Objective;
import enum eClientError from HTTP.Client;

const KEY_DELIMITER = ".";
const REQUEST_ID_LENGTH = 8;

enum eRootKey
{
    RK_REQUEST_ID,          /* 0 Unique REQUEST_ID_LENGTH-long request id */
    RK_VERSION,             /* 1 Version of the tracker extension */
    RK_PORT,                /* 2 Join port */
    RK_TIMESTAMP,           /* 3 Current unix timestamp */
    RK_HASH,                /* 4 Server hash signature */

    RK_GAME_TITLE,          /* 5 Game title (SWAT 4/SWAT 4 X, encoded) Default 0 */
    RK_GAME_VERSION,        /* 6 Game version 1.0, 1.1, etc */

    RK_HOSTNAME,            /* 7 Server name */
    RK_GAMETYPE,            /* 8 Gametype (encoded) Default 0 */
    RK_MAP,                 /* 9 Map (encoded) Default 0 */
    RK_PASSWORDED,          /* 10 Password protection Default 0 */

    RK_PLAYER_COUNT,        /* 11 Current player count */
    RK_PLAYER_LIMIT,        /* 12 Player limit */

    RK_ROUND_INDEX,         /* 13 Current round index Default 0*/
    RK_ROUND_LIMIT,         /* 14 Rounds per map limit */

    RK_TIME_ABSOLUTE,       /* 15 Time elapsed since the round start */
    RK_TIME_PLAYED,         /* 16 Game time */
    RK_TIME_LIMIT,          /* 17 Game time limit */

    RK_SWAT_ROUNDS,         /* 18 SWAT victories Default 0 */
    RK_SUS_ROUNDS,          /* 19 Suspects victories Default 0*/

    RK_SWAT_SCORE,          /* 20 SWAT score Default 0 */
    RK_SUS_SCORE,           /* 21 Suspects score Default 0*/

    RK_OUTCOME,             /* 22 Round outcome (encoded) */

    RK_BOMBS_DEFUSED,       /* 23 Number of bombs defused Default 0 */
    RK_BOMBS_TOTAL,         /* 24 Total number of bombs Default 0 */

    RK_OBJECTIVES,          /* 25 List of COOP objectives */
    RK_PROCEDURES,          /* 26 List of COOP procedures */

    RK_PLAYERS,             /* 27 List of all players participated in the game */
};

enum ePlayerKey
{
    PK_ID,                  /* 0 */
    PK_IP,                  /* 1 */

    PK_DROPPED,             /* 2 */
    PK_ADMIN,               /* 3 */
    PK_VIP,                 /* 4 */

    PK_NAME,                /* 5 */
    PK_TEAM,                /* 6 */
    PK_TIME,                /* 7 */

    PK_SCORE,               /* 8 */
    PK_KILLS,               /* 9 */
    PK_TEAM_KILLS,          /* 10 */
    PK_DEATHS,              /* 11 */
    PK_SUICIDES,            /* 12 */
    PK_ARRESTS,             /* 13 */
    PK_ARRESTED,            /* 14 */

    PK_KILL_STREAK,         /* 15 */
    PK_ARREST_STREAK,       /* 16 */
    PK_DEATH_STREAK,        /* 17 */

    PK_VIP_CAPTURES,        /* 18 */
    PK_VIP_RESCUES,         /* 19 */
    PK_VIP_ESCAPES,         /* 20 */
    PK_VIP_KILLS_VALID,     /* 21 */
    PK_VIP_KILLS_INVALID,   /* 22 */

    PK_BOMBS_DEFUSED,       /* 23 */
    PK_RD_CRYBABY,          /* 24 */

    PK_CASE_KILLS,          /* 25 */
    PK_CASE_ESCAPES,        /* 26 */
    PK_SG_CRYBABY,          /* 27 */

    PK_HOSTAGE_ARRESTS,     /* 28 */
    PK_HOSTAGE_HITS,        /* 29 */
    PK_HOSTAGE_INCAPS,      /* 30 */
    PK_HOSTAGE_KILLS,       /* 31 */
    PK_ENEMY_ARRESTS,       /* 32 */
    PK_ENEMY_INCAPS,        /* 33 */
    PK_ENEMY_KILLS,         /* 34 */
    PK_ENEMY_INCAPS_INVALID,/* 35 */
    PK_ENEMY_KILLS_INVALID, /* 36 */
    PK_TOC_REPORTS,         /* 37 */
    PK_COOP_STATUS,         /* 38 */

    PK_LOADOUT,             /* 39 */
    PK_WEAPONS,             /* 40 */
};

enum eWeaponKey
{
    WK_NAME,            /* 0 Weapon name (encoded) */
    WK_TIME,            /* 1 Time used Default 0 */
    WK_SHOTS,           /* 2 Bullets fired Default 0*/
    WK_HITS,            /* 3 Enemies hit Default 0 */
    WK_TEAM_HITS,       /* 4 Team mates hit Default 0 */
    WK_KILLS,           /* 5 Enemies killed Default 0 */
    WK_TEAM_KILLS,      /* 6 Team mates killed Default 0 */
    WK_KILL_DISTANCE,   /* 7 Best kill distance Default 0 */
};

enum eObjectiveKey
{
    OBJ_NAME,           /* 0 Objective name (encoded) */
    OBJ_STATUS,         /* 1 Objective status Default 1 */
};

enum eProcedureKey
{
    PRO_NAME,           /* 0 Procedure name (encoded) */
    PRO_STATUS,         /* 1 Procedure status x/y Default 0 */
    PRO_VALUE,          /* 2 Procedure score Default 0 */
};

var HTTP.Client Client;

var array<string> ObjectiveClass;
var array<string> ProcedureClass;
var array<string> AmmoClass;

var config array<string> URL;  // List of data trackers
var config bool Feedback;  // Indicate whether any sort of tracker messages should appear in admin chat
var config int Attempts;  // Limit the number of HTTP request attempts
var config string Key;  // Unique server key
var config bool Compatible;  // Indicate whether post data payload should be compatible with php's $_POST


function PreBeginPlay()
{
    Super.PreBeginPlay();

    Attempts = Max(1, Attempts);

    if (URL.Length == 0)
    {
        log(self $ ": no tracker URL has been supplied");
    }
    else if (Key == "")
    {
        log(self $ ": empty Key value");
    }
    else
    {
        // All good - continue
        return;
    }

    Destroy();
}

public function BeginPlay()
{
    Super.BeginPlay();
    Core.RegisterInterestedInMissionEnded(self);
    Client = Spawn(class'HTTP.Client');
}

function OnMissionEnded()
{
    local HTTP.Message Request;

    Request = Spawn(class'HTTP.Message');

    InitRequest(Request);
    AddServerDetails(Request);
    AddPlayerDetails(Request);
    PushRequest(Request);

    Request.Destroy();
}

function OnRequestSuccess(int StatusCode, string Response, string Hostname, int Port)
{
    local array<string> Lines;
    local string Status, Message, StatusMessage;

    if (StatusCode == 200)
    {
        Lines = class'Utils.StringUtils'.static.Part(Response, "\n");

        Status = Lines[0];
        Lines.Remove(0, 1);

        // Limit the message length
        Message = Left(
            class'Utils.StringUtils'.static.Strip(class'Utils.ArrayUtils'.static.Join(Lines, "\n")), 512
        );
        StatusMessage = Locale.Translate("SuccessMessage");

        switch (Status)
        {
            case "1":
                StatusMessage = Locale.Translate("WarningMessage");
                // no break
            case "0":

                // Display a warning/notification
                if (Message != "")
                {
                    DisplayMessage(class'Utils.StringUtils'.static.Format(StatusMessage, Hostname, Message));
                }
                return;

            default:
                break;
        }
    }

    log(self $ ": received " $ Left(Response, 20) $ " from " $ Hostname $ "(" $ StatusCode $ ")");

    // Display an error message
    DisplayMessage(
        Locale.Translate("WarningMessage", Hostname, Locale.Translate("ResponseErrorMessage"))
    );
}

function OnRequestFailure(eClientError ErrorCode, string ErrorMessage, string Hostname, int Port)
{
    log(self $ ": failed to send data to " $ Hostname $ " (" $ ErrorMessage $ ")");
    DisplayMessage(
        Locale.Translate("WarningMessage", Hostname, Locale.Translate("HostFailureMessage"))
    );
}

function InitRequest(HTTP.Message Request)
{
    local int Port, Timestamp;

    Port = SwatGameInfo(Level.Game).GetServerPort();
    Timestamp = class'Utils.LevelUtils'.static.Timestamp(Level);

    // Generate a random key
    AddRequestItem(
        Request, class'Utils.StringUtils'.static.Random(REQUEST_ID_LENGTH, ":alnum:"), "", eRootKey.RK_REQUEST_ID
    );
    // Extension version
    AddRequestItem(Request, Version, "", eRootKey.RK_VERSION);
    // Server join port
    AddRequestItem(Request, Port, "", eRootKey.RK_PORT);
    // Timestamp
    AddRequestItem(Request, Timestamp, "", eRootKey.RK_TIMESTAMP);
    // Unique hash
    AddRequestItem(Request, ComputeHash(Key, Port, Timestamp), "", eRootKey.RK_HASH);
}

function AddServerDetails(HTTP.Message Request)
{
    // 0-SWAT 4/ 1-SWAT 4X (default 0)
    AddRequestItem(Request, int(Core.Server.GetGame() == "SWAT 4X"), "0", eRootKey.RK_GAME_TITLE);
    // Game version
    AddRequestItem(Request, Core.Server.GetGameVer(), "", eRootKey.RK_GAME_VERSION);
    // Server name
    AddRequestItem(Request, Core.Server.GetHostname(), "", eRootKey.RK_HOSTNAME);
    // Game mode (encoded, default 0)
    AddRequestItem(Request, Core.Server.GetGameType(), "0", eRootKey.RK_GAMETYPE);
    // Map name (encoded, default 0)
    AddRequestItem(
        Request, EncodeString(Core.Server.GetMap(), class'Utils'.default.MapTitle), "0", eRootKey.RK_MAP
    );
    // Indicate whether the server is password protected (default 0)
    AddRequestItem(Request, int(Core.Server.IsPassworded()), "0", eRootKey.RK_PASSWORDED);
    // Current number of players on the server
    AddRequestItem(Request, Core.Server.GetPlayerCount(), "", eRootKey.RK_PLAYER_COUNT);
    // Number of player slots
    AddRequestItem(Request, Core.Server.GetPlayerLimit(), "", eRootKey.RK_PLAYER_LIMIT);
    // Current zero based round number (default 0)
    AddRequestItem(Request, Core.Server.GetRoundIndex(), "0", eRootKey.RK_ROUND_INDEX);
    // Rounds per map
    AddRequestItem(Request, Core.Server.GetRoundLimit(), "", eRootKey.RK_ROUND_LIMIT);
    // Time elapsed since the round start
    AddRequestItem(Request, int(Core.Server.TimeTotal), "", eRootKey.RK_TIME_ABSOLUTE);
    // Time spent playing
    AddRequestItem(Request, int(Core.Server.TimePlayed), "", eRootKey.RK_TIME_PLAYED);
    // Round time limit
    AddRequestItem(Request, Core.Server.GetRoundTimeLimit(), "", eRootKey.RK_TIME_LIMIT);
    // Rounds won by SWAT
    AddRequestItem(Request, Core.Server.GetSwatVictories(), "0", eRootKey.RK_SWAT_ROUNDS);
    // Rounds won by suspects
    AddRequestItem(Request, Core.Server.GetSuspectsVictories(), "0", eRootKey.RK_SUS_ROUNDS);
    // SWAT score
    AddRequestItem(Request, Core.Server.GetSwatScore(), "0", eRootKey.RK_SWAT_SCORE);
    // Suspects score
    AddRequestItem(Request, Core.Server.GetSuspectsScore(), "0", eRootKey.RK_SUS_SCORE);
    // Round outcome
    AddRequestItem(Request, Core.Server.Outcome, "", eRootKey.RK_OUTCOME);
    // RD stats
    if (Core.Server.GetGameType() == MPM_RapidDeployment)
    {
        AddRequestItem(Request, Core.Server.GetBombsDefused(), "0", eRootKey.RK_BOMBS_DEFUSED);
        AddRequestItem(Request, Core.Server.GetBombsTotal(), "0", eRootKey.RK_BOMBS_TOTAL);
    }
    // Coop stats
    else if (Core.Server.IsCOOP())
    {
        AddCOOPObjectives(Request);
        AddCOOPProcedures(Request);
    }
}

function AddCOOPObjectives(HTTP.Message Request)
{
    local int i, j;
    local MissionObjectives Objectives;
    local string Name;
    local ObjectiveStatus Status;

    Objectives = SwatRepo(Level.GetRepo()).MissionObjectives;

    for (i = 0; i < Objectives.Objectives.Length; i++)
    {
        if (Objectives.Objectives[i].name == 'Automatic_DoNot_Die')
        {
            continue;
        }

        Name = EncodeString(Objectives.Objectives[i].name, ObjectiveClass);
        Status = SwatGameReplicationInfo(Level.Game.GameReplicationInfo).ObjectiveStatus[i];

        // Objective name (encoded)
        AddRequestItem(Request, Name, "", eRootKey.RK_OBJECTIVES, j, eObjectiveKey.OBJ_NAME);
        // Objective status (default 1)
        AddRequestItem(Request, Status, "1", eRootKey.RK_OBJECTIVES, j, eObjectiveKey.OBJ_STATUS);
        j++;
    }
}

function AddCOOPProcedures(HTTP.Message Request)
{
    local int i;
    local Procedures Procedures;
    local string Name;

    Procedures = SwatRepo(Level.GetRepo()).Procedures;

    for (i = 0; i < Procedures.Procedures.Length; i++)
    {
        Name = EncodeString(Procedures.Procedures[i].class.name, ProcedureClass);
        // Procedure name (encoded)
        AddRequestItem(
            Request, Name, "", eRootKey.RK_PROCEDURES, i, eProcedureKey.PRO_NAME
        );
        // Procedure status x/y (Default 0)
        AddRequestItem(
            Request, Procedures.Procedures[i].Status(), "0", eRootKey.RK_PROCEDURES, i, eProcedureKey.PRO_STATUS
        );
        // Procedure score (e.g. 40 for mission completed) (Default 0)
        AddRequestItem(
            Request, Procedures.Procedures[i].GetCurrentValue(), "0", eRootKey.RK_PROCEDURES, i, eProcedureKey.PRO_VALUE
        );
    }
}

function AddPlayerDetails(HTTP.Message Request)
{
    local int i, j, k;
    local Player Player;
    local DynamicLoadoutSpec Loadout;
    local string WeaponName, PocketEncoded;

    for (i = 0; i < Core.Server.Players.Length; i++)
    {
        Player = Core.Server.Players[i];
        // Instance has been created, but not filled with actual data (rare)
        if (Player.LastTeam == -1)
        {
            continue;
        }
        // Player ID
        AddRequestItem(Request, i, "", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_ID);
        // IP address
        AddRequestItem(Request, Player.IPAddr, "", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_IP);
        // Has the player left the server? (default 0)
        AddRequestItem(Request, int(Player.bWasDropped), "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_DROPPED);
        // Is the player an admin? (default 0)
        AddRequestItem(Request, int(Player.bWasAdmin), "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_ADMIN);
        // Is the player the VIP? (default 0)
        AddRequestItem(Request, int(Player.bWasVIP), "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_VIP);
        // Player name
        AddRequestItem(Request, Player.LastName, "", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_NAME);
        // Team (default 0)
        AddRequestItem(Request, Player.LastTeam, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_TEAM);
        // Time played (default 0)
        AddRequestItem(Request, int(Player.TimePlayed), "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_TIME);
        // Score (default 0)
        AddRequestItem(Request, Player.LastScore, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_SCORE);
        // Kills (default 0)
        AddRequestItem(Request, Player.LastKills, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_KILLS);
        // Team kills (default 0)
        AddRequestItem(Request, Player.LastTeamKills, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_TEAM_KILLS);
        // Deaths (default 0)
        AddRequestItem(Request, Player.LastDeaths, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_DEATHS);
        // Suicides (default 0)
        AddRequestItem(Request, Player.Suicides, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_SUICIDES);
        // Arrests (default 0)
        AddRequestItem(Request, Player.LastArrests, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_ARRESTS);
        // Times arrested (default 0)
        AddRequestItem(Request, Player.LastArrested, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_ARRESTED);
        // Best kill streak (default 0)
        AddRequestItem(Request, Player.BestKillStreak, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_KILL_STREAK);
        // Best arrest streak (default 0)
        AddRequestItem(Request, Player.BestArrestStreak, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_ARREST_STREAK);
        // "Best" death streak (default 0)
        AddRequestItem(Request, Player.BestDeathStreak, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_DEATH_STREAK);
        // Numer of VIP arrests (default 0)
        AddRequestItem(Request, Player.LastVIPCaptures, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_VIP_CAPTURES);
        // Numer of VIP rescues (default 0)
        AddRequestItem(Request, Player.LastVIPRescues, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_VIP_RESCUES);
        // Numer of VIP escapes (default 0)
        AddRequestItem(Request, Player.LastVIPEscapes, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_VIP_ESCAPES);
        // Numer of valid VIP kills (default 0)
        AddRequestItem(
            Request, Player.LastVIPKillsValid, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_VIP_KILLS_VALID
        );
        // Numer of invalid VIP kills (default 0)
        AddRequestItem(
            Request, Player.LastVIPKillsInvalid, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_VIP_KILLS_INVALID
        );
        // Numer of bombs defused (default 0)
        AddRequestItem(Request, Player.LastBombsDefused, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_BOMBS_DEFUSED);
        // RD crybaby (default 0)
        AddRequestItem(Request, Player.LastRDCryBaby, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_RD_CRYBABY);
        // Number of case carrier kills (default 0)
        AddRequestItem(Request, Player.LastSGKills, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_CASE_KILLS);
        // Number of case escapes (default 0)
        AddRequestItem(Request, Player.LastSGEscapes, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_CASE_ESCAPES);
        // SG crybaby (default 0)
        AddRequestItem(Request, Player.LastSGCryBaby, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_SG_CRYBABY);
        // Number of hostage arrests (default 0)
        AddRequestItem(
            Request, Player.CivilianArrests, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_HOSTAGE_ARRESTS
        );
        // Number of hostage hits (default 0)
        AddRequestItem(
            Request, Player.CivilianHits, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_HOSTAGE_HITS
        );
        // Number of hostage incaps (default 0)
        AddRequestItem(
            Request, Player.CivilianIncaps, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_HOSTAGE_INCAPS
        );
        // Number of hostage kills (default 0)
        AddRequestItem(
            Request, Player.CivilianKills, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_HOSTAGE_KILLS
        );
        // Number of suspect arrests (default 0)
        AddRequestItem(
            Request, Player.EnemyArrests, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_ENEMY_ARRESTS
        );
        // Number of suspect incaps (default 0)
        AddRequestItem(
            Request, Player.EnemyIncaps, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_ENEMY_INCAPS
        );
        // Number of suspect kills (default 0)
        AddRequestItem(
            Request, Player.EnemyKills, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_ENEMY_KILLS
        );
        // Number of unauthorized suspect incaps (default 0)
        AddRequestItem(
            Request, Player.EnemyIncapsInvalid, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_ENEMY_INCAPS_INVALID
        );
        // Number of unauthorized suspect kills (default 0)
        AddRequestItem(
            Request, Player.EnemyKillsInvalid, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_ENEMY_KILLS_INVALID
        );
        // Number of TOC reports (default 0)
        AddRequestItem(
            Request, Player.CharacterReports, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_TOC_REPORTS
        );
        // COOP status (default 0)
        AddRequestItem(
            Request, Player.LastCOOPStatus, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_COOP_STATUS
        );

        // Last used loadout
        Loadout = GetPlayerLoadout(Player);

        if (LoadOut != None)
        {
            for (j = 0; j <= Pocket.Pocket_HeadArmor; j++)
            {
                if (Loadout.LoadOutSpec[j] == None)
                {
                    continue;
                }
                switch (Pocket(j))
                {
                    // Encode ammo
                    case Pocket_PrimaryAmmo :
                    case Pocket_SecondaryAmmo :
                        PocketEncoded = EncodeString(Loadout.LoadOutSpec[j].Name, AmmoClass);
                        break;
                    // Encode everything else
                    default:
                        PocketEncoded = EncodeString(Loadout.LoadOutSpec[j].Name, class'Utils'.default.EquipmentClass);
                        break;
                }
                AddRequestItem(Request, PocketEncoded, "", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_LOADOUT, j);
            }
        }

        k = 0;
        for (j = 0; j < Player.Weapons.Length; j++)
        {
            // Skip unused weapons
            if (Player.Weapons[j].Shots == 0 && Player.Weapons[j].TimeUsed == 0)
            {
                continue;
            }

            WeaponName = EncodeString(Player.Weapons[j].ClassName, class'Utils'.default.EquipmentClass);
            // Weapon name (encoded)
            AddRequestItem(
                Request, WeaponName, "", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_WEAPONS, k, eWeaponKey.WK_NAME
            );
            // Weapon usage time (default 0)
            AddRequestItem(
                Request, int(Player.Weapons[j].TimeUsed), "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_WEAPONS, k, eWeaponKey.WK_TIME
            );
            // Ammo fired (default 0)
            AddRequestItem(
                Request, Player.Weapons[j].Shots, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_WEAPONS, k, eWeaponKey.WK_SHOTS
            );
            // Enemy hits (default 0)
            AddRequestItem(
                Request, Player.Weapons[j].Hits, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_WEAPONS, k, eWeaponKey.WK_HITS
            );
            // Team hits (default 0)
            AddRequestItem(
                Request, Player.Weapons[j].TeamHits, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_WEAPONS, k, eWeaponKey.WK_TEAM_HITS
            );
            // Enemy kills (default 0)
            AddRequestItem(
                Request, Player.Weapons[j].Kills, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_WEAPONS, k, eWeaponKey.WK_KILLS
            );
            // Team kills (default 0)
            AddRequestItem(
                Request, Player.Weapons[j].TeamKills, "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_WEAPONS, k, eWeaponKey.WK_TEAM_KILLS
            );
            // Best kill distance (cm, default 0)
            AddRequestItem(
                Request, int(Player.Weapons[j].BestKillDistance), "0", eRootKey.RK_PLAYERS, i, ePlayerKey.PK_WEAPONS, k, eWeaponKey.WK_KILL_DISTANCE
            );
            k++;
        }
    }
}

function PushRequest(HTTP.Message Request)
{
    local int i;

    for (i = 0; i < URL.Length; i++)
    {
        Client.Send(Request.Copy(), URL[i], 'POST', self, Attempts);
    }
}

/**
 * Display a message in admin chat
 */
function DisplayMessage(string Message)
{
    if (!Feedback)
    {
        return;
    }
    class'Utils.LevelUtils'.static.TellAdmins(Level, Message, None, Locale.Translate("MessageColor"));
}

/**
 * Add a querystring item to Request instance unless Value matches DefaultValue
 * If multiple keys provided, form up a complex key
 */
function AddRequestItem(
    HTTP.Message Request, coerce string Value, coerce string DefaultValue,
    coerce string Key1,
    coerce optional string Key2,
    coerce optional string Key3,
    coerce optional string Key4,
    coerce optional string Key5
)
{
    local string Key;
    // Skip items equal to the default value or items with empty value
    if (Value == "" || (DefaultValue != "" && Value == DefaultValue))
    {
        return;
    }
    // Construct a key in the form of foo[bar][ham]
    if (Compatible)
    {
        Key = FormatArrayKey(Key1, Key2, Key3, Key4, Key5);
    }
    // Or use the efficient notation foo.bar.ham
    else
    {
        Key = FormatDelimitedKey(Key1, Key2, Key3, Key4, Key5);
    }
    Request.AddQueryString(Key, Value);
}

static function DynamicLoadoutSpec GetPlayerLoadout(Player Player)
{
    if (Player.LastValidPawn != None)
    {
        return NetPlayer(Player.LastValidPawn).GetLoadoutSpec();
    }
    return None;
}


static function string ComputeHash(coerce string Key, coerce string Port, coerce string Unixtime)
{
    return Right(ComputeMD5Checksum(Key $ Port $ Unixtime), 8);
}

/**
 * Encode a string by replacing it with its corresponding position in array Array
 */
static function string EncodeString(coerce string String, array<string> Array)
{
    local int i;
    i = class'Utils.ArrayUtils'.static.Search(Array, String, true);
    if (i == -1)
    {
        log("EncodeString: failed to decode \"" $ String $ "\"");
    }
    return string(i);
}

/**
 * Join non empty keys with Delimiter
 */
static function string FormatDelimitedKey(string Key1, optional string Key2, optional string Key3, optional string Key4, optional string Key5)
{
    local int i;
    local array<string> Keys;

    Keys[0] = Key1;
    Keys[1] = Key2;
    Keys[2] = Key3;
    Keys[3] = Key4;
    Keys[4] = Key5;

    // Remove empty keys
    for (i = Keys.Length-1; i >= 0; i--)
    {
        if (Keys[i] == "")
        {
            Keys.Remove(i, 1);
        }
    }

    return class'Utils.ArrayUtils'.static.Join(Keys, KEY_DELIMITER);
}

/**
 * Enclose non empty key bits with square brackets
 */
static function string FormatArrayKey(string Key1, optional string Key2, optional string Key3, optional string Key4, optional string Key5)
{
    local int i;
    local array<string> Keys;

    Keys[0] = Key2;
    Keys[1] = Key3;
    Keys[2] = Key4;
    Keys[3] = Key5;

    for (i = Keys.Length-1; i >= 0; i--)
    {
        // Remove empty components
        if (Keys[i] == "")
        {
            Keys.Remove(i, 1);
        }
        // Otherwise enclose them in a pair of square brackets
        else
        {
            Keys[i] = "[" $ Keys[i] $ "]";
        }
    }

    return Key1 $ class'Utils.ArrayUtils'.static.Join(Keys, "");
}

event Destroyed()
{
    if (Core != None)
    {
        Core.UnregisterInterestedInMissionEnded(self);
    }
    if (Client != None)
    {
        Client.Destroy();
        Client = None;
    }
    Super.Destroyed();
}

defaultproperties
{
    Title="Julia/Tracker";
    LocaleClass=class'TrackerLocale';

    Attempts=3;
    Feedback=true;
    Compatible=false;

    URL(0)="http://swat4stats.com/stream/";
    Key="swat4stats";

    ProcedureClass(0)="Procedure_ArrestIncapacitatedSuspects";          // Bonus points for incapacitating a suspect (12,5/total each)
    ProcedureClass(1)="Procedure_ArrestUnIncapacitatedSuspects";        // Bonus points for arresting a suspect (25/1=25/total each)
    ProcedureClass(2)="Procedure_CompleteMission";                      // Bonus points for all objectives completed (40)
    ProcedureClass(3)="Procedure_EvacuateDownedOfficers";               // Penalty points for not reporting a downed officer (??)
    ProcedureClass(4)="Procedure_KillSuspects";                         // No bonus points for killing suspects
    ProcedureClass(5)="Procedure_NoCiviliansInjured";                   // Bonus points for not letting civilians to be injured (5 for all)
    ProcedureClass(6)="Procedure_NoHostageIncapacitated";               // Penalty points for incapacitating a civilian (-5 each)
    ProcedureClass(7)="Procedure_NoHostageKilled";                      // Penalty points for killing a civilian (-15 each)
    ProcedureClass(8)="Procedure_NoOfficerIncapacitated";               // Penalty points for killing an officer (-15 each)
    ProcedureClass(9)="Procedure_NoOfficerInjured";                     // Penalty points for injuring an officer (-5 each)
    ProcedureClass(10)="Procedure_NoOfficersDown";                      // Bonus points for staying alive (10/total each officer)
    ProcedureClass(11)="Procedure_NoSuspectsNeutralized";               // Bonus points for not letting suspects to be killed (5 for all)
    ProcedureClass(12)="Procedure_NoUnauthorizedUseOfDeadlyForce";      // Penalty points for using unauthorized deadly force (-10 each)
    ProcedureClass(13)="Procedure_NoUnauthorizedUseOfForce";            // Penalty points for using unauthorized force (-5 each)
    ProcedureClass(14)="Procedure_PlayerUninjured";                     // Bonus points for staying uninjured (5/total each)
    ProcedureClass(15)="Procedure_PreventEvidenceDestruction";          // Penalty points for an evidence destruction (-5 each)
    ProcedureClass(16)="Procedure_PreventSuspectEscape";                // Penalty points for a suspect escape (-5 each)
    ProcedureClass(17)="Procedure_ReportCharactersToTOC";               // Bonus points for TOC reports (5/total each)
    ProcedureClass(18)="Procedure_SecureAllWeapons";                    // Bonus points for securing all weapons (5/total each)

    ObjectiveClass(0)="Arrest_Jennings";
    ObjectiveClass(1)="Custom_NoCiviliansInjured";
    ObjectiveClass(2)="Custom_NoOfficersInjured";
    ObjectiveClass(3)="Custom_NoOfficersKilled";
    ObjectiveClass(4)="Custom_NoSuspectsKilled";
    ObjectiveClass(5)="Custom_PlayerUninjured";
    ObjectiveClass(6)="Custom_Timed";
    ObjectiveClass(7)="Disable_Bombs";
    ObjectiveClass(8)="Disable_Office_Bombs";
    ObjectiveClass(9)="Investigate_Laundromat";
    ObjectiveClass(10)="Neutralize_Alice";
    ObjectiveClass(11)="Neutralize_All_Enemies";
    ObjectiveClass(12)="Neutralize_Arias";
    ObjectiveClass(13)="Neutralize_CultLeader";
    ObjectiveClass(14)="Neutralize_Georgiev";
    ObjectiveClass(15)="Neutralize_Grover";
    ObjectiveClass(16)="Neutralize_GunBroker";
    ObjectiveClass(17)="Neutralize_Jimenez";
    ObjectiveClass(18)="Neutralize_Killer";
    ObjectiveClass(19)="Neutralize_Kiril";
    ObjectiveClass(20)="Neutralize_Koshka";
    ObjectiveClass(21)="Neutralize_Kruse";
    ObjectiveClass(22)="Neutralize_Norman";
    ObjectiveClass(23)="Neutralize_TerrorLeader";
    ObjectiveClass(24)="Neutralize_Todor";
    ObjectiveClass(25)="Rescue_Adams";
    ObjectiveClass(26)="Rescue_All_Hostages";
    ObjectiveClass(27)="Rescue_Altman";
    ObjectiveClass(28)="Rescue_Baccus";
    ObjectiveClass(29)="Rescue_Bettencourt";
    ObjectiveClass(30)="Rescue_Bogard";
    ObjectiveClass(31)="Rescue_CEO";
    ObjectiveClass(32)="Rescue_Diplomat";
    ObjectiveClass(33)="Rescue_Fillinger";
    ObjectiveClass(34)="Rescue_Kline";
    ObjectiveClass(35)="Rescue_Macarthur";
    ObjectiveClass(36)="Rescue_Rosenstein";
    ObjectiveClass(37)="Rescue_Sterling";
    ObjectiveClass(38)="Rescue_Victims";
    ObjectiveClass(39)="Rescue_Walsh";
    ObjectiveClass(40)="Rescue_Wilkins";
    ObjectiveClass(41)="Rescue_Winston";
    ObjectiveClass(42)="Secure_Briefcase";
    ObjectiveClass(43)="Secure_Weapon";

    AmmoClass(0)="None";
    AmmoClass(1)="M4Super90SGAmmo";
    AmmoClass(2)="M4Super90SGSabotAmmo";
    AmmoClass(3)="NovaPumpSGAmmo";
    AmmoClass(4)="NovaPumpSGSabotAmmo";
    AmmoClass(5)="LessLethalAmmo";
    AmmoClass(6)="CSBallLauncherAmmo";
    AmmoClass(7)="M4A1MG_JHP";
    AmmoClass(8)="M4A1MG_FMJ";
    AmmoClass(9)="AK47MG_FMJ";
    AmmoClass(10)="AK47MG_JHP";
    AmmoClass(11)="G36kMG_FMJ";
    AmmoClass(12)="G36kMG_JHP";
    AmmoClass(13)="UZISMG_FMJ";
    AmmoClass(14)="UZISMG_JHP";
    AmmoClass(15)="MP5SMG_JHP";
    AmmoClass(16)="MP5SMG_FMJ";
    AmmoClass(17)="UMP45SMG_FMJ";
    AmmoClass(18)="UMP45SMG_JHP";
    AmmoClass(19)="ColtM1911HG_JHP";
    AmmoClass(20)="ColtM1911HG_FMJ";
    AmmoClass(21)="Glock9mmHG_JHP";
    AmmoClass(22)="Glock9mmHG_FMJ";
    AmmoClass(23)="PythonRevolverHG_FMJ";
    AmmoClass(24)="PythonRevolverHG_JHP";
    AmmoClass(25)="TaserAmmo";
    AmmoClass(26)="VIPPistolAmmo_FMJ";
    AmmoClass(27)="ColtAR_FMJ";
    AmmoClass(28)="HK69GL_StingerGrenadeAmmo";
    AmmoClass(29)="HK69GL_FlashbangGrenadeAmmo";
    AmmoClass(30)="HK69GL_CSGasGrenadeAmmo";
    AmmoClass(31)="HK69GL_TripleBatonAmmo";
    AmmoClass(32)="SAWMG_JHP";
    AmmoClass(33)="SAWMG_FMJ";
    AmmoClass(34)="FNP90SMG_FMJ";
    AmmoClass(35)="FNP90SMG_JHP";
    AmmoClass(36)="DEHG_FMJ";
    AmmoClass(37)="DEHG_JHP";
    AmmoClass(38)="TEC9SMG_FMJ";
}
