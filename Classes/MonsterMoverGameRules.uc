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

class MonsterMoverGameRules extends GameRules
	config(MonsterMover);

var array<PathNode> Nodes;
var config int MaxPlayerDistance;
var config int MinPlayerDistance;

var config int RespawnMaxPlayerDistance;
var config int RespawnMinPlayerDistance;

var config int RetryCount;
var config bool SpawnAnyway;

var bool Debug;

var bool started;

function PostBeginPlay()
{
	local NavigationPoint nav;

	for(nav = Level.NavigationPointList; nav != None; nav = nav.NextNavigationPoint)
		if(nav.isA('PathNode'))
			Nodes[Nodes.length] = PathNode(nav);

	Super.PostBeginPlay();
}

/**
 *  Give the monster a random start point.
 */
function NavigationPoint FindPlayerStart(Controller Player, optional byte InTeam, optional string incomingName)
{
	local int x, i;
	local int LocalMinPlayerDistance, LocalMaxPlayerDistance;
	local bool bNearbyPawns;
	local bool bAnyPawns;
	local xPawn p;
	local Pawn pawn;
	local NavigationPoint other;
	other = super.FindPlayerStart( Player, InTeam, incomingName );
	
	//For a fantastic hack, we have to handle Player == None, because Monsters apparently 
	//dont have a controller when this method is called. (Look at SkaarjPack.Invasion and you'll see)
	
	//however, we cant start dealing with that until we see an XGame.xPlayer
	//otherwise a lot of other objects that want to spawn will be messed up.

	if(!started)
	{
		if(Player == None)
			return other;
		else
			started = true;
	}

	if(Player != None && !Player.isA('MonsterController'))
	{
		if(Debug)
			log("MonsterMover: Not a MonsterController: " @ String(Player.class));
	
		return(other);
	}

	if(Player != None && Player.Pawn != None)
	{
		LocalMinPlayerDistance = RespawnMinPlayerDistance;
		LocalMaxPlayerDistance = RespawnMaxPlayerDistance;
		if(Debug)
			log("MonsterMover: Monster is respawning");
	}
	else
	{
		LocalMinPlayerDistance = MinPlayerDistance;
		LocalMaxPlayerDistance = MaxPlayerDistance;
		if(Debug)
			log("MonsterMover: Monster is spawning for the first time. Incomingname was:" @ incomingname);
	}
	
	bNearbyPawns = true;

	for(i = 0; i < RetryCount && (bNearbyPawns || !bAnyPawns); i++)
	{
		if(Nodes[x] == None)
			continue;
		x = Rand(Nodes.length);
		if(Nodes[x].taken || Nodes[x].bMayCausePain)
			continue;
		if(FlyingPathNode(Nodes[x]) != None && (Player.PawnClass == None || !Player.PawnClass.default.bCanFly))
			continue;

		//I dont think I want to do this.
		//other = Nodes[x]; //set other for SpawnAnyway since this monster can go here. 

		bNearbyPawns = false;
		
		foreach Nodes[x].VisibleCollidingActors(class'xPawn', p, LocalMinPlayerDistance)
		{
			if(Debug)
				log("MonsterMover: Found a pawn within the minimum radius. Not Spawning here..");
			bNearbyPawns = true;
			break;
		}

		bAnyPawns = false;
		if(!bNearByPawns)
		{
			foreach Nodes[x].CollidingActors(class'Pawn', pawn, LocalMaxPlayerDistance)
			{
				if(pawn.isA('Monster'))
					continue;
				if(Pawn.isA('Vehicle') && Vehicle(Pawn).Driver == None)
					continue;
				if(Pawn.isPlayerPawn())
				{
					if(Debug)
						log("MonsterMover: Found a pawn within the maximum radius.");
					bAnyPawns = true;
					break;
				}
			}
			if(!bAnyPawns)
			{
				if(Debug)
					log("MonsterMover: Didn't find a pawn within the maximum radius. Not Spawning here.");
			}
		}
	}

	if(i == RetryCount && SpawnAnyway)
	{
		if(Debug)
			log("MonsterMover: Couldn't find a spot, but told to spawn anyway.");

		return Other;
	}
	else if(i == RetryCount)
	{
		if(Debug)
			log("MonsterMover: Couldn't find a spot, Returning None.");

		return None;
	}
	else
		return Nodes[x];
}

defaultproperties
{
     MinPlayerDistance=1000
     MaxPlayerDistance=15000
     RespawnMinPlayerDistance=500
     RespawnMaxPlayerDistance=8000
     RetryCount=100
     SpawnAnyway=false
}