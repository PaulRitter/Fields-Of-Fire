//shaft
#define SHAFT_MAX_NAILS 7
#define FORCE_PER_NAIL 2
//this item should never be spawned, only its children
/obj/item/weapon/shaft
	name = ""
	icon = 'icons/FoF/melee.dmi'
	force = 10
	throwforce = 2
	var/list/nails_required = list(
		/obj/item/shaft_component/mace_head = 7,
		/obj/item/shaft_component/axe_head = 5,
		/obj/item/shaft_component/flail_head = 4,
		/obj/item/shaft_component/shovel_head = 2
	)
	var/list/results = list() //gets populated by children cause eb and wu have different colors hurr durr im bimmer

/obj/item/weapon/shaft/New(loc, var/nails = 0)
	. = ..(loc)
	if(nails > SHAFT_MAX_NAILS)
		nails = SHAFT_MAX_NAILS
	for(var/i in nails)
		contents += new /obj/item/stack/nail(src, 1)
	update_vars()

//dont judge me
/obj/item/weapon/shaft/update_icon()
	if(!contents.len)
		icon_state = initial(name) + "-shaft"
	else if(contents.len <= SHAFT_MAX_NAILS)
		icon_state = initial(name) + "-club_[contents.len]"
	else
		icon_state = initial(name) + "-club_[SHAFT_MAX_NAILS]"

/obj/item/weapon/shaft/examine(mob/user, distance)
	..()
	if(contents.len && Adjacent(user))
		to_chat(user, "It has [contents.len] nail\s lodged inside it.")

/obj/item/weapon/shaft/proc/update_vars()
	var/add = " Club"
	if(!contents.len)
		add = " Shaft"
	name = initial(name) + add
	force = initial(force) + contents.len * FORCE_PER_NAIL
	update_icon()

/obj/item/weapon/shaft/attackby(obj/item/weapon/W, mob/user)
	if(istype(W, /obj/item/stack/nail) && (user.a_intent == I_HELP))
		if(contents.len > SHAFT_MAX_NAILS)
			to_chat(user, "<span class='notice'>\the [src] can't hold anymore [W]</span>")
			return 0
		var/obj/item/stack/nail/N = W

		if(!N.use(1))
			return 0

		
		contents += new N.type(src, 1)
		update_vars()
		to_chat(user, "<span class='notice'>You add \a [N.singular_name] to \the [src]</span>")
		return 1
	if((W.type in nails_required) && (W.type in results))		
		if(contents.len < nails_required[W.type])
			to_chat(user, "<span class='notice'>You need more nails to attach that</span>")
			return 0
		
		var/productType = results[W.type] //else it would give a weird warning
		// warning: loc: unused label
		var/atom/product = new productType(loc)
		transfer_fingerprints_to(product)
		src.forceMove(null)
		qdel(W)
		user.put_in_hands(product)
		to_chat(user, "<span class='notice'>You construct \a [product]</span>")
		return 1
	return ..()

/obj/item/weapon/shaft/attack_hand(mob/user)
	if(user.a_intent == I_HURT)
		if(!contents.len)
			return ..()

		var/obj/item/stack/nail/N = pop(contents)
		if(!istype(N))
			return 0
		
		to_chat(user, "<span class='notice'>You remove \a [N.singular_name] to \the [src]</span>")
		user.put_in_hands(N)
		return 1
	return ..()

/obj/item/weapon/shaft/eb
	name = "EB"
	results = list(
		/obj/item/shaft_component/mace_head = /obj/item/weapon/twohanded/mace/eb,
		/obj/item/shaft_component/axe_head = /obj/item/weapon/axe/eb,
		/obj/item/shaft_component/flail_head = /obj/item/weapon/flail/eb,
		/obj/item/shaft_component/shovel_head = /obj/item/weapon/shovel/trench/eb
	)

/obj/item/weapon/shaft/wu
	name = "WU"
	results = list(
		/obj/item/shaft_component/mace_head = /obj/item/weapon/twohanded/mace/wu,
		/obj/item/shaft_component/axe_head = /obj/item/weapon/axe/wu,
		/obj/item/shaft_component/flail_head = /obj/item/weapon/flail/wu,
		/obj/item/shaft_component/shovel_head = /obj/item/weapon/shovel/trench/wu
	)

/obj/item/shaft_component
	icon = 'icons/FoF/melee.dmi'

/obj/item/shaft_component/mace_head
	name = "Mace Head"
	icon_state = "mace-head"
/obj/item/shaft_component/axe_head
	name = "Axe Head"
	icon_state = "axe-head"

/obj/item/shaft_component/flail_head
	name = "Flail Head"
	icon_state = "flail-head"

/obj/item/shaft_component/shovel_head
	name = "Shovel Head"
	icon_state = "shovel-head"
