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

//set by /obj/effect/landmark/supply_truck, their faction_id will be the key
var/list/supply_truck_pos = list()

// *** HUB ***
/obj/structure/radio_hub
	name = "Radio HUB"
	desc = "This HUB relays all received signals to command. Do not tamper."
	icon = 'icons/placeholders/comm_tower.dmi'
	icon_state = "comm_tower"
	anchored = 1
	density = 1
	plane = ABOVE_HUMAN_PLANE
	layer = ABOVE_HUMAN_LAYER
	var/datum/radionet/radionet
	var/faction_id //used to link to truck spawner ~and maybe other things later on~

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
	var/list/truck_contents = list() //truck contents go here as soon as it departs
	var/commandMoney = 10000 //Money currently stored at command
	var/nextWithdrawal = 0
	var/transitCost = 0

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

	var/broken = FALSE //is it broken?

/obj/structure/radio_hub/New()
	..()
	if(!faction_id)
		message_admins("there is a radio hub which holds no faction_id at x:[loc.x] y:[loc.y] z:[loc.z], someone spawned some fucky stuff or some smoothbrain mapper fucked up.")
		qdel(src)
		return 0

	//setting up our cargo system
	var/pack_id = 1
	for(var/typepath in subtypesof(/datum/supply_pack))
		supply_packs["[pack_id++]"] = new typepath()

	transitCost = rand(20,30)
	
	add_command_order(new /datum/command_order/per_unit/default())
	add_command_order(new /datum/command_order/per_unit/per_reagent/default())

	//finding a connected radionet
	var/datum/radionet/RN = new()
	for(var/obj/structure/radio_cable/C in loc)
		if(C.radionet != RN)
			C.propagateRadionet(RN)

//the truck arriving either at base or at command
//receives truck_contents and handles selling to command
/obj/structure/radio_hub/proc/truck_arrive()
	if(!at_base) //not at station
		if(!supply_truck_pos[faction_id])
			message_admins("No Truck pos set, some smoothbrain mapper fucked up")
			return
		truck = new (supply_truck_pos[faction_id])
		truck.contents = truck_contents
		truck_contents.len = 0
		truck.update_icon()
		if(truck.contents.len)
			var/list/alreadyPrinted = list()
			for(var/obj/structure/receipt_printer/RP in radionet.printers)
				if(RP in alreadyPrinted)
					continue
				new /obj/item/weapon/paper/truck_manifest(RP, truck.getGroupedContentList(), price, shipments)
				alreadyPrinted += RP
		allSay("Truck arrived at Base.")
		at_base = 1
	else //at station
		commandMoney += sell(truck_contents)
		truck_contents.len = 0
		allSay("Truck arrived at Command.")
		at_base = 0
	moving = 0

//the truck departing either from base or command
//basically sets truck_contents and handles buying from command
/obj/structure/radio_hub/proc/truck_depart()
	if(moving)
		allSay("Truck already in transit.")
		return 0

	if(at_base)//at station
		if(!truck)
			//this could also trigger on truck destruction, but having this feedback only when using the radio adds a bit of immersion
			//~also its easier this way~
			allSay("We received message that your truck was destroyed. We have a new one standing by at command, watch your assets!")
			at_base = 0
			return 0
		truck_contents = truck.contents
		truck.forceMove(null)
		allSay("Truck sent to Command.")
	else
		//buys all of shopping list
		var/list/L = buy()
		if(!L) //if buy failed we need to abort and not send the truck
			return 0
		truck_contents = L
		commandMoney -= transitCost
		allSay("Truck left Command and is enroute.")
	
	moving = 1
	spawn(rand(movetimeMin, movetimeMax))
		if(moving)
			truck_arrive()
	return 1

/obj/structure/radio_hub/proc/getOrderPrice()
	. = nextWithdrawal + transitCost
	for(var/orderid in shoppinglist)
		var/datum/supply_order/SO = shoppinglist["[orderid]"]
		for(var/pack_id in SO.packs)
			. += supply_packs["[pack_id]"].cost * SO.packs["[pack_id]"]

//tries to sell an obj to the command orders
/obj/structure/radio_hub/proc/SellObjToOrders(var/atom/A,var/in_crate)
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
/obj/structure/radio_hub/proc/sell(var/list/stuff)
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
/obj/structure/radio_hub/proc/buy()
	if(getOrderPrice() > commandMoney) //not enough money to buy
		allSay("Couldn't afford to send the truck. You are [getOrderPrice() - commandMoney]$ over budget.")
		return 0

	var/list/contents = list()

	//how much space will a truck have
	var/obj/structure/supply_truck/T = new ()

	//fluff vars
	price = 0
	shipments++
	var/size = 0

	if(nextWithdrawal)
		var/obj/structure/closet/crate/crate = new ()
		crate.name = "Withdrawal Order"
		spawn_money(nextWithdrawal, crate)
		new /obj/item/weapon/paper/withdrawal_order(crate, nextWithdrawal, shipments)
		commandMoney -= nextWithdrawal
		nextWithdrawal = 0
		contents += crate

	var/doBreak = 0
	for(var/order in shoppinglist)
		var/datum/supply_order/SO = shoppinglist["[order]"]
		var/order_size = 0

		for(var/pack_id in SO.packs)
			var/datum/supply_pack/SP = supply_packs["[pack_id]"]
			
			var/idx
			for(idx = 0; idx < SO.packs["[pack_id]"]; idx++)
				var/atom/A = SP.create(SO)
				if(!T.hasSpace(size + order_size + T.getSize(A))) //can it fit in the truck?
					doBreak = 1
					break

				//paying for the order
				commandMoney -= SP.cost
				price += SP.cost

				if(prob(0.5)) //1 in 200 crates will be lost
					continue

				if(!SP.contraband)
					new /obj/item/weapon/paper/shipping_manifest(A, SP, shipments, SO)
				contents += A
				order_size++
			
			SO.packs["[pack_id]"] -= idx

			if(doBreak)
				break

		if(doBreak)
			break

		size += order_size
		shoppinglist.Remove(SO)
	
	T.forceMove(null)

	return contents

/obj/structure/radio_hub/proc/add_command_order(var/datum/command_order/C)
	command_orders["[C.id]"] = C

	if(!C.listed) //if its not listed we don't need to notify them
		return

	var/list/alreadyPrinted = list()
	for(var/obj/structure/receipt_printer/RP in radionet.printers)
		if(RP in alreadyPrinted)
			continue
		new /obj/item/weapon/paper/command_order(RP, C)
		alreadyPrinted += RP

	allSay("Hey, we got a new buy order up. Id is [C.id]")

/obj/structure/radio_hub/proc/allSay(var/message)
	for(var/obj/machinery/computer/supply/S in radionet.radios)
		S.commandResponse("[message]")

/obj/structure/radio_hub/Destroy()
	broken = TRUE
	return QDEL_HINT_LETMELIVE

#define RADIO_HUB_REPAIR_CABLE_AMOUNT 10
/obj/structure/radio_hub/attackby(obj/item/O, mob/user)
	if(istype(O, /obj/item/stack/radio_cable))
		var/obj/item/stack/radio_cable/S = O
		if(!S.can_use(RADIO_HUB_REPAIR_CABLE_AMOUNT))
			to_chat(user, "<span class='notice'>You don't have enough [S.singular_name] to repair \the [src]</span>")
			return 0

		to_chat(user, "<span class='notice'>You start repairing \the [src]</span>")
		user.visible_message("<span class='notice'>[user] starts repairing \the [src]</span>")
		if(do_after(user, 10 SECONDS, src))
			if(!S.can_use(RADIO_HUB_REPAIR_CABLE_AMOUNT))
				to_chat(user, "<span class='notice'>You finish repairing \the [src]</span>")
				user.visible_message("<span class='notice'>[user] finishes repairing \the [src]</span>")
				return 0

			broken = FALSE
			S.use(RADIO_HUB_REPAIR_CABLE_AMOUNT)
			return 1
	return 0
#undef RADIO_HUB_REPAIR_CABLE_AMOUNT

/obj/structure/radio_hub/faction_1
	faction_id = "faction_1"

/obj/structure/radio_hub/faction_2
	faction_id = "faction_2"

/*
SUPPLY ORDER
*/
/datum/supply_order
	var/list/packs = null // pack_id -> amount
	var/mob/orderedby = null // who ordered it
	var/id = 0
	var/obj/structure/radio_hub/hub //what hub it got ordered over

/datum/supply_order/proc/getSize()
	. = 0
	var/obj/structure/supply_truck/T = new ()
	for(var/pack_id in packs)
		var/atom/movable/A = hub.supply_packs["[pack_id]"].create(null)
		. += T.getSize(A) * packs["[pack_id]"]
		A.forceMove(null)
	T.forceMove(null)

/datum/supply_order/proc/getCost()
	. = 0
	for(var/pack_id in packs)
		var/datum/supply_pack/SP = hub.supply_packs["[pack_id]"]
		. += SP.cost

/datum/supply_order/proc/OnConfirmed(var/mob/user)
	for(var/datum/supply_pack/SP in packs)
		SP.onApproved(user)