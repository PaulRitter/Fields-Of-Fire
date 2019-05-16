var/list/all_supply_groups = list("Supplies","Clothing","Security","Hospitality","Engineering","Medical","Science","Hydroponics","Vending Machine packs")

/datum/supply_packs
	var/name = null
	var/list/contains = list()
	var/manifest = ""
	var/amount = null
	var/cost = null
	var/containertype = null
	var/containername = null
	var/access = null // See code/game/jobs/access.dm
	var/one_access = null // See above
	var/hidden = 0 //Emaggable
	var/contraband = 0 //Hackable via tools
	var/group = "Supplies"

/datum/supply_packs/New()
	manifest += "<ul>"
	for(var/path in contains)
		if(!path)
			continue
		var/atom/movable/AM = new path()
		manifest += "<li>[AM.name]</li>"
		AM.forceMove(null)	//just to make sure they're deleted by the garbage collector
	manifest += "</ul>"

// Called after a crate containing the items specified by this datum is created
/datum/supply_packs/proc/post_creation(var/atom/movable/container)
	return

/datum/supply_packs/proc/OnConfirmed(var/mob/user)
	return // Blank proc