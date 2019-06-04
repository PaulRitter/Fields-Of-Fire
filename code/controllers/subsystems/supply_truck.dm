/*
relevant files:
- /code/datums/supplypacks/
contains all supplypacks
- /code/datums/command_orders/
contains all command orders
- /code/game/objects/structures/supply_truck.dm
contains supply truck
- code/game/machinery/computer/supply.dm
contains supply radio
- code\game\objects\items\weapons\circuitboards\computer\supply.dm
supply radio circuits
- code/datums/radionet.dm
radionet cable + hub + net datum
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
	//SHOULD BE 1, IS 0 FOR DEBUGGING
	var/restriction = 0 //Who can approve orders? 0 = autoapprove; 1 = has access; 2 = has an ID (omits silicons)
	var/movetimeMax = 5 SECONDS
	var/movetimeMin = 1 SECONDS
	// var/movetimeMax = 3 MINUTES //how long the truck takes
	// var/movetimeMin = 1.5 MINUTES

	//SYSTEM VARS
	//control
	var/list/command_orders = list() //orders by command that can be fulfilled
	var/list/shoppinglist = list() //approved orders that will be bought with the next shipment
	var/list/supply_packs = list() //all packs that can be ordered
	var/list/supply_radios = list() //for feedback eg. "the supply radio beeps "cargo truck arrived""
	var/list/truck_contents = list() //truck contents go here as soon as it departs
	var/commandMoney = 10000 //Money currently stored at command

	//fluff stuff
	var/price = 0 //how much we payed for the last shipment
	var/shipments = 0 //how many shipments we already had
	var/orderid = 0 //fluff for creating new orders

	//truck movement
	var/at_base = 0 //if shuttle is at base
	var/moving = 0 // 0 = shuttle not moving; 1 = shuttle is moving
	var/eta_timeofday //eta used by the ticker
	var/eta //eta to used in uis
	var/obj/structure/supply_truck/truck //to keep track of our spawned truck
	
//gets supply packs for uis
/datum/controller/subsystem/supply_truck/Initialize(timeofday)
	var/pack_id = 1
	for(var/typepath in subtypesof(/datum/supply_pack))
		supply_packs["[pack_id++]"] = new typepath()
	
	add_command_order(new /datum/command_order/per_unit/default())
	add_command_order(new /datum/command_order/per_unit/per_reagent/default())
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
		truck.update_icon()
		if(truck.contents.len)
			var/list/alreadyPrinted = list()
			for(var/obj/machinery/computer/supply/R in supply_radios)
				for(var/obj/structure/receipt_printer/RP in R.radionet.printers)
					if(RP in alreadyPrinted)
						continue
					new /obj/item/weapon/paper/truck_manifest(RP, truck.getGroupedContentList(), price, shipments)
					alreadyPrinted += RP
		allSay("Truck arrived at base.")
		at_base = 1
	else //at station
		commandMoney += sell(truck_contents)
		truck_contents.len = 0
		allSay("Truck arrived at command.")
		at_base = 0
	moving = 0

//the truck departing either from base or command
//basically sets truck_contents and handles buying from command
/datum/controller/subsystem/supply_truck/proc/depart()
	if(moving)
		allSay("Truck already in Transit.")
		return 0

	if(at_base)//at station
		if(!truck)
			//this could also trigger on truck destruction, but having this feedback only when using the radio adds a bit of immersion
			//~also its easier this way~
			allSay("We received message your truck was destroyed. We have a new one standing by at command, watch your assets!")
			at_base = 0
			return 0
		truck_contents = truck.contents
		truck.forceMove(null)
		allSay("Truck sent to Command.")
	else
		//buys all of shopping list
		truck_contents = buy()
		allSay("Truck left Command and is enroute.")
	
	//sets the eta timer
	eta_timeofday = world.timeofday + rand(movetimeMin, movetimeMax)

	moving = 1
	return 1

/datum/controller/subsystem/supply_truck/proc/getOrderPrice()
	. = 0
	for(var/orderid in shoppinglist)
		var/datum/supply_order/SO = SSsupply_truck.shoppinglist["[orderid]"]
		for(var/pack_id in SO.packs)
			. += SSsupply_truck.supply_packs["[pack_id]"].cost * SO.packs["[pack_id]"]

//tries to sell an obj to the command orders
/datum/controller/subsystem/supply_truck/proc/SellObjToOrders(var/atom/A,var/in_crate)
	// Per-unit orders run last so they don't steal shit.
	var/list/priority1=list() //normal orders here
	var/list/priority2=list() //per_unit goes here
	//here we only want to sell to reagent orders
	for(var/order_id in command_orders)
		var/datum/command_order/O = command_orders["[order_id]"]
		if(!istype(O, /datum/command_order/per_unit/per_reagent))
			if(istype(O,/datum/command_order/per_unit))
				priority2 += order_id
			else
				priority1 += order_id
			continue
		O.trySellObj(A) //no return since we aren't actually removing the obj

	//second we loop through the not-per-unit orders
	for(var/idx in priority1)
		if(command_orders["[idx]"].trySellObj(A,in_crate))
			return 1
	//check if we can sell to per-unit orders
	for(var/idx in priority2)
		if(command_orders["[idx]"].trySellObj(A,in_crate))
			return 1
	return 0

//sells items and returns total money gained
/datum/controller/subsystem/supply_truck/proc/sell(var/list/stuff)
	var/money = 0
	for(var/atom/movable/MA in stuff)
		if(istype(MA,/obj/structure/closet/crate)) //is crate
			var/obj/structure/closet/crate/C = MA
			money += C.points_per_crate

			for(var/atom/A in MA)
				SellObjToOrders(A,1)

				if(A)
					qdel(A)
		else //not a crate
			SellObjToOrders(MA,0)

		// PAY UP BITCHES
		for(var/order_id in command_orders)
			var/datum/command_order/O = command_orders["[order_id]"]
			var/pay = O.CheckFulfilled()
			money += pay
			if(O.shouldRemove())
				command_orders["[order_id]"] = null
		qdel(MA)
	return money

//buys items and returns all crates in a list
/datum/controller/subsystem/supply_truck/proc/buy()
	if(!shoppinglist.len) //no things to buy, no need to go any further
		return list()

	if(getOrderPrice() > commandMoney) //not enough money to buy
		return list()

	var/list/contents = list()

	//how much space will a truck have
	var/obj/structure/supply_truck/T = new ()

	//fluff vars
	price = 0
	shipments++
	var/size = 0

	for(var/order in shoppinglist)
		var/datum/supply_order/SO = shoppinglist["[order]"]

		var/order_size = SO.getSize()
		if(!T.hasSpace((size + order_size)))
			continue

		for(var/pack_id in SO.packs)
			var/datum/supply_pack/SP = supply_packs["[pack_id]"]
			for(var/idx = 0; idx < SO.packs["[pack_id]"]; idx++)
				//paying for the order
				commandMoney -= SP.cost
				price += SP.cost

				if(prob(0.5)) //1 in 200 crates will be lost
					continue

				var/atom/A = SP.create(SO)
				if(!SP.contraband)
					new /obj/item/weapon/paper/shipping_manifest(A, SP, shipments, SO)
				contents += A

		size += order_size
		shoppinglist.Remove(SO)
	
	T.forceMove(null)

	return contents

/datum/controller/subsystem/supply_truck/proc/add_command_order(var/datum/command_order/C)
	command_orders["[C.id]"] = C

	if(!C.listed) //if its not listed we don't need to notify them
		return

	var/list/alreadyPrinted = list()
	for(var/obj/machinery/computer/supply/R in supply_radios)
		for(var/obj/structure/receipt_printer/RP in R.radionet.printers)
			if(RP in alreadyPrinted)
				continue
			new /obj/item/weapon/paper/command_order(RP, C)
			alreadyPrinted += RP
	
	allSay("New buy order by [C.name] available.")

/datum/controller/subsystem/supply_truck/proc/allSay(var/message)
	for(var/obj/machinery/computer/supply/S in supply_radios)
		S.commandResponse("[message]")


/*
SUPPLY ORDER
*/
/datum/supply_order
	var/list/packs = null // pack_id -> amount
	var/mob/orderedby = null // who ordered it
	var/id = 0

/datum/supply_order/proc/getSize()
	. = 0
	var/obj/structure/supply_truck/T = new ()
	for(var/pack_id in packs)
		var/atom/movable/A = SSsupply_truck.supply_packs["[pack_id]"].create(null)
		. += T.getSize(A)
		A.forceMove(null)
	T.forceMove(null)

/datum/supply_order/proc/getCost()
	. = 0
	for(var/pack_id in packs)
		var/datum/supply_pack/SP = SSsupply_truck.supply_packs["[pack_id]"]
		. += SP.cost

/datum/supply_order/proc/OnConfirmed(var/mob/user)
	for(var/datum/supply_pack/SP in packs)
		SP.onApproved(user)