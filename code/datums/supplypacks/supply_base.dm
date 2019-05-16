var/list/all_supply_groups = list("Supplies","Clothing","Engineering","Medical")

/datum/supply_pack
	var/name = null
	var/list/contains = list() //type = amount
	var/manifest = ""
	var/cost = null
	var/containertype = /obj/structure/closet
	var/containername = "Crate"
	var/list/req_access = null // See code/game/jobs/access.dm
	var/list/req_one_access = null // See above
	var/hidden = 0 //1 = only shows up when emagged (is this needed?)
	var/contraband = 0 //1 = only shows up when hacked (is this needed?)
	var/group = "Supplies"

/datum/supply_pack/New()
	manifest += "<ul>"
	for(var/path in contains)
		if(!path)
			continue
		var/atom/movable/AM = new path()
		manifest += "<li>[AM.name] ([contains[path]])</li>"
		AM.forceMove(null)	//just to make sure they're deleted by the garbage collector
	manifest += "</ul>"

// Called after a crate containing the items specified by this datum is created
/datum/supply_pack/proc/post_creation(var/atom/movable/container)
	return

//called when the order gets approved, for adminlog stuff
/datum/supply_pack/proc/onApproved(var/mob/user)
	return // Blank proc