class COOPLocale extends Locale;

var config string EventSwatIncapHostage;
var config string EventSwatKillHostage;
var config string EventSwatIncapSuspect;
var config string EventSwatIncapInvalidSuspect;
var config string EventSwatKillSuspect;
var config string EventSwatKillInvalidSuspect;
var config string EventSuspectsIncapHostage;
var config string EventSuspectsKillHostage;
var config string EventSuspectsIncapOfficer;

var config string MissionEndMessage;

defaultproperties
{
    EventSwatIncapHostage="[b]%1[\\b] incapacitated a hostage!";
    EventSwatKillHostage="[b]%1[\\b] killed a hostage!";
    EventSwatIncapSuspect="[b]%1[\\b] incapacitated a suspect.";
    EventSwatIncapInvalidSuspect="[b]%1[\\b] incapacitated a suspect (unauthorized)!";
    EventSwatKillSuspect="[b]%1[\\b] neutralised a suspect.";
    EventSwatKillInvalidSuspect="[b]%1[\\b] killed a suspect (unauthorized)!";
    EventSuspectsIncapHostage="The suspects incapacitated a hostage!";
    EventSuspectsKillHostage="The suspects killed a hostage!";
    EventSuspectsIncapOfficer="The suspects incapacitated [b]%1[\\b]!";

    MissionEndMessage="All objectives have been completed.\\nYou have [b]%1[\\b] minutes to complete the remaining procedures.";
}
