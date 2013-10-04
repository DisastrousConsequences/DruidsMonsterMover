/*
    Copyright (C) 2005  Clinton H Goudie-Nice aka TheDruidXpawX

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

class MutMonsterMover extends Mutator
	config(MonsterMover);

var config bool EnableTimedMover;
var config bool EnableRandomStarts;
var config int NewMonsterTimer;

var config bool Debug;

function PostBeginPlay()
{
	local MonsterMoverGameRules G;

	Super.PostBeginPlay();
	if(!EnableRandomStarts)
	{
		if(Debug)
			log("MonsterMover: Random spawn points disabled.");
	}
	else
	{
		if(Debug)
			log("MonsterMover: Spawning random start game rules.");
		
		G = spawn(class'MonsterMoverGameRules');
		g.Debug = Debug;

		if ( Level.Game.GameRulesModifiers == None )
			Level.Game.GameRulesModifiers = G;
		else    
			Level.Game.GameRulesModifiers.AddGameRules(G);
	}
	if(EnableTimedMover)
	{
		if(Debug)
			log("MonsterMover: Timed Mover Enabled. Detecting new monsters every:" @ NewMonsterTimer @ "seconds");
		setTimer(NewMonsterTimer, true);
	}
	else if(Debug)
		log("MonsterMover: Timed Mover Disabled.");
}

function Timer()
{
	Local Monster Monster;
	foreach Level.Game.AllActors(class'Monster', Monster)
	{
		if(Monster.FindInventoryType(class'MonsterMoverInv') == None)
			ModifyMonster(Monster);
	}	
	Super.Timer();
}

function ModifyMonster(Monster Other)
{
	Local MonsterMoverInv MonsterMoverInv;

	if (Other.Controller == None)
	{
		if(debug)
			log("MonsterMover: No Controller, No Inventory given.");
		return;
	}

	if(String(Other.Controller.class) == "FriendlyMonsterController")
	{
		if(debug)
			log("MonsterMover: FriendlyMonster, No Inventory Given.");

		return;
	}

	MonsterMoverInv = Other.Spawn(class'MonsterMoverInv');
	MonsterMoverInv.giveTo(Other);
	if(debug)
	{
		log("MonsterMover: Monster Given inventory.");
		MonsterMoverInv.debug = true;
	}
	MonsterMoverInv.SetTimer(MonsterMoverInv.MonsterCheckFrequency, true);
}

defaultproperties
{
     EnableTimedMover=true
     EnableRandomStarts=true
     Debug = False
     NewMonsterTimer=20

     GroupName="MonsterMover"
     FriendlyName="Monster Mover"
     Description="Monsters spawn in random locations, and also causes Monsters to move closer to a random player if the monster can't see any players."
}