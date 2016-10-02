class Locale extends Engine.Actor;

var config string CoreVersionUsage;
var config string CoreVersionDescription;

var config string DispatcherHelpUsage;
var config string DispatcherHelpDescription;

var config string DispatcherCommandList;
var config string DispatcherCommandCooldown;
var config string DispatcherCommandInvalid;
var config string DispatcherCommandTimedout;
var config string DispatcherOutputHeader;
var config string DispatcherOutputLine;
var config string DispatcherOutputColor;
var config string DispatcherCommandHelp;

var config string DispatcherUsageError;
var config string DispatcherPermissionError;


public function PreBeginPlay()
{
    Super.PreBeginPlay();
    self.Disable('Tick');
}

/**
 * Translate a property string
 */
public function string Translate(
    string Property,
    optional coerce string Arg1,
    optional coerce string Arg2,
    optional coerce string Arg3,
    optional coerce string Arg4,
    optional coerce string Arg5
)
{
    return class'Utils.StringUtils'.static.Format(self.GetPropertyText(Property), Arg1, Arg2, Arg3, Arg4, Arg5);
}

event Destroyed()
{
    log(self $ " is about to be destroyed");
    Super.Destroyed();
}

defaultproperties
{
    CoreVersionUsage="!%1";
    CoreVersionDescription="Displays the mod version.";

    DispatcherHelpUsage="!%1";
    DispatcherHelpDescription="Lists available commands.";

    DispatcherCommandList="Available commands: %1\\nType [b]!<command> help[\\b] for more information on the specified command.";
    DispatcherCommandCooldown="Unable to issue the command.\\nPlease try again later.";
    DispatcherCommandInvalid="'%1' is not a valid command.\\nType !help to list available commands.";
    DispatcherCommandTimedout="Failed to issue the command.\\nPlease try again later.";
    DispatcherCommandHelp="%1\\nUsage: [c=FFFF00]%2";
    DispatcherOutputHeader="[b]%1[\\b] %2";
    DispatcherOutputColor="ffffff";
    DispatcherOutputLine="> %1";

    DispatcherUsageError="You provided invalid arguments.\\nType [b]!%1 help[\\b] for more information on command usage.";
    DispatcherPermissionError="You don't have permissions to issue the [b]%1[\\b] command.";
}
