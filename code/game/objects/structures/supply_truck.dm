/obj/structure/multitile/rectangle/supply_truck
	name = "Supply Truck"
	icon = 'icons/placeholders/truck.dmi'
	icon_state = "truck-placeholder"
	anchored = 1
	density = 1
	plane = ABOVE_HUMAN_PLANE
	layer = ABOVE_HUMAN_LAYER
	var/maxContents = 20
	sizeX = 6
	sizeY = 3

/obj/structure/multitile/rectangle/supply_truck/examine(mob/user, distance, infix, suffix)
	if(contents.len)
		var/txt_cont = jointext(contents,", ")
		to_chat(user, "Currently loaded are [txt_cont].") //byond gets all errory when put it inside the string
	else
		to_chat(user, "It is currently empty")
	

/obj/structure/multitile/rectangle/supply_truck/attack_hand(var/mob/user)
	return unload(user)

/obj/structure/multitile/rectangle/supply_truck/attackby(var/obj/item/W, var/mob/user)
	return load(W, user)

/obj/structure/multitile/rectangle/supply_truck/MouseDrop_T(var/atom/movable/dropping, var/mob/user)
	return load(dropping, user)


/obj/structure/multitile/rectangle/supply_truck/proc/load(var/atom/movable/A, var/mob/user)
	if(contents.len >= maxContents)
		to_chat(user, "<span class='notice'>The Truck is already full!</span>")
		return 0
	
	A.forceMove(src)
	return 1

/obj/structure/multitile/rectangle/supply_truck/proc/unload(var/mob/user)
	if(!contents.len)
		to_chat(user, "<span class='notice'>The Truck is empty</span>")
		return 0

	//take the last atom of the list and give it to our mob
	var/atom/movable/A = contents[contents.len]
	user.visible_message("<span class='notice'>[user] starts to pull \the [A] out of \the [src]</span>")
	to_chat(user, "<span class='notice'>You start to pull \the [A] out of \the [src]")
	if(do_after(user, 5 SECONDS, src))
		A.forceMove(get_turf(user))
		user.visible_message("<span class='notice'>[user] pulls \the [A] out of \the [src]</span>")
		to_chat(user, "<span class='notice'>You successfully pull \the [A] out of \the [src]")
		return 1

	return 0