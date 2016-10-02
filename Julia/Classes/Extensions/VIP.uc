class VIP extends Extension
 implements IInterested_GameEvent_PawnArrested,
            InterestedInMissionStarted,
            InterestedInPlayerVIPSet;

var int ExtraRoundTimeCount;

/**
 * Extra round time added in case the VIP is arrested in the last 120 seconds
 * Setting the property to zero disabled this feature
 */
var config float ExtraRoundTime;

/**
 * Limit the maximum number of extra time additions within a round
 */
var config int ExtraRoundTimeLimit;

/**
 * Space separated vip custom health levels
 */
var config string VIPCustomHealth;


public function BeginPlay()
{
    Super.BeginPlay();

    if (Core.Server.GetGameType() != MPM_VIPEscort)
    {
        log(self $ ": refused to operate on a non-VIP server");
        Destroy();
        return;
    }

    SwatGameInfo(Level.Game).GameEvents.PawnArrested.Register(self);
    Core.RegisterInterestedInMissionStarted(self);
    Core.RegisterInterestedInPlayerVIPSet(self);
}

public function OnPawnArrested(Pawn Pawn, Pawn Arrester)
{
    local Player Arrestee;

    if (!Pawn.IsA('SwatPlayer'))
    {
        return;
    }

    Arrestee = Core.Server.GetPlayerByPawn(Pawn);

    if (Arrestee == None)
    {
        return;
    }

    // If the arrested player is the VIP, attempt to add extra time
    if (Arrestee.IsVIP())
    {
        AddExtraRoundTime();
    }
}

public function OnPlayerVIPSet(Player Player)
{
    SetVIPCustomHealth(Player);
}

public function OnMissionStarted()
{
    ExtraRoundTimeCount = 0;
}

protected function AddExtraRoundTime()
{
    // The feature is disabled
    if (ExtraRoundTimeLimit <= 0 || ExtraRoundTime < 120)
    {
        log(self $ ": extra time is disabled");
        return;
    }
    // Check whether extra time is needed at all
    if (
        SwatGameReplicationInfo(Level.Game.GameReplicationInfo).RoundTime > 120 ||
        SwatGameReplicationInfo(Level.Game.GameReplicationInfo).RoundTime <= 1  ||
        SwatGameReplicationInfo(Level.Game.GameReplicationInfo).ServerCountdownTime <= 1
    )
    {
        return;
    }
    // Extra time addition count has exceeded the limit
    if (ExtraRoundTimeCount >= ExtraRoundTimeLimit)
    {
        log(self $ ": reached extra time limit");
        return;
    }

    SwatGameReplicationInfo(Level.Game.GameReplicationInfo).ServerCountdownTime += ExtraRoundTime;
    ExtraRoundTimeCount++;
    
    class'Utils.LevelUtils'.static.TellAll(
        Level,
        Locale.Translate("ExtraRoundTimeAdded", int(ExtraRoundTime)),
        Locale.Translate("MessageColor")
    );
}

protected function SetVIPCustomHealth(Player Player)
{
    local int i;
    local int NewHealth;
    local array<string> CustomLevels;

    if (!Player.IsVIP())
    {
        return;
    }

    // Attempt to get a list of space separated health levels
    CustomLevels = class'Utils.StringUtils'.static.Part(VIPCustomHealth, " ");

    // Remove non-digit values
    for (i = CustomLevels.Length-1; i >= 0; i--)
    {
        if (!class'Utils.StringUtils'.static.IsDigit(CustomLevels[i]))
        {
            CustomLevels.Remove(i, 1);
        }
    }
    // Get the only available value
    if (CustomLevels.Length == 1)
    {
        NewHealth = int(CustomLevels[0]);
    }
    // Pick a random one
    else if (CustomLevels.Length > 1)
    {
        NewHealth = int(class'Utils.ArrayUtils'.static.Random(CustomLevels));
    }
    else
    {
        return;
    }

    if (NewHealth > 0 && NewHealth != 100)
    {
        log(self $ ": setting VIP custom health: " $ NewHealth);

        Player.PC.Pawn.Health = NewHealth;
    }
}

event Destroyed()
{
    if (Core != None)
    {
        Core.UnregisterInterestedInMissionStarted(self);
        Core.UnregisterInterestedInPlayerVIPSet(self);
    }

    SwatGameInfo(Level.Game).GameEvents.PawnArrested.UnRegister(self);

    Super.Destroyed();
}

defaultproperties
{
    Title="Julia/VIP";
    LocaleClass=class'VIPLocale';

    VIPCustomHealth="100";
    ExtraRoundTime=0.0;
    ExtraRoundTimeLimit=0;
}
