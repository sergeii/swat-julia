class BroadcastHandler extends Engine.BroadcastHandler
  implements InterestedInEventBroadcast;

/**
 * Copyright (c) 2014-2015 Sergei Khoroshilov <kh.sergei@gmail.com>
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

/**
 * Reference to the Core super object
 * @type class'Core'
 */
var protected Core Core;

/**
 * Reference to the original BroadcastHandler instance
 * (be it Engine.BroadcastHandler or AMMod.BroadcastHandler)
 * @type class'Engine.BroadcastHandler'
 */
var protected Engine.BroadcastHandler OriginalHandler;

/**
 * Initialize the instance and register itself with the OnEventBroacast signal handler
 * 
 * @param   class'Core' Core 
 *          Reference to the Core super object
 * @return  void
 */
public function Init(Core Core)
{
    self.Core = Core;
    // Store the original instance
    self.OriginalHandler = Level.Game.BroadcastHandler;
    // Override the Level broadcasthandler instance
    Level.Game.BroadcastHandler = self;

    self.Core.RegisterInterestedInEventBroadcast(self);
}

/**
 * Attempt to fix an AIDeath event
 * Send AdminMsg events to the AMMod webadmin console
 * 
 * @see InterestedInEventBroadcast.OnEventBroadcast
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
 * 
 * @param   class'Actor' Sender
 *          The actor that has issued the event
 * @param   string Msg
 *          Provided message
 * @param   name Type
 *          Event type
 * @param   class'PlayerController' Target (optional, expansion)
 *          The event reciever (if specified)
 * @return  void
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
 * 
 * @param   class'Actor' Sender
 *          The actor that has issued the event
 * @param   string Msg
 *          Provided message
 * @param   name Type
 *          Event type
 * @return  void
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
 * 
 * @param   class'Actor' Sender
 *          The actor that has issued the event
 * @param   string Msg (out)
 *          Provided message
 * @param   name Type
 *          Event type
 * @return  bool
 */
protected function bool CheckEvent(Actor Sender, out coerce string Msg, optional name Type)
{
    local Player Player;

    // Attempt to get retrieve the sender's Player instance
    if (Sender != None)
    {
        Player = self.Core.GetServer().GetPlayerByPC(PlayerController(Sender));
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
 * @param   string Message
 *          Provided message (e.g. Player1\tPlayer2\tnearby explosion)
 * @return  bool
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

    Killer = self.Core.GetServer().GetPlayerByName(Args[0]);
    Victim = self.Core.GetServer().GetPlayerByName(Args[1]);

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


/**
 * Propagate an UpdateSentText call to the original broadcast handler
 * 
 * @return void
 */
public function UpdateSentText()
{
    self.OriginalHandler.UpdateSentText();
}

/**
 * Propagate an AllowsBroadcast call to the original broadcast handler
 *
 * @param   class'Actor' Broadcaster
 * @param   int Len
 * @return  bool
 */
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

/* vim: set ft=java: */
