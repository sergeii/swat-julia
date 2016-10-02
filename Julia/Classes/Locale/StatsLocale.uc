class StatsLocale extends Locale;

var config string MessageColor;

var config string StatsCommandUsage;
var config string StatsCommandDescription;

var config string NextMapMessage;

var config string RoundScoreMessage;
var config string RoundPlayerMessage;
var config string RoundPlayerName;
var config string RoundPlayerNameMore;

var config string PlayerErrorNotAvailable;
var config string PlayerErrorNoMatch;
var config string PlayerErrorNoStats;

var config string PlayerDescription;

var config string PlayerHits;
var config string PlayerTeamHits;
var config string PlayerAmmoFired;
var config string PlayerAccuracy;
var config string PlayerNadeHits;
var config string PlayerNadeTeamHits;
var config string PlayerNadeThrown;
var config string PlayerNadeAccuracy;
var config string PlayerKillDistance;
var config string PlayerScore;
var config string PlayerKills;
var config string PlayerArrests;
var config string PlayerArrested;
var config string PlayerTeamKills;
var config string PlayerSuicides;
var config string PlayerDeaths;
var config string PlayerKillStreak;
var config string PlayerArrestStreak;
var config string PlayerDeathStreak;
var config string PlayerVipCaptures;
var config string PlayerVipRescues;
var config string PlayerBombsDefused;
var config string PlayerCaseKills;
var config string PlayerReports;
var config string PlayerHostageArrests;
var config string PlayerHostageHits;
var config string PlayerHostageIncaps;
var config string PlayerHostageKills;
var config string PlayerEnemyArrests;
var config string PlayerEnemyIncaps;
var config string PlayerEnemyKills;
var config string PlayerEnemyIncapsInvalid;
var config string PlayerEnemyKillsInvalid;

var config string RoundHighestHits;
var config string RoundLowestHits;

var config string RoundHighestTeamHits;
var config string RoundLowestTeamHits;

var config string RoundHighestAmmoFired;
var config string RoundLowestAmmoFired;

var config string RoundHighestAccuracy;
var config string RoundLowestAccuracy;

var config string RoundHighestNadeHits;
var config string RoundLowestNadeHits;

var config string RoundHighestNadeTeamHits;
var config string RoundLowestNadeTeamHits;

var config string RoundHighestNadeThrown;
var config string RoundLowestNadeThrown;

var config string RoundHighestNadeAccuracy;
var config string RoundLowestNadeAccuracy;

var config string RoundHighestKillDistance;
var config string RoundLowestKillDistance;

var config string RoundHighestScore;
var config string RoundLowestScore;

var config string RoundHighestKills;
var config string RoundLowestKills;

var config string RoundHighestArrests;
var config string RoundLowestArrests;

var config string RoundHighestArrested;
var config string RoundLowestArrested;

var config string RoundHighestTeamKills;
var config string RoundLowestTeamKills;

var config string RoundHighestSuicides;
var config string RoundLowestSuicides;

var config string RoundHighestDeaths;
var config string RoundLowestDeaths;

var config string RoundHighestKillStreak;
var config string RoundLowestKillStreak;

var config string RoundHighestArrestStreak;
var config string RoundLowestArrestStreak;

var config string RoundHighestDeathStreak;
var config string RoundLowestDeathStreak;

var config string RoundHighestVipCaptures;
var config string RoundLowestVipCaptures;

var config string RoundHighestVipRescues;
var config string RoundLowestVipRescues;

var config string RoundHighestBombsDefused;
var config string RoundLowestBombsDefused;

var config string RoundHighestCaseKills;
var config string RoundLowestCaseKills;

var config string RoundHighestReports;
var config string RoundLowestReports;

var config string RoundHighestHostageArrests;
var config string RoundLowestHostageArrests;

var config string RoundHighestHostageHits;
var config string RoundLowestHostageHits;

var config string RoundHighestHostageIncaps;
var config string RoundLowestHostageIncaps;

var config string RoundHighestHostageKills;
var config string RoundLowestHostageKills;

var config string RoundHighestEnemyArrests;
var config string RoundLowestEnemyArrests;

var config string RoundHighestEnemyIncaps;
var config string RoundLowestEnemyIncaps;

var config string RoundHighestEnemyKills;
var config string RoundLowestEnemyKills;

var config string RoundHighestEnemyIncapsInvalid;
var config string RoundLowestEnemyIncapsInvalid;

var config string RoundHighestEnemyKillsInvalid;
var config string RoundLowestEnemyKillsInvalid;

defaultproperties
{
    MessageColor="FFFFFF";

    StatsCommandUsage="!%1 [optional player name]";
    StatsCommandDescription="Displays the player's current round stats.\\nTo display your own stats, use the command without arguments at all.";

    NextMapMessage="Next map is [b]%1[\\b].";

    RoundPlayerMessage="Player of the round: [b]%1[\\b]";
    RoundPlayerName="[b]%1[\\b]";
    RoundPlayerNameMore="[b]%1[\\b] and %2 more";

    PlayerErrorNotAvailable="N/A";
    PlayerErrorNoMatch="No player matching the criteria has been found.";
    PlayerErrorNoStats="No stats available.";

    PlayerDescription="Displaying stats for [b]%1[\\b]";

    PlayerHits="Enemy hits: [b]%1[\\b]";
    PlayerTeamHits="Team injuries: [b]%1[\\b]";
    PlayerAmmoFired="Ammo fired: [b]%1[\\b]";
    PlayerAccuracy="Accuracy: [b]%1%[\\b]";
    PlayerNadeHits="Grenade hits: [b]%1[\\b]";
    PlayerNadeTeamHits="Team nade hits: [b]%1[\\b]";
    PlayerNadeThrown="Grenades thrown: [b]%1[\\b]";
    PlayerNadeAccuracy="Grenade accuracy: [b]%1%[\\b]";
    PlayerKillDistance="Longest kill: [b]%1m[\\b]";
    PlayerScore="Score: [b]%1[\\b]";
    PlayerKills="Kills: [b]%1[\\b]";
    PlayerArrests="Arrests: [b]%1[\\b]";
    PlayerArrested="Arrested: [b]%1[\\b]";
    PlayerTeamKills="Team kills: [b]%1[\\b]";
    PlayerSuicides="Suicides: [b]%1[\\b]";
    PlayerDeaths="Deaths: [b]%1[\\b]";
    PlayerKillStreak="Highest kill streak: [b]%1[\\b]";
    PlayerArrestStreak="Highest arrest streak: [b]%1[\\b]";
    PlayerDeathStreak="Highest death streak: [b]%1[\\b]";
    PlayerVipCaptures="VIP captures: [b]%1[\\b]";
    PlayerVipRescues="VIP rescues: [b]%1[\\b]";
    PlayerBombsDefused="Bombs defused: [b]%1[\\b]";
    PlayerCaseKills="Case carrier kills: [b]%1[\\b]";
    PlayerReports="Characters reported to TOC: [b]%1[\\b]";
    PlayerHostageArrests="Civilians arrested: [b]%1[\\b]";
    PlayerHostageHits="Civilians injured: [b]%1[\\b]";
    PlayerHostageIncaps="Civilians incapacitated: [b]%1[\\b]";
    PlayerHostageKills="Civilians killed: [b]%1[\\b]";
    PlayerEnemyArrests="Suspects arrested: [b]%1[\\b]";
    PlayerEnemyIncaps="Suspects incapacitated: [b]%1[\\b]";
    PlayerEnemyKills="Suspects killed: [b]%1[\\b]";
    PlayerEnemyIncapsInvalid="Unauthorized use of force: [b]%1[\\b]";
    PlayerEnemyKillsInvalid="Unauthorized use of deadly force: [b]%1[\\b]";

    RoundHighestHits="Most enemy hits: %1 - [b]%2[\\b]";
    RoundLowestHits="Least enemy hits: %1 - [b]%2[\\b]";

    RoundHighestTeamHits="Most team hits: %1 - [b]%2[\\b]";
    RoundLowestTeamHits="Least team hits: %1 - [b]%2[\\b]";

    RoundHighestAmmoFired="Most ammo fired: %1 - [b]%2[\\b]";
    RoundLowestAmmoFired="Least ammo fired: %1 - [b]%2[\\b]";

    RoundHighestAccuracy="Highest accuracy: %1 - [b]%2%[\\b]";
    RoundLowestAccuracy="Lowest accuracy : %1 - [b]%2%[\\b]";

    RoundHighestNadeHits="Most grenade hits: %1 - [b]%2[\\b]";
    RoundLowestNadeHits="Least grenade hits: %1 - [b]%2[\\b]";

    RoundHighestNadeTeamHits="Most team nades: %1 - [b]%2[\\b]";
    RoundLowestNadeTeamHits="Least team nades: %1 - [b]%2[\\b]";

    RoundHighestNadeThrown="Most grenades used: %1 - [b]%2[\\b]";
    RoundLowestNadeThrown="Least grenades used: %1 - [b]%2[\\b]";

    RoundHighestNadeAccuracy="Highest grenade accuracy: %1 - [b]%2%[\\b]";
    RoundLowestNadeAccuracy="Lowest grenade accuracy: %1 - [b]%2%[\\b]";

    RoundHighestKillDistance="Best long range kill: %1 - [b]%2m[\\b]";
    RoundLowestKillDistance="Worst long range kill: %1 - [b]%2m[\\b]";

    RoundHighestScore="Highest score: %1 - [b]%2[\\b]";
    RoundLowestScore="Lowest score: %1 - [b]%2[\\b]";

    RoundHighestKills="Most kills: %1 - [b]%2[\\b]";
    RoundLowestKills="Least kills: %1 - [b]%2[\\b]";

    RoundHighestArrests="Most arrests: %1 - [b]%2[\\b]";
    RoundLowestArrests="Least arrests: %1 - [b]%2[\\b]";

    RoundHighestArrested="Most times arrested: %1 - [b]%2[\\b]";
    RoundLowestArrested="Least times arrested: %1 - [b]%2[\\b]";

    RoundHighestTeamKills="Most team kills: %1 - [b]%2[\\b]";
    RoundLowestTeamKills="Least team kills: %1 - [b]%2[\\b]";

    RoundHighestSuicides="Most suicides: %1 - [b]%2[\\b]";
    RoundLowestSuicides="Least suicides: %1 - [b]%2[\\b]";

    RoundHighestDeaths="Most deaths: %1 - [b]%2[\\b]";
    RoundLowestDeaths="Least deaths: %1 - [b]%2[\\b]";

    RoundHighestKillStreak="Highest kill streak: %1 - [b]%2[\\b]";
    RoundLowestKillStreak="Lowest kill streak: %1 - [b]%2[\\b]";

    RoundHighestArrestStreak="Highest arrest streak: %1 - [b]%2[\\b]";
    RoundLowestArrestStreak="Lowest arrest streak: %1 - [b]%2[\\b]";

    RoundHighestDeathStreak="Highest death streak: %1 - [b]%2[\\b]";
    RoundLowestDeathStreak="Lowest death streak: %1 - [b]%2[\\b]";

    RoundHighestVipCaptures="Most VIP arrests: %1 - [b]%2[\\b]";
    RoundLowestVipCaptures="Least VIP arrests: %1 - [b]%2[\\b]";

    RoundHighestVipRescues="Most VIP rescues: %1 - [b]%2[\\b]";
    RoundLowestVipRescues="Least VIP rescues: %1 - [b]%2[\\b]";

    RoundHighestBombsDefused="Most bombs defused: %1 - [b]%2[\\b]";
    RoundLowestBombsDefused="Least bombs defused: %1 - [b]%2[\\b]";

    RoundHighestCaseKills="Most carrier kills: %1 - [b]%2[\\b]";
    RoundLowestCaseKills="Least carrier kills: %1 - [b]%2[\\b]";

    RoundHighestReports="Most TOC reports: %1 - [b]%2[\\b]";
    RoundLowestReports="Least TOC reports: %1 - [b]%2[\\b]";

    RoundHighestHostageArrests="Most civilians arrested: %1 - [b]%2[\\b]";
    RoundLowestHostageArrests="Least civilians arrested: %1 - [b]%2[\\b]";

    RoundHighestHostageHits="Most civilians hit: %1 - [b]%2[\\b]";
    RoundLowestHostageHits="Least civilians hit: %1 - [b]%2[\\b]";

    RoundHighestHostageIncaps="Most civilians incapacitated: %1 - [b]%2[\\b]";
    RoundLowestHostageIncaps="Least civilians incapacitated: %1 - [b]%2[\\b]";

    RoundHighestHostageKills="Most civilians killed: %1 - [b]%2[\\b]";
    RoundLowestHostageKills="Least civilians killed: %1 - [b]%2[\\b]";

    RoundHighestEnemyArrests="Most suspects arrested: %1 - [b]%2[\\b]";
    RoundLowestEnemyArrests="Least suspects arrested: %1 - [b]%2[\\b]";

    RoundHighestEnemyIncaps="Most suspects incapacitated: %1 - [b]%2[\\b]";
    RoundLowestEnemyIncaps="Least suspects incapacitated: %1 - [b]%2[\\b]";

    RoundHighestEnemyKills="Most suspects killed: %1 - [b]%2[\\b]";
    RoundLowestEnemyKills="Least suspects killed: %1 - [b]%2[\\b]";

    RoundHighestEnemyIncapsInvalid="Most use of unauthorized force: %1 - [b]%2[\\b]";
    RoundLowestEnemyIncapsInvalid="Least use of unauthorized force: %1 - [b]%2[\\b]";

    RoundHighestEnemyKillsInvalid="Most use of unauthorized deadly force: %1 - [b]%2[\\b]";
    RoundLowestEnemyKillsInvalid="Least use of unauthorized deadly force: %1 - [b]%2[\\b]";
}
