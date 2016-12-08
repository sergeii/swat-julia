class Whois extends Extension
 implements InterestedInCommandDispatched,
            InterestedInPlayerConnected,
            HTTP.ClientOwner;

import enum eClientError from HTTP.Client;

const MAX_ARG_LENGTH=150;


enum eRequestKey
{
    RK_KEY_HASH,        // Last 16 characters of the md5-hex-encoded Key
    RK_COMMAND_NAME,    // Command name (such as whois")
    RK_COMMAND_ID,      // Command unique id (used to dispatch command response back to the command user)
    RK_COMMAND_ARGS,    // Command arguments separated by space
    // Name and IP of the player who issued the command */
    RK_PLAYER_NAME,
    RK_PLAYER_IP
};

var HTTP.Client Client;

/**
 * List of extra commands with arbitrary arguments
 */
var config array<string> Commands;

var config string URL;  // Whois service URL
var config string Key;  // Server credentials
var config bool AutoWhois;  // Indicate whether a whois query should be automatically sent upon a player connection


public function PreBeginPlay()
{
    Super.PreBeginPlay();

    if (URL == "")
    {
        log(self $ " has been provided with empty URL");
        Destroy();
    }
    else if (Key == "")
    {
        log(self $ " has been provided with empty key");
        Destroy();
    }
}

public function BeginPlay()
{
    Super.BeginPlay();

    Core.RegisterInterestedInPlayerConnected(self);
    Client = Spawn(class'HTTP.Client');

    RegisterCommands();
}

protected function RegisterCommands()
{
    local int i;

    // Register the builtin whois command
    Core.Dispatcher.Bind(
        "whois", self, Locale.Translate("WhoisCommandUsage"), Locale.Translate("WhoisCommandDescription")
    );
    // Register custom commands defined in the Commands list
    for (i = 0; i < Commands.Length; i++)
    {
        Core.Dispatcher.Bind(
            Commands[i], self, Locale.Translate("CustomCommandUsage"), Locale.Translate("CustomCommandDescription")
        );
    }
}

public function OnCommandDispatched(Dispatcher Dispatcher, string Name, string Id, array<string> Args, Player Player)
{
    local Player MatchedPlayer;
    local string ArgsCombined;

    // whois commands are only available to admins
    if (!Player.IsAdmin())
    {
        Dispatcher.ThrowPermissionError(Id);
        return;
    }

    if (Name == "whois")
    {
        // the whois command require an argument
        if (Args.Length == 0)
        {
            Dispatcher.ThrowUsageError(Id);
            return;
        }

        MatchedPlayer = Core.Server.GetPlayerByWildName(Args[0]);

        if (MatchedPlayer == None)
        {
            Dispatcher.ThrowError(Id, Locale.Translate("WhoisCommandNoMatchError"));
            return;
        }
        // Prepend name and ip delimited by a tab character to the arg list
        ArgsCombined = MatchedPlayer.GetName() $ "\t" $ MatchedPlayer.IpAddr;
    }
    else
    {
        ArgsCombined = class'Utils.ArrayUtils'.static.Join(Args, " ");
    }

    if (Len(ArgsCombined) > MAX_ARG_LENGTH)
    {
        Dispatcher.ThrowError(Id, Locale.Translate("CustomCommandLengthError"));
        return;
    }

    SendCommandRequest(Name, ArgsCombined, Id, Player);
}

public function OnPlayerConnected(Player Player)
{
    // Only perform a whois lookup when a player connects midgame
    if (!AutoWhois || Core.Server.GetGameState() != GAMESTATE_MidGame)
    {
        return;
    }
    SendCommandRequest("whois", Player.GetName() $ "\t" $ Player.IpAddr, "!");
}

public function OnRequestSuccess(int StatusCode, string Response, string Hostname, int Port)
{
    local array<string> Lines;
    local string CommandId, Message;

    if (StatusCode == 200)
    {
        Lines = class'Utils.StringUtils'.static.Part(Response, "\n");

        if (Lines.Length > 2 && Len(Lines[0]) == 1)
        {
            // 0 - Success
            if (Lines[0] == "0")
            {
                // Id of the dispatched command
                CommandId = Lines[1];

                if (CommandId != "")
                {
                    // Strip status code and id from the split response
                    Lines.Remove(0, 2);
                    // Then join what's left back with a \n
                    Message = Left(class'Utils.ArrayUtils'.static.Join(Lines, "\n"), 1024); // dont let chat overflow

                    switch (Left(CommandId, 1))
                    {
                        // Display to all admins
                        case "!":
                            class'Utils.LevelUtils'.static.TellAdmins(Level, Message);
                            break;
                        // Display to all players
                        case "@":
                            class'Utils.LevelUtils'.static.TellAll(Level, Message);
                            break;
                        default:
                            Core.Dispatcher.Respond(CommandId, Message);
                            return;
                    }
                    // Mark the command complete
                    if (Len(CommandId) > 1)
                    {
                        Core.Dispatcher.Void(Mid(CommandId, 1));
                    }
                    return;
                }
            }
        }
    }
    log(self $ " received invalid response from " $ Hostname $ " (" $ StatusCode $ ":" $ Left(Response, 20) $ ")");
}

public function OnRequestFailure(eClientError ErrorCode, string ErrorMessage, string Hostname, int Port)
{
    log(self $ " failed a request to " $ Hostname $ " (" $ ErrorMessage $ ")");
}

protected function SendCommandRequest(string Command, string Args, string Id, optional Player Player)
{
    local HTTP.Message Message;
    local string PlayerName, PlayerIP;

    Message = Spawn(class'Message');

    Message.AddQueryString(eRequestKey.RK_KEY_HASH, Right(ComputeMD5Checksum(Key), 16));
    Message.AddQueryString(eRequestKey.RK_COMMAND_NAME, Command);
    Message.AddQueryString(eRequestKey.RK_COMMAND_ID, Id);
    Message.AddQueryString(eRequestKey.RK_COMMAND_ARGS, Args);

    // Pass name and IP address of the player who issues the command
    if (Player != None)
    {
        PlayerName = Player.GetName();
        PlayerIP = Player.IPAddr;
    }
    Message.AddQueryString(eRequestKey.RK_PLAYER_NAME, PlayerName);
    Message.AddQueryString(eRequestKey.RK_PLAYER_IP, PlayerIP);

    Client.Send(Message, URL, 'GET', self, 1);  // 1 attempt
}

event Destroyed()
{
    if (Client != None)
    {
        Client.Destroy();
        Client = None;
    }

    if (Core != None)
    {
        Core.Dispatcher.UnbindAll(self);
        Core.UnregisterInterestedInPlayerConnected(self);
    }

    Super.Destroyed();
}

defaultproperties
{
    Title="Julia/Whois";
    LocaleClass=class'WhoisLocale';
    AutoWhois=True;
    URL="http://swat4stats.com/api/whois/";
    Key="swat4stats";
}
