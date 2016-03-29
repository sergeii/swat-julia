class Cache extends Engine.Actor;

/**
 * Delimiter for cache entries in the Swat4DedicatedServer.ini
 * @example key $ DELIMITER $ value $ DELIMITER $ TTL
 */
const DELIMITER = "\t";

/**
 * Cache check rate
 */
const DELTA = 30.0;


struct sCacheEntry
{
    var string Key;
    var string Value;
    var int TTL;
};

/**
 * An array of cache entries stored in memory
 */
var array<sCacheEntry> Live;

/**
 * An array of cache entries stored in config
 */
var config array<string> Saved;

/**
 * Default cache entry TTL
 */
var config int TTL;


public function PreBeginPlay()
{
    Super.PreBeginPlay();
    self.Disable('Tick');
}

/**
 * Load cache entries into memory
 * Clean up expired entries
 */
public function BeginPlay()
{
    Super.BeginPlay();

    self.LoadCache();
    self.CheckExpiredEntries();
    self.SetTimer(class'Cache'.const.DELTA, true);
}

/**
 * Periodically clean up expired entries
 */
event Timer()
{
    self.CheckExpiredEntries();
}

/**
 * Retrieve cache entry value stored under provided key
 */
public function string GetValue(string Key)
{
    return self.GetArray(Key)[0];
}

/**
 * Return a collection of entries stored under the same key Key
 */
public function array<string> GetArray(string Key)
{
    local int i;
    local array<string> Array;

    for (i = 0; i < self.Live.Length; i++)
    {
        if (self.Live[i].Key ~= Key)
        {
            Array[Array.Length] = self.Live[i].Value;
        }
    }
    return Array;
}

/**
 * Set up a cache entru with key Key and corresponding value
 */
public function SetValue(string Key, string Value)
{
    self.Discard(Key);
    self.Append(Key, Value);
}

/**
 * Save a collection of values under the same key
 */
public function SetArray(string Key, array<string> Array)
{
    local int i;
    // Purge the existing entries that have been previously stored with the same key
    self.Discard(Key);
    // Store as many cache entries with the same key as provided by the collection
    for (i = 0; i < Array.Length; i++)
    {
        self.Append(Key, Array[i]);
    }
}

/**
 * Add a new cache entry with provided key and value
 * If custom TTL provided, use it. Otherwise stick to the default value
 */
public function Append(string Key, string Value, optional int TTL)
{
    local sCacheEntry NewEntry;

    if (TTL <= 0)
    {
        TTL = class'Utils.LevelUtils'.static.Timestamp(Level) + self.TTL;
    }

    NewEntry.Key = Key;
    NewEntry.Value = Value;
    NewEntry.TTL = TTL;

    self.Live[self.Live.Length] = NewEntry;
}

/**
 * Remove all cache entries that have been stored with the provided key
 */
protected function Discard(string Key)
{
    local int i;

    for (i = self.Live.Length-1; i >= 0 ; i--)
    {
        if (self.Live[i].Key == Key)
        {
            self.Live.Remove(i, 1);
        }
    }
}

/**
 * Remove the cache entries that have expired
 */
protected function CheckExpiredEntries()
{
    local int i;

    for (i = self.Live.Length-1; i >= 0 ; i--)
    {
        if (self.Live[i].TTL < class'Utils.LevelUtils'.static.Timestamp(Level))
        {
            self.Live.Remove(i, 1);
        }
    }
}

/**
 * Parse and load the cached entries into memory
 */
public function LoadCache()
{
    local int i;
    local array<string> Parsed;

    for (i = 0; i < self.Saved.Length; i++)
    {
        Parsed = class'Utils.StringUtils'.static.Part(self.Saved[i], class'Cache'.const.DELIMITER);

        if (Parsed.Length != 3)
        {
            continue;
        }
        self.Append(Parsed[0], Parsed[1], int(Parsed[2]));
    }
}

/**
 * Attempt to store memory cache entries currently stored onto disk
 */
public function Commit()
{
    local int i;
    local array<string> OldSaved;

    OldSaved = self.Saved;

    // Replace disk data with live entries
    while (self.Saved.Length > 0)
    {
        self.Saved.Remove(0, 1);
    }

    for (i = 0; i < self.Live.Length; i++)
    {
        self.Saved[self.Saved.Length] = (
            self.Live[i].Key $ class'Cache'.const.DELIMITER $ self.Live[i].Value $ class'Cache'.const.DELIMITER $ self.Live[i].TTL
        );
    }

    // Only commit changes if the live and disk entries differ from each other
    if (!class'Utils.ArrayUtils'.static.Compare(OldSaved, self.Saved))
    {
        self.SaveConfig("", "", false, true);
    }
}


event Destroyed()
{
    while (self.Live.Length > 0)
    {
        self.Live.Remove(0, 1);
    }
}

defaultproperties
{
    TTL=86400;
}
