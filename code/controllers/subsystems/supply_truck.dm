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

var/station_name = "TODO find where to get this var"

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
	var/list/requestlist = list() //requested orders that haven't been approved yet
	var/list/supply_packs = list() //all packs that can be ordered
	var/list/supply_radios = list() //for feedback eg. "the supply radio beeps "cargo truck arrived""
	var/list/truck_contents = list() //truck contents go here as soon as it departs
	var/commandMoney = 10000 //Money currently stored at command

	//fluff stuff
	var/price = 0 //how much we payed for the last shipment
	var/shipments = 0 //how many shipments we already had

	//truck movement
	var/at_base = 0 //if shuttle is at base
	var/moving = 0 // 0 = shuttle not moving; 1 = shuttle is moving
	var/eta_timeofday //eta used by the ticker
	var/eta //eta to used in uis
	var/obj/structure/supply_truck/truck //to keep track of our spawned truck
	
//gets supply packs for uis
/datum/controller/subsystem/supply_truck/Initialize(timeofday)
	for(var/typepath in subtypesof(/datum/supply_pack))
		var/datum/supply_pack/P = new typepath
		supply_packs[P.name] = P

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
			for(var/obj/machinery/computer/supply/administration/R in supply_radios)
				new /obj/item/weapon/paper/truck_manifest(R.loc, truck.getGroupedContentList(), price, shipment)
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
		if(!truck_contents)
			allSay("Order failed.")
			return 0
		allSay("Truck left Command and is enroute.")
	
	//sets the eta timer
	eta_timeofday = world.timeofday + rand(movetimeMin, movetimeMax)

	moving = 1
	return 1

/datum/controller/subsystem/supply_truck/proc/getOrderPrice()
	. = 0
	for(var/datum/supply_order/SO in shoppinglist)
		. += SO.object.cost

//tries to sell an obj to the command orders
/datum/controller/subsystem/supply_truck/proc/SellObjToOrders(var/atom/A,var/in_crate)
	// Per-unit orders run last so they don't steal shit.
	var/list/priority1=list() //normal orders here
	var/list/priority2=list() //per_unit goes here
	//here we only want to sell to reagent orders
	for(var/idx = 1; idx <= command_orders.len; idx++)
		var/datum/command_order/O = command_orders[idx]
		if(!istype(O, /datum/command_order/per_unit/per_reagent))
			if(istype(O,/datum/command_order/per_unit))
				priority2 += idx
			else
				priority1 += idx
			continue
		if(O.trySellObj(A))
			return 1

	//second we loop through the not-per-unit orders
	for(var/idx in priority1)
		if(command_orders[idx].trySellObj(A,in_crate))
			return 1
	//check if we can sell to per-unit orders
	for(var/idx in priority2)
		if(command_orders[idx].trySellObj(A,in_crate))
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
		for(var/datum/command_order/O in command_orders)
			var/pay = O.CheckFulfilled()
			money += pay
			if(O.shouldRemove())
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
	
	//how much space will a truck have
	var/obj/structure/supply_truck/T = new ()
	var/space = T.getSpace()
	T.forceMove(null)

	var/list/toBuy = list()
	if(shoppinglist.len > space)
		toBuy = shoppinglist.Copy(1,space+1)
		shoppinglist.Cut(1,space+1)
	else
		toBuy = shoppinglist.Copy()
		shoppinglist.len = 0

	//fluff vars
	price = 0
	shipments++

	for(var/datum/supply_order/SO in toBuy)
		var/datum/supply_pack/SP = SO.object

		//paying for the order
		commandMoney -= SP.cost
		price += SP.cost
		shoppinglist.Remove(SO)

		if(prob(0.5)) //1 in 200 crates will be lost
			continue

		var/atom/A = new SP.containertype()
		A.name = "[SP.containername] [SO.comment ? "([SO.comment])":"" ]"

		//spawn the stuff, finish generating the manifest while you're at it
		if(istype(A, /obj/structure/closet))
			var/obj/structure/closet/C = A
			if(SP.req_access)
				C.req_access = SP.req_access

			if(SP.req_one_access)
				C.req_one_access = SP.req_one_access

		for(var/typepath in SP.contains)
			if(!typepath)
				continue
			var/atom/B2 = new typepath(A)
			if(istype(B2, /obj/item/stack))
				var/obj/item/stack/ST = B2
				ST.amount = SP.contains[typepath]
			else
				for(var/i=1, i<SP.contains[typepath], i++) //one less since we already made one (B2)
					new typepath(A)

		var/obj/item/weapon/paper/shipping_manifest/slip = new(A, SO, shipments)

		SP.post_creation(A)

		if (SP.contraband)
			slip.forceMove(null)	//we are out of blanks for Form #44-D Ordering Illicit Drugs.

		contents += A
	return contents

/datum/controller/subsystem/supply_truck/proc/confirm_order(datum/supply_order/O,mob/user,var/position, var/wasAutoConfirmed) //position represents where it falls in the request list
	var/datum/supply_pack/P = O.object

	if((commandMoney - getOrderPrice()) >= P.cost)
		requestlist.Cut(position,position+1)
		O.authorizedby = user
		shoppinglist += O
		if(!wasAutoConfirmed)
			O.OnConfirmed(user)
	else
		to_chat(user, "<span class='warning'>Command does not have enough funds for this request.</span>")

/datum/controller/subsystem/supply_truck/proc/add_command_order(var/datum/command_order/C)
	command_orders.Add(C)

	if(!C.listed) //if its not listed we don't need to notify them
		return

	for(var/obj/machinery/computer/supply/administration/S in supply_radios)
		var/obj/item/weapon/paper/command_order/slip = new (S, C)
	
	allSay("New buy order by [C.name] available.")

/datum/controller/subsystem/supply_truck/proc/allSay(var/message)
	for(var/obj/machinery/computer/supply/administration/S in supply_radios)
		S.visible_message("<span class='notice'>[message]</span>")


/*
SUPPLY ORDER
*/
/datum/supply_order
	var/datum/supply_pack/object = null
	var/mob/orderedby = null // who ordered it
	var/mob/authorizedby = null // who approved it
	var/comment = null

/datum/supply_order/proc/OnConfirmed(var/mob/user)
	object.onApproved(user)