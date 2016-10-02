class TrackerLocale extends Locale;

var config string MessageColor;

var config string SuccessMessage;
var config string WarningMessage;
var config string ResponseErrorMessage;
var config string HostFailureMessage;


defaultproperties
{
    MessageColor="FFFF00";

    SuccessMessage="[c=00FF00](%1)[\\c] %2";
    WarningMessage="[c=FF0000](%1)[\\c] %2";
    ResponseErrorMessage="The tracker is not available.";
    HostFailureMessage="The remote host is not responding.";
}
