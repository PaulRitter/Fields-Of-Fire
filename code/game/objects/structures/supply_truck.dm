/obj/structure/supply_truck
    icon = 'icons/placeholders/truck.dmi'
    icon_state = "truck-placeholder"
    anchored = 1
	density = 1
    plane = ABOVE_HUMAN_PLANE
	layer = ABOVE_HUMAN_LAYER
    var/maxContents = 20

/obj/structure/supply_truck/attack_hand(var/mob/user)
    if(!contents.len)
        to_chat(user, "<span class='notice'>The Truck is empty</span>")
        return 0

    //take the last atom of the list and give it to our mob
    var/atom/A = contents[contents.len]
    A.forceMove(get_turf(user))
    contents.len--
    return 1

/obj/structure/supply_truck/attackBy(obj/item/W, mob/user)
    if(contents.len >= maxContents)
        return 0
    
    W.forceMove(src)
    return 1