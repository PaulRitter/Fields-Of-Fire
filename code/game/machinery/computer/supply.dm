/* Contents:
 - supplyradio (This one approves orders)
 - orderradio (This is the public-facing one)
For the shuttle controller, see supplyshuttle.dm
For cargo crates, see supplypacks.dm
For vending packs, see vending_packs.dm*/

//request form to spawn
/obj/item/weapon/paper/request_form/New(var/loc, var/datum/supply_pack/pack, var/number_of_crates, var/name, var/reason = "No reason provided.")
	. = ..(loc)
	name = "[pack.name] Requisition Form"
	info += {"<h3>[station_name] Supply Requisition Form</h3><hr>
		REQUESTED BY: [name]<br>"}

	info+= {"REASON: [reason]<br>
		SUPPLY CRATE: [pack.name]<br>
		NUMBER OF CRATES: [number_of_crates]<br>
		ACCESS RESTRICTION: [get_access_desc(pack.req_access)]<br>
		CONTENTS:<br>"}
	info += pack.manifest
	info += {"<hr>
		STAMP BELOW TO APPROVE THIS REQUISITION:<br>"}
	update_icon()

#define REASON_LEN 140

/obj/machinery/computer/supply
	name = "Supply requests radio"
	icon = 'icons/obj/computer.dmi'
	icon_state = "request"
	circuit = "/obj/item/weapon/circuitboard/orderradio"
	var/reqtime = 0 //Cooldown for requisitions - Quarxink
	var/last_viewed_group = "Supplies"

/obj/machinery/computer/supply/attack_ai(var/mob/user as mob)
	add_hiddenprint(user)
	return attack_hand(user)

/obj/machinery/computer/supply/attack_hand(var/mob/user as mob)
	if(..())
		return

	user.set_machine(src)
	ui_interact(user)
	return

/obj/machinery/computer/supply/proc/makeBaseNanoData(var/mob/user)
	// ui data
	var/data[0]
	// make assoc list for supply groups because either I'm retarded or nanoui is retarded
	var/supply_group_data[0]
	for(var/i = 1; i <= all_supply_groups.len; i++)
		supply_group_data.Add(list(list("category" = all_supply_groups[i])))
	data["all_supply_groups"] = supply_group_data
	data["last_viewed_group"] = last_viewed_group

	// current supply group packs being displayed
	var/packs_list[0]
	for(var/set_name in SSsupply_truck.supply_packs)
		var/datum/supply_pack/pack = SSsupply_truck.supply_packs[set_name]
		if(!pack.contraband && !pack.hidden)
			if(last_viewed_group == pack.group)
				packs_list.Add(list(list("name" = pack.name, "cost" = pack.cost, "command1" = list("doorder" = "[set_name]0"), "command2" = list("doorder" = "[set_name]1"))))
				// command1 is for a single crate order, command2 is for multi crate order
	data["supply_packs"] = packs_list

	var/obj/item/weapon/card/id/I = user.get_id_card()
	// current usr's cargo requests
	var/requests_list[0]
	for(var/i = 1; i <= SSsupply_truck.requestlist.len; i++)
		var/datum/supply_order/SO = SSsupply_truck.requestlist[i]
		if(SO)
			if(!SO.comment)
				SO.comment = "No reason provided."
			requests_list.Add(list(list("supply_type" = SO.object.name, "orderedby" = SO.orderedby, "authorized_name" = SO.authorized_name, "comment" = SO.comment, "command1" = list("confirmorder" = i), "command2" = list("rreq" = i))))
	data["requests"] = requests_list

	var/orders_list[0]
	for(var/set_name in SSsupply_truck.shoppinglist)
		var/datum/supply_order/SO = set_name
		if(SO )
			// Check if usr owns the order
			if(I && SO.orderedby == I.registered_name)
				orders_list.Add(list(list("supply_type" = SO.object.name, "orderedby" = SO.orderedby, "authorized_name" = SO.authorized_name, "comment" = SO.comment)))
	data["orders"] = orders_list
	data["money"] = SSsupply_truck.commandMoney
	return data

/obj/machinery/computer/supply/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null)
	var/data = makeBaseNanoData(user)

	ui = GLOB.nanomanager.try_update_ui(user, src, ui_key, ui, data)
	if(!ui)
		ui = new(user, src, ui_key, "order_console.tmpl", name, 600, 660)
		ui.set_initial_data(data)
		ui.open()

/obj/machinery/computer/supply/proc/check_restriction(mob/user)
	if(!user)
		return FALSE
	var/result = FALSE
	switch(SSsupply_truck.restriction)
		if(0)
			result = TRUE
		if(1)
			result = allowed(user)
		if(2)
			result = allowed(user) && iscarbon(user)
	if(!result) //This saves a lot of pasted to_chat everywhere else
		to_chat(user, "<span class='warning'>Your credentials were rejected by the current permissions protocol.</span>")
	return result

/obj/machinery/computer/supply/Topic(href, href_list)
	if(..())
		return 1
	add_fingerprint(usr)

	if (href_list["doorder"])
		if(world.time < reqtime)
			for(var/mob/V in hearers(src))
				V.show_message("<b>[src]</b>'s monitor flashes, \"[world.time - reqtime] seconds remaining until another requisition form may be printed.\"")
			return 1

		var/pack_name = copytext(href_list["doorder"], 1, lentext(href_list["doorder"]))
		var/multi = text2num(copytext(href_list["doorder"], -1))
		if(!isnum(multi))
			return 1
		//Find the correct supply_pack datum
		var/datum/supply_pack/P = SSsupply_truck.supply_packs[pack_name]
		if(!istype(P))
			return 1

		var/crates = 1
		if(multi)
			var/tempcount = input(usr, "Amount:", "How many crates?", "") as num
			crates = Clamp(round(text2num(tempcount)), 1, 20)

		var/timeout = world.time + 600
		var/reason = input(usr,"Reason:","Why do you require this item?","") as null|text
		if(length(reason) > REASON_LEN)
			return 1
		if(world.time > timeout)
			return 1
		if(!reason)
			return 1

		var/obj/item/weapon/card/id/I = usr.get_id_card()

		new /obj/item/weapon/paper/request_form(loc, P, crates, (I && I.registered_name) ? I.registered_name : usr.name, reason)
		reqtime = (world.time + 5) % 1e5
		//make our supply_order datum
		for(var/i = 1; i <= crates; i++)
			var/datum/supply_order/O = new /datum/supply_order()
			O.object = P
			O.orderedby = (I && I.registered_name) ? I.registered_name : usr.name
			O.comment = reason

			SSsupply_truck.requestlist += O

			if(!SSsupply_truck.restriction) //If set to 0 restriction, auto-approve
				SSsupply_truck.confirm_order(O,usr,SSsupply_truck.requestlist.len, 1)
		return 1
	else if (href_list["last_viewed_group"])
		last_viewed_group = href_list["last_viewed_group"]
		return 1
	else if (href_list["rreq"])
		if(!check_restriction(usr))
			return 1
		var/ordernum = text2num(href_list["rreq"])
		if(!ordernum)
			return 1
		SSsupply_truck.requestlist.Cut(ordernum,ordernum+1)
		return 1
	else if (href_list["close"])
		if(usr.machine == src)
			usr.unset_machine()
		return 1

#define SCR_MAIN 1
#define SCR_CENTCOM 2

/obj/machinery/computer/supply/administration
	name = "Supply administration radio"
	icon_state = "supply"
	req_access = list(access_cargo)
	circuit = "/obj/item/weapon/circuitboard/supplyradio"
	var/hacked = 0 //is this needed?
	var/can_order_contraband = 0 //is this needed?
	var/permissions_screen = FALSE // permissions setting screen toggle
	var/screen = SCR_MAIN

/obj/machinery/computer/supply/administration/New()
	..()
	SSsupply_truck.supply_radios.Add(src)

/obj/machinery/computer/supply/administration/Destroy()
	SSsupply_truck.supply_radios.Remove(src)
	..()

/obj/machinery/computer/supply/administration/attackby(var/obj/item/I, var/mob/user)
	if(istype(I,/obj/item/weapon/card/emag) && !hacked)
		to_chat(user, "<span class='notice'>Special supplies unlocked.</span>")
		hacked = 1
		return
	return ..()

/obj/machinery/computer/supply/administration/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null)
	var/data = makeBaseNanoData(user)

	var/centcomm_list[0]
	for(var/datum/command_order/O in SSsupply_truck.command_orders)
		centcomm_list.Add(list(list("id" = O.id, "requested" = O.getRequestsByName(), "fulfilled" = O.getFulfilledByName(), "name" = O.name, "worth" = O.worth)))
	data["command_orders"] = centcomm_list

	data["send"] = list("send" = 1)
	data["moving"] = SSsupply_truck.moving
	data["at_station"] = SSsupply_truck.at_base
	data["show_permissions"] = permissions_screen
	data["restriction"] = SSsupply_truck.restriction

	data["screen"] = screen

	ui = GLOB.nanomanager.try_update_ui(user, src, ui_key, ui, data)
	if (!ui)
		ui = new(user, src, ui_key, "supply_console.tmpl", name, 600, 660)
		ui.set_initial_data(data)
		ui.open()

/obj/machinery/computer/supply/administration/Topic(href, href_list)
	if(..())
		return 1
	add_fingerprint(usr)
	
	//Handle access and requisitions
	if(href_list["permissions"])
		if(!permissions_screen)
			permissions_screen = TRUE
		else
			permissions_screen = FALSE
	//Calling the shuttle
	else if(href_list["send"])
		if(!check_restriction(usr))
			to_chat(usr, "<span class='warning'>Your credentials were rejected by the current permissions protocol.</span>")
		else
			SSsupply_truck.depart()
	else if(href_list["confirmorder"])
		//Find the correct supply_order datum
		if(!check_restriction(usr))
			return 1
		var/ordernum = text2num(href_list["confirmorder"])
		if(!ordernum)
			return 1

		var/datum/supply_order/O = SSsupply_truck.requestlist[ordernum]

		// Calculate money tied up in shoppinglist
		var/total_cost = 0
		for(var/datum/supply_order/R in SSsupply_truck.shoppinglist)
			var/datum/supply_pack/R_pack = R.object
			total_cost += R_pack.cost
		// check they can afford the order
		if((O.object.cost + total_cost) > SSsupply_truck.commandMoney)
			to_chat(usr, "<span class='warning'>You can't affort to approve this order.</span>")
			return 1

		SSsupply_truck.confirm_order(O,usr,ordernum)
	else if (href_list["access_restriction"])
		if(!check_restriction(usr))
			return 1
		SSsupply_truck.restriction = text2num(href_list["access_restriction"])
	else if (href_list["screen"])
		if(!check_restriction(usr))
			return 1
		var/result = text2num(href_list["screen"])
		if(result == SCR_MAIN || result == SCR_CENTCOM)
			screen = result
		return 1
	return 1

#undef SCR_MAIN
#undef SCR_CENTCOM
#undef REASON_LEN