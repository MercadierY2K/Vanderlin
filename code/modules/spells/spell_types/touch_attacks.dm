/obj/effect/proc_holder/spell/targeted/touch
	var/hand_path = /obj/item/melee/touch_attack
	var/obj/item/melee/touch_attack/attached_hand = null
	var/drawmessage = "You channel the power of the spell to my hand."
	var/dropmessage = "You draw the power out of my hand."
	invocation_type = "none" //you scream on connecting, not summoning
	include_user = TRUE
	range = -1

/obj/effect/proc_holder/spell/targeted/touch/Destroy()
	remove_hand()
	to_chat(usr, "<span class='notice'>The power of the spell dissipates from my hand.</span>")
	return ..()

/obj/effect/proc_holder/spell/targeted/touch/proc/remove_hand(recharge = FALSE)
	QDEL_NULL(attached_hand)
	if(recharge)
		charge_counter = recharge_time

/obj/effect/proc_holder/spell/targeted/touch/proc/on_hand_destroy(obj/item/melee/touch_attack/hand)
	if(hand != attached_hand)
		CRASH("Incorrect touch spell hand.")
	//Start recharging.
	attached_hand = null
	recharging = TRUE
	action.UpdateButtonIcon()

/obj/effect/proc_holder/spell/targeted/touch/cast(list/targets,mob/user = usr)
	if(!QDELETED(attached_hand))
		remove_hand(TRUE)
		to_chat(user, "<span class='notice'>[dropmessage]</span>")
		return FALSE

	for(var/mob/living/carbon/C in targets)
		if(!attached_hand)
			if(ChargeHand(C))
				recharging = FALSE
				return ..()

/obj/effect/proc_holder/spell/targeted/touch/charge_check(mob/user,silent = FALSE)
	if(!QDELETED(attached_hand)) //Charge doesn't matter when putting the hand away.
		return TRUE
	else
		return ..()

/obj/effect/proc_holder/spell/targeted/touch/proc/ChargeHand(mob/living/carbon/user)
	attached_hand = new hand_path(src)
	attached_hand.attached_spell = src
	if(!user.put_in_hands(attached_hand))
		remove_hand(TRUE)
		if(user.usable_hands == 0)
			to_chat(user, "<span class='warning'>I dont have any usable hands!</span>")
		else
			to_chat(user, "<span class='warning'>My hands are full!</span>")
		return FALSE
	to_chat(user, "<span class='notice'>[drawmessage]</span>")
	adjust_hand_charges()
	return TRUE

/obj/effect/proc_holder/spell/targeted/touch/proc/adjust_hand_charges()
	return
