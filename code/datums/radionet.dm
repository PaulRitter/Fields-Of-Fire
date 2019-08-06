// HOW DO ADD NEW TYPES TO THE NETWORK
// (WE CAN'T USE AN UNIVERSAL SUBTYPE SINCE WE ARE USING COMPUTERS AND STRUCTURES)
// 1. add logic on how it will connect in /obj/structure/radio_cable/get_connections
// 2. add logic on how to add it to the network in /obj/structure/radio_cable/propagateRadionet
// 3. if you want the network to be redone when something gets placed, check for a cable underneath and call propagateRadionet on it

/*
>  9   1   5
>    \ | /
>  8 - 0 - 4
>    / | \
>  10  2   6
*/

// *** STRUCTURE ***
/obj/structure/radio_cable
	level = 1
	anchored = 1
	var/datum/radionet/radionet //to see if we actually have a proper connection
	var/inactive = FALSE
	name = "Radio cable"
	desc = "A heavy cable for transmitting radio signals. Nearly indestructable."
	icon = 'icons/FoF/radio_cable.dmi'
	icon_state = "cable"

	plane = ABOVE_TURF_PLANE
	layer = ABOVE_TILE_LAYER

	color = COLOR_BROWN_ORANGE

/obj/structure/radio_cable/New()
	..()
	// ensure d1 & d2 reflect the icon_state for entering and exiting cable
	var/dash = findtext(icon_state, "-")
	d1 = text2num( copytext( icon_state, 1, dash ) )
	d2 = text2num( copytext( icon_state, dash+1 ) )

	propagateRadionet()

/obj/structure/radio_cable/Destroy()
	var/list/connectedThings = get_connections()
	inactive = TRUE
	var/list/newRNs = list()
	for(var/A in connectedThings)
		if(istype(A, /obj/structure/radio_cable))
			var/obj/structure/radio_cable/C = A
			if(!(C.radionet in newRNs)) //did we already propagate over this one? optimization, this wouldn't produce errors but just prevents unneeded propagations
				var/datum/radionet/RN = new ()
				propagateRadionet(RN, C)
				newRNs += RN
	. = ..()

/obj/structure/radio_cable/proc/get_dirs()
	if(icon_state == "cable_end")
		return list(GLOB.reverse_dir[dir])

	if(dir & (dir - 1)) //we are diagonal
		return list(turn(dir, 45), turn(dir, -45))
	else //we're straight
		return list(dir, GLOB.reverse_dir[dir])

/obj/structure/radio_cable/proc/get_connections()
	. = list()
	var/list/dirs = get_dirs()

	for(var/cable_dir in dirs)
		var/turf/step = get_step(loc, cable_dir)
		for(var/atom/AM in step)
			if(isConnected(AM))
				. += AM
	
	for(var/atom/AM in loc)
		if(isConnected(AM))
			. += AM

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
/obj/structure/radio_cable/attack_tk(mob/user)
	return

/obj/structure/radio_cable/proc/isConnected(var/obj/O)
	if(!O)
		return 0
	if(!O.loc)
		return 0
	if(O == src)
		return 0

	var/dist = get_dist(loc, O.loc)
	if(istype(O, /obj/structure/radio_cable))
		var/obj/structure/radio_cable/SC = O
		if(SC.inactive)
			return 0
		if((SC.icon_state == "cable_end") && (SC.loc == loc))
			return 1
		var/dirn = get_dir(src, SC)
		if(dist == 1 && !(dirn & (dirn - 1))) //next to us in a cardinal dir
			var/mydir = (icon_state == "cable_end") ? dir : GLOB.reverse_dir[dir]
			var/scdir = (SC.icon_state == "cable_end") ? GLOB.reverse_dir[SC.dir] : SC.dir
			if(mydir & scdir)
				return 1
	
	if((istype(O, /obj/machinery/computer/supply) || istype(O , /obj/structure/radio_hub) || istype(O, /obj/structure/receipt_printer)) && (O.loc == loc))
		return 1

	return 0

/obj/structure/radio_cable/proc/propagateRadionet(var/datum/radionet/RN = new (), var/obj/source) //source override
	var/list/worklist = list()
	var/list/found_radios = list()
	var/list/found_hubs = list()
	var/list/found_printers = list()
	var/index = 1

	worklist+= source ? source : src //start propagating from the passed object

	while(index<=worklist.len)
		var/obj/P = worklist[index] //get the next power object found
		index++

		if(istype(P,/obj/structure/radio_cable))
			var/obj/structure/radio_cable/C = P
			if(C.radionet != RN)
				RN.add_cable(C)
			worklist |= C.get_connections()
		else if(P.anchored && istype(P,/obj/machinery/computer/supply) && !(P in found_radios))
			var/obj/machinery/computer/supply/R = P
			if(R.radionet != RN)
				RN.add_radio(R)
			found_radios |= R
		else if(P.anchored && istype(P, /obj/structure/radio_hub) && !(P in found_hubs))
			var/obj/structure/radio_hub/H = P
			if(H.radionet != RN) 
				RN.add_hub(H)
			found_hubs |= H
		else if(P.anchored && istype(P, /obj/structure/receipt_printer) && !(P in found_printers))
			var/obj/structure/receipt_printer/R = P
			if(R.radionet != RN)
				RN.add_printer(R)
			found_printers |= R

/obj/structure/radio_cable/AltClick(mob/user)
	. = ..()
	to_chat(user, "=== \ref[src] ===")
	to_chat(user, "RN: \ref[radionet]")
	to_chat(user, "Connections:")
	for(var/atom/con in get_connections())
		to_chat(user, "- [con] <A HREF='?_src_=vars;Vars=\ref[con]'>\[VV\]</A>: [dir2text(get_dir(src, con))]")

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

// called when radio_cable is clicked on a turf/simulated/floor
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
		dirn = get_dir(user, F)

	if(dirn & (dirn - 1)) //no diagonal stuff
		to_chat(user, "You can't lay a cable at that angle.")
		return

	var/complete = FALSE
	var/finaldir = dirn
	var/obj/structure/radio_cable/to_qdel
	for(var/obj/structure/radio_cable/RC in F)
		if(RC.icon_state == "cable_end")
			if(RC.dir == dirn)
				to_chat(user, "There's already a cable at that position.")
				return
			else if(RC.dir != GLOB.reverse_dir[dirn])
				complete = TRUE
				finaldir = GLOB.reverse_dir[(dirn + RC.dir)]
				to_qdel = RC
			else if(RC.dir == GLOB.reverse_dir[dirn])
				complete = TRUE
				finaldir = dirn
				to_qdel = RC
		else if(RC.dir & dirn || ((RC.dir & (RC.dir - 1)) && (GLOB.reverse_dir[RC.dir] & dirn)))
			to_chat(user, "There's already a cable at that position.")
			return

	put_cable(F, user, finaldir, complete)
	qdel(to_qdel)

//called when radio_cable is clicked on a obj/structure/radio_cable
/obj/item/stack/radio_cable/proc/cable_join(obj/structure/radio_cable/C, mob/user)
	var/turf/U = user.loc
	if(!isturf(U))
		return

	var/turf/T = C.loc

	if(!isturf(T))
		return

	if(get_dist(C, user) > 1)		// make sure it's close enough
		to_chat(user, "You can't lay cable at a place that far away.")
		return

	var/dirn = get_dir(C, user)
	if(dirn & (dirn - 1))
		to_chat(user, "You can't lay a cable at that angle.")
		return

	if(U == T || C.icon_state == "cable_end") //if clicked on the turf we're standing on, try to put a cable in the direction we're facing
		turf_place(T,user)
		return

	var/fdirn = GLOB.reverse_dir[dirn] // the opposite direction
	if(C.dir == dirn || C.dir == fdirn)
		// cable is pointing at us, we're standing on an open tile
		// so create a stub pointing at the clicked cable on our tile

		for(var/obj/structure/radio_cable/LC in U)		// check to make sure there's not a cable there already
			if(LC.dir == dirn || LC.dir == fdirn)
				to_chat(user, "There's already a cable at that position.")
				return
		put_cable(U,user,dirn,FALSE)
		return

/obj/item/stack/radio_cable/proc/put_cable(turf/simulated/F, mob/user, dirn, complete)
	if(!istype(F))
		return

	var/obj/structure/radio_cable/C = new(F)
	C.dir = dirn
	if(!complete)
		C.icon_state = "cable_end"
	use(1)
	C.add_fingerprint(user)

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