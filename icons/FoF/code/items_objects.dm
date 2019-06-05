/obj/item/weapon/reagent_containers/pill/iron
	name = "Iron pill"
	desc = "Used to increase the speed of blood replenishment."
	icon_state = "pill18"
	New()
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