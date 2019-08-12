////////////////////////////////
///// Construction datums //////
////////////////////////////////

/datum/construction/mecha/custom_action(step, atom/used_atom, mob/user)
	if(istype(used_atom, /obj/item/weapon/weldingtool))
		var/obj/item/weapon/weldingtool/W = used_atom
		if (W.remove_fuel(0, user))
			playsound(holder, 'sound/items/Welder2.ogg', 50, 1)
		else
			return 0
	else if(istype(used_atom, /obj/item/weapon/wrench))
		playsound(holder, 'sound/items/Ratchet.ogg', 50, 1)

	else if(istype(used_atom, /obj/item/weapon/screwdriver))
		playsound(holder, 'sound/items/Screwdriver.ogg', 50, 1)

	else if(istype(used_atom, /obj/item/weapon/wirecutters))
		playsound(holder, 'sound/items/Wirecutter.ogg', 50, 1)

	else if(istype(used_atom, /obj/item/stack/cable_coil))
		var/obj/item/stack/cable_coil/C = used_atom
		if(C.use(4))
			playsound(holder, 'sound/items/Deconstruct.ogg', 50, 1)
		else
			to_chat(user, ("There's not enough cable to finish the task."))
			return 0
	else if(istype(used_atom, /obj/item/stack))
		var/obj/item/stack/S = used_atom
		if(S.get_amount() < 5)
			to_chat(user, ("There's not enough material in this stack."))
			return 0
		else
			S.use(5)
	return 1

/datum/construction/reversible/mecha/custom_action(index as num, diff as num, atom/used_atom, mob/user as mob)
	if(istype(used_atom, /obj/item/weapon/weldingtool))
		var/obj/item/weapon/weldingtool/W = used_atom
		if (W.remove_fuel(0, user))
			playsound(holder, 'sound/items/Welder2.ogg', 50, 1)
		else
			return 0
	else if(istype(used_atom, /obj/item/weapon/wrench))
		playsound(holder, 'sound/items/Ratchet.ogg', 50, 1)

	else if(istype(used_atom, /obj/item/weapon/screwdriver))
		playsound(holder, 'sound/items/Screwdriver.ogg', 50, 1)

	else if(istype(used_atom, /obj/item/weapon/wirecutters))
		playsound(holder, 'sound/items/Wirecutter.ogg', 50, 1)

	else if(istype(used_atom, /obj/item/stack/cable_coil))
		var/obj/item/stack/cable_coil/C = used_atom
		if(C.use(4))
			playsound(holder, 'sound/items/Deconstruct.ogg', 50, 1)
		else
			to_chat(user, ("There's not enough cable to finish the task."))
			return 0
	else if(istype(used_atom, /obj/item/stack))
		var/obj/item/stack/S = used_atom
		if(S.get_amount() < 5)
			to_chat(user, ("There's not enough material in this stack."))
			return 0
		else
			S.use(5)
	return 1


/datum/construction/mecha/ripley_chassis
	steps = list(list("key"=/obj/item/mecha_parts/part/ripley_torso),//1
					 list("key"=/obj/item/mecha_parts/part/ripley_left_arm),//2
					 list("key"=/obj/item/mecha_parts/part/ripley_right_arm),//3
					 list("key"=/obj/item/mecha_parts/part/ripley_left_leg),//4
					 list("key"=/obj/item/mecha_parts/part/ripley_right_leg)//5
					)

	custom_action(step, atom/used_atom, mob/user)
		user.visible_message("[user] has connected [used_atom] to [holder].", "You connect [used_atom] to [holder]")
		holder.overlays += used_atom.icon_state+"+o"
		qdel(used_atom)
		return 1

	action(atom/used_atom,mob/user as mob)
		return check_all_steps(used_atom,user)

	spawn_result()
		var/obj/item/mecha_parts/chassis/const_holder = holder
		const_holder.construct = new /datum/construction/reversible/mecha/ripley(const_holder)
		const_holder.icon = 'icons/mecha/mech_construction.dmi'
		const_holder.icon_state = "ripley0"
		const_holder.set_density(1)
		const_holder.overlays.len = 0
		spawn()
			qdel(src)
		return


/datum/construction/reversible/mecha/ripley
	result = /obj/mecha/working/ripley
	steps = list(
					//1
					list("key"=/obj/item/weapon/weldingtool,
							"backkey"=/obj/item/weapon/wrench,
							"desc"="External armor is wrenched."),
					//2
					 list("key"=/obj/item/weapon/wrench,
					 		"backkey"=/obj/item/weapon/crowbar,
					 		"desc"="External armor is installed."),
					 //3
					 list("key"=/obj/item/stack/material/plasteel,
					 		"backkey"=/obj/item/weapon/weldingtool,
					 		"desc"="Internal armor is welded."),
					 //4
					 list("key"=/obj/item/weapon/weldingtool,
					 		"backkey"=/obj/item/weapon/wrench,
					 		"desc"="Internal armor is wrenched"),
					 //5
					 list("key"=/obj/item/weapon/wrench,
					 		"backkey"=/obj/item/weapon/crowbar,
					 		"desc"="Internal armor is installed"),
					 //6
					 list("key"=/obj/item/stack/material/steel,
					 		"backkey"=/obj/item/weapon/screwdriver,
					 		"desc"="Peripherals control module is secured"),
					 //7
					 list("key"=/obj/item/weapon/screwdriver,
					 		"backkey"=/obj/item/weapon/crowbar,
					 		"desc"="Peripherals control module is installed"),
					 //8
					 list("key"=/obj/item/weapon/circuitboard/mecha/ripley/peripherals,
					 		"backkey"=/obj/item/weapon/screwdriver,
					 		"desc"="Central control module is secured"),
					 //9
					 list("key"=/obj/item/weapon/screwdriver,
					 		"backkey"=/obj/item/weapon/crowbar,
					 		"desc"="Central control module is installed"),
					 //10
					 list("key"=/obj/item/weapon/circuitboard/mecha/ripley/main,
					 		"backkey"=/obj/item/weapon/screwdriver,
					 		"desc"="The wiring is adjusted"),
					 //11
					 list("key"=/obj/item/weapon/wirecutters,
					 		"backkey"=/obj/item/weapon/screwdriver,
					 		"desc"="The wiring is added"),
					 //12
					 list("key"=/obj/item/stack/cable_coil,
					 		"backkey"=/obj/item/weapon/screwdriver,
					 		"desc"="The hydraulic systems are active."),
					 //13
					 list("key"=/obj/item/weapon/screwdriver,
					 		"backkey"=/obj/item/weapon/wrench,
					 		"desc"="The hydraulic systems are connected."),
					 //14
					 list("key"=/obj/item/weapon/wrench,
					 		"desc"="The hydraulic systems are disconnected.")
					)

	action(atom/used_atom,mob/user as mob)
		return check_step(used_atom,user)

	custom_action(index, diff, atom/used_atom, mob/user)
		if(!..())
			return 0

		//TODO: better messages.
		switch(index)
			if(14)
				user.visible_message("[user] connects [holder] hydraulic systems", "You connect [holder] hydraulic systems.")
				holder.icon_state = "ripley1"
			if(13)
				if(diff==FORWARD)
					user.visible_message("[user] activates [holder] hydraulic systems.", "You activate [holder] hydraulic systems.")
					holder.icon_state = "ripley2"
				else
					user.visible_message("[user] disconnects [holder] hydraulic systems", "You disconnect [holder] hydraulic systems.")
					holder.icon_state = "ripley0"
			if(12)
				if(diff==FORWARD)
					user.visible_message("[user] adds the wiring to [holder].", "You add the wiring to [holder].")
					holder.icon_state = "ripley3"
				else
					user.visible_message("[user] deactivates [holder] hydraulic systems.", "You deactivate [holder] hydraulic systems.")
					holder.icon_state = "ripley1"
			if(11)
				if(diff==FORWARD)
					user.visible_message("[user] adjusts the wiring of [holder].", "You adjust the wiring of [holder].")
					holder.icon_state = "ripley4"
				else
					user.visible_message("[user] removes the wiring from [holder].", "You remove the wiring from [holder].")
					var/obj/item/stack/cable_coil/coil = new /obj/item/stack/cable_coil(get_turf(holder))
					coil.amount = 4
					holder.icon_state = "ripley2"
			if(10)
				if(diff==FORWARD)
					user.visible_message("[user] installs the central control module into [holder].", "You install the central computer mainboard into [holder].")
					qdel(used_atom)
					holder.icon_state = "ripley5"
				else
					user.visible_message("[user] disconnects the wiring of [holder].", "You disconnect the wiring of [holder].")
					holder.icon_state = "ripley3"
			if(9)
				if(diff==FORWARD)
					user.visible_message("[user] secures the mainboard.", "You secure the mainboard.")
					holder.icon_state = "ripley6"
				else
					user.visible_message("[user] removes the central control module from [holder].", "You remove the central computer mainboard from [holder].")
					new /obj/item/weapon/circuitboard/mecha/ripley/main(get_turf(holder))
					holder.icon_state = "ripley4"
			if(8)
				if(diff==FORWARD)
					user.visible_message("[user] installs the peripherals control module into [holder].", "You install the peripherals control module into [holder].")
					qdel(used_atom)
					holder.icon_state = "ripley7"
				else
					user.visible_message("[user] unfastens the mainboard.", "You unfasten the mainboard.")
					holder.icon_state = "ripley5"
			if(7)
				if(diff==FORWARD)
					user.visible_message("[user] secures the peripherals control module.", "You secure the peripherals control module.")
					holder.icon_state = "ripley8"
				else
					user.visible_message("[user] removes the peripherals control module from [holder].", "You remove the peripherals control module from [holder].")
					new /obj/item/weapon/circuitboard/mecha/ripley/peripherals(get_turf(holder))
					holder.icon_state = "ripley6"
			if(6)
				if(diff==FORWARD)
					user.visible_message("[user] installs internal armor layer to [holder].", "You install internal armor layer to [holder].")
					holder.icon_state = "ripley9"
				else
					user.visible_message("[user] unfastens the peripherals control module.", "You unfasten the peripherals control module.")
					holder.icon_state = "ripley7"
			if(5)
				if(diff==FORWARD)
					user.visible_message("[user] secures internal armor layer.", "You secure internal armor layer.")
					holder.icon_state = "ripley10"
				else
					user.visible_message("[user] pries internal armor layer from [holder].", "You prie internal armor layer from [holder].")
					var/obj/item/stack/material/steel/MS = new /obj/item/stack/material/steel(get_turf(holder))
					MS.amount = 5
					holder.icon_state = "ripley8"
			if(4)
				if(diff==FORWARD)
					user.visible_message("[user] welds internal armor layer to [holder].", "You weld the internal armor layer to [holder].")
					holder.icon_state = "ripley11"
				else
					user.visible_message("[user] unfastens the internal armor layer.", "You unfasten the internal armor layer.")
					holder.icon_state = "ripley9"
			if(3)
				if(diff==FORWARD)
					user.visible_message("[user] installs external reinforced armor layer to [holder].", "You install external reinforced armor layer to [holder].")
					holder.icon_state = "ripley12"
				else
					user.visible_message("[user] cuts internal armor layer from [holder].", "You cut the internal armor layer from [holder].")
					holder.icon_state = "ripley10"
			if(2)
				if(diff==FORWARD)
					user.visible_message("[user] secures external armor layer.", "You secure external reinforced armor layer.")
					holder.icon_state = "ripley13"
				else
					user.visible_message("[user] pries external armor layer from [holder].", "You prie external armor layer from [holder].")
					var/obj/item/stack/material/plasteel/MS = new /obj/item/stack/material/plasteel(get_turf(holder))
					MS.amount = 5
					holder.icon_state = "ripley11"
			if(1)
				if(diff==FORWARD)
					user.visible_message("[user] welds external armor layer to [holder].", "You weld external armor layer to [holder].")
				else
					user.visible_message("[user] unfastens the external armor layer.", "You unfasten the external armor layer.")
					holder.icon_state = "ripley12"
		return 1

	spawn_result()
		..()
		feedback_inc("mecha_ripley_created",1)
		return

/datum/construction/mecha/firefighter_chassis
	steps = list(list("key"=/obj/item/mecha_parts/part/ripley_torso),//1
					 list("key"=/obj/item/mecha_parts/part/ripley_left_arm),//2
					 list("key"=/obj/item/mecha_parts/part/ripley_right_arm),//3
					 list("key"=/obj/item/mecha_parts/part/ripley_left_leg),//4
					 list("key"=/obj/item/mecha_parts/part/ripley_right_leg),//5
					 list("key"=/obj/item/clothing/suit/fire)//6
					)

	custom_action(step, atom/used_atom, mob/user)
		user.visible_message("[user] has connected [used_atom] to [holder].", "You connect [used_atom] to [holder]")
		holder.overlays += used_atom.icon_state+"+o"
		user.drop_item()
		qdel(used_atom)
		return 1

	action(atom/used_atom,mob/user as mob)
		return check_all_steps(used_atom,user)

	spawn_result()
		var/obj/item/mecha_parts/chassis/const_holder = holder
		const_holder.construct = new /datum/construction/reversible/mecha/firefighter(const_holder)
		const_holder.icon = 'icons/mecha/mech_construction.dmi'
		const_holder.icon_state = "fireripley0"
		const_holder.set_density(1)
		spawn()
			qdel(src)
		return


/datum/construction/reversible/mecha/firefighter
	result = /obj/mecha/working/ripley/firefighter
	steps = list(
					//1
					list("key"=/obj/item/weapon/weldingtool,
							"backkey"=/obj/item/weapon/wrench,
							"desc"="External armor is wrenched."),
					//2
					 list("key"=/obj/item/weapon/wrench,
					 		"backkey"=/obj/item/weapon/crowbar,
					 		"desc"="External armor is installed."),
					 //3
					 list("key"=/obj/item/stack/material/plasteel,
					 		"backkey"=/obj/item/weapon/crowbar,
					 		"desc"="External armor is being installed."),
					 //4
					 list("key"=/obj/item/stack/material/plasteel,
					 		"backkey"=/obj/item/weapon/weldingtool,
					 		"desc"="Internal armor is welded."),
					 //5
					 list("key"=/obj/item/weapon/weldingtool,
					 		"backkey"=/obj/item/weapon/wrench,
					 		"desc"="Internal armor is wrenched"),
					 //6
					 list("key"=/obj/item/weapon/wrench,
					 		"backkey"=/obj/item/weapon/crowbar,
					 		"desc"="Internal armor is installed"),

					 //7
					 list("key"=/obj/item/stack/material/plasteel,
					 		"backkey"=/obj/item/weapon/screwdriver,
					 		"desc"="Peripherals control module is secured"),
					 //8
					 list("key"=/obj/item/weapon/screwdriver,
					 		"backkey"=/obj/item/weapon/crowbar,
					 		"desc"="Peripherals control module is installed"),
					 //9
					 list("key"=/obj/item/weapon/circuitboard/mecha/ripley/peripherals,
					 		"backkey"=/obj/item/weapon/screwdriver,
					 		"desc"="Central control module is secured"),
					 //10
					 list("key"=/obj/item/weapon/screwdriver,
					 		"backkey"=/obj/item/weapon/crowbar,
					 		"desc"="Central control module is installed"),
					 //11
					 list("key"=/obj/item/weapon/circuitboard/mecha/ripley/main,
					 		"backkey"=/obj/item/weapon/screwdriver,
					 		"desc"="The wiring is adjusted"),
					 //12
					 list("key"=/obj/item/weapon/wirecutters,
					 		"backkey"=/obj/item/weapon/screwdriver,
					 		"desc"="The wiring is added"),
					 //13
					 list("key"=/obj/item/stack/cable_coil,
					 		"backkey"=/obj/item/weapon/screwdriver,
					 		"desc"="The hydraulic systems are active."),
					 //14
					 list("key"=/obj/item/weapon/screwdriver,
					 		"backkey"=/obj/item/weapon/wrench,
					 		"desc"="The hydraulic systems are connected."),
					 //15
					 list("key"=/obj/item/weapon/wrench,
					 		"desc"="The hydraulic systems are disconnected.")
					)

	action(atom/used_atom,mob/user as mob)
		return check_step(used_atom,user)

	custom_action(index, diff, atom/used_atom, mob/user)
		if(!..())
			return 0

		//TODO: better messages.
		switch(index)
			if(15)
				user.visible_message("[user] connects [holder] hydraulic systems", "You connect [holder] hydraulic systems.")
				holder.icon_state = "fireripley1"
			if(14)
				if(diff==FORWARD)
					user.visible_message("[user] activates [holder] hydraulic systems.", "You activate [holder] hydraulic systems.")
					holder.icon_state = "fireripley2"
				else
					user.visible_message("[user] disconnects [holder] hydraulic systems", "You disconnect [holder] hydraulic systems.")
					holder.icon_state = "fireripley0"
			if(13)
				if(diff==FORWARD)
					user.visible_message("[user] adds the wiring to [holder].", "You add the wiring to [holder].")
					holder.icon_state = "fireripley3"
				else
					user.visible_message("[user] deactivates [holder] hydraulic systems.", "You deactivate [holder] hydraulic systems.")
					holder.icon_state = "fireripley1"
			if(12)
				if(diff==FORWARD)
					user.visible_message("[user] adjusts the wiring of [holder].", "You adjust the wiring of [holder].")
					holder.icon_state = "fireripley4"
				else
					user.visible_message("[user] removes the wiring from [holder].", "You remove the wiring from [holder].")
					var/obj/item/stack/cable_coil/coil = new /obj/item/stack/cable_coil(get_turf(holder))
					coil.amount = 4
					holder.icon_state = "fireripley2"
			if(11)
				if(diff==FORWARD)
					user.visible_message("[user] installs the central control module into [holder].", "You install the central computer mainboard into [holder].")
					qdel(used_atom)
					holder.icon_state = "fireripley5"
				else
					user.visible_message("[user] disconnects the wiring of [holder].", "You disconnect the wiring of [holder].")
					holder.icon_state = "fireripley3"
			if(10)
				if(diff==FORWARD)
					user.visible_message("[user] secures the mainboard.", "You secure the mainboard.")
					holder.icon_state = "fireripley6"
				else
					user.visible_message("[user] removes the central control module from [holder].", "You remove the central computer mainboard from [holder].")
					new /obj/item/weapon/circuitboard/mecha/ripley/main(get_turf(holder))
					holder.icon_state = "fireripley4"
			if(9)
				if(diff==FORWARD)
					user.visible_message("[user] installs the peripherals control module into [holder].", "You install the peripherals control module into [holder].")
					qdel(used_atom)
					holder.icon_state = "fireripley7"
				else
					user.visible_message("[user] unfastens the mainboard.", "You unfasten the mainboard.")
					holder.icon_state = "fireripley5"
			if(8)
				if(diff==FORWARD)
					user.visible_message("[user] secures the peripherals control module.", "You secure the peripherals control module.")
					holder.icon_state = "fireripley8"
				else
					user.visible_message("[user] removes the peripherals control module from [holder].", "You remove the peripherals control module from [holder].")
					new /obj/item/weapon/circuitboard/mecha/ripley/peripherals(get_turf(holder))
					holder.icon_state = "fireripley6"
			if(7)
				if(diff==FORWARD)
					user.visible_message("[user] installs internal armor layer to [holder].", "You install internal armor layer to [holder].")
					holder.icon_state = "fireripley9"
				else
					user.visible_message("[user] unfastens the peripherals control module.", "You unfasten the peripherals control module.")
					holder.icon_state = "fireripley7"

			if(6)
				if(diff==FORWARD)
					user.visible_message("[user] secures internal armor layer.", "You secure internal armor layer.")
					holder.icon_state = "fireripley10"
				else
					user.visible_message("[user] pries internal armor layer from [holder].", "You prie internal armor layer from [holder].")
					var/obj/item/stack/material/plasteel/MS = new /obj/item/stack/material/plasteel(get_turf(holder))
					MS.amount = 5
					holder.icon_state = "fireripley8"
			if(5)
				if(diff==FORWARD)
					user.visible_message("[user] welds internal armor layer to [holder].", "You weld the internal armor layer to [holder].")
					holder.icon_state = "fireripley11"
				else
					user.visible_message("[user] unfastens the internal armor layer.", "You unfasten the internal armor layer.")
					holder.icon_state = "fireripley9"
			if(4)
				if(diff==FORWARD)
					user.visible_message("[user] starts to install the external armor layer to [holder].", "You start to install the external armor layer to [holder].")
					holder.icon_state = "fireripley12"
				else
					user.visible_message("[user] cuts internal armor layer from [holder].", "You cut the internal armor layer from [holder].")
					holder.icon_state = "fireripley10"
			if(3)
				if(diff==FORWARD)
					user.visible_message("[user] installs external reinforced armor layer to [holder].", "You install external reinforced armor layer to [holder].")
					holder.icon_state = "fireripley13"
				else
					user.visible_message("[user] removes the external armor from [holder].", "You remove the external armor from [holder].")
					var/obj/item/stack/material/plasteel/MS = new /obj/item/stack/material/plasteel(get_turf(holder))
					MS.amount = 5
					holder.icon_state = "fireripley11"
			if(2)
				if(diff==FORWARD)
					user.visible_message("[user] secures external armor layer.", "You secure external reinforced armor layer.")
					holder.icon_state = "fireripley14"
				else
					user.visible_message("[user] pries external armor layer from [holder].", "You prie external armor layer from [holder].")
					var/obj/item/stack/material/plasteel/MS = new /obj/item/stack/material/plasteel(get_turf(holder))
					MS.amount = 5
					holder.icon_state = "fireripley12"
			if(1)
				if(diff==FORWARD)
					user.visible_message("[user] welds external armor layer to [holder].", "You weld external armor layer to [holder].")
				else
					user.visible_message("[user] unfastens the external armor layer.", "You unfasten the external armor layer.")
					holder.icon_state = "fireripley13"
		return 1

	spawn_result()
		..()
		feedback_inc("mecha_firefighter_created",1)
		return
