/* Contents:
 - supplyradio (This one approves orders)
 - orderradio (This is the public-facing one)
For the shuttle controller, see supplyshuttle.dm
For cargo crates, see supplypacks.dm
For vending packs, see vending_packs.dm*/


//truck mainfest
/obj/item/weapon/paper/truck_manifest/New(var/loc, var/list/contentlist, var/price, var/shipmentNum)
	. = ..(loc)
	name = "Truck Manifest"
	info += {"<h3>Truck Manifest</h3><hr>
		DESTINATION: [GLOB.using_map.station_name]<br>
		SHIPMENT #[shipmentNum]<br>
		CONTENTS:<br><ul>"}
	info += "<li>"+jointext(contentlist, "</li><li>")+"</li>"
	info += {"</ul><br>
		TOTAL COST: [price]<br>
		CHECK CONTENTS AND STAMP BELOW THE LINE TO CONFIRM RECEIPT OF GOODS<hr>"}
	update_icon()

//crate manifest
/obj/item/weapon/paper/shipping_manifest/New(var/loc, var/datum/supply_pack/SP, var/shipmentNum, var/datum/supply_order/SO)
	. = ..(loc)
	name = "Shipping Manifest for [(SO && SO.orderedby) ? SO.orderedby : "unknown"]'s Order"
	info = {"<h3>Shipping Manifest for [(SO && SO.orderedby) ? SO.orderedby : "unknown"]'s Order</h3><hr><br>
		DESTINATION: [GLOB.using_map.station_name]<br>
		SHIPMENT #[shipmentNum]<br>
		CONTENTS:<br><ul>"}

	for(var/typepath in SP.contains)
		if(!typepath)
			continue
		var/atom/B2 = new typepath(null)
		info += "<li>[B2.name] ([SP.contains[typepath]])</li>" //add the item to the manifest

	info += {"</ul><br>
		COST: [(SO && SO.getCost()) ? SO.getCost() : "unknown cost"]<br>
		CHECK CONTENTS AND STAMP BELOW THE LINE TO CONFIRM RECEIPT OF GOODS<hr>"}
	update_icon()

//crate manifest
/obj/item/weapon/paper/withdrawal_order/New(var/loc, var/amount, var/shipmentNum)
	. = ..(loc)
	name = "Withdrawal Manifest"
	info = {"<h3>Withdrawal Manifest</h3><hr><br>
		DESTINATION: [GLOB.using_map.station_name]<br>
		SHIPMENT #[shipmentNum]<br>
		AMOUNT: [amount]$<br>
		CHECK CONTENTS AND STAMP BELOW THE LINE TO CONFIRM RECEIPT OF GOODS<hr>"}
	update_icon()

//supply pack info
/obj/item/weapon/paper/supply_pack_info/New(var/loc, var/pack_id, var/datum/supply_pack/SP)
	name = "Pack #[pack_id] Info Sheet"
	info = {"<h3>Pack #[pack_id] Info Sheet</h3><hr><br>
		CONTENTS:<br><ul>"}
	for(var/typepath in SP.contains)
		if(!typepath)
			continue
		var/atom/B2 = new typepath(null)
		info += "<li>[B2.name] ([SP.contains[typepath]])</li>" //add the item to the manifest

	info += {"</ul><hr><br>
		COST: [SP.cost]"}

//all supply packs
/obj/item/weapon/paper/inventory_manifest/New(var/loc, var/obj/structure/radio_hub/hub)
	. = ..(loc)

	name = "Command Inventory Manifest"
	info += "<h3>Command inventory manifest</h3>"

	var/list/categories = list()
	for(var/pack_id in hub.supply_packs)
		var/datum/supply_pack/SP = hub.supply_packs["[pack_id]"]
		if(!(SP.group in categories))
			categories["[SP.group]"] = list()
		categories["[SP.group]"] += pack_id
	
	for(var/group in categories)
		info += "<hr><h5>[group]</h5>"
		for(var/pack_id in categories["[group]"])
			info += "#[pack_id]: [hub.supply_packs["[pack_id]"].name]<br>"

	update_icon()

//order info
/obj/item/weapon/paper/order_form/New(var/loc, var/datum/supply_order/SO, var/obj/structure/radio_hub/hub)
	. = ..(loc)
	var/obj/item/weapon/card/id/card = SO.orderedby.get_id_card()
	var/pname = (card && card.registered_name) ? card.registered_name : SO.orderedby.name
	name = "#[SO.id] Order Form"
	info += {"<h3>[GLOB.using_map.station_name] Supply Order Form</h3><br>
		REQUESTED BY: [pname]<hr>"}

	info+= "CONTENTS:<br>"
	for(var/pack_id in SO.packs)
		var/datum/supply_pack/SP = hub.supply_packs[pack_id]
		info += "#[pack_id] [SP.name] (x[SO.packs[pack_id]])<br>"
	update_icon()

//all orders
/obj/item/weapon/paper/order_list/New(var/loc, var/obj/structure/radio_hub/hub)
	. = ..(loc)

	name = "Active Order List"
	info += {"<h3>Active Order List</h3><hr>
			Current active orders:<ul>"}
	if(hub.nextWithdrawal)
		info += "<li>Withdrawal - Amount: [hub.nextWithdrawal]</li>"
	for(var/order_id in hub.shoppinglist)
		if(!hub.shoppinglist["[order_id]"])
			continue
		info += "<li>#[order_id] - requested by [hub.shoppinglist["[order_id]"].orderedby.name]</li>"

	update_icon()

//command order
/obj/item/weapon/paper/command_order/New(var/loc, var/datum/command_order/C)
	. = ..(loc)

	name = "External order form - [C.name] order number [C.id]"
	info = {"<h3>Command supply requisition form</h3><hr>
				INDEX: #[C.id]<br>
				REQUESTED BY: [C.name]<br>
				MUST BE IN CRATE: [C.must_be_in_crate ? "YES" : "NO"]<br>"}
	if(istype(C, /datum/command_order/per_unit/per_reagent))
		info += {"REQUESTED REAGENTS:
				[C.getRequestsByName()]"}
	else if(istype(C, /datum/command_order/per_unit))
		info += {"REQUESTED ITEMS:
				[C.getRequestsByName()]"}
	else
		info +=	{"REQUESTED ITEMS:
				[C.getRequestsByName()]
				PAYOUT: [C.worth]"}
	update_icon()

//all command orders
/obj/item/weapon/paper/request_list/New(var/loc, var/obj/structure/radio_hub/hub)
	. = ..(loc)

	name = "Active Command Order List"
	info += {"<h3>Active Command Order List</h3><hr>
			Current active command orders:<br>"}
	for(var/order_id in hub.command_orders)
		info += "#[order_id] - requested by [hub.command_orders["[order_id]"].name]<br>"

	update_icon()

//comm help
/obj/item/weapon/paper/communication_guidelines/New(var/loc)
	. = ..(loc)

	name = "Supply radio communication guidelines"
	info += {"<h3>Supply radio communication guidelines</h3><hr>
			Valid Commands:<br><ul>
			<li>order (supplypack_id)\[x(amount)\] ...<ul>
				<li>to order supply packs</li>
				<li>you can specify multiple supplypack_ids</li>
				<li>amount is optional, if you specify no amount it just orders one</li>
			</ul></li>
			<li>cancel (order_id)<ul>
				<li>to cancel an order</li>
			</ul></li>
			<li>total<ul>
				<li>returns the cost of all active orders combined</li>
			</ul></li>
			<li>funds<ul>
				<li>returns current command funds</li>
			</ul></li>
			<li>withdraw (amount)<ul>
				<li>places a withdraw order which will get sent with the next order</li>
			</ul></li>
			<li>help<ul>
				<li>prints out this document</li>
			</ul></li>
			<li>packinfo (supplypack_id)<ul>
				<li>prints an infosheet about a supplypack</li>
			</ul></li>
			<li>packlist<ul>
				<li>prints a list of all supplypacks</li>
			</ul></li>
			<li>orderinfo (order_id)<ul>
				<li>prints an infosheet about an order</li>
			</ul></li>
			<li>orderlist<ul>
				<li>prints a list of all placed orders</li>
			</ul></li>
			<li>requestinfo<ul>
				<li>prints an infosheet about a command order</li>
			</ul></li>
			<li>requestlist<ul>
				<li>prints a list of all active command orders</li>
			</ul></li>
			<li>sendtruck<ul>
				<li>sends the truck</li>
			</ul></li>
			<li>truckstatus<ul>
				<li>returns the current status of the truck</li>
			</ul></li>"}
	update_icon()


/obj/machinery/computer/supply
	name = "Supply requests radio"
	icon = 'icons/obj/computer.dmi'
	icon_state = "request"
	req_access = list(access_cargo)
	circuit = "/obj/item/weapon/circuitboard/orderradio"
	var/datum/radionet/radionet

/obj/machinery/computer/supply/New()
	..()
	var/datum/radionet/RN = new()
	for(var/obj/structure/radio_cable/C in loc)
		if(C.radionet != RN)
			C.propagateRadionet(RN)

/obj/machinery/computer/supply/Destroy()
	. = ..()
	radionet.remove_radio(src)

/obj/machinery/computer/supply/attack_ai(var/mob/user as mob)
	add_hiddenprint(user)
	return attack_hand(user)

/obj/machinery/computer/supply/attack_hand(var/mob/user as mob)
	if(..())
		return

	user.set_machine(src)
	interact(user)
	return

/obj/machinery/computer/supply/interact(var/mob/user)
	if(!checkConnection())
		return 0

	commandResponse("Please state your authorization.")
	//authorization fluff
	var/obj/item/weapon/card/id/card = user.get_id_card()	
	var/id = copytext(replacetext(replacetext(splittext("\ref[card]", "x")[2], "]",""), "", "-"), 2) //this just takes the last bit of the ref and puts - between them
	user.say("This is [(card && card.registered_name) ? card.registered_name : user.name]. Authorization [id]")
	
	if(!check_access(card))
		commandResponse("Authorization denied. Who is this?")
		return 0

	doCommand(user)

/obj/machinery/computer/supply/proc/checkConnection()
	if(!radionet || !radionet.hub || radionet.hub.broken)
		commandResponse("** BEEP ** BEEP **")
		return 0
	return 1

/*UI PROCS*/
/obj/machinery/computer/supply/proc/doCommand(var/mob/user, var/continuing)
	if(!checkConnection())
		return 0

	var/command = input(user, pick("What do you need?","Go ahead.","Listening."), "Say Command") as text|null
	if(!command)
		if(continuing)
			user.say(pick("Thats all.", "Signing off.", "Ending Transmission.", "That should be all."))
			commandResponse(pick("Got it. Signing off.", "Affirmative.", "Goodbye"))
		else
			user.say(pick("Nevermind.","Sorry, called on accident.", "Errrr, you're breaking up.", "Erm, I gotta go."))
			commandResponse(pick("Stop wasting my time.", "Keep the line clear.", "Stop fucking around."))
		return 0

	user.say("[command].")

	var/list/params = splittext(lowertext(command), " ")

	switch(trim(params[1]))
		if("order") //creates an order
			if(params.len < 2)
				commandResponse("You didn't give me a pack id.")
				return doCommand(user)

			//syntax is [pack_id]x[amount]
			var/list/orders = params.Copy(2)
			var/list/packs = list()
			var/list/inv_packids = list()
			for(var/order in orders)
				var/list/sp_param = splittext(order, "x")
				if(!radionet.hub.supply_packs["[sp_param[1]]"])
					inv_packids += sp_param[1]
					continue

				var/amount = 1
				if(sp_param.len == 2)
					if(!isnum(sp_param[2]))
						sp_param[2] = text2num(sp_param[2])
					if(isnum(sp_param[2]))
						amount = sp_param[2]
				packs["[sp_param[1]]"] = amount

			if(inv_packids.len)
				commandResponse("Order failed. You stated following invalid request numbers: [inv_packids.Join(",")]")
				return doCommand(user)
			
			if(!packs.len)
				commandResponse("You gotta give me something to order.")
				return doCommand(user)

			return doOrder(packs)
		if("cancel") //cancels an order
			return cancelOrder(trim(params[2]))	
		if("total") //returns the total order price
			commandResponse("Current order total is at [radionet.hub.getOrderPrice()].")
		if("funds") //return the total money at command
			commandResponse("Our current budget is at [radionet.hub.commandMoney].")
		if("withdraw") //places a withdraw order
			if(params.len < 2)
				commandResponse("You didn't specify an amount.")
				return doCommand(user)
			var/amount = trim(params[2])
			if(!isnum(amount))
				amount = text2num(amount)
			if(!isnum(amount))
				commandResponse(pick("At least give me a number to withdraw.","Thats not a number.","I don't understand."))
				return doCommand(user)

			radionet.hub.nextWithdrawal += amount
			commandResponse("Withdraw order updated. Now withdrawing [radionet.hub.nextWithdrawal] with next shipment.")
		if("help") //prints a help sheet for the commands
			for(var/obj/structure/receipt_printer/RP in radionet.printers)
				RP.doPrint()
				new /obj/item/weapon/paper/communication_guidelines(RP.loc)
		if("packinfo") //prints an infopaper about a supply pack
			if(params.len < 2)
				commandResponse("I'm gonna need an id with that.")
				return doCommand(user)
			var/pack_id = trim(params[2])
			if(!radionet.hub.supply_packs["[pack_id]"])
				commandResponse("There are no supply packs with that id.")
				return doCommand(user)

			for(var/obj/structure/receipt_printer/RP in radionet.printers)
				RP.doPrint()
				new /obj/item/weapon/paper/supply_pack_info(RP.loc, pack_id, radionet.hub.supply_packs["[pack_id]"])
		if("packlist") //prints a new inventory paper
			for(var/obj/structure/receipt_printer/RP in radionet.printers)
				RP.doPrint()
				new /obj/item/weapon/paper/inventory_manifest(RP.loc, radionet.hub)
		if("orderinfo") //prints an infopaper about an order
			if(params.len < 2)
				commandResponse("I'm gonna need an id with that.")
				return doCommand(user)
			var/order_id = trim(params[2])
			if(!radionet.hub.shoppinglist["[order_id]"])
				commandResponse("There are no orders with that id.")
				return doCommand(user)

			for(var/obj/structure/receipt_printer/RP in radionet.printers)
				RP.doPrint()
				new /obj/item/weapon/paper/order_form(RP.loc, radionet.hub.shoppinglist["[order_id]"], radionet.hub)
		if("orderlist") //prints a list of all active orders
			for(var/obj/structure/receipt_printer/RP in radionet.printers)
				RP.doPrint()
				new /obj/item/weapon/paper/order_list(RP.loc, radionet.hub)
		if("requestinfo") //prints an info sheet about a specific command order
			if(params.len < 2)
				commandResponse("I'm gonna need an id with that.")
				return doCommand(user)
			var/request_id = trim(params[2])
			if(!radionet.hub.command_orders["[request_id]"])
				commandResponse("There are no command orders with that id.")
				return doCommand(user)

			for(var/obj/structure/receipt_printer/RP in radionet.printers)
				RP.doPrint()
				new /obj/item/weapon/paper/command_order(RP.loc, radionet.hub.command_orders["[request_id]"])
		if("requestlist") //prints a list of all active command orders
			for(var/obj/structure/receipt_printer/RP in radionet.printers)
				RP.doPrint()
				new /obj/item/weapon/paper/request_list(RP.loc, radionet.hub)
		if("sendtruck") //sends a truck
			spawn()
				radionet.hub.truck_depart()
		if("truckstatus") //returns a rough idea of how long the truck will take
			if(!radionet.hub.moving)
				if(radionet.hub.at_base)
					commandResponse("Truck should be your location.")
				else
					commandResponse("We got the truck over here.")
			else
				commandResponse("Truck is on the road.")
		else
			commandResponse("I didn't understand that.")
	
	return doCommand(user, 1)

/obj/machinery/computer/supply/proc/commandResponse(var/message)
	for(var/mob/V in hearers(src))
		V.show_message("<b>[src]</b> says, \"[message]\"")

/obj/machinery/computer/supply/proc/doOrder(var/list/packs)
	var/obj/structure/supply_truck/T = new ()
	var/size = 0
	for(var/pack_id in packs)
		for(var/i = 0; i < packs["[pack_id]"]; i++)
			var/atom/A = radionet.hub.supply_packs["[pack_id]"].create(null)
			size += T.getSize(A)
			qdel(A)
	T.forceMove(null)

	//make our supply_order datum
	var/datum/supply_order/O = new ()
	O.packs = packs
	O.orderedby = usr
	O.id = ++radionet.hub.orderid
	O.hub = radionet.hub

	radionet.hub.shoppinglist["[O.id]"] += O
	for(var/obj/structure/receipt_printer/RP in radionet.printers)
		new /obj/item/weapon/paper/order_form(RP.loc, O, radionet.hub)

	commandResponse("Order [O.id] approved.")
	return 1

/obj/machinery/computer/supply/proc/cancelOrder(var/id)
	if(!radionet.hub.shoppinglist["[id]"])
		commandResponse("We don't have an order under that registration.")
		return 0

	radionet.hub.shoppinglist["[id]"] = null
	commandResponse("Removed order [id].")
	return 1

/obj/structure/receipt_printer
	name = "Supply Receipt Printer"
	desc = "Receives and prints papers command sends"
	icon = 'icons/obj/library.dmi'
	icon_state = "fax"
	anchored = 1
	density = 1
	var/datum/radionet/radionet

/obj/structure/receipt_printer/New()
	..()
	var/datum/radionet/RN = new()
	for(var/obj/structure/radio_cable/C in loc)
		if(C.radionet != RN)
			C.propagateRadionet(RN)

/obj/structure/receipt_printer/Destroy()
	..()
	radionet.remove_printer(src)

/obj/structure/receipt_printer/proc/doPrint()
	playsound(src, 'sound/machines/printer.ogg')