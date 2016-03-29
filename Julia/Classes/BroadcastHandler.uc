class BroadcastHandler extends Engine.BroadcastHandler
  implements InterestedInEventBroadcast;

var Core Core;

/**
 * Reference to the original BroadcastHandler instance
 * (be it Engine.BroadcastHandler or AMMod.BroadcastHandler)
 */
var Engine.BroadcastHandler OriginalHandler;


public function Init(Core Core)
{
    self.Core = Core;

    // Override the Level broadcasthandler instance
    self.OriginalHandler = Level.Game.BroadcastHandler;
    Level.Game.BroadcastHandler = self;

    // register itself with the OnEventBroacast signal handler
    self.Core.RegisterInterestedInEventBroadcast(self);
}

/**
 * Attempt to fix an AIDeath event
 * Send AdminMsg events to the AMMod webadmin console
 */
public function bool OnEventBroadcast(Player Player, Actor Sender, name Type, out string Msg, optional PlayerController Receiver, optional bool bHidden)
{
    // Attempt to fix an AIDeath event that is caused
    // by a killer dying before their victim
    if (Type == 'AIDeath')
    {
        // If such an event has been successfully fixed
        // then mark it hidden, since an appropriate event is issued
        // by the underlying method
        return !self.FixAIDeath(Msg);
    }
    else if (Type == 'AdminMsg')
    {
        if (self.OriginalHandler.IsA('AMBroadcastHandler'))
        {
            self.OriginalHandler.SendToWebAdmin(Sender, 'Caption', Msg);
        }
        // Strip out color codes as the message goes straight into chatlog
        Msg = class'Utils.StringUtils'.static.Filter(Msg);
    }
    return true;
}

/**
 * Propagate the event to the original BroadcastHandler instance
 */
#if IG_SWAT && IG_SPEECH_RECOGNITION
    public function Broadcast(Actor Sender, coerce string Msg, optional name Type, optional PlayerController Target)
#else
    public function Broadcast(Actor Sender, coerce string Msg, optional name Type)
#endif
{
    if (!self.CheckEvent(Sender, Msg, Type))
    {
        log(self $ ": suppressing " $ Type);
        return;
    }
    #if IG_SWAT && IG_SPEECH_RECOGNITION
        self.OriginalHandler.Broadcast(Sender, Msg, Type, Target);
    #else
        self.OriginalHandler.Broadcast(Sender, Msg, Type);
    #endif
}

/**
 * Check the event before propagating it to the original BroadcastHandler instance
 */
public function BroadcastTeam(Controller Sender, coerce string Msg, optional name Type)
{
    if (!self.CheckEvent(Sender, Msg, Type))
    {
        log(self $ ": suppressing " $ Type);
        return;
    }
    self.OriginalHandler.BroadcastTeam(Sender, Msg, Type);
}

/**
 * Check whether the event is allowed to be broadcast into the game
 */
protected function bool CheckEvent(Actor Sender, out coerce string Msg, optional name Type)
{
    local Player Player;

    // Attempt to get retrieve the sender's Player instance
    if (Sender != None)
    {
        Player = self.Core.Server.GetPlayerByPC(PlayerController(Sender));
    }

    // If one of the listeners do not wish this event to appear in game
    // (for instance, this could be a censored Say/TeamSay event)
    // then don't allow this event to be broadcast at all
    return self.Core.TriggerOnEventBroadcast(Player, Sender, Type, Msg);
}

/**
 * Attempt to fix an unbroadcast kill event (SwatKill, SwatTeamKill, SuspectsKill, SuspectsTeamKill)
 * Return whether the event has been fixed
 *
 * @param   Message
 *          Potential AIDeath message (e.g. Player1\tPlayer2\tnearby explosion)
 */
protected function bool FixAIDeath(string Message)
{
    local name FixedType;
    local array<string> Args;
    local Player Killer, Victim;

    Args = class'Utils.StringUtils'.static.Part(Message, "\t");
    // Check whether the victim has been killed either
    // with Grenade Explosion or nearby explosion
    switch (Args[2])
    {
        case "Grenade Explosion" :
        case "nearby explosion" :   // lower-case
            break;
        default :
            return false;
    }

    Killer = self.Core.Server.GetPlayerByName(Args[0]);
    Victim = self.Core.Server.GetPlayerByName(Args[1]);

    if (Killer == None || Victim == None)
    {
        return false;
    }
    if (Killer.GetTeam() == 0)
    {
        if (Killer.IsEnemyTo(Victim))
        {
            FixedType = 'SwatKill';
        }
        else
        {
            FixedType = 'SwatTeamKill';
        }
    }
    else
    {
        if (Killer.IsEnemyTo(Victim))
        {
            FixedType = 'SuspectsKill';
        }
        else
        {
            FixedType = 'SuspectsTeamKill';
        }
    }
    // Broadcast a new event
    self.Broadcast(None, Message, FixedType);
    return true;
}


public function UpdateSentText()
{
    self.OriginalHandler.UpdateSentText();
}

public function bool AllowsBroadcast(Actor Broadcaster, int Len)
{
    return self.OriginalHandler.AllowsBroadcast(Broadcaster, Len);
}

event Destroyed()
{
    self.Core.UnregisterInterestedInEventBroadcast(self);
    // Restore the original reference
    Level.Game.BroadcastHandler = self.OriginalHandler;

    self.Core = None;
    self.OriginalHandler = None;

    Super.Destroyed();
}
