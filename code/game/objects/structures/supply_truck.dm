/obj/structure/supply_truck
	name = "Supply Truck"
	icon = 'icons/placeholders/truck.dmi'
	icon_state = "truck-placeholder"
	anchored = 1
	density = 1
	plane = ABOVE_HUMAN_PLANE
	layer = ABOVE_HUMAN_LAYER
	var/maxContents = 20
	bound_width = 6 * WORLD_ICON_SIZE
	bound_height = 2 * WORLD_ICON_SIZE
	var/r1_pixel_x = 2.5 * WORLD_ICON_SIZE
	var/r1_pixel_y = 0.5 * WORLD_ICON_SIZE
	var/r2_pixel_x = WORLD_ICON_SIZE
	var/r2_pixel_y = 0.5 * WORLD_ICON_SIZE


/obj/structure/supply_truck/update_icon()
	. = ..()
	if(contents.len > 0)
		var/image/I1 = image(contents[1].icon, contents[1].icon_state)
		var/image/I2 = image(contents[1].icon, contents[1].icon_state)
		var/image/I3 = image(contents[1].icon, contents[1].icon_state)
		var/image/I4 = image(contents[1].icon, contents[1].icon_state)
		I1.pixel_x = r1_pixel_x
		I1.pixel_y = r1_pixel_y
		I2.pixel_x = r1_pixel_x + r2_pixel_x
		I2.pixel_y = r1_pixel_y
		I3.pixel_x = r1_pixel_x
		I3.pixel_y = r1_pixel_y + r2_pixel_y
		I4.pixel_x = r1_pixel_x + r2_pixel_x
		I4.pixel_y = r1_pixel_y + r2_pixel_y
		overlays += I1
		overlays += I2
		overlays += I3
		overlays += I4


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

/obj/structure/supply_truck/attackby(var/obj/item/W, var/mob/user)
	if(sanityCheck(user))
		return 0
	return load(W, user)

/obj/structure/supply_truck/MouseDrop_T(var/atom/movable/dropping, var/mob/user)
	if(sanityCheck(user))
		return 0
	return load(dropping, user)

/obj/structure/supply_truck/proc/load(var/atom/movable/A, var/mob/user)
	if(contents.len >= maxContents)
		to_chat(user, "<span class='notice'>The Truck is already full!</span>")
		return 0

	user.visible_message("<span class='notice'>[user] starts putting \the [A] into \the [src]</span>")
	to_chat(user, "<span class='notice'>You start to put \the [A] into \the [src]")
	if(do_after(user, 5 SECONDS, src, progress = 0))
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
	if(do_after(user, 5 SECONDS, src, progress = 0))
		A.forceMove(get_turf(user))
		user.visible_message("<span class='notice'>[user] pulls \the [A] out of \the [src]</span>")
		to_chat(user, "<span class='notice'>You successfully pull \the [A] out of \the [src]")
		update_icon()
		return 1
	return 0