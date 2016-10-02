class COOP extends Extension
 implements IInterested_GameEvent_PawnDied,
            InterestedInEventBroadcast,
            InterestedInInternalEventBroadcast,
            InterestedInMissionEnded;

import enum ObjectiveStatus from SwatGame.Objective;

const COLOR_BLUE = "0000FF";
const COLOR_RED = "FF0000";

/**
 * List of players who have joined spec mode when they were still alive
 */
var array<Pawn> Spectators;

/**
 * Indicate whether the Ten Seconds warning has been shown
 */
var bool bMissionEndTenSecWarning;

/**
 * Indicate whether the One Minute warning has been shown
 */
var bool bMissionEndOneMinWarning;

/**
 * Indicate whether mission has been been completed with or without completing its objectives
 */
var bool bMissionCompleted;

/**
 * Time mission will be aborted at (Level.TimeSeconds)
 */
var float MissionAbortTime;

/**
 * Time a mission will be forced to end if neither of all charcters or all evidenced have been reported/secured
 * Setting this property to zero disables this feature
 */
var config int MissionEndTime;

/**
 * Indicate whether spectators should be excluded from procedure score table
 */
var config bool IgnoreSpectators;


public function BeginPlay()
{
    Super.BeginPlay();

    if (!Core.Server.IsCOOP())
    {
        log(self $ " refused to operate on a non-COOP server");
        Destroy();
        return;
    }

    SwatGameInfo(Level.Game).GameEvents.PawnDied.Register(self);

    Core.RegisterInterestedInEventBroadcast(self);
    Core.RegisterInterestedInInternalEventBroadcast(self);
    Core.RegisterInterestedInMissionEnded(self);
}

event Timer()
{
    if (MissionEndTime > 0)
    {
        CheckMissionAbortTime();
    }
}

/**
 * Attempt to register a player who has just joined spectator mode
 */
public function OnPawnDied(Pawn Pawn, Actor Killer, bool WasAThreat)
{
    if (!Pawn.IsA('SwatPlayer') || !IgnoreSpectators || !class'Utils'.static.IsAMEnabled(Level))
    {
        return;
    }

    if (IsSpectatorName(Pawn.GetHumanReadableName()))
    {
        AddSpectator(Pawn);
    }
}

public function bool OnEventBroadcast(Player Player, Actor Sender, name Type, string Msg, optional PlayerController Receiver, optional bool bHidden)
{
    switch (Type)
    {
        case 'MissionCompleted' :
        case 'MissionFailed' :
            bMissionCompleted = true;
            break;
    }
    return true;
}

/**
 * Display incap/kill messages in chat
 */
public function OnInternalEventBroadcast(name Type, optional string Msg, optional Player PlayerOne, optional Player PlayerTwo)
{
    local string Color, Message;

    // Overwrite for suspects
    Color = COLOR_BLUE;

    switch (Type)
    {
        case 'EnemyHostageIncap' :
            Message = Locale.Translate("EventSuspectsIncapHostage");
            Color = COLOR_RED;
            break;
        case 'EnemyHostageKill' :
            Message = Locale.Translate("EventSuspectsKillHostage");
            Color = COLOR_RED;
            break;
        case 'EnemyPlayerKill' :
            Message = Locale.Translate("EventSuspectsIncapOfficer");
            Color = COLOR_RED;
            break;
        case 'PlayerHostageIncap' :
            Message = Locale.Translate("EventSwatIncapHostage");
            break;
        case 'PlayerHostageKill' :
            Message = Locale.Translate("EventSwatKillHostage");
            break;
        case 'PlayerEnemyIncap' :
            Message = Locale.Translate("EventSwatIncapSuspect");
            break;
        case 'PlayerEnemyIncapInvalid' :
            Message = Locale.Translate("EventSwatIncapInvalidSuspect");
            break;
        case 'PlayerEnemyKill' :
            Message = Locale.Translate("EventSwatKillSuspect");
            break;
        case 'PlayerEnemyKillInvalid' :
            Message = Locale.Translate("EventSwatKillInvalidSuspect");
            break;
        default :
            return;
    }

    if (PlayerOne != None)
    {
        Message = class'Utils.StringUtils'.static.Format(Message, PlayerOne.GetName());
    }

    class'Utils.LevelUtils'.static.TellAll(Level, Message, Color);
}

public function OnMissionEnded()
{
    if (IgnoreSpectators)
    {
        DeductSpectatorPoints();
    }
}

/**
 * Attempt to autocomplete the current mission if all of its objectives have been completed
 */
protected function CheckMissionAbortTime()
{
    local int TimeRemaining;

    // The game is paused/ has been completed/ has not started yet
    if (Core.Server.GetGameState() != GAMESTATE_MidGame || !SwatRepo(Level.GetRepo()).AnyPlayersOnServer())
    {
        return;
    }

    // Timer is not active, attempt to activate it
    if (MissionAbortTime <= 0)
    {
        if (bMissionCompleted && AllObjectivesCompleted())
        {
            if (!AllProceduresCompleted())
            {
                log(self $ ": setting up mission abort timer");

                class'Utils.LevelUtils'.static.TellAll(
                    Level, Locale.Translate("MissionEndMessage", MissionEndTime/60, MissionEndTime),
                );
                MissionAbortTime = Level.TimeSeconds + MissionEndTime;
            }
            // Don't do the same check again
            bMissionCompleted = false;
        }
    }
    // All procedures have been completed, abort timer
    else if (AllProceduresCompleted())
    {
        log(self $ ": all procedures have been completed, aborting the timer");
        MissionAbortTime = 0;
    }
    // Time's up - abort game
    else if (MissionAbortTime <= Level.TimeSeconds)
    {
        log(self $ ": mission end time is up");
        SwatGameInfo(Level.Game).GameAbort();
        MissionAbortTime = 0;
    }
    // Attempt to display One Minute/Ten Seconds warnings
    else
    {
        TimeRemaining = int(MissionAbortTime - Level.TimeSeconds);

        if (TimeRemaining <= 10 && !bMissionEndTenSecWarning)
        {
            Level.Game.Broadcast(None, "", 'TenSecWarning');
            bMissionEndTenSecWarning = true;
        }
        else if (TimeRemaining <= 60 && !bMissionEndOneMinWarning)
        {
            Level.Game.Broadcast(None, "", 'OneMinWarning');
            bMissionEndOneMinWarning = true;
        }
    }
}

/**
 * Tell whether all COOP objectives have been completed
 */
protected function bool AllObjectivesCompleted()
{
    local int i;
    local ObjectiveStatus Status;
    local MissionObjectives Objectives;

    Objectives = SwatRepo(Level.GetRepo()).MissionObjectives;

    for (i = 0; i < Objectives.Objectives.Length; i++)
    {
        Status = SwatGameReplicationInfo(Level.Game.GameReplicationInfo).ObjectiveStatus[i];

        if (Objectives.Objectives[i].name == 'Automatic_DoNot_Die')
        {
            if (Status == ObjectiveStatus_Failed)
            {
                return false;
            }
        }
        else if (Status == ObjectiveStatus_InProgress)
        {
            return false;
        }
    }
    return true;
}

/**
 * Tell whether all procedures have been completed
 */
protected function bool AllProceduresCompleted()
{
    return SwatRepo(Level.GetRepo()).Procedures.ProceduresMaxed();
}

/**
 * Attempt to deduct NoOfficersDown penalty points for players who have joined spectator mode
 */
protected function DeductSpectatorPoints()
{
    local int i, j;
    local Procedures Procedures;
    local Procedure_NoOfficersDown Procedure;

    Procedures = SwatRepo(Level.GetRepo()).Procedures;

    for (i = 0; i < Procedures.Procedures.Length; i++)
    {
        if (Procedures.Procedures[i].class.name == 'Procedure_NoOfficersDown')
        {
            Procedure = Procedure_NoOfficersDown(Procedures.Procedures[i]);

            log(self $ ": number of DownedOfficers/Spectators - " $ Procedure.DownedOfficers.Length $ "/" $ Spectators.Length);

            while (Spectators.Length > 0)
            {
                for (j = 0; j < Procedure.DownedOfficers.Length; j++)
                {
                    if (Procedure.DownedOfficers[j] == SwatPawn(Spectators[0]))
                    {
                        log(self $ ": removing " $ Spectators[0] $ "/" $ SwatPawn(Spectators[0]) $ ") from DownedOfficers");
                        Procedure.DownedOfficers.Remove(j, 1);
                        break;
                    }
                }
                Spectators.Remove(0, 1);
            }
            break;
        }
    }
}

protected function AddSpectator(Pawn Pawn)
{
    local int i;

    for (i = 0; i < Spectators.Length; i++)
    {
        if (Spectators[i] == Pawn)
        {
            return;
        }
    }
    log(self $ ": adding " $ Pawn $ " (" $ Pawn.GetHumanReadableName() $ ") to the spectator list");
    Spectators[Spectators.Length] = Pawn;
}

/**
 * Tell whether given name contains (SPEC) or (VIEW) suffix
 */
static function bool IsSpectatorName(string Name)
{
    switch (Right(Name, 6))
    {
        case "(SPEC)":
        case "(VIEW)":
            return true;
    }
    return false;
}

event Destroyed()
{
    SwatGameInfo(Level.Game).GameEvents.PawnDied.UnRegister(self);

    if (Core != None)
    {
        Core.UnregisterInterestedInEventBroadcast(self);
        Core.UnregisterInterestedInInternalEventBroadcast(self);
        Core.UnregisterInterestedInMissionEnded(self);
    }

    while (Spectators.Length > 0)
    {
        Spectators[0] = None;
        Spectators.Remove(0, 1);
    }

    Super.Destroyed();
}

defaultproperties
{
    Title="Julia/COOP";
    LocaleClass=class'COOPLocale';
}
