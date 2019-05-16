/datum/event/shipping_error/start()
	var/datum/supply_order/O = new /datum/supply_order()
	O.object = pick(subtypesof(/datum/supply_pack))
	O.orderedby = random_name(pick(MALE,FEMALE), species = SPECIES_HUMAN)
	SSsupply_truck.shoppinglist += O
