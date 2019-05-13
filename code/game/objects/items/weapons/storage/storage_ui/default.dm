#define num2screen(x) "[round(x)]:[round(x * 32)%32]"
/datum/storage_ui/default
	var/list/is_seeing = new/list() //List of mobs which are currently seeing the contents of this item's storage
	var/list/client_uis = new/list()

/datum/client_storage_ui
	var/list/grid_boxes = new/list()
	var/list/grab_bar = new/list()
	var/obj/screen/close/close_button = null
	var/client/client = null
	var/tx = 1
	var/ty = 4

/datum/client_storage_ui/New(var/client/C)
	client = C

/obj/screen/storage/gridbox
	name = "storage"
	icon = 'icons/mob/screen1_small.dmi'
	icon_state = "grid"
	layer = HUD_BASE_LAYER
	var/store_x = -1
	var/store_y = -1

/obj/screen/storage/gridbox/New(var/obj/item/weapon/storage/storage, var/x, var/y)
	..()
	loc = null
	master = storage
	store_x = x
	store_y = y

/obj/screen/storage/dragbar
	name = "storage"
	icon = 'icons/mob/scren1_small.dmi'
	icon_state = "grab0"
	layer = HUD_BASE_LAYER
	var/datum/client_storage_ui/csu
	var/pos = 0

/obj/screen/storage/dragbar/New(var/datum/client_storage_ui/set_csu,var/ind,var/typ)
	..()
	loc = null
	csu = set_csu
	pos = ind
	icon_state = "grab[typ]"

/obj/screen/storage/gridbox/Click()
	if(!usr.canClick())
		return 1
	if(usr.stat || usr.paralysis || usr.stunned || usr.weakened)
		return 1
	if (istype(usr.loc,/obj/mecha)) // stops inventory actions in a mech
		return 1
	var/obj/item/weapon/storage/storage = master
	if(istype(storage))
		var/obj/item/I = usr.get_active_hand()
		if(I)
			if(storage.can_be_inserted(I, usr, store_x, store_y))
				storage.handle_item_insertion(I, store_x, store_y)
	return 1

/datum/storage_ui/default/New(var/storage)
	..()

/datum/storage_ui/default/Destroy()
	close_all()
	for(var/client/C in client_uis)
		var/datum/client_storage_ui/csu = client_uis[C]
		for(var/obj/screen/storage/gridbox/box in csu.grid_boxes)
			QDEL_NULL(box)
		csu.grid_boxes.Cut()
		QDEL_NULL(csu)
	client_uis.Cut()
	. = ..()

/datum/storage_ui/default/on_open(var/mob/user)
	// Do nothing for now.

/datum/storage_ui/default/after_close(var/mob/user)
	user.s_active -= src

/datum/storage_ui/default/on_insertion(var/mob/user)
	if(storage in user.s_active)
		storage.show_to(user)

/datum/storage_ui/default/on_pre_remove(var/mob/user, var/obj/item/W)
	for(var/mob/M in range(1, storage.loc))
		if (storage in M.s_active)
			if (M.client)
				M.client.screen -= W

/datum/storage_ui/default/on_post_remove(var/mob/user)
	if(storage in user.s_active)
		storage.show_to(user)

/datum/storage_ui/default/on_hand_attack(var/mob/user)
	for(var/mob/M in range(1))
		if (storage in M.s_active)
			storage.close(M)

/datum/storage_ui/default/show_to(var/mob/user)
	if(!(storage in user.s_active))
		for(var/obj/item/I in storage)
			if(I.on_found(user))
				return
	if(storage in user.s_active)
		storage.hide_from(user)
	var/datum/client_storage_ui/csu = client_uis[user.client]
	if(csu)
		for(var/obj/screen/storage/gridbox/box in csu.grid_boxes)
			user.client.screen -= box
		csu.grid_boxes.Cut()
		QDEL_NULL(csu)
	user.client.screen -= storage.contents

	csu = new(user.client)
	client_uis[user.client] = csu

	user.client.screen += storage.contents
	for(var/x = 1 to storage.storage_slots_w)
		for(var/y = 1 to storage.storage_slots_h)
			var/obj/screen/storage/gridbox/box = new(storage, x, y)
			csu.grid_boxes += box
			box.screen_loc = "[csu.tx + round((box.store_x - 1)/2)]:[((box.store_x - 1)%2) * 16],[csu.ty + round((box.store_y - 1)/2)]:[((box.store_y - 1)%2) * 16]"
			user.client.screen += box

	is_seeing |= user
	user.s_active |= storage

/datum/storage_ui/default/hide_from(var/mob/user)
	is_seeing -= user
	if(!user.client)
		return
	var/datum/client_storage_ui/csu = client_uis[user.client]
	if(csu)
		for(var/obj/screen/storage/gridbox/box in csu.grid_boxes)
			user.client.screen -= box
		csu.grid_boxes.Cut()
		QDEL_NULL(csu)
		client_uis[user.client] = null
	if(storage in user.s_active)
		user.s_active -= src

//Creates the storage UI
/datum/storage_ui/default/prepare_ui()
	neo_orient_objs()


/datum/storage_ui/default/close_all()
	for(var/mob/M in can_see_contents())
		storage.close(M)
		. = 1

/datum/storage_ui/default/proc/can_see_contents()
	var/list/cansee = list()
	for(var/mob/M in is_seeing)
		if((storage in M.s_active) && M.client)
			cansee |= M
		else
			is_seeing -= M
	return cansee

//This proc draws out UI elements based on their 2D size and position
/datum/storage_ui/default/proc/neo_orient_objs().
	for(var/client/C in client_uis)
		var/datum/client_storage_ui/csu = client_uis[C]
		var/tx = csu.tx
		var/ty = csu.ty

		for(var/obj/O in storage.contents)
			var/datum/vec2/stored_loc = storage.stored_locations[O]
			if(istype(stored_loc))
				var sx = tx + ((stored_loc.x-1)/2)
				var sy = ty + ((stored_loc.y-1)/2)
				O.screen_loc = "[round(sx)]:[round(sx*32)%32],[round(sy)]:[round(sy*32)%32]"
				O.hud_layerise()