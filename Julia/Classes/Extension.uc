class Extension extends SwatGame.SwatMutator;

var string Version;  // Extension details
var string Title;
var config bool Enabled;

var Core Core;
var Locale Locale;
var class<Locale> LocaleClass;


/**
 * Check whether the extension is disabled
 */
public function PreBeginPlay()
{
    Super.PreBeginPlay();
    self.Disable('Tick');

    if (Level.NetMode == NM_ListenServer || Level.NetMode == NM_DedicatedServer)
    {
        if (Level.Game != None && SwatGameInfo(Level.Game) != None)
        {
            if (self.Enabled)
            {
                return;
            }
        }
    }
    self.Destroy();
}

public function BeginPlay()
{
    Super.BeginPlay();

    self.Core = self.GetCoreInstance();

    if (self.Core == None)
    {
        log(self $ " was unable to find the Julia.Core instance");
        self.Destroy();
    }

    if (self.LocaleClass != None)
    {
        self.Locale = Spawn(self.LocaleClass);
    }

    log("Julia/" $ self.Title $ " (version " $ self.Version $ ") has been initialized");

    self.SetTimer(class'Core'.const.DELTA, true);
}

/**
 * Attempt to find the Julia's Core instance in the list of server actors
 */
protected function Core GetCoreInstance()
{
    local Core Core;

    foreach DynamicActors(class'Julia.Core', Core)
    {
        return Core;
    }
    return None;
}


/** Deprecated methods **/

final public function string GetTitle()
{
    return self.Title;
}
final public function string GetVersion()
{
    return self.Version;
}


event Destroyed()
{
    self.Core = None;
    self.LocaleClass = None;

    if (self.Locale != None)
    {
        self.Locale.Destroy();
        self.Locale = None;
    }

    log(self $ ": Julia/" $ self.Title $ " is about to be destroyed");

    Super.Destroyed();
}

defaultproperties
{
    Title="undefined";
    Version="unknown";
    LocaleClass=None;
}
