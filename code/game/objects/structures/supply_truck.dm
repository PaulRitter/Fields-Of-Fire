/obj/structure/closet/crate/small
	icon_state = "crate"

/obj/structure/supply_truck
	name = "Supply Truck"
	icon = 'icons/placeholders/truck.dmi'
	icon_state = "truck-placeholder"
	anchored = 1
	density = 1
	plane = ABOVE_HUMAN_PLANE
	layer = ABOVE_HUMAN_LAYER
	bound_width = 6 * WORLD_ICON_SIZE
	bound_height = 2 * WORLD_ICON_SIZE

	var/allowedTypes = list(
		/obj/structure/closet/crate/small = 0.5,
		/obj/structure/closet/crate = 1,
		/obj/structure/reagent_dispensers/fueltank = 2
	)// /type = size(0<size<2)

	//vars for the overlay rendering
	//the starting point of the crate rendering, basically crate (0,0)
	var/start_pixel_x = 2.65
	var/start_pixel_y = 0.6
	//the x and y steps for crate rendering
	var/step_pixel_x = 0.95
	var/step_pixel_y = 0.45
	var/step_pixel_z = 0.3
	//rendering limits
	var/maxX = 3
	var/maxY = 2
	var/maxZ = 2
	//so we can update our images
	var/list/truck_images = list()
	var/image/foreground = null

/obj/structure/supply_truck/examine(mob/user, distance, infix, suffix)
	if(contents.len)
		var/txt_cont = jointext(contents,", ")
		to_chat(user, "Currently loaded are [txt_cont].") //byond gets all errory when put it inside the string
	else
		to_chat(user, "It is currently empty")

/obj/structure/supply_truck/proc/sanityCheck(var/mob/user)
	if(Adjacent(user))
		return 0
	return 1

/obj/structure/supply_truck/attack_hand(var/mob/user)
	if(sanityCheck(user))
		return 0
	return unload(user)

/obj/structure/supply_truck/MouseDrop_T(var/atom/movable/dropping, var/mob/user)
	if(sanityCheck(user))
		return 0
	return load(dropping, user)

/obj/structure/supply_truck/proc/load(var/atom/movable/A, var/mob/user)
	if(!is_type_in_list(A, allowedTypes))
		to_chat(user, "<span class='notice'>\the [A] cannot be shipped</span>")
		return 0

	if(!hasSpace(getSize(A)))
		to_chat(user, "<span class='notice'>\the [A] doesn't fit!</span>")
		return 0

	user.visible_message("<span class='notice'>[user] starts putting \the [A] into \the [src]</span>")
	to_chat(user, "<span class='notice'>You start to put \the [A] into \the [src]")
	if(do_after(user, 5 SECONDS, src, progress = 2))
		A.forceMove(src)
		user.visible_message("<span class='notice'>[user] finishes putting \the [A] into \the [src]</span>")
		to_chat(user, "<span class='notice'>You finish putting \the [A] into \the [src]")
		update_icon()
		return 1
	return 0

/obj/structure/supply_truck/proc/unload(var/mob/user)
	if(!contents.len)
		to_chat(user, "<span class='notice'>The Truck is empty.</span>")
		return 0

	//take the last atom of the list and give it to our mob
	var/atom/movable/A = contents[contents.len]
	user.visible_message("<span class='notice'>[user] starts to pull \the [A] out of \the [src]</span>")
	to_chat(user, "<span class='notice'>You start to pull \the [A] out of \the [src]")
	if(do_after(user, 5 SECONDS, src, progress = 2))
		A.forceMove(get_turf(user))
		user.visible_message("<span class='notice'>[user] pulls \the [A] out of \the [src]</span>")
		to_chat(user, "<span class='notice'>You successfully pull \the [A] out of \the [src]")
		update_icon()
		return 1
	return 0

/obj/structure/supply_truck/proc/hasSpace(var/num)
	var/remainingSize = maxX * maxY * maxZ
	for(var/atom/A in contents)
		remainingSize -= getSize(A)
	return (remainingSize >= num)

//rendering the crates ontop of the truck
//render order:
// 1 3 5
// 2 4 6
// z_order: asc
// bigger items (fueltank) will take up two z-levels and hence block some positions, which will in turn manipulate the rendering order
// 
/obj/structure/supply_truck/update_icon()
	. = ..()
	overlays -= truck_images	
	var/list/temp_images = truck_images.Copy()
	truck_images.len = 0

	overlays -= foreground

	var/x = 0
	var/y = maxY-1
	var/z = 0
	var/list/renderOrder = getWeightedContentList()
	var/list/alreadyRendered = list()
	for(var/atom/A in renderOrder)
		message_admins("=== started rendering [A] ===")
		var/index = "\ref[A]"
		if(!(index in temp_images))
			temp_images[index] = image(A.icon, A.icon_state)
		var/image/I = temp_images[index]
		var/doBreak = 0
		var/alreadyLooped = 0
		while(skipCoords(x,y,z,alreadyRendered,getSize(A)))
			message_admins("skipping pos [x],[y],[z]")
			var/nextPos = nextPos(x, y, z)
			x = nextPos[1]
			y = nextPos[2]
			z = nextPos[3]
			message_admins("next pos [x],[y],[z]")

			if(z >= maxZ)
				if(!alreadyLooped)
					x = 0
					y = maxY-1
					z = 0
					alreadyLooped = 1
				else
					doBreak = 1 
					break

		if(doBreak)
			message_admins("had to force renderbreak! this should not have happened")
			break

		message_admins("creating icon at [x],[y],[z]")
		var/man_y = y + getPosSize(x, y, z, alreadyRendered) //for half boxes
		message_admins("manipulated y: [man_y]")
		I.pixel_x = (start_pixel_x * WORLD_ICON_SIZE) + (x * (step_pixel_x * WORLD_ICON_SIZE))
		I.pixel_y = (start_pixel_y * WORLD_ICON_SIZE) + (man_y * (step_pixel_y * WORLD_ICON_SIZE)) + (z * (step_pixel_z * WORLD_ICON_SIZE))
		
		alreadyRendered[++alreadyRendered.len] = list(x, y, z, getSize(A)) //for skipCoords

		var/nextPos = nextPos(x, y, z)
		x = nextPos[1]
		y = nextPos[2]
		z = nextPos[3]
		message_admins("next pos [x],[y],[z]")

		truck_images += I
		message_admins("=== finished rendering [A] ===")

	message_admins("finished rendering")
	overlays |= truck_images

	if(!foreground)
		foreground = image('icons/placeholders/truck.dmi', "truck-placeholder foreground")
	overlays |= foreground

/obj/structure/supply_truck/proc/getPosSize(var/x, var/y, var/z, var/list/already_rendered)
	var/sum = 0
	for(var/list/R in already_rendered)
		message_admins("query [x],[y],[z]")
		message_admins("quest [R[1]],[R[2]],[R[3]]")
		if((x == R[1]) && (y == R[2]) && (z == R[3]))
			message_admins("add [R[4]]")
			sum += R[4]
	message_admins("returning: [sum]")
	return sum

/obj/structure/supply_truck/proc/skipCoords(var/x, var/y, var/z, var/list/already_rendered, var/size)
	for(var/list/R in already_rendered)
		message_admins("comparing [x],[y],[z]")
		message_admins("with      [R[1]],[R[2]],[R[3]]")
		if((x == R[1]) && (y == R[2]))
			if(z == R[3]) //this is our position
				if((getPosSize(x, y, z, already_rendered)+size) <= 1) //check if we can fit ontop of the already existing obj
					message_admins("skipCoords: ([x],[y],[z]) we fit on another obj")
					return 0
				else //we can't
					message_admins("skipCoords: ([x],[y],[z]) another obj is occupying")
					return 1
			else if((z == (R[3]+1)) && (getPosSize(x, y, z-1, already_rendered) == 1)) //check if there is a filled pos underneath
				message_admins("skipCoords: ([x],[y],[z]) there is a pos underneath, we are good to go")
				return 0

	if(z == 0)
		message_admins("skipCoords: ([x],[y],[z]) no entry found and z == 0")
		return 0
	else
		message_admins("skipCoords: ([x],[y],[z]) no entry found and z != 0")
		return 1

/obj/structure/supply_truck/proc/getSize(var/atom/A)
	if(!A)
		return 0

	for(var/type in allowedTypes)
		if(istype(A, type))
			message_admins("getting size [allowedTypes[type]]")
			return allowedTypes[type]

	return 1

//use this to determine if something can be added too
//basic desc bubblesort, since we want to render the biggest objs first
/obj/structure/supply_truck/proc/getWeightedContentList()
	var/list/L = contents.Copy()
	for(var/atom/A in L)
		for(var/i = 1; i < L.len; i++)
			if(getSize(L[i]) < getSize(L[i+1]))
				var/atom/T = L[i]
				L[i] = L[i+1]
				L[i+1] = T
	message_admins("returning ordered list ([L.len])")
	return L

/obj/structure/supply_truck/proc/nextPos(var/x, var/y, var/z)
	if(y > 0)
		y--
	else
		x++
		y = maxY-1

	if(x == maxX)
		x = 0
		y = maxY-1
		z++

	return list(x, y, z)