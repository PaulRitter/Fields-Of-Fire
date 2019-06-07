#define NEXT_PAGE_ID "__next__"
#define DEFAULT_CHECK_DELAY 2 SECONDS

/obj/screen/radial
	icon = 'icons/mob/radial.dmi'
	layer = ABOVE_HUD_LAYER
	plane = ABOVE_HUD_PLANE
	var/datum/radial_menu/parent

/obj/screen/radial/slice
	icon_state = "radial_slice"
	var/datum/radial_menu_choice/choice
	var/next_page = FALSE
	var/tooltip_desc

/obj/screen/radial/slice/MouseEntered(location, control, params)
	. = ..()
	icon_state = "radial_slice_focus"
	if(tooltip_desc)
		openToolTip(usr,src,params,title = src.name,content = tooltip_desc,theme = parent.tooltip_theme)

/obj/screen/radial/slice/MouseExited(location, control, params)
	. = ..()
	icon_state = "radial_slice"
	closeToolTip(usr)

/obj/screen/radial/slice/Click(location, control, params)
	return choice.ClickOn(usr, params)

/obj/screen/radial/slice/proc/selected(var/mob/user, var/list/modifier)
	if(user.client == parent.current_user)
		if(next_page)
			parent.next_page()
		else
			parent.element_chosen(choice.value, modifier, user)

/obj/screen/radial/center
	name = "Close Menu"
	icon_state = "radial_center"

/obj/screen/radial/center/Click(location, control, params)
	if(usr.client == parent.current_user)
		parent.finished = TRUE

/datum/radial_menu
	var/list/choices = list() //List of /datum/radial_menu_choice
	var/list/page_data = list() //list of choices per page

	var/icon_file = 'icons/mob/radial.dmi'
	var/tooltip_theme = "radial-default"

	var/selected_choice
	var/selected_modifier
	var/list/obj/screen/elements = list()
	var/obj/screen/radial/center/close_button
	var/client/current_user
	var/atom/anchor
	var/image/menu_holder
	var/finished = FALSE

	var/event/custom_check
	var/next_check = 0
	var/check_delay = DEFAULT_CHECK_DELAY

	var/radius = 32
	var/starting_angle = 0
	var/ending_angle = 360
	var/zone = 360
	var/min_angle = 45 //Defaults are setup for this value, if you want to make the menu more dense these will need changes.
	var/max_elements
	var/pages = 1
	var/current_page = 1

	var/hudfix_method = TRUE //TRUE to change anchor to user, FALSE to shift by py_shift
	var/py_shift = 0
	var/entry_animation = TRUE

//If we swap to vis_contens inventory these will need a redo
/datum/radial_menu/proc/check_screen_border(mob/user)
	var/atom/movable/AM = anchor
	if(!istype(AM) || !AM.screen_loc)
		return
	if(AM in user.client.screen)
		if(hudfix_method)
			anchor = user
		else
			py_shift = 32
			restrict_to_dir(NORTH) //I was going to parse screen loc here but that's more effort than it's worth.

//Sets defaults
//These assume 45 deg min_angle
/datum/radial_menu/proc/restrict_to_dir(dir)
	switch(dir)
		if(NORTH)
			starting_angle = 270
			ending_angle = 135
		if(SOUTH)
			starting_angle = 90
			ending_angle = 315
		if(EAST)
			starting_angle = 0
			ending_angle = 225
		if(WEST)
			starting_angle = 180
			ending_angle = 45

/datum/radial_menu/proc/setup_menu()
	if(ending_angle > starting_angle)
		zone = ending_angle - starting_angle
	else
		zone = 360 - starting_angle + ending_angle

	max_elements = round(zone / min_angle)
	var/paged = max_elements < choices.len
	if(elements.len < max_elements)
		var/elements_to_add = max_elements - elements.len
		for(var/i in 1 to elements_to_add) //Create all elements
			var/obj/screen/radial/new_element = new /obj/screen/radial/slice
			new_element.icon = icon_file
			new_element.parent = src
			elements += new_element

	var/page = 1
	page_data = list()
	var/list/current = list()
	var/list/choices_left = choices.Copy()
	while(choices_left.len)
		if(current.len == max_elements)
			page_data[page] = current
			page++
			page_data.len++
			current = list()
		if(paged && current.len == max_elements - 1)
			current += NEXT_PAGE_ID
			continue
		else
			current += shift(choices_left)
	if(paged && current.len < max_elements)
		current += NEXT_PAGE_ID

	page_data[page] = current
	pages = page
	current_page = 1
	update_screen_objects(anim = entry_animation)

/datum/radial_menu/proc/update_screen_objects(anim = FALSE)
	var/list/page_choices = page_data[current_page]
	var/angle_per_element = round(zone / page_choices.len)
	for(var/i in 1 to elements.len)
		var/obj/screen/radial/E = elements[i]
		var/angle = Wrap(starting_angle + (i - 1) * angle_per_element,0,360)
		if(i > page_choices.len)
			HideElement(E)
		else
			SetElement(E,page_choices[i],angle,anim = anim,anim_order = i)

/datum/radial_menu/proc/HideElement(obj/screen/radial/slice/E)
	E.overlays.len = 0
	E.alpha = 0
	E.name = "None"
	E.maptext = null
	E.mouse_opacity = 0
	E.choice = null
	E.next_page = FALSE
	E.choice = null

/datum/radial_menu/proc/SetElement(obj/screen/radial/slice/E,/datum/radial_menu_choice/choice,angle,anim,anim_order)
	//Position
	var/py = round(cos(angle) * radius) + py_shift
	var/px = round(sin(angle) * radius)
	if(anim)
		var/timing = anim_order * 0.5
		var/matrix/starting = matrix()
		starting.Scale(0.1,0.1)
		E.transform = starting
		var/matrix/TM = matrix()
		animate(E,pixel_x = px,pixel_y = py, transform = TM, time = timing)
	else
		E.pixel_y = py
		E.pixel_x = px

	//Visuals
	E.alpha = 255
	E.mouse_opacity = 1
	E.overlays.len = 0
	if(choice_id == NEXT_PAGE_ID)
		E.name = "Next Page"
		E.next_page = TRUE
		push(E.overlays, "radial_next")
		E.choice = new /datum/radial_menu_choice() //default will do, we only need the logic
	else
		E.name = choice.name
		E.choice = choice
		choice.parent = E
		E.maptext = null
		E.next_page = FALSE
		if(choice.img)
			push(E.overlays,choice.img)
		if(choice.tooltip)
			E.tooltip_desc = choice.tooltip

/datum/radial_menu/New(var/icon_file, var/tooltip_theme, var/radius, var/min_angle)
	if(icon_file)
		src.icon_file = icon_file
	if(tooltip_theme)
		src.tooltip_theme = tooltip_theme
	if(radius)
		src.radius = radius
	if(min_angle)
		src.min_angle = min_angle

	close_button = new
	close_button.parent = src
	close_button.icon = src.icon_file

/datum/radial_menu/proc/Reset()
	choices.Cut()
	current_page = 1

/datum/radial_menu/proc/element_chosen(var/choice_id, var/list/modifier, var/mob/user)
	selected_choice = choice_id
	selected_modifier = modifier

/datum/radial_menu/proc/get_next_id()
	return "c_[choices.len]"

/datum/radial_menu/proc/set_choices(var/list/new_choices)
	if(choices.len)
		Reset()
	//check if they are valid (no double values)
	var/list/all_values = list()
	for(var/datum/radial_menu_choice/choice in new_choices)
		if(choice.value in all_values)
			continue

		all_values += choice.value
		choices += choice
	setup_menu()


/datum/radial_menu/proc/extract_image(E)
	var/mutable_appearance/MA = new /mutable_appearance(E)
	if(MA)
		MA.layer = ABOVE_HUD_LAYER
		MA.plane = ABOVE_HUD_PLANE
		MA.appearance_flags |= RESET_TRANSFORM
	return MA


/datum/radial_menu/proc/next_page()
	if(pages > 1)
		current_page = Wrap(current_page + 1,1,pages+1)
		update_screen_objects()

/datum/radial_menu/proc/show_to(mob/M)
	if(current_user)
		hide()
	if(!M.client || !anchor)
		return
	current_user = M.client
	//Blank
	menu_holder = image(icon='icons/effects/effects.dmi',loc=anchor,icon_state="nothing",layer = ABOVE_HUD_LAYER)
	menu_holder.appearance_flags |= KEEP_APART
	menu_holder.vis_contents += elements + close_button
	current_user.images += menu_holder

/datum/radial_menu/proc/hide()
	if(current_user)
		current_user.images -= menu_holder

/datum/radial_menu/proc/wait()
	while (!gc_destroyed && current_user && !finished && !selected_choice)
		if(istype(custom_check) && next_check < world.time)
			if(!INVOKE_EVENT(custom_check, list()))
				return
			else
				next_check = world.time + check_delay
		stoplag(1)

/datum/radial_menu/Destroy()
	Reset()
	hide()
	if(istype(custom_check))
		custom_check.holder = null
		custom_check = null
	. = ..()

/datum/radial_menu_choice
	var/name
	var/image/img
	var/tooltip
	var/obj/screen/radial/slice/parent
	var/value

/datum/radial_menu_choice/New(var/n_name, var/image/n_img, var/n_tooltip)
	..()
	if(istext(n_name))
		name = n_name
	if(istype(n_img))
		img = n_img
	if(istext(n_tooltip))
		tooltip = n_tooltip

/datum/radial_menu_choice/proc/ClickOn(var/mob/user, params)
	if(istype(parent))
		var/list/modifiers = params2list(params)
		parent.selected(user, modifiers)
		return 1
	return 0

/*
	Presents radial menu to user anchored to anchor (or user if the anchor is currently in users screen)
	Choices should be a list where list keys are movables or text used for element names and return value
	and list values are movables/icons/images used for element icons
*/
/proc/show_radial_menu(mob/user,atom/anchor,list/choices,var/icon_file,var/tooltip_theme,var/event/custom_check,var/uniqueid,var/radius,var/min_angle)
	if(!user || !anchor || !length(choices))
		return

	var/client/current_user = user.client
	if(anchor in current_user.radial_menus)
		return
	current_user.radial_menus += anchor //This should probably be done in the menu's New()

	var/datum/radial_menu/menu = new(icon_file, tooltip_theme, radius, min_angle)

	if(istype(custom_check))
		menu.custom_check = custom_check
	menu.anchor = anchor
	menu.check_screen_border(user) //Do what's needed to make it look good near borders or on hud
	menu.set_choices(choices)
	menu.show_to(user)
	menu.wait()
	if(!menu.gc_destroyed)
		var/list/answer = menu.selected_choice
		answer += menu.modifier
		qdel(menu)
		current_user.radial_menus -= anchor
		return answer
