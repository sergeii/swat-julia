class Admin extends Extension
  implements InterestedInEventBroadcast,
             InterestedInInternalEventBroadcast,
             InterestedInMissionEnded,
             InterestedInPlayerNameChanged,
             InterestedInPlayerTeamSwitched,
             InterestedInPlayerAdminLogged,
             InterestedInPlayerDisconnected,
             InterestedInPlayerVoiceChanged,
             InterestedInCommandDispatched;

import enum eVoiceType from SwatGame.SwatGUIConfig;

const CACHE_AUTH_KEY = "auth";
const CACHE_AUTH_DELIMITER = ";";


struct sFriendlyFireRule
{
    /**
     * A list of comma separated weapon friendly names (9mm SMG, Taser Stun Gun)
     */
    var string Weapons;

    /**
     * Admin action (kick, kickban, etc)
     */
    var string Action;

    /**
     * The number of friendly hits required for the action to be taken of
     */
    var int ActionLimit;

    /**
     * Indicate whether admins should be notified
     */
    var bool Alert;

    /**
     * Indicate whether admins should also be ignored
     */
    var bool IgnoreAdmins;

    /**
     * List of parsed comma separated Weapons
     */
    var array<string> Parsed;
};

struct sInstantAction
{
    /**
     * Punished player
     */
    var Player Player;

    /**
     * Punishment type (AutoBalance, DisallowWords, etc)
     */
    var string Type;

    /**
     * The action that has been taken upon the player (forcelesslethal, forcemute, etc)
     */
    var string Action;

    /**
     * Current violation count
     */
    var int Count;

    /**
     * The original action limit that had been required for the action to be taken (0 - disabled)
     */
    var int Limit;
};

struct sDelayedAction
{
    /**
     * Punished player
     */
    var Player Player;

    /**
     * Punishment type
     */
    var string Type;

    /**
     * Admin action (kick, kickban, etc)
     */
    var string Action;

    /**
     * Time the action will be issued at (Level.TimeSeconds)
     */
    var float Time;

    /**
     * Time between warnings (seconds)
     */
    var float WarningInterval;

    /**
     * Time the player was last warned at (Level.TimeSeconds)
     */
    var float LatestWarningTime;

    /**
     * Message shown to the player every ActionWarningInterval seconds
     */
    var string WarningMessage;

    /**
     * Message shown to admins upon taking the action
     */
    var string ActionMessage;
};

struct sProtectedName
{
    /**
     * Wildcard friendly name, such as |MYT|*
     */
    var string Name;

    /**
     * Password required to use the protected name
     */
    var string Password;
};

/**
 * List of players, sorted in the order of their team switching
 */
var array<Player> BalanceList;

/**
 * List of actions that should be issued upon reaching their respective action limits
 */
var array<sInstantAction> InstantActions;

/**
 * List of delayed admin actions that should be issued upon reaching their execution time
 */
var array<sDelayedAction> DelayedActions;

/**
 * List of parsed protected name=password structs
 */
var array<sProtectedName> ProtectedNames;

/**
 * Indicate whether an auto balance is required in favor of the specified team
 * 0 = swat, 1 = suspects, -1 = not required
 * @type int
 */
var int AutoBalanceRequired;

/**
 * Indicate whether the `Teams will be balanced in AutoBalanceTime/2 seconds` message has been shown
 */
var bool bAutoBalanceHalfTime;

/**
 * Time untill the next autobalancing
 */
var float AutoBalanceCounter;

/**
 * Indicate whether the autobalance feature is enabled
 */
var config bool AutoBalance;

/**
 * Time required to perform auto balancing
 */
var config int AutoBalanceTime;

/**
 * Do not commence autobalance if admins are present on a server
 */
var config bool AutoBalanceAdminPresent;

/**
 * An action (adminmod command) taken upon an unbalancer that has reached the action limit
 */
var config string AutoBalanceAction;

/**
 * Number of unbalances required for the action to be taken (0 - disabled)
 */
var config int AutoBalanceActionLimit;

/**
 * List of wildcard friendly disallowed names
 */
var config array<string> DisallowNames;

/**
 * Admin action that should taken against a player using a name the DisallowNames list
 */
var config string DisallowNamesAction;

/**
 * Time required for the action above to be taken
 */
var config int DisallowNamesActionTime;

/**
 * Number of warnings to be display before taking the action
 */
var config int DisallowNamesActionWarnings;

/**
 * A list of "name password" pairs with the password required to use the assotiated name
 */
var config array<string> ProtectNames;

/**
 * Indicate whether admins should be allowed to use protected names without password authentication
 */
var config bool ProtectNamesIgnoreAdmins;

/**
 * Action to take against an unauthenticated player
 */
var config string ProtectNamesAction;

/**
 * Time required for the action to be taken against an unauthenticated player
 */
var config int ProtectNamesActionTime;

/**
 * Number of warnings to display
 */
var config int ProtectNamesActionWarnings;

/**
 * List of pattern friendly words that should not be allowed for players to use
 */
var config array<string> DisallowWords;

/**
 * An AMMod admin action (such as forcemute or kick) that is taken upon a player using disallowed words
 */
var config string DisallowWordsAction;

/**
 * Number of times player's messages get filtered before the action is taken (0-disabled)
 */
var config int DisallowWordsActionLimit;

/**
 * Indicate whether admins should be immune to the DisallowWords filter
 */
var config bool DisallowWordsIgnoreAdmins;

/**
 * Indicate whether admins should see original messages that have been filtered out
 */
var config bool DisallowWordsAlertAdmins;

/**
 * Dont allow players to use VIP voice
 */
var config bool DisallowVIPVoice;

/**
 * Indicate whether text decoration codes in player messages should be filtered out
 */
var config bool FilterText;

/**
 * Indicate whether admins should be allowed to use text codes
 */
var config bool FilterTextIgnoreAdmins;

/**
 * List of friendly fire rules
 */
var config array<sFriendlyFireRule> FriendlyFire;


public function PreBeginPlay()
{
    Super.PreBeginPlay();
    AutoBalanceRequired = -1;
}

public function BeginPlay()
{
    Super.BeginPlay();

    ParseProtectedNames();

    Core.RegisterInterestedInEventBroadcast(self);
    Core.RegisterInterestedInInternalEventBroadcast(self);
    Core.RegisterInterestedInMissionEnded(self);
    Core.RegisterInterestedInPlayerNameChanged(self);
    Core.RegisterInterestedInPlayerTeamSwitched(self);
    Core.RegisterInterestedInPlayerAdminLogged(self);
    Core.RegisterInterestedInPlayerDisconnected(self);
    Core.RegisterInterestedInPlayerVoiceChanged(self);

    Core.Dispatcher.Bind(
        "auth", self, Locale.Translate("AuthCommandUsage"), Locale.Translate("AuthCommandDescription"), true
    );
}

event Timer()
{
    CheckAutoBalance();
    CheckDelayedActions();
}

/**
 * Drop all issued admins actions upon a round end
 */
public function OnMissionEnded()
{
    DropIssuedActions();
}

/**
 * Add a player to the balance list upon a change of team
 * This does also handle connected players
 */
public function OnPlayerTeamSwitched(Player Player)
{
    AddToBalanceList(Player);
}

/**
 * Display a welcome message to a logged in admin
 * Also attempt to drop queued delayed admin actions if they have been set to ignore admins
 */
public function OnPlayerAdminLogged(Player Player)
{
    CheckProtectedName(Player);
    GreetAdmin(Player);

    // Let other admins see the log in
    class'Utils.LevelUtils'.static.TellAdmins(
        Level,
        Locale.Translate("AdminLoginMessage", Player.GetName(), Player.IpAddr),
        Player.PC
    );
}

/**
 * Get rid of references to a disconnected player upon their leaving
 */
public function OnPlayerDisconnected(Player Player)
{
    DropAllActions(Player);
    RemoveFromBalanceList(Player);
}

/**
 * Check Say and TeamSay event messages through text filters
 */
public function bool OnEventBroadcast(Player Player, Actor Sender, name Type, out string Msg, optional PlayerController Receiver, optional bool bHidden)
{
    if (!bHidden)
    {
        if (Player != None && (Type == 'Say' || Type == 'TeamSay'))
        {
            // Dont allow unauthenticated players to talk
            if (MatchDelayedAction(Player, "ProtectNames"))
            {
                class'Utils.LevelUtils'.static.TellPlayer(
                    Level, Locale.Translate("ProtectNamesNoChatMessage"), Player.PC
                );
                return false;
            }
            // Filter the [b] [u] [c=xxxxxx] codes
            if (FilterText && (!Player.IsAdmin() || !FilterTextIgnoreAdmins))
            {
                Msg = class'Utils.StringUtils'.static.Filter(Msg);
            }
            // Dont allow empty messages
            if (Msg == "")
            {
                return false;
            }
            // Check whether the message contains a word from the DisallowWords list
            return CheckDisallowedWord(Msg, Player);
        }
    }
    return true;
}

public function OnInternalEventBroadcast(name Type, optional string Msg, optional Player PlayerOne, optional Player PlayerTwo)
{
    if (Type == 'PlayerTeamHit')
    {
        PunishTeamKiller(PlayerOne, PlayerTwo, Msg);
    }
}

/**
 * Dont let players other than the VIP to use VIP voice
 */
public function OnPlayerVoiceChanged(Player Player)
{
    if (DisallowVIPVoice && !Player.IsVIP())
    {
        if (Player.GetVoiceType() == VOICETYPE_VIP)
        {
            Player.SetVoiceType(VOICETYPE_Lead);
            log(self $ " forced " $ Player.GetName() $ " to use " $ GetEnum(eVoiceType, Player.GetVoiceType()));
        }
    }
}

/**
 * Check the new player name against filters
 */
public function OnPlayerNameChanged(Player Player, string OldName)
{
    CheckProtectedName(Player);
    CheckDisallowedName(Player);
}

/**
 * Attempt to authenticate a player
 */
public function OnCommandDispatched(Dispatcher Dispatcher, string Name, string Id, array<string> Args, Player Player)
{
    local sProtectedName Protected;

    if (Name == "auth")
    {
        if (Args.Length == 0)
        {
            Dispatcher.ThrowUsageError(Id);
            return;
        }

        if (MatchProtectedName(Player.GetName(), Protected))
        {
            if (!IsPlayerAuthenticated(Player, Protected))
            {
                if (Args[0] == Protected.Password)
                {
                    AuthenticatePlayer(Player, Protected);
                    Dispatcher.Respond(Id, Locale.Translate("ProtectNamesResponseAccepted"));
                }
                else
                {
                    Dispatcher.Respond(Id, Locale.Translate("ProtectNamesResponseRejected"));
                }
                return;
            }
        }
        Dispatcher.ThrowError(Id, Locale.Translate("ProtectNamesResponseInvalid"));
    }
}

/**
 * Show an admin welcome message to a player
 */
protected function GreetAdmin(Player Player)
{
    local Player TestAdmin;
    local int i;
    local array<string> AdminNames;
    local string Message;

    // Display "Welcome to Duty"
    class'Utils.LevelUtils'.static.TellPlayer(
        Level,
        Locale.Translate("AdminWelcomeMessage", Player.GetName()),
        Player.PC
    );

    for (i = Core.Server.Players.Length-1; i >= 0; i--)
    {
        TestAdmin = Core.Server.Players[i];
        if (TestAdmin.PC != None && TestAdmin.IsAdmin() && TestAdmin != Player)
        {
            AdminNames[AdminNames.Length] = TestAdmin.GetName();
        }
    }
    if (AdminNames.Length == 0)
    {
        Message = Locale.Translate("AdminWelcomeListNone");
    }
    else if (AdminNames.Length == 1)
    {
        Message = Locale.Translate("AdminWelcomeListOne");
    }
    else
    {
        Message = Locale.Translate("AdminWelcomeListMany");
    }
    // Display them
    class'Utils.LevelUtils'.static.TellPlayer(
        Level,
        class'Utils.StringUtils'.static.Format(
            Message, class'Utils.ArrayUtils'.static.Join(AdminNames, ", "), AdminNames.Length
        ),
        Player.PC
    );
}

/**
 * Check whether autobalance is required
 */
protected function CheckAutoBalance()
{
    local Player Player;

    // Nothing to balance
    if (AutoBalanceRequired == -1)
    {
        return;
    }
     // Wait for the game to start or the feature to be enabled ingame
    else if (Core.Server.GetGameState() != GAMESTATE_MidGame || !AutoBalance)
    {
        return;
    }
    // Time's up
    if (AutoBalanceCounter >= AutoBalanceTime)
    {
        // Get the last switched/joined player from the opposing team
        Player = GetLastJoinedPlayer(int(!bool(AutoBalanceRequired)));
        // Switch one player per tick to keep the BalanceList array up-to-date
        SwatGameInfo(Level.Game).ChangePlayerTeam(SwatGamePlayerController(Player.PC));

        class'Utils.LevelUtils'.static.TellAll(
            Level,
            Locale.Translate("AutoBalanceMessage", Locale.Translate("ServerString"), Player.GetName()),
            Locale.Translate("ActionColor")
        );
        // Punish the unbalancer
        IssueInstantAction(
            Player,
            "AutoBalance",
            AutoBalanceAction,
            AutoBalanceActionLimit,
            Locale.Translate("AutoBalancePunishMessage")
        );
        // Wait for further instructions
        AutoBalanceRequired = -1;

        return;
    }
    // Keep deducting time
    AutoBalanceCounter += class'Core'.const.DELTA;
    // Attempt to show the 'Teams will be balanced in %n seconds' message
    if (!bAutoBalanceHalfTime && AutoBalanceCounter >= AutoBalanceTime / 2)
    {
        class'Utils.LevelUtils'.static.TellAll(
            Level,
            Locale.Translate("AutoBalanceWarning", AutoBalanceTime / 2),
            Locale.Translate("MessageColor")
        );
        bAutoBalanceHalfTime = true;
    }
}

/**
 * Add a player to the balance list
 */
protected function AddToBalanceList(Player Player)
{
    RemoveFromBalanceList(Player, true);
    BalanceList[BalanceList.Length] = Player;
    // Check whether the teams have just been unbalanced
    CheckTeams();
}

/**
 * Remove a player from the balance list
 *
 * @param   Player
 * @param   bSkipCheck (optional)
 *          Indicate whether this is an intermediate action and no further balance check should be taken
 */
protected function RemoveFromBalanceList(Player Player, optional bool bSkipCheck)
{
    local int i;

    for (i = BalanceList.Length-1; i >= 0; i--)
    {
        if (BalanceList[i] == Player)
        {
            BalanceList.Remove(i, 1);
        }
    }
    if (!bSkipCheck)
    {
        CheckTeams();
    }
}

/**
 * Check whether teams have been unbalanced and attempt to queue an autobalance action
 */
protected function CheckTeams()
{
    local int SufferingTeam;

    if (Core.Server.IsCOOP())
    {
        return;
    }

    // Skip teams check if there are admins on the server
    if (
        (AutoBalanceAdminPresent || !class'Utils'.static.AnyAdminsOnServer(Level)) &&
        !AreTeamsBalanced(SufferingTeam)
    )
    {
        AutoBalanceRequired = SufferingTeam;
    }
    // Reset the counter
    else
    {
        AutoBalanceCounter = 0;
        AutoBalanceRequired = -1;
        bAutoBalanceHalfTime = false;
    }
}

/**
 * Tell whether the teams are balanced
 */
protected function bool AreTeamsBalanced(out int SufferingTeam)
{
    local int i, Diff;
    local int Team[2];

    // The balance list is beleieved to be an up-to-date list of online players
    for (i = 0; i < BalanceList.Length; i++)
    {
        Team[BalanceList[i].GetTeam()]++;
    }

    Diff = Abs(Team[0]-Team[1]);
    // Check the difference
    if (Diff > 0)
    {
        SufferingTeam = int(Team[0] > Team[1]);
        // Check whether the difference is greater than 1 player
        // unless its VIP Escort and the swat team has only 1 or less players
        if (Diff > 1 || Core.Server.GetGameType() == MPM_VIPEscort && SufferingTeam == 0 && Team[0] <= 1)
        {
            return false;
        }
    }

    SufferingTeam = -1;

    return true;
}

/**
 * Return the player (other than VIP) that has joined given team last
 */
protected function Player GetLastJoinedPlayer(int Team)
{
    local int i;

    for (i = BalanceList.Length-1; i >= 0; i--)
    {
        // Dont mess with the VIP
        if (!BalanceList[i].IsVIP() && BalanceList[i].LastTeam == Team) // dont do GetTeam()
        {
            return BalanceList[i];
        }
    }
    return None;
}

/**
 * Check whether Message is free from the words defined in DisallowWords
 */
public function bool CheckDisallowedWord(string Message, Player Player)
{
    local int i, j;
    local array<string> Words;
    local string PunctChars, NormalizedMessage;

    if (DisallowWordsIgnoreAdmins && Player.IsAdmin())
    {
        // allow admins to use disallowed words
        return true;
    }

    PunctChars = "'!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~'";
    // Clear the message from text codes
    NormalizedMessage = class'Utils.StringUtils'.static.Filter(Message);
    // Remove the punctuation characters from the test message
    for (i = 0; i < Len(PunctChars); i++)
    {
        NormalizedMessage = class'Utils.StringUtils'.static.Replace(NormalizedMessage, Mid(PunctChars, i, 1), "");
    }

    Words = class'Utils.StringUtils'.static.SplitWords(NormalizedMessage);

    for (i = 0; i < DisallowWords.Length; i++)
    {
        for (j = 0; j < Words.Length; j++)
        {
            if (class'Utils.StringUtils'.static.Match(Words[j], DisallowWords[i]))
            {
                // Display a warning
                class'Utils.LevelUtils'.static.TellPlayer(
                    Level,
                    Locale.Translate("DisallowWordsWarningMessage"),
                    Player.PC
                );
                // Let admins see the original message
                if (DisallowWordsAlertAdmins)
                {
                    class'Utils.LevelUtils'.static.TellAdmins(
                        Level,
                        Locale.Translate("DisallowWordsAdminMessage", Player.GetName(), Message),
                        Player.PC  // dont display this message to the player
                    );
                }
                // Attempt to punish the player
                IssueInstantAction(
                    Player,
                    "DisallowWords",
                    DisallowWordsAction,
                    DisallowWordsActionLimit,
                    Locale.Translate("DisallowWordsPunishMessage")
                );
                return false;
            }
        }
    }
    return true;
}

/**
 * Attempt to issue a delayed action if Player is using a disallowed nickname
 */
protected function CheckDisallowedName(Player Player)
{
    local int i;
    local string Name;

    Name = class'Utils.StringUtils'.static.Filter(Player.GetName());

    for (i = 0; i < DisallowNames.Length; i++)
    {
        if (class'Utils.StringUtils'.static.Match(Name, DisallowNames[i]))
        {
            IssueDelayedAction(
                Player,
                "DisallowNames",
                DisallowNamesAction,
                DisallowNamesActionTime,
                DisallowNamesActionWarnings,
                Locale.Translate("DisallowNamesWarningMessage"),
                Locale.Translate("DisallowNamesPunishMessage")
            );
            return;
        }
    }
    // Attempt to drop a delayed action if the player had used a disallowed name
    DropDelayedAction(Player, "DisallowNames");
}

/**
 * Attempt to queue a delayed action if a player
 * has not authenticated themself to use the protected nickname
 */
protected function CheckProtectedName(Player Player)
{
    local sProtectedName Protected;
    local string Name;

    Name = class'Utils.StringUtils'.static.Filter(Player.GetName());

    // Get the matching protected name
    if (MatchProtectedName(Name, Protected))
    {
        if (!IsPlayerAuthenticated(Player, Protected))
        {
            // Authenticate admins automatically
            if (Player.IsAdmin() && ProtectNamesIgnoreAdmins)
            {
                log(self $ ": succeffully authorized admin " $ Name $ " to use " $ Protected.Name);
                AuthenticatePlayer(Player, Protected);
            }
            else
            {
                IssueDelayedAction(
                    Player,
                    "ProtectNames",
                    ProtectNamesAction,
                    ProtectNamesActionTime,
                    ProtectNamesActionWarnings,
                    Locale.Translate("ProtectNamesWarningMessage"),
                    Locale.Translate("ProtectNamesPunishMessage")
                );
            }
            return;
        }
    }
    // Drop a queued action in case the player's previous name was a protected one
    DropDelayedAction(Player, "ProtectNames");
}

/**
 * Tell whether given name matches a protected name
 */
protected function bool MatchProtectedName(string TestName, out sProtectedName ProtectedName)
{
    local int i;

    for (i = 0; i < ProtectedNames.Length; i++)
    {
        if (class'Utils.StringUtils'.static.Match(TestName, ProtectedNames[i].Name))
        {
            ProtectedName = ProtectedNames[i];
            return true;
        }
    }
    return false;
}

/**
 * Tell whether Player has authenticated themself to use ProtectedName
 */
protected function bool IsPlayerAuthenticated(Player Player, sProtectedName ProtectedName)
{
    local int i;
    local array<string> Cached;

    log(self $ ": trying to authorize " $ Player.GetName() $ " to use " $ ProtectedName.Name);

    Cached = Core.Cache.GetArray(CACHE_AUTH_KEY);

    for (i = 0; i < Cached.Length; i++)
    {
        if (Cached[i] == (ProtectedName.Name $ CACHE_AUTH_DELIMITER $ Player.IpAddr))
        {
            log(self $ ": found a " $ Cached[i] $ " entry matching " $ Player.GetName());
            return true;
        }
    }
    log(self $ ": failed to authenticate " $ Player.GetName());
    return false;
}

/**
 * Authenticate a player to use a protected name
 */
protected function AuthenticatePlayer(Player Player, sProtectedName ProtectedName)
{
    Core.Cache.Append(CACHE_AUTH_KEY,
                      ProtectedName.Name $ CACHE_AUTH_DELIMITER $ Player.IpAddr);
    // Also drop queued actions
    DropDelayedAction(Player, "ProtectNames");
}

/**
 * Populate the ProtectedNames array with parsed name=password pairs
 */
protected function ParseProtectedNames()
{
    local int i;
    local sProtectedName NewEntry;
    local array<string> Pair;

    for (i = 0; i < ProtectNames.Length; i++)
    {
        Pair = class'Utils.StringUtils'.static.SplitWords(ProtectNames[i]);

        if (Pair.Length != 2)
        {
            log(self $ " failed to parse a protected name: " $ ProtectNames[i]);
            continue;
        }

        NewEntry.Name = Pair[0];
        NewEntry.Password = Pair[1];

        ProtectedNames[ProtectedNames.Length] = NewEntry;
    }
}

/**
 * Attempt to punish Killer for friendly fire.
 * Additionally attempt to display the hit message to admins
 */
protected function PunishTeamKiller(Player Killer, Player Victim, string Weapon)
{
    local sFriendlyFireRule Rule;
    local string Message, Type;

    if (Weapon == "")
    {
        Weapon = "None";
        Message = Locale.Translate("FriendlyFireNoWeaponMessage");
    }
    else
    {
        Message = Locale.Translate("FriendlyFireMessage");
    }
    // Check if there is an appropriate ff rule for this weapon
    if (MatchFriendlyFireRule(Weapon, Rule))
    {
        // See if admins are ignored
        if (Killer.IsAdmin() && Rule.IgnoreAdmins)
        {
            return;
        }
        // Alert admins
        if (Rule.Alert)
        {
            class'Utils.LevelUtils'.static.TellAdmins(
                Level,
                class'Utils.StringUtils'.static.Format(
                    Message,
                    class'Utils'.static.GetTeamColoredName(Killer.GetName(), Killer.GetTeam(), Killer.IsVIP()),
                    class'Utils'.static.GetTeamColoredName(Victim.GetName(), Victim.GetTeam(), Victim.IsVIP()),
                    Weapon
                ),
                Killer.PC
            );
        }
        // Attempt to punish the player
        if (Rule.Action != "" && Rule.ActionLimit > 0)
        {
            if (GetPlayerTeamHits(Killer, Rule.Parsed) == Rule.ActionLimit)
            {
                // Each set of weapons yields its own punishment type
                Type = "FriendlyFire_" $ Left(ComputeMD5Checksum(Rule.Weapons), 6);
                IssueInstantAction(Killer, Type, Rule.Action, 1, Locale.Translate("FriendlyFirePunishMessage"));
            }
        }
    }
}

/**
 * Find the first FriendlyFire struct matching given weapon name
 */
protected function bool MatchFriendlyFireRule(string WeaponName, out sFriendlyFireRule Rule)
{
    local int i, j;

    if (WeaponName != "")
    {
        for (i = 0; i < FriendlyFire.Length; i++)
        {
            // Parse comma separated list of weapons
            if (FriendlyFire[i].Parsed.Length == 0)
            {
                FriendlyFire[i].Parsed = class'Utils.StringUtils'.static.SplitWords(FriendlyFire[i].Weapons, ",");
            }

            for (j = 0; j < FriendlyFire[i].Parsed.Length; j++)
            {
                if (Caps(WeaponName) == Caps(FriendlyFire[i].Parsed[j]))
                {
                    Rule = FriendlyFire[i];
                    return true;
                }
            }
        }
    }
    return false;
}

/**
 * Attempt to issue an instant action against a player
 */
protected function IssueInstantAction(Player Player, string Type, string Action, int ActionLimit, optional string ActionMessage)
{
    local int i;
    local int ActionIndex;
    local sInstantAction NewEntry;

    Action = class'Utils.StringUtils'.static.Strip(Action);

    if (Action == "" || Action ~= "none" || ActionLimit <= 0)
    {
        return;
    }

    ActionIndex = -1;
    // Attempt to find an existing open action
    for (i = 0; i < InstantActions.Length; i++)
    {
        if (InstantActions[i].Player == Player)
        {
            // The same action has already been taken
            if (InstantActions[i].Count >= InstantActions[i].Limit)
            {
                if (InstantActions[i].Action ~= Action)
                {
                    log(self $ ": " $ Player.GetName() $ " has already been punished with " $ Action);
                    return;
                }
            }
            else if (InstantActions[i].Type == Type)
            {
                ActionIndex = i;
            }
        }
    }
    if (ActionIndex == -1)
    {
        log(self $ ": setting up a new " $ Type $ " punishment");

        NewEntry.Player = Player;
        NewEntry.Action = Action;
        NewEntry.Type = Type;
        NewEntry.Limit = ActionLimit;

        ActionIndex = InstantActions.Length;
        InstantActions[ActionIndex] = NewEntry;
    }
    // Check if the player has reached the action limit
    if (++InstantActions[ActionIndex].Count == ActionLimit)
    {
        log(self $ ": issuing " $ Action $ " action against " $ Player.GetName());
        IssueAdminCommand(Action, Player, ActionMessage);
        return;
    }
}

/**
 * Attempt to issue delayed actions
 */
protected function CheckDelayedActions()
{
    local int i;

    for (i = DelayedActions.Length-1; i >= 0; i--)
    {
        // Time's up
        if (DelayedActions[i].Time <= Level.TimeSeconds)
        {
            log(self $ ": time of " $ DelayedActions[i].Type $ " for " $ DelayedActions[i].Player.GetName() $ " has come up");
            // Issue a normal action
            IssueInstantAction(
                DelayedActions[i].Player,
                DelayedActions[i].Type,
                DelayedActions[i].Action,
                1,  // instant
                DelayedActions[i].ActionMessage
            );
            DelayedActions.Remove(i, 1);
        }
        // Keep showing warnings
        else if (DelayedActions[i].LatestWarningTime < Level.TimeSeconds - DelayedActions[i].WarningInterval)
        {
            log(self $ ": displaying a warning to " $ DelayedActions[i].Player.GetName() $ " for " $ DelayedActions[i].Type);

            class'Utils.LevelUtils'.static.TellPlayer(
                Level, DelayedActions[i].WarningMessage, DelayedActions[i].Player.PC
            );
            DelayedActions[i].LatestWarningTime = Level.TimeSeconds;
        }
    }
}

/**
 * Attempt to queue a delayed action of given type against a player
 */
protected function IssueDelayedAction(Player Player, string Type, string Action, int ActionTime, int Warnings, string WarningMessage, string ActionMessage)
{
    local sDelayedAction NewEntry;

    Action = class'Utils.StringUtils'.static.Strip(Action);

    if (Action == "" || Action ~= "none")
    {
        log(self $ ": wont queue " $ Type $ " against " $ Player.GetName());
        return;
    }
    if (MatchDelayedAction(Player, Type))
    {
        log(self $ ": " $ Type $ " against " $ Player.GetName() $ " has already been queued");
        return;
    }

    NewEntry.Player = Player;
    NewEntry.Type = Type;
    NewEntry.Action = Action;
    NewEntry.Time = FMax(1.0, float(ActionTime)) + Level.TimeSeconds;
    NewEntry.WarningInterval = FMax(1.0, float(ActionTime)/float(Warnings));
    NewEntry.WarningMessage = WarningMessage;
    NewEntry.ActionMessage = ActionMessage;

    DelayedActions[DelayedActions.Length] = NewEntry;
    log(self $ ": successfuly queued " $ Type $ " against " $ Player.GetName());
}

/**
 * Tell if there is a delayed action matching given Player and Type
 */
protected function bool MatchDelayedAction(Player Player, string Type)
{
    local int i;

    for (i = 0; i < DelayedActions.Length; i++)
    {
        if (DelayedActions[i].Player == Player && DelayedActions[i].Type == Type)
        {
            return true;
        }
    }
    return false;
}

/**
 * Attempt to drop a delayed action matching given Type and Player
 */
protected function DropDelayedAction(Player Player, string Type)
{
    local int i;

    for (i = DelayedActions.Length-1; i >= 0 ; i--)
    {
        if (DelayedActions[i].Player == Player && DelayedActions[i].Type == Type)
        {
            log(self $ ": dropping a " $ Type $ " action for " $ Player.LastName);
            DelayedActions.Remove(i, 1);
            break;
        }
    }
}

/**
 * Attempt to lift all issued punishment actions
 */
protected function DropIssuedActions()
{
    local int i;

    for (i = InstantActions.Length-1; i >= 0; i--)
    {
        // Only lift actions that have actually been issued
        if (InstantActions[i].Count < InstantActions[i].Limit)
        {
            continue;
        }

        log(self $ ": lifting a " $ InstantActions[i].Type $ " punishment of " $ InstantActions[i].Player.LastName);

        // Unmute the player (other admin actions dont normally persist through rounds)
        if (InstantActions[i].Action ~= "forcemute")
        {
            IssueAdminCommand("forcemute", InstantActions[i].Player);
        }

        InstantActions[i].Player = None;
        InstantActions.Remove(i, 1);
    }
}

/**
 * Drop all action entries for a player
 */
protected function DropAllActions(optional Player Player)
{
    local int i;

    for (i = InstantActions.Length-1; i >= 0; i--)
    {
        if (Player == None || InstantActions[i].Player == Player)
        {
            log(self $ ": dropping " $ InstantActions[i].Type);
            InstantActions[i].Player = None;
            InstantActions.Remove(i, 1);
        }
    }

    for (i = DelayedActions.Length-1; i >= 0; i--)
    {
        if (Player == None || DelayedActions[i].Player == Player)
        {
            log(self $ ": dropping " $ DelayedActions[i].Type);
            DelayedActions[i].Player = None;
            DelayedActions.Remove(i, 1);
        }
    }
}

/**
 * Issue an arbitrary AdminMod command.
 * If Player argument is provided, append its AM player id to the command
 *
 * @param   AdminCommand
 *          Arbitrary admin command
 * @param   Player (optional)
 *          Optional target
 * @param   ActionMessage (optional)
 *          An optional message to display upon the action being taken
 */
protected function IssueAdminCommand(string AdminCommand, optional Player Player, optional string ActionMessage)
{
    if (ActionMessage != "")
    {
        if (Player != None)
        {
            ActionMessage = class'Utils.StringUtils'.static.Format(ActionMessage, Player.LastName);
        }
        class'Utils.LevelUtils'.static.TellAdmins(Level, ActionMessage, Player.PC);
    }

    // Append the player's id
    if (Player != None)
    {
        AdminCommand = AdminCommand $ " " $ GetPlayerAMId(Player);
    }

    if (!class'Utils'.static.AdminModCommand(Level, AdminCommand, Locale.Translate("ServerString"), ""))
    {
        // Show a warning upon a failure
        if (Player != None)
        {
            class'Utils.LevelUtils'.static.TellAdmins(
                Level,
                Locale.Translate("AdminActionMessage", AdminCommand, Player.LastName),
                Player.PC
            );
        }
    }
}

/**
 * Return the player's AdminMod player id
 */
protected function int GetPlayerAMId(Player Player)
{
    local SwatGame.SwatMutator SM;

    foreach DynamicActors(class'SwatGame.SwatMutator', SM)
    {
        if (SM.IsA('AMPlayerController'))
        {
            if (AMMod.AMPlayerController(SM).PC == Player.PC)
            {
                return AMMod.AMPlayerController(SM).id;
            }
        }
    }
    return -1;
}

/**
 * Return the number of Player's teamhits performed with specific weapons WeaponNames
 * WeaponNames is a string array that must contain case-insensitive weapon friendly names (Colt M4A1 Carbine, 9mm SMG)
 */
static function int GetPlayerTeamHits(Player Player, array<string> WeaponNames)
{
    local int i, TeamHits;

    for (i = 0; i < Player.Weapons.Length; i++)
    {
        if (class'Utils.ArrayUtils'.static.Search(WeaponNames, Player.Weapons[i].GetFriendlyName(), true) >= 0)
        {
            TeamHits += Player.Weapons[i].TeamHits;
        }
    }

    return TeamHits;
}

event Destroyed()
{
    if (Core != None)
    {
        Core.Dispatcher.UnbindAll(self);

        Core.UnregisterInterestedInEventBroadcast(self);
        Core.UnregisterInterestedInInternalEventBroadcast(self);
        Core.UnregisterInterestedInMissionEnded(self);
        Core.UnregisterInterestedInPlayerNameChanged(self);
        Core.UnregisterInterestedInPlayerTeamSwitched(self);
        Core.UnregisterInterestedInPlayerAdminLogged(self);
        Core.UnregisterInterestedInPlayerDisconnected(self);
        Core.UnregisterInterestedInPlayerVoiceChanged(self);
    }

    DropAllActions();

    while (BalanceList.Length > 0)
    {
        BalanceList[0] = None;
        BalanceList.Remove(0, 1);
    }

    while (ProtectedNames.Length > 0)
    {
        ProtectedNames.Remove(0, 1);
    }

    Super.Destroyed();
}

defaultproperties
{
    Title="Julia/Admin";
    LocaleClass=class'AdminLocale';

    AutoBalanceAdminPresent=true;
    AutoBalanceAction="none";
    AutoBalanceTime=20;

    ProtectNamesAction="kick";
    ProtectNamesActionTime=60;
    ProtectNamesActionWarnings=5;

    DisallowNamesAction="kick";
    DisallowNamesActionTime=60;
    DisallowNamesActionWarnings=5;

    DisallowWordsAction="none";
}
