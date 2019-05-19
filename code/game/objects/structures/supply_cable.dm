// *** STRUCTURE ***
/obj/structure/supply_cable
	level = 1
	anchored =1
	var/datum/radionet/radionet //to see if we actually have a proper connection
	name = "Radio cable"
	desc = "A heavy cable for transmitting radio signals. Nearly indestructable."
	icon = 'icons/obj/power_cond_white.dmi'
	icon_state = "0-1"
	var/d1 = 0
	var/d2 = 1

	plane = ABOVE_TURF_PLANE
	layer = ABOVE_TILE_LAYER

	color = COLOR_BROWN_ORANGE

/obj/structure/supply_cable/New(var/nicon_state = "0-1")
	..()
	icon_state = nicon_state

	// ensure d1 & d2 reflect the icon_state for entering and exiting cable
	var/dash = findtext(icon_state, "-")
	d1 = text2num( copytext( icon_state, 1, dash ) )
	d2 = text2num( copytext( icon_state, dash+1 ) )

	propagateRadionet()

/obj/structure/supply_cable/Destroy()
	var/list/connectedThings = get_connections()
	forceMove(null) //so we wont be propagated over
	var/list/newRNs = list()
	for(var/A in connectedThings)
		if(istype(A, /obj/structure/supply_cable))
			var/obj/structure/supply_cable/C = A
			if(!(C.radionet in newRNs)) //did we already propagate over this one? optimization, would produce errors but just prevents unneeded propagations
				var/datum/radionet/RN = new ()
				propagateRadionet(RN, C)
				newRNs += RN

/obj/structure/supply_cable/proc/get_connections()
	. = list()
	for(var/cable_dir in list(d1, d2))
		var/turf/step = get_step(loc, cable_dir)
		for(var/atom/AM in step)
			if(isConnected(AM))
				. += AM
	
	for(var/atom/AM in loc)
		if(isConnected(AM))
			. += AM

//explosion handling
/obj/structure/supply_cable/ex_act(severity)
	switch(severity)
		if(1.0)
			if (prob(50))
				//add some decals
				qdel(src)

/obj/structure/supply_cable/attackby(obj/item/W, mob/user)

	if(istype(W, /obj/item/device/multitool))
		radionet.readout(user)
	else if(istype(W, /obj/item/stack/radio_cable))
		var/obj/item/stack/radio_cable/coil = W
		if (coil.get_amount() < 1)
			to_chat(user, "Not enough cable")
			return
		coil.cable_join(src, user)

	src.add_fingerprint(user)

//Telekinesis has no effect on a cable
/obj/structure/supply_cable/attack_tk(mob/user)
	return

/obj/structure/supply_cable/proc/isConnected(var/obj/O)
	if(!O)
		return 0
	
	var/dist = get_dist(loc, O.loc)
	if(istype(O, /obj/structure/supply_cable))
		var/obj/structure/supply_cable/SC = O
		if(dist == 1)
			var/r1 = turn(d1, 180)
			var/r2 = turn(d2, 180)
			if(SC.d1 == r1 || SC.d1 == r2 || SC.d2 == r1 || SC.d2 == r2)
				return 1
		else if(SC.loc == loc)
			if(SC.d1 == d1 || SC.d2 == d1 || SC.d1 == d2 || SC.d2 == d2)
				return 1
	
	if((istype(O, /obj/machinery/computer/supply) || istype(O , /obj/structure/supply_hub)) && (O.loc == loc))
		return 1

	return 0

/obj/structure/supply_cable/proc/propagateRadionet(var/datum/radionet/RN = new (), var/obj/source) //source override
	var/list/worklist = list()
	var/list/found_radios = list()
	var/list/found_hubs = list()
	var/index = 1

	worklist+= source ? source : src //start propagating from the passed object

	while(index<=worklist.len)
		var/obj/P = worklist[index] //get the next power object found
		index++

		if(istype(P,/obj/structure/supply_cable))
			var/obj/structure/supply_cable/C = P
			if(C.radionet != RN)
				RN.add_cable(C)
			worklist |= C.get_connections()
		else if(P.anchored && istype(P,/obj/machinery/computer/supply) && !(P in found_radios))
			var/obj/machinery/computer/supply/R = P
			if(R.radionet != RN)
				RN.add_radio(R)
			found_radios |= R
		else if(P.anchored && istype(P,/obj/structure/supply_hub) && !(P in found_hubs))
			var/obj/structure/supply_hub/H = P
			if(H.radionet != RN) 
				RN.add_hub(H)
			found_hubs |= H

// *** INHAND ***
/obj/item/stack/radio_cable
	name = "radio cable coil"
	icon = 'icons/obj/power.dmi'
	icon_state = "coil"
	randpixel = 2
	amount = 10
	max_amount = 10
	color = COLOR_BROWN_ORANGE
	desc = "A coil of power cable."
	throwforce = 10
	w_class = ITEM_SIZE_SMALL
	throw_speed = 1
	throw_range = 1
	matter = list(DEFAULT_WALL_MATERIAL = 50, "glass" = 20)
	flags = CONDUCT
	slot_flags = SLOT_BELT
	item_state = "coil"
	attack_verb = list("whipped", "lashed", "disciplined", "flogged")
	stacktype = /obj/item/stack/radio_cable

// called when cable_coil is clicked on a turf/simulated/floor
/obj/item/stack/radio_cable/proc/turf_place(turf/simulated/F, mob/user)
	if(!isturf(user.loc))
		return

	if(get_amount() < 1) // Out of cable
		to_chat(user, "There is no cable left.")
		return

	if(get_dist(F,user) > 1) // Too far
		to_chat(user, "You can't lay cable at a place that far away.")
		return

	var/dirn
	if(user.loc == F)
		dirn = user.dir			// if laying on the tile we're on, lay in the direction we're facing
	else
		dirn = get_dir(F, user)

	for(var/obj/structure/supply_cable/LC in F)
		if((LC.d1 == dirn && LC.d2 == 0 ) || ( LC.d2 == dirn && LC.d1 == 0))
			to_chat(user, "<span class='warning'>There's already a cable at that position.</span>")
			return

	put_cable(F, user, 0, dirn)

/obj/item/stack/radio_cable/proc/cable_join(obj/structure/supply_cable/C, mob/user)
	var/turf/U = user.loc
	if(!isturf(U))
		return

	var/turf/T = C.loc

	if(!isturf(T))
		return

	if(get_dist(C, user) > 1)		// make sure it's close enough
		to_chat(user, "You can't lay cable at a place that far away.")
		return

	if(U == T) //if clicked on the turf we're standing on, try to put a cable in the direction we're facing
		turf_place(T,user)
		return

	var/dirn = get_dir(C, user)

	// one end of the clicked cable is pointing towards us
	if(C.d1 == dirn || C.d2 == dirn)
		// cable is pointing at us, we're standing on an open tile
		// so create a stub pointing at the clicked cable on our tile

		var/fdirn = GLOB.reverse_dir[dirn] // the opposite direction

		for(var/obj/structure/supply_cable/LC in U)		// check to make sure there's not a cable there already
			if(LC.d1 == fdirn || LC.d2 == fdirn)
				to_chat(user, "There's already a cable at that position.")
				return
		put_cable(U,user,0,fdirn)
		return

	// exisiting cable doesn't point at our position, so see if it's a stub
	else if(C.d1 == 0)
							// if so, make it a full cable pointing from it's old direction to our dirn
		var/nd1 = C.d2	// these will be the new directions
		var/nd2 = dirn


		if(nd1 > nd2)		// swap directions to match icons/states
			nd1 = dirn
			nd2 = C.d2


		for(var/obj/structure/supply_cable/LC in T)		// check to make sure there's no matching cable
			if(LC == C)			// skip the cable we're interacting with
				continue
			if((LC.d1 == nd1 && LC.d2 == nd2) || (LC.d1 == nd2 && LC.d2 == nd1) )	// make sure no cable matches either direction
				to_chat(user, "There's already a cable at that position.")
				return

		qdel(C)
		var/obj/structure/supply_cable/SC = new (T, nicon_state = "[nd1]-[nd2]")
		SC.add_fingerprint()

/obj/item/stack/radio_cable/proc/put_cable(turf/simulated/F, mob/user, d1, d2)
	if(!istype(F))
		return

	var/obj/structure/supply_cable/C = new(F, nicon_state = "[d1]-[d2]")
	C.add_fingerprint(user)

// *** HUB ***
/obj/structure/supply_hub
	name = "Supply HUB"
	desc = "This HUB relays all received signals to command. Do not tamper."
	icon = 'icons/placeholders/comm_tower.dmi'
	icon_state = "comm_tower"
	anchored = 1
	var/datum/radionet/radionet

// *** NET ***
/datum/radionet
	//we only save radios and hubs cause what the fuck would we even do with cables
	var/cables = 0
	var/list/radios = list()
	var/list/hubs = list()

//only need an add_cable cause we do a new net anyways whenever one gets removed
/datum/radionet/proc/add_cable(var/obj/structure/supply_cable/C)
	C.radionet = src
	cables++

/datum/radionet/proc/add_radio(var/obj/machinery/computer/supply/R)
	R.radionet = src
	radios += R
	//fluff message about radiooperator coming online

/datum/radionet/proc/remove_radio(var/obj/machinery/computer/supply/R)
	R.radionet = null
	radios -= R
	//fluff message about loosing connection to radiooperator

/datum/radionet/proc/add_hub(var/obj/structure/supply_hub/H)
	H.radionet = src
	hubs += H

/datum/radionet/proc/remove_hub(var/obj/structure/supply_hub/H)
	H.radionet = null
	hubs -= H

/datum/radionet/proc/notifyRadios(var/message)
	for(var/obj/machinery/computer/supply/R in radios)
		R.visible_message("[message]")

/datum/radionet/proc/readout(var/mob/user)
	to_chat(user, "=== Radionet readout ===")
	to_chat(user, "Cables: [cables]")
	to_chat(user, "Radio: [radios.len]")
	to_chat(user, "HUBs: [hubs.len]")