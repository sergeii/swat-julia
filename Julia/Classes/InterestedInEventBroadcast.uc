interface InterestedInEventBroadcast;

/**
 * Copyright (c) 2014 Sergei Khoroshilov <kh.sergei@gmail.com>
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
 * The implemented method is called to signal about a game event broadcast (Say, SwatKill, Caption, etc)
 * 
 * @param   class'Player' Player
 *          Player instance of the sender (or None)
 * @param   class'Actor' Sender
 *          The original sender instance
 * @param   name Type
 *          Event type (Say, TeamSay,...)
 * @param   string Msg
 *          Optional message (Player1\tPlayer2\t9mm SMG, hi all,...)
 * @param   class'PlayerController' Receiver (optional)
 *          Optional receiver
 * @param   bool bHidden (optional)
 *          Indicate whether the event has been set to ignored by broadcast handler
 * @return  bool
 *          Return false to mark the event hidden, i.e. to stop it from appearing in game
 */
public function bool OnEventBroadcast(Player Player, Actor Sender, name Type, out string Msg, optional PlayerController Receiver, optional bool bHidden);

/* vim: set ft=java: */