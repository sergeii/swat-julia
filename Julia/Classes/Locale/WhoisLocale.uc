class WhoisLocale extends Locale;

var config string WhoisCommandUsage;
var config string WhoisCommandDescription;
var config string WhoisCommandNoMatchError;

var config string CustomCommandUsage;
var config string CustomCommandDescription;
var config string CustomCommandLengthError;

defaultproperties
{
    WhoisCommandUsage="!%1 <name> <arguments>";
    WhoisCommandDescription="Performs a whois request against the named player.\\nName may contain wildcard characters.";
    WhoisCommandNoMatchError="No player matching the criteria has been found.\\nPlease provide a more specific name.";

    CustomCommandUsage="!%1 <arguments>";
    CustomCommandDescription="This is a custom command that is handled by the whois service.";
    CustomCommandLengthError="Command is too long. Please shorten the argument list.";
}
