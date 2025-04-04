/obj/effect/landmark/mapGenerator/beach
	mapGeneratorType = /datum/mapGenerator/beach
	endTurfX = 1
	endTurfY = 1
	startTurfX = 1
	startTurfY = 1

/datum/mapGenerator/beach
	modules = list(/datum/mapGeneratorModule/beach)

/datum/mapGeneratorModule/beach
	clusterCheckFlags = CLUSTER_CHECK_SAME_ATOMS|CLUSTER_CHECK_DIFFERENT_ATOMS
	allowed_turfs = list(/turf/open/floor/dirt/road)
	allowed_areas = list(/area/rogue/outdoors/beach)
	spawnableAtoms = list(	/obj/item/natural/stone = 11,
							/obj/item/grown/log/tree/stick = 1)
