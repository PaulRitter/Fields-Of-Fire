/*
throw_speed = 2
	throw_range = 5
*/

//Knife
/obj/item/weapon/material/knife/wu
	name = "WU Knife"
	icon = 'icons/FoF/melee.dmi'
	icon_state = "WU-knife"

/obj/item/weapon/material/knife/wu
	name = "EB Knife"
	icon = 'icons/FoF/melee.dmi'
	icon_state = "EB-knife"

//Machete
//TODO add sheath
/obj/item/weapon/machete/trench
	icon = 'icons/FoF/melee.dmi'
	sharp = 1
	slot_flags = 0
	force = 20
	throwforce = 10

/obj/item/weapon/machete/trench/wu
	name = "WU Machete"
	icon_state = "WU-machete"

/obj/item/weapon/machete/trench/wu
	name = "WU Machete"
	icon_state = "WU-machete"

//Kukri
//TODO add sheath
/obj/item/weapon/machete/trench/kukri
	name = "Kukri"
	icon = 'icons/FoF/melee.dmi'
	icon_state = "kukri"
	throwforce = 15

//Flail
/obj/item/weapon/flail
	icon = 'icons/FoF/melee.dmi'
	force = 30
	throwforce = 20

/obj/item/weapon/flail/wu
	name = "WU Flail"
	icon_state = "WU-flail"

/obj/item/weapon/flail/eb
	name = "EB Flail"
	icon_state = "EB-flail"

//Axe
/obj/item/weapon/axe
	icon = 'icons/FoF/melee.dmi'
	force = 25
	throwforce = 20
	sharp = 1

/obj/item/weapon/axe/eb
	name = "EB Axe"
	icon_state = "EB-axe"

/obj/item/weapon/axe/wu
	name = "WU Axe"
	icon_state = "WU-axe"

//Mace
/obj/item/weapon/twohanded/mace
	icon = 'icons/FoF/melee.dmi'
	force = 40
	throwforce = 4

/obj/item/weapon/twohanded/mace/wu
	name = "WU Mace"
	icon_state = "WU-mace"

/obj/item/weapon/twohanded/mace/eb
	name = "EB Mace"
	icon_state = "EB-mace"

//shovel
/obj/item/weapon/shovel/trench
	icon = 'icons/FoF/melee.dmi'
	var/shafttype

/obj/item/weapon/shovel/trench/attack_hand(mob/user)
	if((user.a_intent == I_HURT) && shafttype)
		to_chat(user, "<span class='notice'>You break off the shovel head</span>")
		var/atom/movable/A = new shafttype(loc)
		new /obj/item/shaft_component/shovel_head(loc)
		src.forceMove(null)
		user.put_in_hands(A)
		return 1
	return ..()

/obj/item/weapon/shovel/trench/eb
	name = "EB Shovel"
	icon_state = "EB-shovel"
	shafttype = /obj/item/weapon/shaft/eb

/obj/item/weapon/shovel/trench/wu
	name = "WU Shovel"
	icon_state = "WU-shovel"
	shafttype = /obj/item/weapon/shaft/wu