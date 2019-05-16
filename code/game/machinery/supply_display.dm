/obj/machinery/status_display/supply_display
	ignore_friendc = 1

/obj/machinery/status_display/supply_display/update()
	if(!..() && mode == STATUS_DISPLAY_CUSTOM)
		message1 = "CARGO"
		message2 = ""

		if(SSsupply_truck.moving)
			message2 = get_supply_shuttle_timer()
			if(lentext(message2) > CHARS_PER_LINE)
				message2 = "Error"
		else
			if(SSsupply_truck.at_base)
				message2 = "Docked"
			else
				message1 = ""
		update_display(message1, message2)
		return 1
	return 0

/obj/machinery/status_display/supply_display/receive_signal/(datum/signal/signal)
	if(signal.data["command"] == "supply")
		mode = STATUS_DISPLAY_CUSTOM
	else
		..(signal)
