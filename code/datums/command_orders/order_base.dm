var/global/current_command_order_id=124901

/datum/command_order
	var/id = 0 // Some bullshit ID we use for fluff.
	var/name = "Command" // Name of the ordering entity. Fluff.

	// Amount decided upon
	var/worth = 0

	var/must_be_in_crate = 0

	var/list/requested=list()
	var/list/fulfilled=list()

	var/listed = 1 //if the order is to be listed on the cargo radio

/datum/command_order/New()
	..()
	id = current_command_order_id++

//tries to sell obj; 0 = fail; 1 = success, obj got removed
/datum/command_order/proc/trySellObj(var/obj/O, var/in_crate)
	if(must_be_in_crate && !in_crate)
		return 0
	if(!O)
		return 0
	if(O.type in requested)
		var/amount = 1
		if(istype(O, /obj/item/stack)) //use stack amount if O is stack
			var/obj/item/stack/S = O
			amount = S.amount
		if(!(O.type in fulfilled)) //create entry in fulfilled if noone already exists
			fulfilled[O.type]=0
		if(fulfilled[O.type]==requested[O.type]) // if we already have our desired amount
			return 0
		fulfilled[O.type]+=amount
		qdel(O)
		return 1
	return 0

//if the order is fulfilled, returns what they get paid
/datum/command_order/proc/CheckFulfilled()
	for(var/typepath in requested)
		if(!(typepath in fulfilled) || fulfilled[typepath] < requested[typepath])
			return 0
	onFulfilled()
	return worth

//UI FLUFF
//creates a requests manifest
/datum/command_order/proc/getRequestsByName()
	var/manifest = "<ul>"
	for(var/path in requested)
		if(!path)
			continue
		var/atom/movable/AM = path
		manifest += "<li>[initial(AM.name)]"
		if(requested[path] != INFINITY)
			manifest += "<ul><li>still required: [requested[path]]</li><li>shipped: [fulfilled[path]]</li></ul></li>"
		manifest += "</li>"
	manifest += "</ul>"
	return manifest

/datum/command_order/proc/onFulfilled()
	return

/datum/command_order/proc/shouldRemove()
	var/sum = 0
	for(var/typepath in requested)
		sum += requested[typepath]
	return !sum //if its 0, we can remove, so we return 1

// These run last to not steal items from other orders
/datum/command_order/per_unit
	var/list/unit_prices=list()

// Same as normal, but will take every last bit of what you provided.
/datum/command_order/per_unit/trySellObj(var/obj/O, var/in_crate)
	if(must_be_in_crate && !in_crate)
		return 0
	if(!O)
		return 0
	if(O.type in requested)
		if(!(O.type in fulfilled))
			fulfilled[O.type]=0
		if(fulfilled[O.type]==requested[O.type])
			return 0
		fulfilled[O.type]++
		qdel(O)
		return 1

/datum/command_order/per_unit/CheckFulfilled()
	var/toPay=0
	for(var/typepath in fulfilled)
		var/worth_per_unit = unit_prices[typepath]
		var/amount         = fulfilled[typepath]
		toPay += amount * worth_per_unit
		if(requested[typepath]!=INFINITY)
			requested[typepath] = max(0,requested[typepath] - fulfilled[typepath])
		fulfilled[typepath]=0
	if(toPay)
		onFulfilled()
	return toPay

/datum/command_order/per_unit/getRequestsByName()
	var/manifest = "<ul>"
	for(var/path in requested)
		if(!path)
			continue
		var/atom/movable/AM = path
		manifest += "<li>[initial(AM.name)] - [unit_prices[path]] per Unit"
		if(requested[path] != INFINITY)
			manifest += "<ul><li>still required: [requested[path]]</li><li>shipped: [fulfilled[path]]</li></ul></li>"
		manifest += "</li>"
	manifest += "</ul>"
	return manifest

/datum/command_order/per_unit/per_reagent/trySellObj(var/obj/O)
	if(!O.reagents || !O.reagents.reagent_list.len)
		return 0

	for(var/reagent_type in requested)
		if(O.reagents.has_reagent(reagent_type))
			if(!(reagent_type in fulfilled))
				fulfilled[reagent_type]=0
			if(fulfilled[reagent_type]==requested[reagent_type])
				continue
			var/amount = O.reagents.get_reagent_amount(reagent_type)
			var/remainder = requested[reagent_type] - fulfilled[reagent_type]
			if(amount > remainder)
				amount = remainder
			if(amount <= 0)
				continue
			fulfilled[reagent_type] += amount
			O.reagents.remove_reagent(reagent_type, amount, 1)
			. = 1

//default order
//contains all items which will always be bought
/datum/command_order/per_unit/default
	listed = 0
	requested = list(
		/obj/item/weapon/paper/shipping_manifest = INFINITY,
		/obj/structure/reagent_dispensers/fueltank = INFINITY
	)
	unit_prices=list(
		/obj/item/weapon/paper/shipping_manifest = 2,
		/obj/structure/reagent_dispensers/fueltank = 50
	)

/datum/command_order/per_unit/per_reagent/default
	listed = 0
	requested = list(
		/datum/reagent/fuel = INFINITY,
		/datum/reagent/water = INFINITY,
	)
	unit_prices = list(
		/datum/reagent/fuel = 0.4,
		/datum/reagent/water = 0.01
	)