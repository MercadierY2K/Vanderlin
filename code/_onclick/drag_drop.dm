/*
	MouseDrop:

	Called on the atom you're dragging.  In a lot of circumstances we want to use the
	receiving object instead, so that's the default action.  This allows you to drag
	almost anything into a trash can.
*/
/atom/MouseDrop(atom/over, src_location, over_location, src_control, over_control, params)
	if(!usr || !over)
		return
	if(SEND_SIGNAL(src, COMSIG_MOUSEDROP_ONTO, over, usr) & COMPONENT_NO_MOUSEDROP)	//Whatever is receiving will verify themselves for adjacency.
		return
	if(!Adjacent(usr) || !over.Adjacent(usr))
		return // should stop you from dragging through windows
	var/list/L = params2list(params)
	if (L["middle"])
		over.MiddleMouseDrop_T(src,usr)
	else
		if(over == src)
			return usr.client.Click(src, src_location, src_control, params)
		over.MouseDrop_T(src,usr)
	if(isitem(src) && ((isturf(over) && loc == over) || ((istype(over, /obj/structure/table) || istype(over, /obj/structure/rack)) && loc == over.loc)) && (isliving(usr) || prob(10)))
		var/modifier = 1
		var/obj/item/I = src
		if(isdead(usr))
			modifier = 16
		if(!(I.item_flags & ABSTRACT))
			var/list/click_params = params2list(params)
			if(!click_params || !click_params["icon-x"] || !click_params["icon-y"])
				return
			I.pixel_x = round(CLAMP(text2num(click_params["icon-x"]) - 16, -(world.icon_size/2), world.icon_size/2)/modifier, 1)
			I.pixel_y = round(CLAMP(text2num(click_params["icon-y"]) - 16, -(world.icon_size/2), world.icon_size/2)/modifier, 1)
			return
	return

// receive a mousedrop
/atom/proc/MouseDrop_T(atom/dropping, mob/user)
	SEND_SIGNAL(src, COMSIG_MOUSEDROPPED_ONTO, dropping, user)
	return

/atom/proc/MiddleMouseDrop_T(atom/dropping, mob/user)
	SEND_SIGNAL(src, COMSIG_MOUSEDROPPED_ONTO, dropping, user)
	return

/client
	var/list/atom/selected_target[2]
	var/obj/item/active_mousedown_item = null
	var/mouseParams = ""
	var/mouseLocation = null
	var/mouseObject = null
	var/mouseControlObject = null
	var/middragtime = 0
	var/atom/middragatom
	var/tcompare
	var/charging = 0
	var/chargedprog = 0
	var/sections
	var/lastplayed
	var/part
	var/goal
	var/progress
	var/doneset
	var/aghost_toggle
	var/last_charge_process
	var/datum/patreon_data/patreon
	var/toggled_leylines = TRUE

/atom/movable/screen
	blockscharging = TRUE

/client/MouseDown(object, location, control, params)
	if(mob.incapacitated(ignore_grab = TRUE))
		return
	SEND_SIGNAL(src, COMSIG_CLIENT_MOUSEDOWN, object, location, control, params)
	if(istype(object, /obj/abstract/visual_ui_element/hoverable/movable))
		var/obj/abstract/visual_ui_element/hoverable/movable/ui_object = object
		ui_object.MouseDown(location, control, params)

	tcompare = object

	var/atom/AD = object

	if(mob.uses_intents)
		if(mob.used_intent && istype(mob.used_intent))
			mob.used_intent.on_mouse_up()

	if(mob.stat != CONSCIOUS)
		mob.atkswinging = null
		charging = null
		mouse_pointer_icon = 'icons/effects/mousemice/human.dmi'
		return

	if (mouse_down_icon)
		mouse_pointer_icon = mouse_down_icon
	var/delay = mob.CanMobAutoclick(object, location, params)

	mob.atkswinging = null

	charging = 0
	last_charge_process = 0
	chargedprog = 0

	if(!mob.fixedeye) //If fixedeye isn't already enabled, we need to set this var
		mob.tempfixeye = TRUE //Change icon to 'target' red eye
		mob.atom_flags |= NO_DIR_CHANGE

	for(var/atom/movable/screen/eye_intent/eyet in mob.hud_used.static_inventory)
		eyet.update_appearance(UPDATE_ICON_STATE)

	if(delay)
		selected_target[1] = object
		selected_target[2] = params
		while(selected_target[1])
			Click(selected_target[1], location, control, selected_target[2])
			sleep(delay)
	active_mousedown_item = mob.canMobMousedown(object, location, params)
	if(active_mousedown_item)
		active_mousedown_item.onMouseDown(object, location, params, mob)




	var/list/L = params2list(params)
	if (L["right"])
		mob.face_atom(object, location, control, params)
		if(L["left"])
			return
		mob.atkswinging = "right"
		if(mob.oactive)
			if(mob.active_hand_index == 2)
				if(mob.next_lmove > world.time)
					return
			else
				if(mob.next_rmove > world.time)
					return
			mob.cast_move = 0
			mob.used_intent = mob.o_intent
			if(mob.used_intent.get_chargetime() && !AD.blockscharging && !mob.in_throw_mode)
				updateprogbar()
			else
				mouse_pointer_icon = 'icons/effects/mousemice/human_attack.dmi'
			return
		else
			mouse_pointer_icon = 'icons/effects/mousemice/human_looking.dmi'
			return
	if (L["middle"]) //start charging a spell or readying a mmb intent
		if(mob.next_move > world.time)
			return
		mob.atkswinging = "middle"
		if(mob.mmb_intent)
			mob.cast_move = 0
			mob.used_intent = mob.mmb_intent
			if(mob.used_intent.type == INTENT_SPELL && mob.ranged_ability)
				var/obj/effect/proc_holder/spell/S = mob.ranged_ability
				if(!S.cast_check(TRUE,mob, mob.mmb_intent))
					return
		if(!mob.mmb_intent)
			mouse_pointer_icon = 'icons/effects/mousemice/human_looking.dmi'
		else
			if(mob.mmb_intent.get_chargetime() && !AD.blockscharging)
				updateprogbar()
			else
				mouse_pointer_icon = mob.mmb_intent.pointer
		return
	if (L["left"]) //start charging a lmb intent
		mob.face_atom(object, location, control, params)
		if(L["right"])
			return
		if(mob.active_hand_index == 1)
			if(mob.next_lmove > world.time)
				return
		else
			if(mob.next_rmove > world.time)
				return
		mob.atkswinging = "left"
		mob.cast_move = 0
		mob.used_intent = mob.a_intent
		if(mob.uses_intents)
			if(mob.used_intent.get_chargetime() && !AD.blockscharging && !mob.in_throw_mode)
				updateprogbar()
			else
				mouse_pointer_icon = 'icons/effects/mousemice/human_attack.dmi'
		return

/mob
	var/obj/effect/spell_rune/spell_rune
	var/datum/intent/curplaying
	var/accent = ACCENT_DEFAULT

/client/MouseUp(object, location, control, params)
	var/mob/living/L = mob
	if(L)
		update_to_mob(L)
	charging = 0
	last_charge_process = 0
//	mob.update_warning()
	SEND_SIGNAL(src, COMSIG_CLIENT_MOUSEUP, object, location, control, params)

	if(istype(object, /obj/abstract/visual_ui_element/hoverable/movable))
		var/obj/abstract/visual_ui_element/hoverable/movable/ui_object = object
		ui_object.MouseUp(location, control, params)

	mouse_pointer_icon = 'icons/effects/mousemice/human.dmi'

	if(mob.curplaying)
		mob.curplaying.on_mouse_up()

	if(!mob.fixedeye)
		mob.tempfixeye = FALSE
		mob.atom_flags &= ~NO_DIR_CHANGE

	if(mob.hud_used)
		for(var/atom/movable/screen/eye_intent/eyet in mob.hud_used.static_inventory)
			eyet.update_appearance(UPDATE_ICON_STATE) //Update eye icon

	if(!mob.atkswinging)
		return

	var/list/modifiers = params2list(params)
	if(modifiers["left"])
		if(mob.atkswinging != "left")
			mob.atkswinging = null
			return
	if(modifiers["right"])
		if(mob.oactive)
			if(mob.atkswinging != "right")
				mob.atkswinging = null
				return

	if(mob.stat != CONSCIOUS)
		chargedprog = 0
		mob.atkswinging = null
//		mob.update_warning()
		mouse_pointer_icon = 'icons/effects/mousemice/human.dmi'
		return

	if (mouse_up_icon)
		mouse_pointer_icon = mouse_up_icon
	selected_target[1] = null

//	var/list/L = params2list(params)

	if(tcompare)
		if(object)
			if(isatom(object) && object != tcompare && mob.atkswinging && tcompare != mob && (mob.cmode || chargedprog))
				var/atom/N = object
				N.Click(location, control, params)
		tcompare = null

//	mouse_pointer_icon = 'icons/effects/mousemice/human.dmi'

	if(active_mousedown_item)
		active_mousedown_item.onMouseUp(object, location, params, mob)
		active_mousedown_item = null

	if(!isliving(mob))
		return

/client/proc/updateprogbar()
	if(!mob)
		return
	if(!isliving(mob))
		return
	var/mob/living/L = mob
	if(!L.used_intent.can_charge())
		return
	L.used_intent.prewarning()
	if(!charging)
		charging = 1
		L.used_intent.on_charge_start()
		L.update_charging_movespeed(L.used_intent)
//		L.update_warning(L.used_intent)
		progress = 0
//		if(L.used_intent.charge_invocation)
//			sections = 100/L.used_intent.charge_invocation.len
//		else
//			sections = null
		sections = null //commented
		goal = L.used_intent.get_chargetime()
		part = 1
		lastplayed = 0
		doneset = 0
		chargedprog = 0
		START_PROCESSING(SSmousecharge, src)

/client/Destroy()
	STOP_PROCESSING(SSmousecharge, src)
	return ..()

/client/process()
	if(!isliving(mob))
		return PROCESS_KILL
	var/mob/living/L = mob
	if(!L?.client || !update_to_mob(L))
		if(L.curplaying)
			L.curplaying.on_mouse_up()
		L.update_charging_movespeed()
		return PROCESS_KILL

/client/proc/update_to_mob(mob/living/L)
	if(charging)
		if(progress < goal)
			if(last_charge_process)
				progress += world.time - last_charge_process
			else
				progress++
			chargedprog = text2num("[((progress / goal) * 100)]")
			last_charge_process = world.time
// Here we start changing the mouse_pointer_icon
			if(!(mob.used_intent.charge_pointer & mob.used_intent.charged_pointer))
				var/mouseprog = clamp(round(((progress / goal)*100),5), 0, 100)
				mouse_pointer_icon = file("icons/effects/mousemice/charge/default/[mouseprog].dmi")
			else
				mouse_pointer_icon = mob.used_intent.charge_pointer
		else
			if(!doneset)
				doneset = 1
				chargedprog = 100
				if(!(mob.used_intent.charge_pointer & mob.used_intent.charged_pointer))
					mouse_pointer_icon = 'icons/effects/mousemice/charge/default/100.dmi'
				else
					mouse_pointer_icon = mob.used_intent.charged_pointer
// Now we are done messing with the mouse_pointer_icon
//				if(sections)
//					L.say(L.used_intent.charge_invocation[L.used_intent.charge_invocation.len])
				if(L.curplaying && !L.used_intent.keep_looping)
					playsound(L, 'sound/magic/charged.ogg', 100, TRUE)
					L.curplaying.on_mouse_up()
				if(istype(L.used_intent, /datum/intent/shield/block))
					L.visible_message("<span class='danger'>[L] prepares to do a shield bash!</span>")
					playsound(L, 'sound/combat/shieldraise.ogg', 100, TRUE)
			else
				if(!L.adjust_stamina(L.used_intent.chargedrain))
					L.stop_attack()
		return TRUE
	else
		return FALSE

/mob/proc/CanMobAutoclick(object, location, params)

/mob/living/carbon/CanMobAutoclick(atom/object, location, params)
	if(!object.IsAutoclickable())
		return
	var/obj/item/h = get_active_held_item()
	if(h)
		. = h.CanItemAutoclick(object, location, params)

/mob/proc/canMobMousedown(atom/object, location, params)

/mob/living/carbon/canMobMousedown(atom/object, location, params)
	var/obj/item/H = get_active_held_item()
	if(H)
		. = H.canItemMouseDown(object, location, params)

/obj/item/proc/CanItemAutoclick(object, location, params)

/obj/item/proc/canItemMouseDown(object, location, params)
	if(canMouseDown)
		return src

/obj/item/proc/onMouseDown(object, location, params, mob)
	return

/obj/item/proc/onMouseUp(object, location, params, mob)
	return

/obj/item/gun/CanItemAutoclick(object, location, params)
	. = automatic

/atom/proc/IsAutoclickable()
	. = 1

/atom/movable/screen/IsAutoclickable()
	. = 0

/atom/movable/screen/click_catcher/IsAutoclickable()
	. = 1

/client/MouseDrag(src_object,atom/over_object,src_location,over_location,src_control,over_control,params)

	if(mob.incapacitated(ignore_grab = TRUE))
		return

	var/list/L = params2list(params)
	if (L["middle"])
		if (src_object && src_location != over_location)
			middragtime = world.time
			middragatom = src_object
		else
			middragtime = 0
			middragatom = null
	else
		mob.face_atom(over_object, over_location, over_control, params)

	mouseParams = params
	mouseLocation = over_location
	mouseObject = over_object
	mouseControlObject = over_control
	if(selected_target[1] && over_object && over_object.IsAutoclickable())
		selected_target[1] = over_object
		selected_target[2] = params
	if(active_mousedown_item)
		active_mousedown_item.onMouseDrag(src_object, over_object, src_location, over_location, params, mob)


/obj/item/proc/onMouseDrag(src_object, over_object, src_location, over_location, params, mob)
	return

/client/MouseDrop(src_object, over_object, src_location, over_location, src_control, over_control, params)
	if (middragatom == src_object)
		middragtime = 0
		middragatom = null
	..()
