var/global/current_command_order_id=124901

/datum/command_order
	var/id = 0 // Some bullshit ID we use for fluff.
	var/name = "Command" // Name of the ordering entity. Fluff.

	// Amount decided upon
	var/worth = 0

	var/must_be_in_crate = 0
	var/permanent = 0

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
/datum/command_order/proc/getRequestsByName(var/html_format = 0)
	var/manifest = ""
	if(html_format)
		manifest = "<ul>"
	for(var/path in requested)
		if(!path)
			continue
		var/atom/movable/AM = path
		if(html_format)
			manifest += "<li>[initial(AM.name)], amount: [requested[path]]</li>"
		else
			manifest += "[initial(AM.name)], amount: [requested[path]]"
	if(html_format)
		manifest += "</ul>"
	return manifest

//creates a fulfilled manifest
/datum/command_order/proc/getFulfilledByName(var/html_format = 0)
	var/manifest = ""
	if(html_format)
		manifest = "<ul>"
	for(var/path in fulfilled)
		if(!path)
			continue
		var/atom/movable/AM = path
		if(html_format)
			manifest += "<li>[initial(AM.name)], amount: [fulfilled[path]]</li>"
		else
			manifest += "[initial(AM.name)], amount: [fulfilled[path]]"
	if(html_format)
		manifest += "</ul>"
	return manifest

/datum/command_order/proc/onFulfilled()
	return

/datum/command_order/proc/shouldRemove()
	if(permanent)
		return 0
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

/datum/command_order/per_unit/per_reagent/trySellObj(var/obj/O)
	if(!O.reagents || !O.reagents.reagent_list.len)
		return 0

	for(var/datum/reagent/R in requested)
		if(O.reagents.has_reagent(R.type))
			if(!(R.type in fulfilled))
				fulfilled[R.type]=0
			if(fulfilled[R.type]==requested[R.type])
				continue
			var/amount = O.reagents.get_reagent_amount(R.type)
			var/remainder = requested[R.type] - fulfilled[R.type]
			if(amount > remainder)
				amount = remainder
			if(amount <= 0)
				continue
			fulfilled[R.type] += amount
			O.reagents.remove_reagent(R.type, amount, 1)
			. = 1

//default order
//contains all items which will always be bought
/datum/command_order/per_unit/default
	permanent = 1
	listed = 0
	requested = list(
		/obj/item/weapon/paper/manifest = INFINITY,
		/obj/structure/reagent_dispensers/fueltank = INFINITY
	)
	unit_prices=list(
		/obj/item/weapon/paper/manifest = 2,
		/obj/structure/reagent_dispensers/fueltank = 150
	)

/datum/command_order/per_unit/per_reagent/default
	permanent = 1
	listed = 0
	requested = list(
		/datum/reagent/fuel = INFINITY,
		/datum/reagent/water = INFINITY,
	)
	unit_prices = list(
		/datum/reagent/fuel = 2,
		/datum/reagent/water = 0.5
	)