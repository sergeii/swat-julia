class Cache extends Engine.Actor;

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
 * Delimiter for cache entries in the Swat4DedicatedServer.ini
 * @example key $ DELIMITER $ value $ DELIMITER $ TTL
 * @type string
 */
const DELIMITER = "\t";

/**
 * Cache check rate
 * @type float
 */
const DELTA = 30.0;


struct sCacheEntry
{
    /**
     * Cache key
     * @type string
     */
    var string Key;

    /**
     * Cache value
     * @type string
     */
    var string Value;

    /**
     * Cache entry TTL
     * @type int
     */
    var int TTL;
};

/**
 * An array of cache entries stored in memory
 * @type array<struct'sCacheEntry'>
 */
var protected array<sCacheEntry> Live;

/**
 * An array of cache entries stored in config
 * @type array<string>
 */
var config array<string> Saved;

/**
 * Default cache entry TTL
 * @type int
 */
var config int TTL;

/**
 * Disable the Tick event
 * 
 * @return  void
 */
public function PreBeginPlay()
{
    Super.PreBeginPlay();
    self.Disable('Tick');
}

/**
 * Load cache entries into memory
 * Clean up expired entries
 * 
 * @return  void
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
 * 
 * @param   string Key
 * @return  string
 */
public function string GetValue(string Key)
{
    return self.GetArray(Key)[0];
}

/**
 * Return a collection of entries stored under the same key Key
 * 
 * @param   string Key
 *          Cache entry Key
 * @return  array<string>
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
 * Set up a cache entru with key Key and corresponding value Value
 * 
 * @param   string Key
 * @param   string Value
 * @return  void
 */
public function SetValue(string Key, string Value)
{
    self.Discard(Key);
    self.Append(Key, Value);
}

/**
 * Save a collection of values under the same key
 * 
 * @param   string Key
 *          Cache entry key
 * @param   array<string> ArrayOfData
 *          Collection of data
 * @return  void
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
 * 
 * @param   string Key
 * @param   string Value
 * @param   int TTL (optional)
 *          Optional TTL
 * @return  void
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
 * 
 * @param   string Key 
 *          Cache entry key
 * @return  void
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
 *
 * @return  void
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
 * 
 * @return  void
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
 * 
 * @return  void
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

/* vim: set ft=java: */
