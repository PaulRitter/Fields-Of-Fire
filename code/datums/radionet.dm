// HOW DO ADD NEW TYPES TO THE NETWORK
// (WE CAN'T USE AN UNIVERSAL SUBTYPE SINCE WE ARE USING COMPUTERS AND STRUCTURES)
// 1. add logic on how it will connect in /obj/structure/radio_cable/get_connections
// 2. add logic on how to add it to the network in /obj/structure/radio_cable/propagateRadionet
// 3. if you want the network to be redone when something gets placed, check for a cable underneath and call propagateRadionet on it

/*
>      1 
>      |
>  8 - 0 - 4
>      | 
>      2 
*/

// *** STRUCTURE ***
/obj/structure/radio_cable
	name = "radio cable"
	desc = "A heavy cable for transmitting radio signals. Nearly indestructable."
	icon = 'icons/FoF/radio_cable.dmi'
	icon_state = "0-1"
	level = 1
	anchored = 1
	var/d1 = 0
	var/d2 = 1

	var/datum/radionet/radionet //to see if we actually have a proper connection
	var/inactive = FALSE

	plane = ABOVE_TURF_PLANE
	layer = ABOVE_TILE_LAYER

	color = COLOR_BROWN_ORANGE

/obj/structure/radio_cable/New()
	. = ..()

	// ensure d1 & d2 reflect the icon_state for entering and exiting cable
	var/dash = findtext(icon_state, "-")
	d1 = text2num( copytext( icon_state, 1, dash ) )
	d2 = text2num( copytext( icon_state, dash + 1 ) )

	propagateRadionet()

/obj/structure/radio_cable/Destroy()
	inactive = TRUE
	var/list/newRNs = list()

	for(var/obj/structure/radio_cable/C in get_connections())
		if(!(C.radionet in newRNs)) //did we already propagate over this one? optimization, this wouldn't produce errors but just prevents unneeded propagations
			newRNs += propagateRadionet(source = C)

	. = ..()

/obj/structure/radio_cable/update_icon()
	icon_state = "[d1]-[d2]"

/obj/structure/radio_cable/proc/get_connections()
	. = list()
	var/turf/T

	// Handle standard cables in adjacent turfs
	for(var/cable_dir in list(d1, d2))
		if(cable_dir == 0)
			continue
		var/reverse = GLOB.reverse_dir[cable_dir]
		T = get_step(src, cable_dir)
		if(T)
			for(var/obj/structure/radio_cable/C in T)
				if(C.d1 == reverse || C.d2 == reverse)
					. += C

	// Handle cables on the same turf as us
	for(var/obj/structure/radio_cable/C in loc)
		if(C == src)
			continue

		if(C.d1 == d1 || C.d2 == d1 || C.d1 == d2 || C.d2 == d2) // if either of C's d1 and d2 match either of ours
			. += C

	for(var/obj/O in loc)
		if((istype(O, /obj/machinery/computer/supply) || istype(O , /obj/structure/radio_hub) || istype(O, /obj/structure/receipt_printer)) && (O.loc == loc))
			. += O

//explosion handling
/obj/structure/radio_cable/ex_act(severity)
	switch(severity)
		if(1.0)
			if (prob(50))
				qdel(src)
				gibs(loc, null, /obj/effect/gibspawner/robot)
		if(2.0)
			if(prob(25))
				qdel(src)
				gibs(loc, null, /obj/effect/gibspawner/robot)

/obj/structure/radio_cable/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/stack/radio_cable))
		var/obj/item/stack/radio_cable/coil = W
		if (coil.get_amount() < 1)
			to_chat(user, "Not enough cable")
			return
		coil.cable_join(src, user)

	src.add_fingerprint(user)

//Telekinesis has no effect on a cable
/obj/structure/radio_cable/attack_tk(mob/user)
	return

/obj/structure/radio_cable/proc/propagateRadionet(var/datum/radionet/RN = new (), var/obj/source = null) //source override
	var/list/worklist = list()
	var/list/found_radios = list()
	var/list/found_hubs = list()
	var/list/found_printers = list()
	var/index = 1

	worklist += source ? source : src //start propagating from the passed object

	while(index <= worklist.len)
		var/obj/P = worklist[index] //get the next power object found
		index++

		if(istype(P, /obj/structure/radio_cable))
			var/obj/structure/radio_cable/C = P

			if (!C.inactive)
				if(C.radionet != RN)
					RN.add_cable(C)
					C.radionet = RN
				worklist |= C.get_connections()
		else if(P.anchored && istype(P, /obj/machinery/computer/supply) && !(P in found_radios))
			var/obj/machinery/computer/supply/R = P
			if(R.radionet != RN)
				RN.add_radio(R)
				R.radionet = RN
			found_radios |= R
		else if(P.anchored && istype(P, /obj/structure/radio_hub) && !(P in found_hubs))
			var/obj/structure/radio_hub/H = P
			if(H.radionet != RN) 
				RN.add_hub(H)
				H.radionet = RN
			found_hubs |= H
		else if(P.anchored && istype(P, /obj/structure/receipt_printer) && !(P in found_printers))
			var/obj/structure/receipt_printer/R = P
			if(R.radionet != RN)
				RN.add_printer(R)
				R.radionet = RN
			found_printers |= R

	return RN

// *** INHAND ***
/obj/item/stack/radio_cable
	name = "radio cable coil"
	icon = 'icons/obj/power.dmi'
	icon_state = "coil"
	randpixel = 2
	amount = 10
	max_amount = 10
	color = COLOR_BROWN_ORANGE
	desc = "A coil of radio cable."
	singular_name = "cable"
	throwforce = 10
	w_class = ITEM_SIZE_HUGE
	throw_speed = 1
	throw_range = 1
	matter = list(DEFAULT_WALL_MATERIAL = 50, "glass" = 20)
	flags = CONDUCT
	slot_flags = SLOT_BELT
	item_state = "coil"
	slowdown_general = 5

/obj/item/stack/radio_cable/proc/turf_place(turf/simulated/F, mob/user)
	if(!isturf(user.loc))
		return

	if(get_amount() < 1) // Out of cable
		to_chat(user, "There is no cable left.")
		return

	if(get_dist(F,user) > 1) // Too far
		to_chat(user, "You can't lay cable that far away from yourself.")
		return

	var/dirn
	if(user.loc == F)
		dirn = user.dir			// if laying on the tile we're on, lay in the direction we're facing
	else
		dirn = get_dir(F, user)

	if(dirn & (dirn - 1)) //no diagonal stuff
		to_chat(user, "You can't lay a cable at that angle.")
		return

	var/end_dir = 0
	for(var/obj/structure/radio_cable/RC in F)
		to_chat(user, "<span class='warning'>There's already a cable at that position.</span>")
		return

	put_cable(F, user, end_dir, dirn)

//called when radio_cable is clicked on a obj/structure/radio_cable
/obj/item/stack/radio_cable/proc/cable_join(obj/structure/radio_cable/C, mob/user)
	var/turf/U = user.loc
	if(!isturf(U))
		return

	var/turf/T = C.loc

	if(get_dist(C, user) > 1)		// make sure it's close enough
		to_chat(user, "You can't lay cable that far away from yourself.")
		return

	if(U == T) //if clicked on the turf we're standing on, try to put a cable in the direction we're facing
		turf_place(T, user)
		return

	var/dirn = get_dir(C, user)

	if(dirn & (dirn - 1))
		to_chat(user, "You can't lay a cable at that angle.")
		return

	// one end of the clicked cable is pointing towards us
	if(C.d1 == dirn || C.d2 == dirn)
		// cable is pointing at us, we're standing on an open tile
		// so create a stub pointing at the clicked cable on our tile

		var/fdirn = GLOB.reverse_dir[dirn]		// the opposite direction

		for(var/obj/structure/radio_cable/RC in U)		// check to make sure there's not a cable there already
			if(RC.d1 == fdirn || RC.d2 == fdirn)
				to_chat(user, "There's already a cable at that position.")
				return

		put_cable(U, user, 0, fdirn)
		return
	// existing cable doesn't point at our position, so see if it's a stub
	else if(C.d1 == 0)
		// if so, make it a full cable pointing from it's old direction to our dirn
		var/nd1 = C.d2	// these will be the new directions
		var/nd2 = dirn

		if(nd1 > nd2)		// swap directions to match icons/states
			nd1 = dirn
			nd2 = C.d2

		for(var/obj/structure/radio_cable/RC in T)		// check to make sure there's no matching cable
			if(RC == C)			// skip the cable we're interacting with
				continue

			if((RC.d1 == nd1 && RC.d2 == nd2) || (RC.d1 == nd2 && RC.d2 == nd1) )	// make sure no cable matches either direction
				to_chat(user, "There's already a cable at that position.")
				return

		C.d1 = nd1
		C.d2 = nd2

		C.update_icon()

		var/datum/radionet/RN = null
		for (var/obj/structure/radio_cable/con in C.get_connections())
			if (con.radionet)
				RN = con.radionet
				break

		if (RN)
			C.propagateRadionet(RN)
		else
			C.propagateRadionet()

/obj/item/stack/radio_cable/proc/put_cable(turf/simulated/F, mob/user, d1, d2)
	if(!istype(F))
		return

	var/obj/structure/radio_cable/C
	var/create = TRUE
	for (var/obj/structure/radio_cable/RC in F)
		RC.d1 = d2
		if (RC.d2 < RC.d1)
			var/temp = RC.d2
			RC.d2 = RC.d1
			RC.d1 = temp
		RC.update_icon()
		C = RC
		create = FALSE

	if (create)
		C = new(F)
		C.d1 = d1
		C.d2 = d2
		C.add_fingerprint(user)
		C.update_icon()

		use(1)

	var/datum/radionet/RN = null
	for (var/obj/structure/radio_cable/con in C.get_connections())
		if (con.radionet)
			RN = con.radionet
			break

	if (RN)
		C.propagateRadionet(RN)
	else
		C.propagateRadionet()

// *** NET ***
/datum/radionet
	//we only save radios and hubs cause what the fuck would we even do with cables
	var/cables = 0
	var/list/radios = list()
	var/obj/structure/radio_hub/hub
	var/list/printers = list()

//only need an add_cable cause we do a new net anyways whenever one gets removed
/datum/radionet/proc/add_cable(var/obj/structure/radio_cable/C)
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

/datum/radionet/proc/add_hub(var/obj/structure/radio_hub/H)
	H.radionet = src
	hub = H

/datum/radionet/proc/remove_hub(var/obj/structure/radio_hub/H)
	H.radionet = null
	hub = null

/datum/radionet/proc/add_printer(var/obj/structure/receipt_printer/R)
	R.radionet = src
	printers += R

/datum/radionet/proc/remove_printer(var/obj/structure/receipt_printer/R)
	R.radionet = null
	printers -= R

/datum/radionet/proc/notifyRadios(var/message)
	for(var/obj/machinery/computer/supply/R in radios)
		R.visible_message("[message]")

/datum/radionet/proc/readout(var/mob/user)
	to_chat(user, "=== Radionet readout ===")
	to_chat(user, "Cables: [cables]")
	to_chat(user, "Radio: [radios.len]")
	to_chat(user, "Printers: [printers.len]")
	to_chat(user, "HUB: [hub ? "YES" : "NO"]")