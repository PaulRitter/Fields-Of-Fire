/obj/item/weapon/reagent_containers/pill/iron
	name = "Iron pill"
	desc = "Used to increase the speed of blood replenishment."
	icon_state = "pill18"

/obj/item/weapon/reagent_containers/pill/iron/New()
	..()
	reagents.add_reagent(/datum/reagent/iron, 20)

/obj/item/weapon/storage/pill_bottle/iron
	name = "bottle of Iron pills"
	desc = "Contains pills used to assist in blood replenishment."

	startswith = list(/obj/item/weapon/reagent_containers/pill/iron = 7)

/obj/item/weapon/storage/belt/trenchmed
	icon = 'icons/FoF/misc.dmi'
	name = "medical satchel"
	desc = "A red bag with a yellow cross that shows that the contents are medical in nature. Fits around your waist as well as your torso."
	w_class = ITEM_SIZE_HUGE
	storage_slots_w = 4
	storage_slots_h = 3
	show_above_suit = 0
	icon_state = "medkit"
	slot_flags = SLOT_BELT | SLOT_BACK

/obj/item/weapon/storage/belt/trenchmed/New()
	..()
	new /obj/item/weapon/storage/pill_bottle/iron(src)
	new /obj/item/stack/medical/bruise_pack/trench/ten(src)
	new /obj/item/stack/medical/splint/ghetto/three(src)
	new /obj/item/weapon/reagent_containers/syringe/steroid(src)


/***************************
	Tools
***************************/

obj/item/weapon/wrench/trench
	name = "wrench"
	icon = 'icons/FoF/tools_ww1.dmi'
	icon_state = "ww1_wrench"
	desc = "A heavy wrench coated in rust. A small wheel near the head allows for size adjustment."
	force = 15
	throwforce = 10
	attack_verb = list("beaten","clubbed","whacked","smacked","slapped","crushed","crunched","bashed","clobbered","struck","busted","thumped","battered","pounded","pummeled","slammed")
	w_class = ITEM_SIZE_NORMAL


/obj/item/weapon/screwdriver/trench
	name = "screwdriver"
	desc = "A small screwdriver with a wide grip. Makes a nice punch weapon if you're desperate."
	icon = 'icons/FoF/tools_ww1.dmi'
	icon_state = "ww1_screwdriver"
	force = 10
	slot_flags = SLOT_BELT


/obj/item/weapon/screwdriver/opener
	name = "can opener"
	desc = "A can opener that doubles as a screwdriver in a pinch. You can't rob somebody with it, even if it is pointy."
	icon = 'icons/FoF/misc.dmi'
	icon_state = "opener"
	force = 0
	slot_flags = SLOT_BELT


/obj/item/weapon/wirecutters/trench
	name = "wirecutters"
	icon = 'icons/FoF/tools_ww1.dmi'
	icon_state = "ww1_wirecutter"
	desc = "A rusty pair of wirecutters."


obj/item/weapon/crowbar/trench
	icon = 'icons/FoF/tools_ww1.dmi'
	icon_state = "ww1_multitool-crowbar"
	name = "crowbar"
	desc = "A rusty crowbar with a menacing hooked end."
	force = 15
	throwforce = 10
	attack_verb = list("beaten","clubbed","whacked","smacked","slapped","crushed","crunched","bashed","clobbered","struck","busted","thumped","battered","pounded","pummeled","slammed")
	w_class = ITEM_SIZE_NORMAL
	armor_penetration = 20


obj/item/weapon/weldingtool/trench
	name = "welding tool"
	icon = 'icons/FoF/tools_ww1.dmi'
	icon_state = "ww1_welder"
	desc = "A rusty old welding tool attached to a fuel tank."
	w_class = ITEM_SIZE_NORMAL

/obj/item/weapon/weldingtool/trench/get_storage_cost()
	if(isOn())
		return ITEM_SIZE_NO_CONTAINER
	return ..()