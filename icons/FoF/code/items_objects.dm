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
	name = "crowbar"
	desc = "A rusty crowbar with a menacing hooked end."
	icon = 'icons/FoF/tools_ww1.dmi'
	icon_state = "ww1_crowbar"
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

/obj/item/weapon/reagent_containers/food/snacks/can
	icon = 'icons/FoF/misc.dmi'

/obj/item/weapon/reagent_containers/food/snacks/can/soup
	name = "\improper Ration Soup"
	desc = "A can of sour soup meant to last months in the trenches."
	icon_state = "soup_f"
	throwforce = 10
	trash = /obj/item/trash/cansoup
	center_of_mass = "x=16;y=15"
	nutriment_desc = list("sourness" = 2,"stale soup" = 2)
	nutriment_amt = 20
	throw_range = 5
	flags = OPENCONTAINER

/obj/item/weapon/reagent_containers/food/snacks/can/soup/New()
	..()
	reagents.add_reagent(/datum/reagent/iron, 2)
	reagents.add_reagent(/datum/reagent/dylovene, 5)
	reagents.add_reagent(/datum/reagent/nutriment, 4)
	reagents.add_reagent(/datum/reagent/ethylredoxrazine, 4)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/can/beans
	name = "\improper Ration Beans"
	desc = "A can of bland beans meant to last months in the trenches."
	icon_state = "beans_f"
	throwforce = 10
	trash = /obj/item/trash/canbean
	center_of_mass = "x=16;y=15"
	nutriment_desc = list("dirt" = 2,"stale beans" = 4)
	nutriment_amt = 20
	throw_range = 5

/obj/item/weapon/reagent_containers/food/snacks/can/beans/New()
	..()
	reagents.add_reagent(/datum/reagent/iron, 5)
	reagents.add_reagent(/datum/reagent/nutriment, 3)
	reagents.add_reagent(/datum/reagent/nutriment/protein, 10)
	reagents.add_reagent(/datum/reagent/peridaxon, 3)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/can/fish
	name = "\improper Ration Fish"
	desc = "A can of reeking fish meant to last months in the trenches."
	icon_state = "fish_f"
	throwforce = 10
	trash = /obj/item/trash/canfish
	center_of_mass = "x=16;y=15"
	nutriment_desc = list("raw seafood" = 2,"fish" = 4)
	nutriment_amt = 20
	throw_range = 7

/obj/item/weapon/reagent_containers/food/snacks/can/fish/New()
	..()
	reagents.add_reagent(/datum/reagent/iron, 4)
	reagents.add_reagent(/datum/reagent/inaprovaline, 4)
	reagents.add_reagent(/datum/reagent/nutriment, 5)
	reagents.add_reagent(/datum/reagent/nutriment/protein, 10)
	reagents.add_reagent(/datum/reagent/spaceacillin, 5)
	reagents.add_reagent(/datum/reagent/dylovene, 5)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/can/ham
	name = "\improper Ration Ham"
	desc = "A can of tasty looking salted meat."
	icon_state = "ham_f"
	center_of_mass = "x=16;y=15"
	trash = /obj/item/trash/canham
	nutriment_desc = list("cold jerky" = 4, "salt" = 2)
	nutriment_amt = 20
	throw_range = 5

/obj/item/weapon/reagent_containers/food/snacks/can/ham/New()
	..()
	reagents.add_reagent(/datum/reagent/iron, 8)
	reagents.add_reagent(/datum/reagent/bicaridine, 5)
	reagents.add_reagent(/datum/reagent/nutriment, 5)
	reagents.add_reagent(/datum/reagent/nutriment/protein, 10)
	reagents.add_reagent(/datum/reagent/dylovene, 5)
	reagents.add_reagent(/datum/reagent/dermaline, 5)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/oats
	icon = 'icons/FoF/misc.dmi'
	icon_state = "food_grains"
	name = "\improper handful of oats"
	desc = "Processed oats can be eaten raw and last forever. If only they didn't taste so bad."
	center_of_mass = "x=16;y=12"
	x_class = 2
	y_class = 1
	nutriment_desc = list("preservatives" = 2,"bland powder" = 4)
	nutriment_amt = 2

/obj/item/weapon/reagent_containers/food/snacks/oats/New()
	..()
	reagents.add_reagent(/datum/reagent/iron, 2)
	reagents.add_reagent(/datum/reagent/inaprovaline, 2)
	reagents.add_reagent(/datum/reagent/nutriment, 2)
	reagents.add_reagent(/datum/reagent/bicaridine, 2)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/ham
	icon = 'icons/FoF/misc.dmi'
	icon_state = "food_ham"
	name = "\improper slab of smoked ham"
	desc = "A cutlet of smoked ham. Full of salt preserved goodness."
	center_of_mass = "x=16;y=12"
	nutriment_desc = list("dried meat" = 2,"salt" = 4)
	nutriment_amt = 10

/obj/item/weapon/reagent_containers/food/snacks/ham/New()
	..()
	reagents.add_reagent(/datum/reagent/iron, 8)
	reagents.add_reagent(/datum/reagent/inaprovaline, 5)
	reagents.add_reagent(/datum/reagent/tricordrazine)
	reagents.add_reagent(/datum/reagent/nutriment, 5)
	reagents.add_reagent(/datum/reagent/nutriment/protein, 10)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/beans
	name = "\improper handful of beans"
	icon = 'icons/FoF/misc.dmi'
	desc = "These are healthy. Right?"
	icon_state = "food_beans"
	center_of_mass = "x=16;y=15"
	x_class = 2
	y_class = 1
	nutriment_desc = list("dirt" = 2,"stale beans" = 4)
	nutriment_amt = 3
	throw_range = 7

/obj/item/weapon/reagent_containers/food/snacks/beans/New()
	..()
	reagents.add_reagent(/datum/reagent/iron, 3)
	reagents.add_reagent(/datum/reagent/nutriment, 3)
	reagents.add_reagent(/datum/reagent/bicaridine, 3)
	reagents.add_reagent(/datum/reagent/nutriment/protein, 3)
	reagents.add_reagent(/datum/reagent/inaprovaline, 3)
	reagents.add_reagent(/datum/reagent/peridaxon, 3)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/fish
	name = "\improper smoked fish"
	desc = "Someone smoked this fish whole. Watch for bones. Or don't."
	icon = 'icons/FoF/misc.dmi'
	icon_state = "food_fish"
	center_of_mass = "x=16;y=12"
	nutriment_desc = list("dried meat" = 2,"salt" = 4)
	nutriment_amt = 10

/obj/item/weapon/reagent_containers/food/snacks/fish/New()
	..()
	reagents.add_reagent(/datum/reagent/iron, 8)
	reagents.add_reagent(/datum/reagent/inaprovaline, 5)
	reagents.add_reagent(/datum/reagent/bicaridine, 5)
	reagents.add_reagent(/datum/reagent/nutriment, 5)
	reagents.add_reagent(/datum/reagent/nutriment/protein, 10)
	reagents.add_reagent(/datum/reagent/dylovene, 5)
	reagents.add_reagent(/datum/reagent/spaceacillin, 5)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/bowl
	icon = 'icons/FoF/misc.dmi'

/obj/item/weapon/reagent_containers/food/snacks/bowl/oats
	name = "\improper bowl of oats"
	desc = "This looks cooked."
	icon_state = "bowl_grains"
	center_of_mass = "x=16;y=12"
	trash = /obj/item/trash/bowl
	nutriment_desc = list("mud" = 2,"warm oat" = 4)
	nutriment_amt = 15

/obj/item/weapon/reagent_containers/food/snacks/bowl/oats/New()
	..()
	reagents.add_reagent(/datum/reagent/iron, 5)
	reagents.add_reagent(/datum/reagent/bicaridine, 5)
	reagents.add_reagent(/datum/reagent/inaprovaline, 5)
	reagents.add_reagent(/datum/reagent/nutriment, 8)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/bowl/ham
	name = "\improper bowl of ham"
	desc = "An actual homecooked meal out here. Who would have thought?"
	icon_state = "bowl_ham"
	center_of_mass = "x=16;y=12"
	trash = /obj/item/trash/bowl
	nutriment_desc = list("love" = 2,"warm bacon" = 4, "salt" = 2)
	nutriment_amt = 15

/obj/item/weapon/reagent_containers/food/snacks/bowl/ham/New()
	..()
	reagents.add_reagent(/datum/reagent/iron, 8)
	reagents.add_reagent(/datum/reagent/bicaridine, 5)
	reagents.add_reagent(/datum/reagent/nutriment, 5)
	reagents.add_reagent(/datum/reagent/nutriment/protein, 10)
	reagents.add_reagent(/datum/reagent/dylovene, 5)
	reagents.add_reagent(/datum/reagent/dermaline, 5)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/bowl/beans
	name = "\improper bowl of beans"
	desc = "These don't look any healthier sitting in a bowl."
	icon_state = "bowl_beans"
	center_of_mass = "x=16;y=15"
	nutriment_desc = list("dirt" = 2,"warm bean" = 4)
	nutriment_amt = 15
	trash = /obj/item/trash/bowl

/obj/item/weapon/reagent_containers/food/snacks/bowl/beans/New()
	..()
	reagents.add_reagent(/datum/reagent/iron, 3)
	reagents.add_reagent(/datum/reagent/nutriment, 3)
	reagents.add_reagent(/datum/reagent/bicaridine, 3)
	reagents.add_reagent(/datum/reagent/nutriment/protein, 3)
	reagents.add_reagent(/datum/reagent/inaprovaline, 3)
	reagents.add_reagent(/datum/reagent/peridaxon, 3)
	bitesize = 5
