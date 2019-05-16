/*
relevant files:
- /code/datums/supplypacks/
contains all supplypacks
- /code/datums/command_orders/
contains all command orders
- /code/game/objects/structures/supply_truck.dm
contains supply truck
- code/game/machinery/computer/supply.dm TODO
contains supply radio
*/

/*
Possible TODO:
- truck
- arrive and depart in general
- supply radio ((needs to be connected off map with reinforced cable))
- ((overlay boxes on truck))
*/

//set by a landmark with the name "supply_truck", cannot be multiple
var/supply_truck_pos

/*
SUPPLY TRUCK SUBSYSTEM
*/
SUBSYSTEM_DEF(supply_truck)
	name		= "Supply Truck"
	init_order	= INIT_ORDER_SUPPLY_TRUCK
	flags		= SS_NO_TICK_CHECK
	wait		= 1 SECONDS

	//CONFIG VARS
	var/money_per_crate = 5 //how much command pays per crate
	var/restriction = 1 //Who can approve orders? 0 = autoapprove; 1 = has access; 2 = has an ID (omits silicons); 3 = actions require PIN
	var/movetime = 2 MINUTES //how long the truck takes

	//SYSTEM VARS
	//control
	var/list/command_orders = list() //orders by command that can be fulfilled
	var/list/shoppinglist = list() //approved orders that will be bought with the next shipment
	var/list/requestlist = list() //requested orders that haven't been approved yet
	var/list/supply_packs = list() //all packs that can be ordered
	var/list/supply_radio = list() //for feedback eg. "the supply radio beeps "cargo truck arrived""
	var/list/truck_contents = list() //truck contents go here as soon as it departs
	var/commandMoney = 0 //Money currently stored at command

	//truck movement
	var/at_base = 0 //if shuttle is at base
	var/moving = 0 // 0 = shuttle not moving; 1 = shuttle is moving
	var/eta_timeofday //eta used by the ticker
	var/eta //eta to used in uis
	var/obj/structure/supply_truck/truck //to keep track of our spawned truck
	
//gets supply packs for uis
/datum/controller/subsystem/supply_truck/Initialize(timeofday)
	materials_list = new
	for(var/typepath in subtypesof(/datum/supply_pack))
		var/datum/supply_pack/P = new typepath
		supply_packs[P.name] = P
	..()

//ticker for the eta
/datum/controller/subsystem/supply_truck/fire(resumed = FALSE)
	if(moving == 1)
		var/ticksleft = eta_timeofday - world.timeofday

		if(ticksleft > 0)
			eta = round(ticksleft / 600, 1)
		else
			eta = 0
			arrive()

//the truck arriving either at base or at command
//receives truck_contents and handles selling to command
/datum/controller/subsystem/supply_truck/proc/arrive()
	if(!at_base) //not at station
		if(!supply_truck_pos)
			message_admins("No Truck pos set, some smoothbrain mapper fucked up")
			return
		truck = new (supply_truck_pos)
		truck.contents = truck_contents
		truck_contents.len = 0
		allSay("Truck arrived at base.")
		at_base = 1
	else //at station
		allSay("Truck arrived at command.")
		commandMoney += sell(truck_contents)
		truck_contents.len = 0
		at_base = 0
	moving = 0

//the truck departing either from base or command
//basically sets truck_contents and handles buying from command
/datum/controller/subsystem/supply_truck/proc/depart()
	if(at_base)//at station
		if(!truck)
			//this could also trigger on truck destruction, but having this feedback only when using the radio adds a bit of immersion
			allSay("We received message your truck was destroyed. We have a new one standing by at command, watch your assets!")
			at_base = 0
			return 0
		truck_contents = truck.contents
		truck.forceMove(null)
		allSay("Truck is sent. Arrival at Command in T-2 Minutes.")
	else
		//buys all of shopping list
		truck_contents = buy()
		if(!truck_contents)
			allSay("Order failed.")
			return 0
		allSay("Order received - Truck is sent.")
	
	//sets the eta timer
	eta_timeofday = world.timeofday + movetime
	moving = 1
	return 1

/datum/controller/subsystem/supply_truck/proc/getOrderPrice()
	. = 0
	for(var/datum/supply_order in shoppinglist)
		. += supply_order.object.cost

/datum/controller/subsystem/supply_truck/proc/SellObjToOrders(var/atom/A,var/in_crate)
	// Per-unit orders run last so they don't steal shit.
	var/list/deferred_order_checks=list()
	var/order_idx=0
	for(var/datum/command_order/O in command_orders)
		order_idx++
		if(istype(O,/datum/command_order/per_unit))
			deferred_order_checks += order_idx
		if(O.trySellObj(A,in_crate))
			return 1
	for(var/oid in deferred_order_checks)
		var/datum/command_order/O = command_orders[oid]
		if(O.trySellObj(A,in_crate))
			return 1
	return 0

//sells items and returns total money gained
/datum/controller/subsystem/supply_truck/proc/sell(var/list/stuff)
	var/money = 0
	for(var/atom/movable/MA in stuff)
		if(istype(MA,/obj/structure/closet/crate)) //is crate
			money += money_per_crate

			for(var/atom/A in MA)
				SellObjToOrders(A,1)

				if(A)
					qdel(A)
		else //not a crate
			SellObjToOrders(MA,0)

		// PAY UP BITCHES
		for(var/datum/command_order/O in command_orders)
			var/pay = O.CheckFulfilled()
			money += pay
			if(pay)
				command_orders.Remove(O)
		qdel(MA)
	return money

//buys items and returns all crates in a list
/datum/controller/subsystem/supply_truck/proc/buy()
	if(!shoppinglist.len) //no things to buy, no need to go any further
		return 0

	if(getOrderPrice() > commandMoney) //not enough money to buy
		return 0

	var/list/contents = list()
	for(var/datum/supply_order/SO in shoppinglist)
		var/datum/supply_pack/SP = SO.object
		var/atom/A = new SP.containertype()
		A.name = "[SP.containername] [SO.comment ? "([SO.comment])":"" ]"

		//supply manifest generation begin

		var/obj/item/weapon/paper/manifest/slip = new /obj/item/weapon/paper/manifest(A)

		slip.name = "Shipping Manifest for [SO.orderedby]'s Order"
		slip.info = {"<h3>[command_name()] Shipping Manifest for [SO.orderedby]'s Order</h3><hr><br>
			Order #[SO.ordernum]<br>
			Destination: [station_name]<br>
			[shoppinglist.len] PACKAGES IN THIS SHIPMENT<br>
			CONTENTS:<br><ul>"}
		//spawn the stuff, finish generating the manifest while you're at it
		if(SP.access && istype(A, /obj/structure/closet))
			A.req_access = SP.req_access

		if(SP.one_access && istype(A, /obj/structure/closet))
			A.req_one_access = SP.req_one_access

		for(var/typepath in SP.contains)
			if(!typepath)
				continue
			var/atom/B2 = new typepath(A)
			if(B2:amount)
				B2:amount = SP.contains[typepath]
			else
				for(var/i=1, i<SP.contains[typepath], i++) //one less since we already made one (B2)
					var/atom/tempB = new typepath(A)
			slip.info += "<li>[B2.name] ([SP.contains[typepath]])</li>" //add the item to the manifest

		SP.post_creation(A)

		//manifest finalisation

		slip.info += {"</ul><br>
			CHECK CONTENTS AND STAMP BELOW THE LINE TO CONFIRM RECEIPT OF GOODS<hr>"}
		if (SP.contraband)
			slip.forceMove(null)	//we are out of blanks for Form #44-D Ordering Illicit Drugs.
		commandMoney -= SP.cost
		shoppinglist.Remove(SO)

		contents += A
	return contents

/datum/controller/subsystem/supply_truck/proc/confirm_order(datum/supply_order/O,mob/user,var/position) //position represents where it falls in the request list
	var/datum/supply_pack/P = O.object

	if((commandMoney - getOrderPrice()) >= P.cost)
		requestlist.Cut(position,position+1)
		shoppinglist += O
	else
		to_chat(user, "<span class='warning'>Command does not have enough funds for this request.</span>")

/datum/controller/subsystem/supply_truck/proc/add_command_order(var/datum/command_order/C)
	command_orders.Add(C)
	var/name = "External order form - [C.name] order number [C.id]"
	var/info = {"<h3>Central command supply requisition form</h3><hr>
	 			INDEX: #[C.id]<br>
	 			REQUESTED BY: [C.name]<br>
	 			MUST BE IN CRATE: [C.must_be_in_crate ? "YES" : "NO"]<br>
	 			REQUESTED ITEMS:<br>
	 			[C.getRequestsByName(1)]
	 			WORTH: [C.worth] credits TO [C.acct_by_string]
	 			"}

	for(var/obj/machinery/computer/supplyradio/S in supply_consoles)
		var/obj/item/weapon/paper/reqform = new /obj/item/weapon/paper(S.loc)
		reqform.name = name
		reqform.info = info
		reqform.update_icon()
	
	allSay("New buy order by [C.name] available.")

/datum/controller/subsystem/supply_truck/proc/allSay(var/message)
	for(var/obj/machinery/computer/supplyradio/S in supply_consoles)
		S.say(message)


/*
SUPPLY ORDER
*/
/datum/supply_order
	var/datum/supply_pack/object = null
	var/orderedby = null // who ordered it
	var/authorized_name = null // who approved it
	var/comment = null

/datum/supply_order/proc/OnConfirmed(var/mob/user)
	object.OnConfirmed(user)