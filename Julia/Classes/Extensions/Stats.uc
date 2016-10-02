class Stats extends Extension
 implements InterestedInMissionStarted,
            InterestedInMissionEnded,
            InterestedInPlayerDisconnected,
            InterestedInCommandDispatched;

/**
 * Min number of fired ammuntion required for accuracy calculation
 */
const MIN_ACCURACY_SHOTS=10;

/**
 * Min number of thrown grenades required for accuracy calculation
 */
const MIN_ACCURACY_THROWN=5;


enum eRoundStatType
{
    STAT_NONE,

    HIGHEST_HITS,
    LOWEST_HITS,

    HIGHEST_TEAM_HITS,
    LOWEST_TEAM_HITS,

    HIGHEST_AMMO_FIRED,
    LOWEST_AMMO_FIRED,

    HIGHEST_ACCURACY,
    LOWEST_ACCURACY,

    HIGHEST_NADE_HITS,
    LOWEST_NADE_HITS,

    HIGHEST_NADE_TEAM_HITS,
    LOWEST_NADE_TEAM_HITS,

    HIGHEST_NADE_THROWN,
    LOWEST_NADE_THROWN,

    HIGHEST_NADE_ACCURACY,
    LOWEST_NADE_ACCURACY,

    HIGHEST_KILL_DISTANCE,
    LOWEST_KILL_DISTANCE,

    HIGHEST_SCORE,
    LOWEST_SCORE,

    HIGHEST_KILLS,
    LOWEST_KILLS,

    HIGHEST_ARRESTS,
    LOWEST_ARRESTS,

    HIGHEST_ARRESTED,
    LOWEST_ARRESTED,

    HIGHEST_TEAM_KILLS,
    LOWEST_TEAM_KILLS,

    HIGHEST_SUICIDES,
    LOWEST_SUICIDES,

    HIGHEST_DEATHS,
    LOWEST_DEATHS,

    HIGHEST_KILL_STREAK,
    LOWEST_KILL_STREAK,

    HIGHEST_ARREST_STREAK,
    LOWEST_ARREST_STREAK,

    HIGHEST_DEATH_STREAK,
    LOWEST_DEATH_STREAK,

    HIGHEST_VIP_CAPTURES,
    LOWEST_VIP_CAPTURES,

    HIGHEST_VIP_RESCUES,
    LOWEST_VIP_RESCUES,

    HIGHEST_BOMBS_DEFUSED,
    LOWEST_BOMBS_DEFUSED,

    HIGHEST_CASE_KILLS,
    LOWEST_CASE_KILLS,

    HIGHEST_REPORTS,
    LOWEST_REPORTS,

    HIGHEST_HOSTAGE_ARRESTS,
    LOWEST_HOSTAGE_ARRESTS,

    HIGHEST_HOSTAGE_HITS,
    LOWEST_HOSTAGE_HITS,

    HIGHEST_HOSTAGE_INCAPS,
    LOWEST_HOSTAGE_INCAPS,

    HIGHEST_HOSTAGE_KILLS,
    LOWEST_HOSTAGE_KILLS,

    HIGHEST_ENEMY_ARRESTS,
    LOWEST_ENEMY_ARRESTS,

    HIGHEST_ENEMY_INCAPS,
    LOWEST_ENEMY_INCAPS,

    HIGHEST_ENEMY_KILLS,
    LOWEST_ENEMY_KILLS,

    HIGHEST_ENEMY_INCAPS_INVALID,
    LOWEST_ENEMY_INCAPS_INVALID,

    HIGHEST_ENEMY_KILLS_INVALID,
    LOWEST_ENEMY_KILLS_INVALID,
};

enum ePlayerStatType
{
    STAT_NONE,

    HITS,
    TEAM_HITS,
    AMMO_FIRED,
    ACCURACY,

    NADE_HITS,
    NADE_TEAM_HITS,
    NADE_THROWN,
    NADE_ACCURACY,

    KILL_DISTANCE,

    SCORE,
    KILLS,
    ARRESTS,
    ARRESTED,
    TEAM_KILLS,
    SUICIDES,
    DEATHS,

    KILL_STREAK,
    ARREST_STREAK,
    DEATH_STREAK,

    VIP_CAPTURES,
    VIP_RESCUES,

    BOMBS_DEFUSED,

    CASE_KILLS,

    REPORTS,
    HOSTAGE_ARRESTS,
    HOSTAGE_HITS,
    HOSTAGE_INCAPS,
    HOSTAGE_KILLS,

    ENEMY_ARRESTS,
    ENEMY_INCAPS,
    ENEMY_KILLS,
    ENEMY_INCAPS_INVALID,
    ENEMY_KILLS_INVALID,
};

struct sRoundStat
{
    /**
     * Round stat type
     */
    var eRoundStatType Type;
    /**
     * Current record holders
     */
    var array<Player> Players;
    var float Points;
};

struct sPlayerStatCache
{
    /**
     * Reference to the stats owner
     */
    var Player Player;

    /**
     * List of stats in the following format: Stats[STAT_NONE]=0.0, Stats[HITS]=n, Stats[TEAM_HITS]=n, etc
     */
    var array<float> Stats;
};

/**
 * List of player stats cached entries that remain available only between rounds
 */
var array<sPlayerStatCache> PlayerStatsCache;

/**
 * List of best/worst player stats that will be displayed upon a round end
 */
var config array<eRoundStatType> FixedStats;

/**
 * List of extra round stats
 */
var config array<eRoundStatType> VariableStats;

/**
 * The number of extra round stats to pick from the list
 */
var config int VariableStatsLimit;

/**
 * Max number of round record holders to display
 */
var config int MaxNames;

/**
 * Min time played/round time ratio required to challenge the "lowest" categories of round stats
 */
var config float MinTimeRatio;

/**
 * List of personal stats that are displayed to a player with the !stats command
 */
var config array<ePlayerStatType> PlayerStats;


public function PreBeginPlay()
{
    Super.PreBeginPlay();
    MaxNames = Max(1, MaxNames);
}

/**
 * Bind the !stats command and register with the Julia's signal handlers
 */
public function BeginPlay()
{
    Super.BeginPlay();

    // Bind the !stats command
    Core.Dispatcher.Bind(
        "stats", self, Locale.Translate("StatsCommandUsage"), Locale.Translate("StatsCommandDescription")
    );
    
    Core.RegisterInterestedInMissionStarted(self);
    Core.RegisterInterestedInMissionEnded(self);
    Core.RegisterInterestedInPlayerDisconnected(self);
}

/**
 * Display the Player's personal stats
 */
public function OnCommandDispatched(Dispatcher Dispatcher, string Name, string Id, array<string> Args, Player Player)
{
    local int i, j;
    local array<string> Response;
    local array<float> Stats;
    local Player PlayerOfInterest;

    if (Args.Length > 0)
    {
        PlayerOfInterest = Core.Server.GetPlayerByWildName(Args[0]);
    }
    else 
    {
        PlayerOfInterest = Player;
    }    

    if (PlayerOfInterest != None)
    {
        // Check the cache first
        Stats = GetPlayerStatsFromCache(PlayerOfInterest);
        
        if (Stats.Length == 0)
        {
            Stats = GetPlayerStats(PlayerOfInterest, PlayerStats);
        }

        for (i = 0; i < PlayerStats.Length; i++)
        {
            j = PlayerStats[i];
            // Skip "STAT_NONE"
            if (j != 0)
            {
                Response[Response.Length] = Locale.Translate(
                    "Player" $ GetLocaleString(string(GetEnum(ePlayerStatType, j))), 
                    GetNeatNumericString(Stats[j])
                );
            }
        }
    }

    if (Response.Length == 0)
    {
        if (PlayerOfInterest == None)
        {
            Dispatcher.ThrowError(Id, Locale.Translate("PlayerErrorNoMatch"));
        }
        else
        {
            Dispatcher.ThrowError(Id, Locale.Translate("PlayerErrorNoStats"));
        }
        return;
    }

    // Display the other player's name
    if (PlayerOfInterest != Player)
    {
        Response.Insert(0, 1);
        Response[0] = Locale.Translate("PlayerDescription", ColorifyName(PlayerOfInterest));
    }

    Dispatcher.Respond(Id, class'Utils.ArrayUtils'.static.Join(Response, "\\n"));
}

/**
 * Remove all Player matching sPlayerStatCache entries from the player stats cache their leaving
 */
public function OnPlayerDisconnected(Player Player)
{
    local int i;

    for (i = PlayerStatsCache.Length-1; i >= 0 ; i--)
    {
        if (PlayerStatsCache[i].Player == Player)
        {
            PlayerStatsCache.Remove(i, 1);
        }
    }
}

/**
 * Show next map message upon start of the first round
 */
public function OnMissionStarted()
{
    ClearPlayerStatsCache();

    if (Core.Server.GetRoundIndex() == 0)
    {
        DisplayNextMapMessage();
    }
}

/**
 * Show round stats upon a round end
 * Also attempt to show the next map message
 */
public function OnMissionEnded()
{
    // Fill the player stats cache, so players issuing the !stats command
    // dont end up with zeroed values during the PostGame state
    FillPlayerStatsCache();
    DisplayRoundPlayer();
    DisplayRoundStats();
    // Display next map message at the end of a map
    if (Core.Server.GetRoundIndex() == Core.Server.GetRoundLimit()-1)
    {
        DisplayNextMapMessage();
    }
}

/**
 * Display player of the round message
 */
protected function DisplayRoundPlayer()
{
    local Player Player;
    local string RoundPlayerName;

    Player = GetBestRoundPlayer();

    if (Player != None)
    {
        RoundPlayerName = ColorifyName(Player);
    }
    else
    {
        RoundPlayerName = Locale.Translate("PlayerErrorNotAvailable");
    }

    // Display the best round player message
    class'Utils.LevelUtils'.static.TellAll(
        Level,
        Locale.Translate("RoundPlayerMessage", RoundPlayerName),
        Locale.Translate("MessageColor")
    );
}

/**
 * Display round stats defined in the RoundStats and RoundStatsRandom lists
 */
protected function DisplayRoundStats()
{
    local int i, j, k, n;
    local array<eRoundStatType> Categories, Variable, Shuffled;
    local array<sRoundStat> Stats, Sorted;
    local int VariableStatCount;

    Categories = FixedStats;
    Variable = VariableStats;

    // Append varying categories
    for (i = 0; i < Variable.Length; i++)
    {
        Categories[Categories.Length] = Variable[i];
    }

    Stats = GetRoundStats(Categories);

    // Display predefined stats first
    for (i = 0; i < FixedStats.Length; i++)
    {
        DisplayRoundStatEntry(Stats[FixedStats[i]]);
    }
    // Shuffle variable categories
    while (Variable.Length > 0)
    {
        n = Rand(Variable.Length);
        Shuffled[Shuffled.Length] = Variable[n];
        Variable.Remove(n, 1);
    }
    // Attempt to sort variable stat entries by the number of assotiated record holders
    // so entries with the lowest number of players are at the beginning of the list
    for (i = 0; i < Shuffled.Length; i++)
    {
        j = Shuffled[i];

        if (Stats[j].Players.Length == 0)
        {
            continue;
        }

        n = -1;

        for (k = 0; k < Sorted.Length; k++)
        {
            if (Stats[j].Players.Length <= Sorted[k].Players.Length)
            {
                n = k;
                break;
            }
        }

        // This stat has the greatest number of players, append it to the end
        if (n == -1)
        {
            n = Sorted.Length;
        }

        Sorted.Insert(n, 1);
        Sorted[n] = Stats[j];
    }

    log(self $ ": " $ Sorted.Length $ " variable stats were sorted in the order:");

    for (i = 0; i < Sorted.Length; i++)
    {
        log(self $ ": " $ GetEnum(eRoundStatType, Sorted[i].Type) $ " - " $ Sorted[i].Players.Length $ " players");
    }

    log(self $ ": displaying the first " $ VariableStatsLimit);

    for (i = 0; i < Sorted.Length; i++)
    {
        if (++VariableStatCount > VariableStatsLimit)
        {
            break;
        }
        DisplayRoundStatEntry(Sorted[i]);
    }
}

/**
 * Display a round stat StatEntry
 */
protected function DisplayRoundStatEntry(sRoundStat StatEntry)
{
    local int i, j;
    local array<string> Names;
    local string NamesCombined, NamesTranslated;

    if (StatEntry.Players.Length == 0)
    {
        return;
    }

    for (i = 0; i < MaxNames; i++)
    {
        if (StatEntry.Players.Length == 0)
        {
            break;
        }
        // Pick a random player
        j = Rand(StatEntry.Players.Length);
        Names[Names.Length] = ColorifyName(StatEntry.Players[j]);
        StatEntry.Players.Remove(j, 1);
    }

    // Join the names in a string
    NamesCombined = class'Utils.ArrayUtils'.static.Join(Names, ", ");

    // Let everyone know if there are more players
    if (StatEntry.Players.Length > 0)
    {
        NamesTranslated = Locale.Translate("RoundPlayerNameMore", NamesCombined, StatEntry.Players.Length);
    }
    // Display names normally
    else
    {
        NamesTranslated = Locale.Translate("RoundPlayerName", NamesCombined);
    }

    class'Utils.LevelUtils'.static.TellAll(
        Level,
        Locale.Translate(
            "Round" $ GetLocaleString(string(GetEnum(eRoundStatType, StatEntry.Type))), 
            NamesTranslated,
            GetNeatNumericString(StatEntry.Points)
        ),
        Locale.Translate("MessageColor")
    );
}

/**
 * Display the next map message
 */
protected function DisplayNextMapMessage()
{
    class'Utils.LevelUtils'.static.TellAll(
        Level,
        Locale.Translate(
            "NextMapMessage", 
            class'Utils'.static.GetFriendlyMapName(class'Utils'.static.GetNextMap(Level))
        ),
        Locale.Translate("MessageColor")
    );
}

/**
 * Return the the Player's stats defined with Types
 */
protected function array<float> GetPlayerStats(Player Player, array<ePlayerStatType> Types)
{
    local int i, j;
    local bool bSkip;
    local array<float> Stats;

    for (i = 0; i < ePlayerStatType.EnumCount; i++)
    {
        // Initialize an empty stat entry
        Stats[i] = 0.0;

        bSkip = true;
        // Check whether the caller is interested in this stat
        for (j = 0; j < Types.Length; j++)
        {
            if (ePlayerStatType(i) == Types[j])
            {
                bSkip = false;
                break;
            }
        }

        if (bSkip)
        {
            continue;
        }

        switch (ePlayerStatType(i))
        {
            case HITS:
                Stats[i] = GetPlayerHits(Player);
                break;
            case TEAM_HITS:
                Stats[i] = GetPlayerTeamHits(Player);
                break;
            case AMMO_FIRED:
                Stats[i] = GetPlayerAmmoFired(Player);
                break;
            case ACCURACY:
                Stats[i] = GetPlayerAccuracy(Player);
                break;
            case NADE_HITS:
                Stats[i] = GetPlayerNadeHits(Player);
                break;
            case NADE_TEAM_HITS:
                Stats[i] = GetPlayerNadeTeamHits(Player);
                break;
            case NADE_THROWN:
                Stats[i] = GetPlayerNadeThrown(Player);
                break;
            case NADE_ACCURACY:
                Stats[i] = GetPlayerNadeAccuracy(Player);
                break;
            case KILL_DISTANCE:
                Stats[i] = GetPlayerKillDistance(Player);
                break;
            case SCORE:
                Stats[i] = Player.LastScore;
                break;
            case KILLS:
                Stats[i] = Player.LastKills;
                break;
            case ARRESTS:
                Stats[i] = Player.LastArrests;
                break;
            case ARRESTED:
                Stats[i] = Player.LastArrested;
                break;
            case TEAM_KILLS:
                Stats[i] = Player.LastTeamKills;
                break;
            case SUICIDES:
                Stats[i] = Player.Suicides;
                break;
            case DEATHS:
                Stats[i] = Player.LastDeaths;
                break;
            case KILL_STREAK:
                Stats[i] = Player.BestKillStreak;
                break;
            case ARREST_STREAK:
                Stats[i] = Player.BestArrestStreak;
                break;
            case DEATH_STREAK:
                Stats[i] = Player.BestDeathStreak;
                break;
            case VIP_CAPTURES:
                Stats[i] = Player.LastVIPCaptures;
                break;
            case VIP_RESCUES:
                Stats[i] = Player.LastVIPRescues;
                break;
            case BOMBS_DEFUSED:
                Stats[i] = Player.LastBombsDefused;
                break;
            case CASE_KILLS:
                Stats[i] = Player.LastSGKills;
                break;
            case REPORTS:
                Stats[i] = Player.CharacterReports;
                break;
            case HOSTAGE_ARRESTS:
                Stats[i] = Player.CivilianArrests;
                break;
            case HOSTAGE_HITS:
                Stats[i] = Player.CivilianHits;
                break;
            case HOSTAGE_INCAPS:
                Stats[i] = Player.CivilianIncaps;
                break;
            case HOSTAGE_KILLS:
                Stats[i] = Player.CivilianKills;
                break;
            case ENEMY_ARRESTS:
                Stats[i] = Player.EnemyArrests;
                break;
            case ENEMY_INCAPS:
                Stats[i] = Player.EnemyIncaps;
                break;
            case ENEMY_KILLS:
                Stats[i] = Player.EnemyKills;
                break;
            case ENEMY_INCAPS_INVALID:
                Stats[i] = Player.EnemyIncapsInvalid;
                break;
            case ENEMY_KILLS_INVALID:
                Stats[i] = Player.EnemyKillsInvalid;
                break;
            default:
                break;
        }
    }
    return Stats;
}

/**
 * Attempt to retrieve Player's stats from cache
 */
protected function array<float> GetPlayerStatsFromCache(Player Player)
{
    local int i;
    local array<float> Empty;

    for (i = 0; i < PlayerStatsCache.Length; i++)
    {
        if (PlayerStatsCache[i].Player == Player)
        {
            return PlayerStatsCache[i].Stats;
        }
    }

    return Empty;
}

/**
 * Fill the player stats cache
 */
protected function FillPlayerStatsCache()
{
    local int i;
    local sPlayerStatCache CacheEntry;

    for (i = 0; i < Core.Server.Players.Length; i++)
    {
        // Only cache online players' stats
        if (Core.Server.Players[i].PC == None)
        {
            continue;
        }

        CacheEntry.Player = Core.Server.Players[i];
        CacheEntry.Stats = GetPlayerStats(Core.Server.Players[i], PlayerStats);

        PlayerStatsCache[PlayerStatsCache.Length] = CacheEntry;
    }
}

/**
 * Clear the player stats cache
 */
protected function ClearPlayerStatsCache()
{
    while (PlayerStatsCache.Length > 0)
    {
        PlayerStatsCache[0].Player = None;
        PlayerStatsCache.Remove(0, 1);
    }
}

/**
 * Return a list of round records. 
 * The list would contain all eRoundStatType entries,
 * but only the categories matching Categories will be actually be calculated
 */
protected function array<sRoundStat> GetRoundStats(array<eRoundStatType> Categories)
{
    local int i, j;
    local bool bSkip;
    local sRoundStat StatEntry;
    local array<sRoundStat> Stats;
    local Player Player;

    for (j = 0; j < eRoundStatType.EnumCount; j++)
    {
        // Set an empty struct for this type of round stat
        // this is required for array integrity
        Stats[j] = StatEntry;
        Stats[j].Type = eRoundStatType(j);

        bSkip = true;

        for (i = 0; i < Categories.Length; i++)
        {
            if (Stats[j].Type == Categories[i])
            {
                bSkip = false;
                break;
            }
        }

        if (bSkip)
        {
            continue;
        }

        log(self $ ": iterating " $ Core.Server.Players.Length $ " players for " $ GetEnum(eRoundStatType, j));

        for (i = 0; i < Core.Server.Players.Length; i++)
        {
            Player = Core.Server.Players[i];
            switch (eRoundStatType(j))
            {
                case HIGHEST_HITS:
                    ChallengeRoundStatRecord(Stats[j], Player, GetPlayerHits(Player), -1);
                    break;
                case LOWEST_HITS:
                    ChallengeRoundStatRecord(Stats[j], Player, GetPlayerHits(Player), -1, true);
                    break;

                case HIGHEST_TEAM_HITS:
                    ChallengeRoundStatRecord(Stats[j], Player, GetPlayerTeamHits(Player), -1);
                    break;
                case LOWEST_TEAM_HITS:
                    ChallengeRoundStatRecord(Stats[j], Player, GetPlayerTeamHits(Player), -1, true);
                    break;

                case HIGHEST_AMMO_FIRED:
                    ChallengeRoundStatRecord(Stats[j], Player, GetPlayerAmmoFired(Player), -1);
                    break;
                case LOWEST_AMMO_FIRED:
                    ChallengeRoundStatRecord(Stats[j], Player, GetPlayerAmmoFired(Player), -1, true);
                    break;

                case HIGHEST_ACCURACY:
                    ChallengeRoundStatRecord(Stats[j], Player, GetPlayerAccuracy(Player), -1);
                    break;
                case LOWEST_ACCURACY:
                    ChallengeRoundStatRecord(Stats[j], Player, GetPlayerAccuracy(Player), -1, true);
                    break;

                case HIGHEST_NADE_HITS:
                    ChallengeRoundStatRecord(Stats[j], Player, GetPlayerNadeHits(Player), -1);
                    break;
                case LOWEST_NADE_HITS:
                    ChallengeRoundStatRecord(Stats[j], Player, GetPlayerNadeHits(Player), -1, true);
                    break;

                case HIGHEST_NADE_TEAM_HITS:
                    ChallengeRoundStatRecord(Stats[j], Player, GetPlayerNadeTeamHits(Player), -1);
                    break;
                case LOWEST_NADE_TEAM_HITS:
                    ChallengeRoundStatRecord(Stats[j], Player, GetPlayerNadeTeamHits(Player), -1, true);
                    break;

                case HIGHEST_NADE_THROWN:
                    ChallengeRoundStatRecord(Stats[j], Player, GetPlayerNadeThrown(Player), -1);
                    break;
                case LOWEST_NADE_THROWN:
                    ChallengeRoundStatRecord(Stats[j], Player, GetPlayerNadeThrown(Player), -1, true);
                    break;

                case HIGHEST_NADE_ACCURACY:
                    ChallengeRoundStatRecord(Stats[j], Player, GetPlayerNadeAccuracy(Player), -1);
                    break;
                case LOWEST_NADE_ACCURACY:
                    ChallengeRoundStatRecord(Stats[j], Player, GetPlayerNadeAccuracy(Player), -1, true);
                    break;

                case HIGHEST_KILL_DISTANCE:
                    ChallengeRoundStatRecord(Stats[j], Player, GetPlayerKillDistance(Player), -1);
                    break;
                case LOWEST_KILL_DISTANCE:
                    ChallengeRoundStatRecord(Stats[j], Player, GetPlayerKillDistance(Player), -1, true);
                    break;

                case HIGHEST_SCORE:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.LastScore, -1);
                    break;
                case LOWEST_SCORE:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.LastScore, -1, true);
                    break;

                case HIGHEST_KILLS:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.LastKills, -1);
                    break;
                case LOWEST_KILLS:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.LastKills, -1, true);
                    break;

                case HIGHEST_ARRESTS:

                    if (!Player.bWasVIP)
                    {
                        ChallengeRoundStatRecord(Stats[j], Player, Player.LastArrests, -1);
                    }
                    break;

                case LOWEST_ARRESTS:

                    if (!Player.bWasVIP)
                    {
                        ChallengeRoundStatRecord(Stats[j], Player, Player.LastArrests, -1, true);
                    }
                    break;

                case HIGHEST_ARRESTED:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.LastArrested, -1);
                    break;
                case LOWEST_ARRESTED:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.LastArrested, -1, true);
                    break;

                case HIGHEST_TEAM_KILLS:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.LastTeamKills, -1);
                    break;
                case LOWEST_TEAM_KILLS:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.LastTeamKills, -1, true);
                    break;

                case HIGHEST_SUICIDES:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.Suicides, -1);
                    break;
                case LOWEST_SUICIDES:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.Suicides, -1, true);
                    break;

                case HIGHEST_DEATHS:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.LastDeaths, -1);
                    break;
                case LOWEST_DEATHS:

                    if (!Player.bWasVIP)
                    {
                        ChallengeRoundStatRecord(Stats[j], Player, Player.LastDeaths, -1, true);
                    }
                    break;

                case HIGHEST_KILL_STREAK:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.BestKillStreak, -1);
                    break;
                case LOWEST_KILL_STREAK:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.BestKillStreak, -1, true);
                    break;

                case HIGHEST_ARREST_STREAK:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.BestArrestStreak, -1);
                    break;
                case LOWEST_ARREST_STREAK:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.BestArrestStreak, -1, true);
                    break;

                case HIGHEST_DEATH_STREAK:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.BestDeathStreak, -1);
                    break;
                case LOWEST_DEATH_STREAK:
                
                    if (!Player.bWasVIP)
                    {
                        ChallengeRoundStatRecord(Stats[j], Player, Player.BestDeathStreak, -1, true);
                    }
                    break;

                case HIGHEST_VIP_CAPTURES:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.LastVIPCaptures, 1);
                    break;
                case LOWEST_VIP_CAPTURES:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.LastVIPCaptures, 1, true);
                    break;

                case HIGHEST_VIP_RESCUES:

                    if (!Player.bWasVIP)
                    {
                        ChallengeRoundStatRecord(Stats[j], Player, Player.LastVIPRescues, 0);
                    }
                    break;

                case LOWEST_VIP_RESCUES:

                    if (!Player.bWasVIP)
                    {
                        ChallengeRoundStatRecord(Stats[j], Player, Player.LastVIPRescues, 0, true);
                    }
                    break;

                case HIGHEST_BOMBS_DEFUSED:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.LastBombsDefused, 0);
                    break;
                case LOWEST_BOMBS_DEFUSED:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.LastBombsDefused, 0, true);
                    break;

                case HIGHEST_CASE_KILLS:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.LastSGKills, 0);
                    break;
                case LOWEST_CASE_KILLS:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.LastSGKills, 0, true);
                    break;

                case HIGHEST_REPORTS:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.CharacterReports, -1);
                    break;
                case LOWEST_REPORTS:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.CharacterReports, -1, true);
                    break;

                case HIGHEST_HOSTAGE_ARRESTS:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.CivilianArrests, -1);
                    break;
                case LOWEST_HOSTAGE_ARRESTS:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.CivilianArrests, -1, true);
                    break;

                case HIGHEST_HOSTAGE_HITS:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.CivilianHits, -1);
                    break;
                case LOWEST_HOSTAGE_HITS:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.CivilianHits, -1, true);
                    break;

                case HIGHEST_HOSTAGE_INCAPS:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.CivilianIncaps, -1);
                    break;
                case LOWEST_HOSTAGE_INCAPS:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.CivilianIncaps, -1, true);
                    break;

                case HIGHEST_HOSTAGE_KILLS:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.CivilianKills, -1);
                    break;
                case LOWEST_HOSTAGE_KILLS:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.CivilianKills, -1, true);
                    break;

                case HIGHEST_ENEMY_ARRESTS:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.EnemyArrests, -1);
                    break;
                case LOWEST_ENEMY_ARRESTS:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.EnemyArrests, -1, true);
                    break;

                case HIGHEST_ENEMY_INCAPS:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.EnemyIncaps, -1);
                    break;
                case LOWEST_ENEMY_INCAPS:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.EnemyIncaps, -1, true);
                    break;

                case HIGHEST_ENEMY_KILLS:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.EnemyKills, -1);
                    break;
                case LOWEST_ENEMY_KILLS:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.EnemyKills, -1, true);
                    break;

                case HIGHEST_ENEMY_INCAPS_INVALID:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.EnemyIncapsInvalid, -1);
                    break;
                case LOWEST_ENEMY_INCAPS_INVALID:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.EnemyIncapsInvalid, -1, true);
                    break;

                case HIGHEST_ENEMY_KILLS_INVALID:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.EnemyKillsInvalid, -1);
                    break;
                case LOWEST_ENEMY_KILLS_INVALID:
                    ChallengeRoundStatRecord(Stats[j], Player, Player.EnemyKillsInvalid, -1, true);
                    break;
            }
        }
    }
    return Stats;
}

/**
 * Compare the current stat record holder's points with Player's Points
 * If the latter beats the record, replace the record holder
 */
protected function ChallengeRoundStatRecord(out sRoundStat StatEntry, Player Player, coerce float Points, int TeamNumber, optional bool bLowest)
{
    if (!(TeamNumber == -1 || Player.LastTeam == TeamNumber))
    {
        return;
    }

    // Ignore players joined midgame in COOP
    if (Core.Server.IsCOOP() && Player.LastValidPawn == None)
    {
        log(self $ ": skipping " $ Player.LastName $ " (LastValidPawn=None)");
        return;
    }

    // Dont let just connected players take all of the "lowest" stat records
    if (bLowest)
    {
        if ((Player.TimePlayed / Core.Server.TimePlayed) < MinTimeRatio)
        {
            log(self $ ": skipping " $ Player.LastName $ " (" $ Player.TimePlayed $ " sec played)");
            return;
        }
    }
    // See if the player is actually better than the current record holders' stats
    if (StatEntry.Players.Length == 0 || (bLowest && Points < StatEntry.Points) || (!bLowest && Points > StatEntry.Points))
    {
        // Discard the list of the old record holders
        StatEntry.Players.Remove(0, StatEntry.Players.Length);
        StatEntry.Players[0] = Player;
        StatEntry.Points = Points;
    }
    // Extend the list
    else if (Points == StatEntry.Points)
    {
        StatEntry.Players[StatEntry.Players.Length] = Player;
    }
}

/**
 * Attempt to "guess" the best player of the round
 */
protected function Player GetBestRoundPlayer()
{
    switch (Core.Server.Outcome)
    {
        // A tie
        case SRO_RoundEndedInTie :
            return GetBestScoredPlayer(-1);

        // COOP round
        case SRO_COOPCompleted:
        case SRO_COOPFailed:
            return GetBestCOOPPlayer();

        // SWAT victory in BS
        case SRO_SwatVictoriousNormal :
            return GetBestScoredPlayer(0);

        // Suspects victory in BS
        case SRO_SuspectsVictoriousNormal :
            return GetBestScoredPlayer(1);

        // SWAT victory in RD
        case SRO_SwatVictoriousRapidDeployment :
            return GetBestRDSwatPlayer();

        // Suspects victory in RD
        case SRO_SuspectsVictoriousRapidDeployment :
            return GetBestScoredPlayer(1);

        // SWAT victory in VIP
        case SRO_SwatVictoriousVIPEscaped :
        case SRO_SwatVictoriousSuspectsKilledVIPInvalid :
            return GetBestVIPSwatPlayer();

        // Suspects victory in VIP
        case SRO_SuspectsVictoriousKilledVIPValid :
        case SRO_SuspectsVictoriousSwatKilledVIP :
            return GetBestVIPSuspectsPlayer();

        // Suspects victory in SG
        case SRO_SuspectsVictoriousSmashAndGrab :
            return GetBestSGSuspectsPlayer();

        // Swat victory in SG
        case SRO_SwatVictoriousSmashAndGrab :
            return GetBestSGSwatPlayer();

        default:
            break;
    }
    return None;
}

/**
 * Return the round best swat player in RD
 */
protected function Player GetBestRDSwatPlayer()
{
    local int i;
    local Player BestPlayer;
    local array<int> CurrentStats, BestStats;
    local Player Player;

    log(self $ ": retrieving the best RD swat player");

    for (i = 0; i < Core.Server.Players.Length; i++)
    {
        Player = Core.Server.Players[i];
        // Ignore suspects
        if (Player.LastTeam != 0)
        {
            continue;
        }

        CurrentStats[0] = Player.LastBombsDefused;
        CurrentStats[1] = Player.LastScore;
        CurrentStats[2] = Player.LastKills;
        CurrentStats[3] = Player.LastArrests;
        CurrentStats[4] = Player.LastDeaths*-1;
        CurrentStats[5] = Player.LastArrested*-1;

        log(self $ ": checking " $ Player.LastName);

        if (BestPlayer == None || CompareStats(CurrentStats, BestStats))
        {
            BestPlayer = Player;
            BestStats = CurrentStats;

            log(self $ ": best player is now " $ BestPlayer.LastName);
        }
    }

    log(self $ ": at last the best player is " $ BestPlayer.LastName);

    return BestPlayer;
}

/**
 * Return the round best swat player in VIP Escort
 */
protected function Player GetBestVIPSwatPlayer()
{
    local int i;
    local Player BestPlayer;
    local array<int> CurrentStats, BestStats;
    local Player Player;

    log(self $ ": retrieving the best VIP swat player");

    for (i = 0; i < Core.Server.Players.Length; i++)
    {
        Player = Core.Server.Players[i];
        // Ignore suspects
        if (Player.LastTeam != 0)
        {
            continue;
        }

        CurrentStats[0] = Player.LastVIPKillsInvalid*-1;
        CurrentStats[1] = Player.LastVIPRescues;
        CurrentStats[2] = Player.LastScore;
        CurrentStats[3] = Player.LastKills;
        CurrentStats[4] = Player.LastArrests;
        CurrentStats[5] = Player.LastDeaths*-1;
        CurrentStats[6] = Player.LastArrested*-1;

        log(self $ ": checking " $ Player.LastName);

        if (BestPlayer == None || CompareStats(CurrentStats, BestStats))
        {
            BestPlayer = Player;
            BestStats = CurrentStats;

            log(self $ ": best player is now " $ BestPlayer.LastName);
        }
    }

    // Set the escaped VIP the best best round player if no swat has rescued the VIP 
    if (BestPlayer != None && BestPlayer.LastVIPRescues == 0)
    {
        log(self $ ": " $ BestPlayer.LastName $ " is the best player with no vip rescues");

        for (i = 0; i < Core.Server.Players.Length; i++)
        {
            if (Core.Server.Players[i].LastVIPEscapes > 0)
            {
                BestPlayer = Core.Server.Players[i];
                log(self $ ": " $ BestPlayer.LastName $ " has escaped, hence the best player");
                break;
            }
        }
    }
    
    log(self $ ": at last the best player is " $ BestPlayer.LastName);

    return BestPlayer;
}

/**
 * Return the round best suspects player in VIP Escort
 */
protected function Player GetBestVIPSuspectsPlayer()
{
    local int i;
    local Player BestPlayer;
    local array<int> CurrentStats, BestStats;
    local Player Player;

    log(self $ ": retrieving the best VIP suspects player");

    for (i = 0; i < Core.Server.Players.Length; i++)
    {
        Player = Core.Server.Players[i];

        // Ignore swat players
        if (Player.LastTeam != 1)
        {
            continue;
        }

        CurrentStats[0] = Player.LastVIPKillsInvalid*-1;
        CurrentStats[1] = Player.LastVIPCaptures;
        CurrentStats[2] = Player.LastVIPKillsValid;
        CurrentStats[3] = Player.LastScore;
        CurrentStats[4] = Player.LastKills;
        CurrentStats[5] = Player.LastArrests;
        CurrentStats[6] = Player.LastDeaths*-1;
        CurrentStats[7] = Player.LastArrested*-1;

        log(self $ ": checking " $ Player.LastName);

        if (BestPlayer == None || CompareStats(CurrentStats, BestStats))
        {
            BestPlayer = Player;
            BestStats = CurrentStats;

            log(self $ ": best player is now " $ BestPlayer.LastName);
        }
    }

    log(self $ ": at last the best player is " $ BestPlayer.LastName);

    return BestPlayer;
}

/**
 * Return the case escaped Smash&Grab suspects player
 */
protected function Player GetBestSGSuspectsPlayer()
{
    local int i;
    local Player BestPlayer;
    local array<int> CurrentStats, BestStats;
    local Player Player;

    log(self $ ": retrieving the best SG suspects player");

    for (i = 0; i < Core.Server.Players.Length; i++)
    {
        Player = Core.Server.Players[i];

        // Ignore swat players
        if (Player.LastTeam != 1)
        {
            continue;
        }

        CurrentStats[0] = Player.LastSGEscapes;
        CurrentStats[1] = Player.LastScore;
        CurrentStats[2] = Player.LastKills;
        CurrentStats[3] = Player.LastArrests;
        CurrentStats[4] = Player.LastDeaths*-1;
        CurrentStats[5] = Player.LastArrested*-1;

        log(self $ ": checking " $ Player.LastName);

        if (BestPlayer == None || CompareStats(CurrentStats, BestStats))
        {
            BestPlayer = Player;
            BestStats = CurrentStats;

            log(self $ ": best player is now " $ BestPlayer.LastName);
        }
    }

    log(self $ ": at last the best player is " $ BestPlayer.LastName);

    return BestPlayer;
}

/**
 * Return a Smash&Grab swat player with the highest number of case-carrying suspects kills
 */
protected function Player GetBestSGSwatPlayer()
{
    local int i;
    local Player BestPlayer;
    local array<int> CurrentStats, BestStats;
    local Player Player;

    log(self $ ": retrieving the best SG swat player");

    for (i = 0; i < Core.Server.Players.Length; i++)
    {
        Player = Core.Server.Players[i];

        // Ignore suspects
        if (Player.LastTeam != 0)
        {
            continue;
        }

        CurrentStats[0] = Player.LastSGCryBaby;
        CurrentStats[1] = Player.LastSGKills;
        CurrentStats[2] = Player.LastScore;
        CurrentStats[3] = Player.LastKills;
        CurrentStats[4] = Player.LastArrests;
        CurrentStats[5] = Player.LastDeaths*-1;
        CurrentStats[6] = Player.LastArrested*-1;

        log(self $ ": checking " $ Player.LastName);

        if (BestPlayer == None || CompareStats(CurrentStats, BestStats))
        {
            BestPlayer = Player;
            BestStats = CurrentStats;

            log(self $ ": best player is now " $ BestPlayer.LastName);
        }
    }

    log(self $ ": at last the best player is " $ BestPlayer.LastName);

    return BestPlayer;
}

/**
 * Return the best COOP player
 */
protected function Player GetBestCOOPPlayer()
{
    local int i;
    local Player BestPlayer;
    local array<int> BestStats, CurrentStats;
    local Player Player;

    log(self $ ": retrieving the best COOP player");

    for (i = 0; i < Core.Server.Players.Length; i++)
    {
        Player = Core.Server.Players[i];

        // Skip players connected midgame
        if (Player.LastValidPawn == None)
        {
            continue;
        }

        CurrentStats[0] = Player.CivilianKills*-1;
        CurrentStats[1] = Player.CivilianIncaps*-1;
        CurrentStats[2] = Player.CivilianHits*-1;
        CurrentStats[3] = Player.EnemyKillsInvalid*-1;
        CurrentStats[4] = Player.EnemyIncapsInvalid*-1;
        CurrentStats[5] = Player.LastDeaths*-1;
        CurrentStats[6] = Player.EnemyArrests;
        CurrentStats[7] = Player.CivilianArrests;
        CurrentStats[8] = Player.EnemyKills*-1;
        CurrentStats[9] = Player.CharacterReports;

        log(self $ ": checking " $ Player.LastName);

        if (BestPlayer == None || CompareStats(CurrentStats, BestStats))
        {
            BestPlayer = Player;
            BestStats = CurrentStats;

            log(self $ ": best player is now " $ BestPlayer.LastName);
        }
    }

    log(self $ ": at last the best player is " $ BestPlayer.LastName);

    return BestPlayer;
}

/**
 * Return the best player from team TeamNumber sorted by score, kills, arrests, < deaths, < arrested

 */
protected function Player GetBestScoredPlayer(int TeamNumber)
{
    local int i;
    local Player BestPlayer;
    local array<int> CurrentStats, BestStats;
    local Player Player;

    log(self $ ": retrieving the best scored player for team " $ TeamNumber);

    for (i = 0; i < Core.Server.Players.Length; i++)
    {
        Player = Core.Server.Players[i];

        if (Player.LastTeam == TeamNumber || TeamNumber == -1)
        {
            CurrentStats[0] = Player.LastScore;
            CurrentStats[1] = Player.LastKills;
            CurrentStats[2] = Player.LastArrests;
            CurrentStats[3] = Player.LastDeaths*-1;
            CurrentStats[4] = Player.LastArrested*-1;

            log(self $ ": checking " $ Player.LastName);

            if (BestPlayer == None || CompareStats(CurrentStats, BestStats))
            {
                BestPlayer = Player;
                BestStats = CurrentStats;

                log(self $ ": best player is now " $ BestPlayer.LastName);
            }
        }
    }

    log(self $ ": at last the best player is " $ BestPlayer.LastName);

    return BestPlayer;
}

/**
 * Return a list of non-grenade weapons used by a player
 */
static function array<Weapon> GetNonGrenadeWeapons(Player Player)
{
    local int i;
    local array<Weapon> WeaponsFiltered;

    for (i = 0; i < Player.Weapons.Length; i++)
    {
        if (!Player.Weapons[i].IsGrenade())
        {
            WeaponsFiltered[WeaponsFiltered.Length] = Player.Weapons[i];
        }
    }

    return WeaponsFiltered;
}

/**
 * Return the total number of enemies hit by Player
 */
static function int GetPlayerHits(Player Player)
{
    local int i, Hits;
    local array<Weapon> Weapons;

    Weapons = GetNonGrenadeWeapons(Player);

    for (i = 0; i < Weapons.Length; i++)
    {
        Hits += Weapons[i].Hits;
    }

    return Hits;
}

/**
 * Return the total number of teammates hit by Player
 */
static function int GetPlayerTeamHits(Player Player)
{
    local int i, TeamHits;
    local array<Weapon> Weapons;

    Weapons = GetNonGrenadeWeapons(Player);

    for (i = 0; i < Weapons.Length; i++)
    {
        TeamHits += Weapons[i].TeamHits;
    }

    return TeamHits;
}

/**
 * Return the number of ammo fired by Player
 */
static function int GetPlayerAmmoFired(Player Player)
{
    local int i, Shots;
    local array<Weapon> Weapons;

    Weapons = GetNonGrenadeWeapons(Player);

    for (i = 0; i < Weapons.Length; i++)
    {
        Shots += Weapons[i].Shots;
    }

    return Shots;
}

/**
 * Return the percent value of Player's accuracy for non-grenade weapons
 */
static function int GetPlayerAccuracy(Player Player)
{
    local int Hits, Shots;

    Hits = GetPlayerHits(Player);
    Shots = GetPlayerAmmoFired(Player);

    // Avoid 100% accuracy with only 2 tazer direct hits 
    if (Shots >= MIN_ACCURACY_SHOTS)
    {
        return int(float(Hits) / float(Shots) * 100.0);
    }

    return 0;
}

/**
 * Return a list of grenades used by Player
 */
static function array<Weapon> GetGrenadeWeapons(Player Player)
{
    local int i;
    local array<Weapon> WeaponsFiltered;

    for (i = 0; i < Player.Weapons.Length; i++)
    {
        if (Player.Weapons[i].IsGrenade())
        {
            WeaponsFiltered[WeaponsFiltered.Length] = Player.Weapons[i];
        }
    }

    return WeaponsFiltered;
}

/**
 * Return the total number of grenade enemy hits
 */
static function int GetPlayerNadeHits(Player Player)
{
    local int i, Hits;
    local array<Weapon> Weapons;

    Weapons = GetGrenadeWeapons(Player);

    for (i = 0; i < Weapons.Length; i++)
    {
        Hits += Weapons[i].Hits;
    }

    return Hits;
}

/**
 * Return the total number of teamnades for a player
 */
static function int GetPlayerNadeTeamHits(Player Player)
{
    local int i, TeamHits;
    local array<Weapon> Weapons;

    Weapons = GetGrenadeWeapons(Player);

    for (i = 0; i < Weapons.Length; i++)
    {
        TeamHits += Weapons[i].TeamHits;
    }

    return TeamHits;
}

/**
 * Return the total number grenades thrown
 */
static function int GetPlayerNadeThrown(Player Player)
{
    local int i, Thrown;
    local array<Weapon> Weapons;

    Weapons = GetGrenadeWeapons(Player);

    for (i = 0; i < Weapons.Length; i++)
    {
        Thrown += Weapons[i].Shots;
    }

    return Thrown;
}

/**
 * Return the percent value of Player's grenade accuracy
 */
static function int GetPlayerNadeAccuracy(Player Player)
{
    local int Hits, Thrown;

    Hits = GetPlayerNadeHits(Player);
    Thrown = GetPlayerNadeThrown(Player);

    if (Thrown >= MIN_ACCURACY_THROWN)
    {
        return int(float(Hits) / float(Thrown) * 100.0);
    }

    return 0;
}

/**
 * Return the Player's best kill distance
 */
static function float GetPlayerKillDistance(Player Player)
{
    local int i;
    local float Distance, BestDistance;

    for (i = 0; i < Player.Weapons.Length; i++)
    {
        Distance = Player.Weapons[i].BestKillDistance / 100;

        if (Distance > BestDistance)
        {
            BestDistance = Distance;
        }
    }

    return BestDistance;
}

/**
 * Perform an integer array comparison and tell whether array This is greater than array That
 */
static function bool CompareStats(array<int> This, array<int> That)
{
    local int i;

    for (i = 0; i < This.Length; i++)
    {
        if (i >= That.Length)
        {
            log("CompareStats(): the other array has no element with the index of " $ i);
            return true;
        }
        if (This[i] > That[i])
        {
            log(This[i] $ " > " $ That[i]);
            return true;
        }
        // Stats equal - attempt the next cycle of comparison
        else if (This[i] == That[i])
        {
            log(This[i] $ " == " $ That[i]);
            continue;
        }
        else
        {
            log(This[i] $ " < " $ That[i]);
            return false;
        }
    }
    // If players have all stats equal, assume the other player is better
    return false;
}

/**
 * Return a Locale normalized string for a dashed string,
 * so HIGHEST_HITS would be converted to HighestHits
 */
static function string GetLocaleString(string DashedString)
{
    local int i;
    local array<string> Words;

    // Split by a dash
    Words = class'Utils.StringUtils'.static.Part(Lower(DashedString), "_");

    for (i = 0; i < Words.Length; i++)
    {
        // Make the first letter uppercase
        Words[i] = class'Utils.StringUtils'.static.Capitalize(Words[i]);
    }

    return class'Utils.ArrayUtils'.static.Join(Words, "");
}

/**
 * Return a string with Number rounded up to 2 decimal points
 * Remove the fractional part if it filled with zeroes
 */
static function string GetNeatNumericString(float Number)
{
    if (Number % 1.0 == 0.0)
    {
        return string(int(Number));
    }
    return class'Utils.StringUtils'.static.Round(Number, 2);
}

/**
 * Colorify a Player's name
 */
static function string ColorifyName(Player Player)
{
    return class'Utils'.static.GetTeamColoredName(Player.LastName, Player.LastTeam, Player.bWasVIP);
}

event Destroyed()
{
    if (Core != None)
    {
        Core.Dispatcher.UnbindAll(self);
        Core.UnregisterInterestedInMissionStarted(self);
        Core.UnregisterInterestedInMissionEnded(self);
        Core.UnregisterInterestedInPlayerDisconnected(self);
    }

    ClearPlayerStatsCache();

    Super.Destroyed();
}

defaultproperties
{
    Title="Julia/Stats";
    LocaleClass=class'StatsLocale';

    MaxNames=1;
    MinTimeRatio=0.3;
}
