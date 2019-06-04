var/list/all_supply_groups = list("Supplies","Clothing","Engineering","Medical")

/datum/supply_pack
	var/name = null
	var/list/contains = list() //type = amount
	var/manifest = ""
	var/cost = null
	var/containertype = /obj/structure/closet/crate
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
		manifest += "<li>[AM.name][(contains[path] > 1) ? " ([contains[path]])": ""]</li>"
		AM.forceMove(null)	//just to make sure they're deleted by the garbage collector
	manifest += "</ul>"

// Called after a crate containing the items specified by this datum is created
/datum/supply_pack/proc/post_creation(var/atom/movable/container)
	return

//called when the order gets approved, for adminlog stuff
/datum/supply_pack/proc/onApproved(var/mob/user)
	return // Blank proc

/datum/supply_pack/proc/create(var/datum/supply_order/SO)
	var/atom/A = new containertype()
	A.name = containername

	//spawn the stuff, finish generating the manifest while you're at it
	if(istype(A, /obj/structure/closet))
		var/obj/structure/closet/C = A
		if(req_access)
			C.req_access = req_access

		if(req_one_access)
			C.req_one_access = req_one_access

	for(var/typepath in contains)
		if(!typepath)
			continue
		var/atom/B2 = new typepath(A)
		if(istype(B2, /obj/item/stack))
			var/obj/item/stack/ST = B2
			ST.amount = contains[typepath]
		else
			for(var/i=1, i<contains[typepath], i++) //one less since we already made one (B2)
				new typepath(A)

	post_creation(A)
	
	return A