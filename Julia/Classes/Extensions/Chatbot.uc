class Chatbot extends Extension
 implements InterestedInEventBroadcast,
            InterestedInPlayerDisconnected;

struct sBotReply
{
    var Player Player;
    var float TimeQueued;
    var string Message;
    var bool bReplied;
};

var array<sBotReply> BotReplies;

var config array<string> Templates;
var config array<string> Replies;
var config float ReplyThreshold;
var config float ReplyDelay;


public function BeginPlay()
{
    Super.BeginPlay();

    Core.RegisterInterestedInEventBroadcast(self);
    Core.RegisterInterestedInPlayerDisconnected(self);
}

event Timer()
{
    HandleBotReplies();
}

/**
 * Attempt to match a Say message against the list of chatbot templates
 */
public function bool OnEventBroadcast(Player Player, Actor Sender, name Type, string Msg, optional PlayerController Receiver, optional bool bHidden)
{
    local string Reply;

    if (!bHidden)
    {
        if (Type == 'Say')
        {
            if (Player != None && IsAllowedToInteract(Player))
            {
                if (ValidateTemplate(Msg, Reply))
                {
                    QueueReply(Reply, Player);
                }
            }
        }
    }
    return true;
}

/**
 * Attempt to parse a message against the list of chatbot templates
 */
protected function bool ValidateTemplate(string Message, out string Reply)
{
    local int i, j;
    local array<string> ParsedTemplates, ParsedReplies;

    for (i = 0; i < Templates.Length; i++)
    {
        if (Replies[i] == "")
        {
            continue;
        }
        else if (i >= Replies.Length)
        {
            break;
        }

        ParsedTemplates = class'Utils.StringUtils'.static.Part(Templates[i], "#");
        ParsedReplies = class'Utils.StringUtils'.static.Part(Replies[i], "#");

        if (ParsedTemplates.Length == 0 || ParsedReplies.Length == 0)
        {
            continue;
        }

        for (j = 0; j < ParsedTemplates.Length; j++)
        {
            if (class'Utils.StringUtils'.static.Match(Message, ParsedTemplates[j]))
            {
                Reply = class'Utils.ArrayUtils'.static.Random(ParsedReplies);
                return true;
            }
        }
    }
    return false;
}

/**
 * Remove disconnected player from the list of dispatched replies
 */
public function OnPlayerDisconnected(Player Player)
{
    local int i;

    for (i = BotReplies.Length-1; i >= 0 ; i--)
    {
        if (BotReplies[i].Player == Player)
        {
            BotReplies[i].Player = None;
            BotReplies.Remove(i, 1);
        }
    }
}

/**
 * Attempt to reply to a player with a dispatched reply
 */
protected function HandleBotReplies()
{
    local int i;

    for (i = BotReplies.Length-1; i >= 0; i--)
    {
        // Reply to a player
        if (!BotReplies[i].bReplied)
        {
            if (BotReplies[i].TimeQueued + ReplyDelay <= Level.TimeSeconds)
            {
                Reply(BotReplies[i].Message, BotReplies[i].Player);
                BotReplies[i].Message = "";
                BotReplies[i].bReplied = true;
            }
        }
        else if (BotReplies[i].TimeQueued + ReplyThreshold < Level.TimeSeconds)
        {
            BotReplies.Remove(i, 1);
        }
    }
}

protected function Reply(string Message, Player Player)
{
    local int i;
    local array<string> Lines;

    // Split lines
    Lines = class'Utils.StringUtils'.static.Part(class'Utils.StringUtils'.static.NormNewline(Message), "\n");

    if (Lines.Length == 0)
    {
        return;
    }
    // Display the first line
    class'Utils.LevelUtils'.static.TellAll(
        Level,
        Locale.Translate("ReplyMessage", FormatReplyMessage(Lines[0], Player)),
        Locale.Translate("ReplyColor")
    );
    Lines.Remove(0, 1);
    // Display the other lines
    for (i = 0; i < Lines.Length; i++)
    {
        class'Utils.LevelUtils'.static.TellAll(
            Level, FormatReplyMessage(Lines[i], Player), Locale.Translate("ReplyColor")
        );
    }
}

protected function QueueReply(string Message, Player Player)
{
    local sBotReply NewReply;

    NewReply.Player = Player;
    NewReply.Message = Message;
    NewReply.TimeQueued = Level.TimeSeconds;

    BotReplies[BotReplies.Length] = NewReply;
}

/**
 * Interpolate a reply message with variables
 */
protected function string FormatReplyMessage(coerce string Message, Player Player)
{
    local array<string> Vars;
    local string Value;
    local int i;

    Vars[0] = "name";
    Vars[1] = "time";
    Vars[2] = "nextmap";
    Vars[3] = "random";

    for (i = 0; i < Vars.Length; i++)
    {
        if (InStr(Message, "%" $ Vars[i] $ "%") >= 0)
        {
            switch (Vars[i])
            {
                case "name" :
                    Value = Player.GetName();
                    break;
                case "time" :
                    Value = class'Utils.LevelUtils'.static.FormatTime(class'Utils.LevelUtils'.static.GetTime(Level), "%H:%M");
                    break;
                case "nextmap" :
                    Value = class'Utils'.static.GetFriendlyMapName(class'Utils'.static.GetNextMap(Level));
                    break;
                case "random" :
                    Value = GetRandomName(Player);
                    break;
                default :
                    Value = "";
            }
            Message = class'Utils.StringUtils'.static.Replace(Message, "%" $ Vars[i] $ "%", Value);
        }
    }
    return Message;
}

/**
 * Tell whether a player is allowed to interact with chatbot at the moment
 */
protected function bool IsAllowedToInteract(Player Player)
{
    local int i;

    for (i = 0; i < BotReplies.Length; i++)
    {
        if (BotReplies[i].Player == Player)
        {
            return false;
        }
    }

    return true;
}

/**
 * Return name of a random online player.
 * Use the FallbackPlayer's name as the last resort
 */
protected function string GetRandomName(Player FallbackPlayer)
{
    local array<string> Names;
    local int i;

    for (i = 0; i < Core.Server.Players.Length; i++)
    {
        if (Core.Server.Players[i].PC != None && Core.Server.Players[i] != FallbackPlayer)
        {
            Names[Names.Length] = Core.Server.Players[i].GetName();
        }
    }
    if (Names.Length > 0)
    {
        return class'Utils.ArrayUtils'.static.Random(Names);
    }
    return FallbackPlayer.GetName();
}

event Destroyed()
{
    if (Core != None)
    {
        Core.UnregisterInterestedInEventBroadcast(self);
        Core.UnregisterInterestedInPlayerDisconnected(self);
    }

    while (BotReplies.Length > 0)
    {
        BotReplies[0].Player = None;
        BotReplies.Remove(0, 1);
    }

    Super.Destroyed();
}

defaultproperties
{
    Title="Julia/Chatbot";
    LocaleClass=class'ChatbotLocale';

    ReplyThreshold=2.0;
    ReplyDelay=0.5;
}
