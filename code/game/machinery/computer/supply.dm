/* Contents:
 - supplyradio (This one approves orders)
 - orderradio (This is the public-facing one)
For the shuttle controller, see supplyshuttle.dm
For cargo crates, see supplypacks.dm
For vending packs, see vending_packs.dm*/

//request form to spawn
/obj/item/weapon/paper/request_form/New(var/loc, var/list/account_information, var/datum/supply_packs/pack, var/number_of_crates, var/reason = "No reason provided.")
	. = ..(loc)
	name = "[pack.name] Requisition Form - [account_information["idname"]], [account_information["idrank"]]"
	info += {"<h3>[station_name] Supply Requisition Form</h3><hr>
		INDEX: #[SSsupply_shuttle.ordernum]<br>
		REQUESTED BY: [account_information["idname"]]<br>"}
	if(account_information["authorized_name"] != "")
		info += "USING DEBIT AS: [account_information["authorized_name"]]<br>"

	info+= {"RANK: [account_information["idrank"]]<br>
		REASON: [reason]<br>
		SUPPLY CRATE TYPE: [pack.name]<br>
		NUMBER OF CRATES: [number_of_crates]<br>
		ACCESS RESTRICTION: [get_access_desc(pack.access)]<br>
		CONTENTS:<br>"}
	info += pack.manifest
	info += {"<hr>
		STAMP BELOW TO APPROVE THIS REQUISITION:<br>"}
	update_icon()

#define SCR_MAIN 1
#define SCR_CENTCOM 2

/obj/machinery/computer/supplyradio
	name = "Supply administration radio"
	icon = 'icons/obj/computer.dmi'
	icon_state = "supply"
	req_access = list(access_cargo)
	circuit = "/obj/item/weapon/circuitboard/supplyradio"
	var/reqtime = 0 //Cooldown for requisitions - Quarxink
	var/hacked = 0 //is this needed?
	var/can_order_contraband = 0 //is this needed?
	var/permissions_screen = FALSE // permissions setting screen toggle
	var/last_viewed_group = all_supply_groups[1]
	var/screen = SCR_MAIN
	light_color = LIGHT_COLOR_BROWN

/obj/machinery/computer/supplyradio/New()
	..()
	SSsupply_truck.supply_radios.Add(src)

/obj/machinery/computer/supplyradio/Destroy()
    SSsupply_truck.supply_radios.Remove(src)
	..()

/obj/machinery/computer/supplyradio/attack_ai(var/mob/user)
	add_hiddenprint(user)
	return attack_hand(user)

/obj/machinery/computer/supplyradio/proc/check_restriction(mob/user)
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

/obj/machinery/computer/supplyradio/attack_hand(var/mob/user)
	if(..())
		return

	user.set_machine(src)
	ui_interact(user)

/obj/machinery/computer/supplyradio/attackby(var/obj/item/I, var/mob/user)
	if(istype(I,/obj/item/weapon/card/emag) && !hacked)
		to_chat(user, "<span class='notice'>Special supplies unlocked.</span>")
		hacked = 1
		return
	return ..()

/obj/machinery/computer/supplyradio/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open=NANOUI_FOCUS)
	// data to send to ui
	var/data[0]
	// make assoc list for supply groups because either I'm retarded or nanoui is retarded
	var/supply_group_data[0]
	for(var/i = 1; i <= all_supply_groups.len; i++)
		supply_group_data.Add(list(list("category" = all_supply_groups[i])))
	data["all_supply_groups"] = supply_group_data
	data["last_viewed_group"] = last_viewed_group

	// list of packs we are displaying
	var/packs_list[0]
	for(var/set_name in SSsupply_truck.supply_packs)
		var/datum/supply_pack/pack = SSsupply_truck.supply_packs[set_name]
		if((pack.hidden && src.hacked) || (pack.contraband && src.can_order_contraband) || (!pack.contraband && !pack.hidden)) // Check if the pack is allowed to be shown
			if(last_viewed_group == pack.group)
				packs_list.Add(list(list("name" = pack.name, "amount" = pack.amount, "cost" = pack.cost, "command1" = list("doorder" = "[set_name]0"), "command2" = list("doorder" = "[set_name]1"))))
				// command1 is for a single crate order, command2 is for multi crate order

	data["supply_packs"] = packs_list

	var/requests_list[0]
    for(var/i = 1; i <= SSsupply_truck.requestlist.len; i++)
		var/datum/supply_order/SO = SSsupply_truck.requestlist[i]
		if(SO)
			if(!SO.comment)
				SO.comment = "No reason provided."
			requests_list.Add(list(list("ordernum" = SO.ordernum, "supply_type" = SO.object.name, "orderedby" = SO.orderedby, "authorized_name" = SO.authorized_name, "comment" = SO.comment, "command1" = list("confirmorder" = SO.ordernum), "command2" = list("rreq" = i))))
	data["requests"] = requests_list

	var/orders_list[0]
	for(var/set_name in SSsupply_truck.shoppinglist)
		var/datum/supply_order/SO = set_name
		if(SO)
			orders_list.Add(list(list("ordernum" = SO.ordernum, "supply_type" = SO.object.name, "orderedby" = SO.orderedby, "authorized_name" = SO.authorized_name, "comment" = SO.comment)))
	data["orders"] = orders_list

	var/centcomm_list[0]
	for(var/datum/centcomm_order/O in SSsupply_truck.centcomm_orders)
		centcomm_list.Add(list(list("id" = O.id, "requested" = O.getRequestsByName(), "fulfilled" = O.getFulfilledByName(), "name" = O.name, "worth" = O.worth)))
	data["centcomm_orders"] = centcomm_list

	data["money"] = SSsupply_truck.commandMoney
	data["send"] = list("send" = 1)
	data["moving"] = SSsupply_truck.moving
	data["at_station"] = SSsupply_truck.at_base
	data["show_permissions"] = permissions_screen
	data["restriction"] = SSsupply_truck.restriction
	data["requisition"] = SSsupply_truck.requisition

	data["screen"] = screen

	ui = nanomanager.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "supply_console.tmpl", name, 600, 660)
		ui.set_initial_data(data)
		ui.open()

/obj/machinery/computer/supplyradio/Topic(href, href_list)
	if(..())
		return 1
	add_fingerprint(usr)
	
	//Handle access and requisitions
	if(href_list["permissions"])
		if(!permissions_screen && pin_query(usr))
			permissions_screen = TRUE
		else
			permissions_screen = FALSE
	//Calling the shuttle
	else if(href_list["send"])
		if(!check_restriction(usr))
			to_chat(usr, "<span class='warning'>Your credentials were rejected by the current permissions protocol.</span>")
		else
			SSsupply_truck.depart()
	else if (href_list["doorder"])
		if(world.time < reqtime)
			for(var/mob/V in hearers(src))
				V.show_message("<b>[src]</b>'s monitor flashes, \"[world.time - reqtime] seconds remaining until another requisition form may be printed.\"")
			return 1

		var/pack_name = copytext(href_list["doorder"], 1, lentext(href_list["doorder"]))
		var/multi = text2num(copytext(href_list["doorder"], -1))
		if(!multi)
			return 1
		//Find the correct supply_pack datum
		var/datum/supply_pack/P = SSsupply_truck.supply_packs[pack_name]
		if(!istype(P))
			return 1

		var/crates = 1
		if(multi)
			var/tempcount = input(usr, "Amount:", "How many crates?", "") as num
			crates = Clamp(round(text2num(tempcount)), 1, 20)

		// Calculate money tied up in requests
		var/total_money_req = 0
		for(var/datum/supply_order/R in SSsupply_truck.requestlist)
            var/datum/supply_packs/R_pack = R.object
            total_money_req += R_pack.cost
		// check they can afford the order
		if((P.cost * crates + total_money_req) > SSsupply_truck.commandMoney)
			var/max_crates = round((SSsupply_truck.commandMoney - total_money_req) / P.cost)
			to_chat(usr, "<span class='warning'>You can only afford [max_crates] crates.</span>")
			return 1
		var/timeout = world.time + 600
		var/reason = stripped_input(usr,"Reason:","Why do you require this item?","",REASON_LEN)
		if(world.time > timeout)
			return 1
		if(!reason)
			return 1

		new /obj/item/weapon/paper/request_form(loc, current_acct, P, crates, reason)
		reqtime = (world.time + 5) % 1e5
		//make our supply_order datum
		for(var/i = 1; i <= crates; i++)
			SSsupply_truck.ordernum++
			var/datum/supply_order/O = new /datum/supply_order()
			O.object = P
			O.orderedby = idname
			O.account = account
			O.comment = reason

			SSsupply_truck.requestlist += O

			if(!SSsupply_truck.restriction) //If set to 0 restriction, auto-approve
				SSsupply_truck.confirm_order(O,usr,SSsupply_truck.requestlist.len, 1)
	else if(href_list["confirmorder"])
		//Find the correct supply_order datum
		if(!check_restriction(usr))
			return 1
		var/ordernum = text2num(href_list["confirmorder"])
        if(!ordernum)
            return 1
		var/datum/supply_order/O = SSsupply_truck.requestlist[ordernum]
        SSsupply_truck.confirm_order(O,usr,ordernum)
	else if (href_list["rreq"])
		if(!check_restriction(usr))
			return
		var/ordernum = text2num(href_list["rreq"])
		if(!ordernum)
            return 1
		var/datum/supply_order/O = SSsupply_truck.requestlist[ordernum]
        SSsupply_truck.requestlist.Cut(ordernum,ordernum+1)
	else if (href_list["last_viewed_group"])
		last_viewed_group = href_list["last_viewed_group"]
	else if (href_list["access_restriction"])
		if(!check_restriction(usr))
			return 1
		SSsupply_truck.restriction = text2num(href_list["access_restriction"])
	else if (href_list["requisition_status"])
		if(!check_restriction(usr))
			return 1
		SSsupply_truck.requisition = text2num(href_list["requisition_status"])
	else if (href_list["screen"])
		if(!check_restriction(usr))
			return 1
		var/result = text2num(href_list["screen"])
		if(result == SCR_MAIN || result == SCR_CENTCOM)
			screen = result
	else if (href_list["close"])
		if(usr.machine == src)
			usr.unset_machine()
	return 1

/obj/machinery/computer/orderradio
	name = "Supply requests radio"
	icon = 'icons/obj/computer.dmi'
	icon_state = "request"
	circuit = "/obj/item/weapon/circuitboard/orderradio"
	var/reqtime = 0 //Cooldown for requisitions - Quarxink
	var/last_viewed_group = all_supply_groups[1]
	light_color = LIGHT_COLOR_BROWN


/obj/machinery/computer/orderradio/attack_ai(var/mob/user as mob)
	add_hiddenprint(user)
	return attack_hand(user)

/obj/machinery/computer/orderradio/attack_hand(var/mob/user as mob)
	if(..())
		return

	user.set_machine(src)
	ui_interact(user)
	return

/obj/machinery/computer/orderradio/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open=NANOUI_FOCUS)
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
		var/datum/supply_packs/pack = SSsupply_truck.supply_packs[set_name]
		if(!pack.contraband && !pack.hidden)
			if(last_viewed_group == pack.group)
				packs_list.Add(list(list("name" = pack.name, "amount" = pack.amount, "cost" = pack.cost, "command1" = list("doorder" = "[set_name]0"), "command2" = list("doorder" = "[set_name]1"))))
				// command1 is for a single crate order, command2 is for multi crate order
	data["supply_packs"] = packs_list

	var/obj/item/weapon/card/id/I = user.get_id_card()
	// current usr's cargo requests
	var/requests_list[0]
    for(var/i = 1; i <= SSsupply_truck.requestlist.len; i++)
		var/datum/supply_order/SO = SSsupply_truck.requestlist[i]
		if(SO)
			// Check if usr owns the request
			if(I && SO.orderedby == I.registered_name)
				requests_list.Add(list(list("ordernum" = SO.ordernum, "supply_type" = SO.object.name, "command1" = list("rreq" = i))))
	data["requests"] = requests_list

	var/orders_list[0]
	for(var/set_name in SSsupply_truck.shoppinglist)
		var/datum/supply_order/SO = set_name
		if(SO )
			// Check if usr owns the order
			if(I && SO.orderedby == I.registered_name)
				orders_list.Add(list(list("ordernum" = SO.ordernum, "supply_type" = SO.object.name)))
	data["orders"] = orders_list
	data["money"] = commandMoney

	ui = nanomanager.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "order_console.tmpl", name, 600, 660)
		ui.set_initial_data(data)
		ui.open()

/obj/machinery/computer/orderradio/Topic(href, href_list)
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
		if(!multi)
			return 1
		//Find the correct supply_pack datum
		var/datum/supply_pack/P = SSsupply_truck.supply_packs[pack_name]
		if(!istype(P))
			return 1

		var/crates = 1
		if(multi)
			var/tempcount = input(usr, "Amount:", "How many crates?", "") as num
			crates = Clamp(round(text2num(tempcount)), 1, 20)

		// Calculate money tied up in requests
		var/total_money_req = 0
		for(var/datum/supply_order/R in SSsupply_truck.requestlist)
            var/datum/supply_packs/R_pack = R.object
            total_money_req += R_pack.cost
		// check they can afford the order
		if((P.cost * crates + total_money_req) > SSsupply_truck.commandMoney)
			var/max_crates = round((SSsupply_truck.commandMoney - total_money_req) / P.cost)
			to_chat(usr, "<span class='warning'>You can only afford [max_crates] crates.</span>")
			return 1
		var/timeout = world.time + 600
		var/reason = stripped_input(usr,"Reason:","Why do you require this item?","",REASON_LEN)
		if(world.time > timeout)
			return 1
		if(!reason)
			return 1

		new /obj/item/weapon/paper/request_form(loc, current_acct, P, crates, reason)
		reqtime = (world.time + 5) % 1e5
		//make our supply_order datum
		for(var/i = 1; i <= crates; i++)
			SSsupply_truck.ordernum++
			var/datum/supply_order/O = new /datum/supply_order()
			O.object = P
			O.orderedby = idname
			O.account = account
			O.comment = reason

			SSsupply_truck.requestlist += O

			if(!SSsupply_truck.restriction) //If set to 0 restriction, auto-approve
				SSsupply_truck.confirm_order(O,usr,SSsupply_truck.requestlist.len, 1)
	else if (href_list["last_viewed_group"])
		last_viewed_group = href_list["last_viewed_group"]
		return 1
	else if (href_list["rreq"])
		if(!check_restriction(usr))
			return
		var/ordernum = text2num(href_list["rreq"])
		if(!ordernum)
            return 1
		var/datum/supply_order/O = SSsupply_truck.requestlist[ordernum]
        SSsupply_truck.requestlist.Cut(ordernum,ordernum+1)
	else if (href_list["close"])
		if(usr.machine == src)
			usr.unset_machine()
	return 1

#undef SCR_MAIN
#undef SCR_CENTCOM
