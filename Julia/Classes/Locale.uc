class Locale extends Engine.Actor;

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

var config string CoreVersionUsage;
var config string CoreVersionDescription;

var config string DispatcherHelpUsage;
var config string DispatcherHelpDescription;

var config string DispatcherCommandList;
var config string DispatcherCommandCooldown;
var config string DispatcherCommandInvalid;
var config string DispatcherCommandTimedout;
var config string DispatcherOutputHeader;
var config string DispatcherOutputLine;
var config string DispatcherOutputColor;
var config string DispatcherCommandHelp;

var config string DispatcherUsageError;
var config string DispatcherPermissionError;

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
 * Translate a property string
 * 
 * @param   string Property
 * @param   string Arg1 (optional)
 * @param   string Arg2 (optional)
 * @param   string Arg3 (optional)
 * @param   string Arg4 (optional)
 * @param   string Arg5 (optional)
 * @return  string
 */
public function string Translate(
    string Property,
    optional coerce string Arg1, 
    optional coerce string Arg2, 
    optional coerce string Arg3, 
    optional coerce string Arg4, 
    optional coerce string Arg5
)
{
    return class'Utils.StringUtils'.static.Format(self.GetPropertyText(Property), Arg1, Arg2, Arg3, Arg4, Arg5);
}

event Destroyed()
{
    log(self $ " is about to be destroyed");
    Super.Destroyed();
}

defaultproperties
{
    CoreVersionUsage="!%1";
    CoreVersionDescription="Displays the mod version.";

    DispatcherHelpUsage="!%1";
    DispatcherHelpDescription="Lists available commands.";

    DispatcherCommandList="Available commands: %1\\nType [b]!<command> help[\\b] for more information on the specified command.";
    DispatcherCommandCooldown="Unable to issue the command.\\nPlease try again later.";
    DispatcherCommandInvalid="'%1' is not a valid command.\\nType !help to list available commands.";
    DispatcherCommandTimedout="Failed to issue the command.\\nPlease try again later.";
    DispatcherCommandHelp="%1\\nUsage: [c=FFFF00]%2";
    DispatcherOutputHeader="[b]%1[\\b] %2";
    DispatcherOutputColor="ffffff";
    DispatcherOutputLine="> %1";

    DispatcherUsageError="You provided invalid arguments.\\nType [b]!%1 help[\\b] for more information on command usage.";
    DispatcherPermissionError="You don't have permissions to issue the [b]%1[\\b] command.";
}

/* vim: set ft=java: */
