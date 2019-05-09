/obj/item/weapon/storage/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1)
	var/list/data = list()

	ui = GLOB.nanomanager.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "storage.tmpl", name, storage_slots_w * 32, storage_slots_h * 32)
		ui.set_initial_data(data)
		ui.open()