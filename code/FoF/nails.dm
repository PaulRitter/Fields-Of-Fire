/obj/item/stack/nail
    name = "Nails"
    max_amount = 7
    icon = 'icons/FoF/melee.dmi'
    icon_state = "nail-handful"
    w_class = ITEM_SIZE_SMALL
    sharp = 1
    throwforce = 10
    flags = CONDUCT

/obj/item/stack/nail/New()
    . = ..()
    update_icon()

/obj/item/stack/nail/use()
	. = ..()
	update_icon()

/obj/item/stack/nail/add()
	. = ..()
	update_icon()

/obj/item/stack/nail/update_icon()
    icon_state = initial(icon_state) + "_[amount]"