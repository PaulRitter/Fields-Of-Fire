/obj/structure/closet/crate/small
	icon_state = "crate"
	icon_opened = "crate_open"
	icon_closed = "crate"

/obj/structure/supply_truck
	name = "Supply Truck"
	icon = 'icons/FoF/trucks.dmi'
	icon_state = "cargo_truck"
	anchored = 1
	density = 1
	plane = ABOVE_HUMAN_PLANE
	layer = ABOVE_HUMAN_LAYER
	bound_width = 6 * WORLD_ICON_SIZE
	bound_height = 2 * WORLD_ICON_SIZE

	contents = list()

	var/allowedTypes = list( //place subtypes before parenttypes
		/obj/structure/closet/crate/small = 0.5, //like this
		/obj/structure/closet/crate = 1,
		/obj/structure/reagent_dispensers/fueltank = 2
	)// /type = size(0<size<2)
	// this allows floatingpoint numbers
	var/list/_using = list() //all the people fucking with us

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
	var/modifier = 1.5
	//so we can update our images
	var/list/truck_images = list()
	var/image/foreground = null

	var/direction = EAST
	

/obj/structure/supply_truck/examine(mob/user, distance, infix, suffix)
	if(contents.len)
		var/txt_cont = jointext(getGroupedContentList(),"\n - ")
		to_chat(user, "Contents:\n - [txt_cont].") //byond gets all errory when I put it inside the string
	else
		to_chat(user, "\the [src] is empty")

/obj/structure/supply_truck/proc/toggleDirection()
	var/icon/I = new(src.icon)
	I.Flip(direction == EAST ? WEST : EAST)
	src.icon = I
	start_pixel_x = direction == EAST ? 2 : 2.65
	step_pixel_x = -step_pixel_x
	direction = direction == EAST ? WEST : EAST

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

	if(istype(A, /obj/structure/closet))
		var/obj/structure/closet/C = A
		if(C.opened)
			to_chat(user, "<span class='notice'>\the [A] needs to be closed!</span>")
			return 0

	if(user in _using)
		to_chat(user, "<span class='notice'>You are already interacting with \the [src]!</span>")
		return

	_using += user
	user.visible_message("<span class='notice'>[user] starts putting \the [A] into \the [src]</span>")
	to_chat(user, "<span class='notice'>You start to put \the [A] into \the [src]")
	if(do_after(user, 5 SECONDS, src, over_user = TRUE))
		A.forceMove(src)
		user.visible_message("<span class='notice'>[user] finishes putting \the [A] into \the [src]</span>")
		to_chat(user, "<span class='notice'>You finish putting \the [A] into \the [src]")
		update_icon()
		_using -= user
		return 1
	_using -= user
	return 0

/obj/structure/supply_truck/proc/unload(var/mob/user)
	if(!contents.len)
		to_chat(user, "<span class='notice'>\the [src] is empty.</span>")
		return 0

	if(user in _using)
		to_chat(user, "<span class='notice'>You are already interacting with \the [src]!</span>")
		return

	//take the last atom of the list and give it to our mob
	var/atom/movable/A = contents[contents.len]
	contents.len--
	_using += user
	user.visible_message("<span class='notice'>[user] starts to pull \the [A] out of \the [src]</span>")
	to_chat(user, "<span class='notice'>You start to pull \the [A] out of \the [src]")
	if(do_after(user, 5 SECONDS, src, over_user = TRUE))
		A.forceMove(get_turf(user))
		user.visible_message("<span class='notice'>[user] pulls \the [A] out of \the [src]</span>")
		to_chat(user, "<span class='notice'>You successfully pull \the [A] out of \the [src]")
		update_icon()
		_using -= user
		return 1
	else
		contents += A
	_using -= user
	return 0

/obj/structure/supply_truck/proc/hasSpace(var/num)
	var/remainingSize = getSpace()
	for(var/atom/A in contents)
		remainingSize -= getSize(A)
	return (remainingSize >= num)

/obj/structure/supply_truck/proc/getSpace()
	return maxX * maxY * maxZ

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
	var/y = maxY - 1
	var/z = 0

	var/list/renderOrder = getWeightedContentList(direction == WEST)
	var/list/alreadyRendered = list()

	for(var/atom/A in renderOrder)
		if(!getSize(A))
			continue

		var/index = "\ref[A]"
		if(!(index in temp_images))
			temp_images[index] = image(A.icon, A.icon_state)

		var/image/I = temp_images[index]
		var/doBreak = FALSE
		var/alreadyLooped = FALSE

		while(skipCoords(x, y, z, alreadyRendered, getSize(A)))
			var/nextPos = nextPos(x, y, z)
			x = nextPos[1]
			y = nextPos[2]
			z = nextPos[3]

			if(z >= maxZ)
				if(!alreadyLooped)
					x = 0
					y = maxY - 1
					z = 0
					alreadyLooped = TRUE
				else
					doBreak = TRUE
					break

		if(doBreak || (z >= maxZ))
			message_admins("Had to force renderbreak in supply truck contents renderer! This should not have happened! Take a pic of the content-var of the truck and send it to a dev. <A HREF='?_src_=vars;Vars=\ref[src]'>\[VV\]</A>")
			break

		var/man_y = y + (getPosSize(x, y, z, alreadyRendered) / modifier) //for half boxes
		I.pixel_x = (start_pixel_x * WORLD_ICON_SIZE) + (x * (step_pixel_x * WORLD_ICON_SIZE))
		I.pixel_y = (start_pixel_y * WORLD_ICON_SIZE) + (man_y * (step_pixel_y * WORLD_ICON_SIZE)) + (z * (step_pixel_z * WORLD_ICON_SIZE))
		
		alreadyRendered[++alreadyRendered.len] = list(x, y, z, getSize(A)) //for skipCoords

		var/nextPos = nextPos(x, y, z)
		x = nextPos[1]
		y = nextPos[2]
		z = nextPos[3]

		truck_images += I

	overlays |= truck_images

	if(!foreground)
		var/icon/I = icon('icons/FoF/trucks.dmi', "cargo_truck-cover")
		if(direction == WEST)
			I.Flip(direction == EAST ? WEST : EAST)

		foreground = image(I)

	overlays |= foreground

/obj/structure/supply_truck/proc/getPosSize(var/x, var/y, var/z, var/list/already_rendered)
	var/sum = 0
	for(var/list/R in already_rendered)
		if((x == R[1]) && (y == R[2]) && (z == R[3]))
			sum += R[4]
			
	return sum

/obj/structure/supply_truck/proc/skipCoords(var/x, var/y, var/z, var/list/already_rendered, var/size)
	var/base = 0
	for(var/list/R in already_rendered)
		if((x == R[1]) && (y == R[2]))
			if(z == R[3]) //this is our position
				if((getPosSize(x, y, z, already_rendered)+size) <= 1) //check if we can fit ontop of the already existing obj
					return 0
				else //we can't
					return 1
			else if((z == (R[3]+1)) && (((getPosSize(x, y, z-1, already_rendered) + size) <= 2) && (getPosSize(x, y, z-1, already_rendered) >= 1))) //check if there is a filled pos underneath and if we fit on it
				base = 1 //this could be invalid due to something already occupying our pos that wasn't looped over yet, so we prospone the return to after the loop, since it will end if our pos is full

	if(base)
		return 0 

	if(z == 0)
		return 0
	else
		return 1

/obj/structure/supply_truck/proc/getSize(var/typepath)
	if(!typepath)
		return 0

	for(var/type in allowedTypes)
		if(istype(typepath, type))
			return allowedTypes[type]

	return 0 //if it got added but we don't know it, it'll probably fuck up the renderer, so we let it ignore it using this

//use this to determine if something can be added too
//basic desc bubblesort, since we want to render the biggest objs first
/obj/structure/supply_truck/proc/getWeightedContentList(var/reverse = FALSE)
	var/list/L = contents.Copy()
	for(var/atom/A in L)
		for(var/i = 1; i < L.len; i++)
			if(getSize(L[i]) < getSize(L[i + 1]))
				var/atom/T = L[i]
				L[i] = L[i + 1]
				L[i + 1] = T

	return L

/obj/structure/supply_truck/proc/nextPos(var/x, var/y, var/z)
	if(y > 0)
		y--
	else
		x++
		y = maxY - 1

	if(x == maxX)
		x = 0
		y = maxY - 1
		z++

	return list(x, y, z)

/obj/structure/supply_truck/proc/getGroupedContentList()
	var/list/L = list()
	for(var/atom/A in contents)
		L[A.name]++
	
	. = list()
	for(var/A in L)
		var/string = "[A]"
		if(L[A] > 1)
			string += " x[L[A]]"
		. += string