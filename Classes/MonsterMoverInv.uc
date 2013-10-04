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

class MonsterMoverInv extends Inventory
	config(MonsterMover);

var config int RespawnSeconds;
var config int MaxFailedRespawns;
var config int RequiredVisibleDistance;
var config int RequiredNotVisibleDistance;

var bool Debug;

var int secondsWithoutTarget;
var int failedRespawns;
var config int MonsterCheckFrequency;

function Timer()
{
	if(Instigator == None)
	{
		if(Debug) 
			log("MonsterMover: Stopped. No Instigator");
		super.Timer();
		SetTimer(0, true);
		return;
	}

	if(Instigator.bIgnoreOutOfWorld)
	{
		if(Debug) 
			log("MonsterMover: Skipped. IgnoreOutOfWorld set");
		super.Timer();
		return;
	}

	if(Instigator.Controller == None || MonsterController(Instigator.Controller) == None)
	{
		//It must be dying or spawning, or something...
		super.Timer();
		if(Debug) 
			log("MonsterMover: Suspended. No Controller");
		return; //Something is amiss. It should get worked out shortly
	}	

	if(Level.Game.bGameEnded)
	{
		if(Debug) 
			log("MonsterMover: Skipped. Game Ended");
		super.Timer();
		return;
	}

	if 
	(
		Instigator.Base != None && 
		Instigator.Base.IsA('BlockingVolume') && 
		!Instigator.Base.bBlockZeroExtentTraces
	)
	{
		// The monster is literally walking on air, and is probably outside the map.
		//Check to see if they're none. Somehow they get changed to none even though we have a check above.
		//I dont have a clue how that could be happening since the system in single threaded.
		if(Instigator.Controller != None && MonsterController(Instigator.Controller) != None && !MonsterController(Instigator.Controller).isHunting())
			secondsWithoutTarget+=(5 * MonsterCheckFrequency); //give em quite a boost to encourage the monster to be respawned.
		else
			secondsWithoutTarget+=MonsterCheckFrequency; //still encourage them to be respawned a bit

		if(Debug)
			log("MonsterMover: Monster walking on air.");
		
	}
	else if(isOpponentNearBy())
		secondsWithoutTarget = 0;
	else
		SecondsWithoutTarget+=MonsterCheckFrequency;
		
	if(secondsWithoutTarget >= RespawnSeconds)
		respawnInstigator();

	super.Timer();
}

function bool isOpponentNearby()
{
	local Pawn Pawn;
	
	if(Instigator.Controller == None || MonsterController(Instigator.Controller) == None)
		return false; //It must be dying or spawning, or something...
	if(MonsterController(Instigator.Controller).isHunting())
	{
		if(Debug)
			log("MonsterMover: Monster is hunting someone.");
		return true; //it's actively hunting someone...
	}

	foreach Instigator.VisibleCollidingActors(class'Pawn', Pawn, RequiredVisibleDistance)
	{
		if(Pawn == None || Pawn == Instigator || Pawn.Controller == None || Pawn.isA('Monster'))
			continue;
		if(Pawn.isA('Vehicle') && Vehicle(Pawn).Driver == None)
			Continue;
		if(Pawn.isPlayerPawn())
		{
			if(Debug) 
				log("MonsterMover: Nearby Pawn:"@Instigator.class @":"@Pawn.class);
			return true; //found an opponent
		}
	}

	foreach Instigator.CollidingActors(class'Pawn', Pawn, RequiredNotVisibleDistance)
	{
		if(Pawn == None || Pawn == Instigator || Pawn.Controller == None || Pawn.isA('Monster'))
			continue;
		if(Pawn.isA('Vehicle') && Vehicle(Pawn).Driver == None)
			Continue;
		if(Pawn.isPlayerPawn())
		{
			if(Debug) 
				log("MonsterMover: Nearby Pawn:"@Instigator.class @":"@Pawn.class);
			return true; //found an opponent
		}
	}

	if(Debug)
		log("MonsterMover: No opponnents nearby.");
	return false;
}


function respawnInstigator()
{
	Local Pawn Pawn;
	local NavigationPoint SpawnPoint;
	local Vector ReviveLocation;
	local Vector PreviousLocation;

	PreviousLocation = Instigator.Location;
	SpawnPoint = Level.Game.FindPlayerStart(Instigator.Controller, ,);
	if(SpawnPoint == None)
	{
		FailedRespawns ++;

		if(FailedRespawns >= MaxFailedRespawns)
		{
			Pawn.Died(Instigator.Controller, class'Gibbed', PreviousLocation);
			return;
		}

		secondsWithoutTarget = RespawnSeconds; //force them to check again next check
		
		if(Debug)
			log("MonsterMover: Unable to move monster.");
		return;
	}
	FailedRespawns = 0;

	if(Debug)
		log("MonsterMover: Moving a monster.");
	
	secondsWithoutTarget = 0;

	ReviveLocation = SpawnPoint.Location;
	
	Instigator.SetLocation(ReviveLocation);

	xPawn(Instigator).DoTranslocateOut(PreviousLocation);

	Instigator.SetOverlayMaterial(class'TransRecall'.default.TransMaterials[0], 1.0, false);
	Instigator.PlayTeleportEffect(false, false);
}

function DropFrom(vector StartLocation)
{
	//this inventory cant be dropped.
}

defaultproperties
{
     RespawnSeconds=20
     RequiredVisibleDistance=8000
     RequiredNotVisibleDistance=1000
     MonsterCheckFrequency=1

     MaxFailedRespawns=20

     RemoteRole=ROLE_None

     bOnlyRelevantToOwner=True
     bReplicateInstigator=False
}