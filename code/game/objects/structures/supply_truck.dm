/obj/structure/supply_truck
	name = "Supply Truck"
	icon = 'icons/placeholders/truck.dmi'
	icon_state = "truck-placeholder"
	anchored = 1
	density = 1
	plane = ABOVE_HUMAN_PLANE
	layer = ABOVE_HUMAN_LAYER
	var/maxContents = 12
	bound_width = 6 * WORLD_ICON_SIZE
	bound_height = 2 * WORLD_ICON_SIZE

	//vars for the overlay rendering
	//the starting point of the crate rendering, basically crate (0,0)
	var/start_pixel_x = 2.65
	var/start_pixel_y = 0.6
	//the x and y steps for crate rendering
	var/step_pixel_x = 0.95
	var/step_pixel_y = 0.45
	var/step_pixel_z = 0.5
	//rendering limits
	var/maxX = 3
	var/maxY = 2
	var/maxZ = 2
	//so we can update our images
	var/list/truck_images = list()

//rendering the crates ontop of the truck
//save all possible positions truck_images[z][x][y] = null
//helper getAvailablePositions(), since some may only be available through stacking, returns list(x,y,z)
// pick() and set address in truck_images to image
/obj/structure/supply_truck/update_icon()
	. = ..()
	overlays -= truck_images
	truck_images.len = 0
	var/x = 0
	var/y = maxY-1
	var/z = 0
	for(var/atom/content in contents)
		var/image/I = image(content.icon, content.icon_state)
		message_admins("creating crate at [x],[y],[z]")
		I.pixel_x = (start_pixel_x * WORLD_ICON_SIZE) + (x * (step_pixel_x * WORLD_ICON_SIZE))
		I.pixel_y = (start_pixel_y * WORLD_ICON_SIZE) + (y * (step_pixel_y * WORLD_ICON_SIZE)) + (z * (step_pixel_z * WORLD_ICON_SIZE))
		if(y > 0)
			y--
		else
			x++
			y = maxY-1

		if(x == maxX)
			x = 0
			y = maxY-1
			z++

		truck_images += I
	
	truck_images += image('icons/placeholders/truck.dmi', "truck-placeholder foreground")
	
	overlays |= truck_images

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
	if(sanityCheck(user) || !istype(dropping, /obj/structure/closet/crate))
		return 0
	return load(dropping, user)

/obj/structure/supply_truck/proc/load(var/atom/movable/A, var/mob/user)
	if(contents.len >= maxContents)
		to_chat(user, "<span class='notice'>The Truck is already full!</span>")
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