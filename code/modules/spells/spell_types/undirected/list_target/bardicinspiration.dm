/datum/action/cooldown/spell/bardicinspiration
	name = "Bardic Inspiration"
	desc = "Inspire the target with stirring words."
	button_icon_state = "comedy"
	sound = 'sound/magic/whiteflame.ogg'

	associated_skill = /datum/skill/misc/music

	charge_required = FALSE
	spell_type = NONE
	cooldown_time = 1 MINUTES
	invocation_type = INVOCATION_SHOUT

/datum/action/cooldown/spell/vicious_mockery/is_valid_target(atom/cast_on)
	return isliving(cast_on)

/datum/action/cooldown/spell/vicious_mockery/before_cast(mob/living/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return

	var/message

	if(owner.cmode && ishuman(owner))
		var/mob/living/carbon/human/H = owner
		if(H.dna?.species)
			message = pick_list_replacements("bard.json", "[H.dna.species.id]_mockery")
	else
		message = browser_input_text(owner, "How will I inspire this fellow?", "XYLIX")
		if(QDELETED(src) || QDELETED(owner) || QDELETED(cast_on) || !can_cast_spell())
			return . | SPELL_CANCEL_CAST

	if(!message)
		reset_spell_cooldown()
		return . | SPELL_CANCEL_CAST

	invocation = message

/datum/action/cooldown/spell/vicious_mockery/cast(mob/living/cast_on)
	. = ..()
	if(cast_on.can_hear())
		SEND_SIGNAL(owner, COMSIG_VICIOUSLY_MOCKED, cast_on)
		cast_on.apply_status_effect(/datum/status_effect/debuff/viciousmockery)
		record_round_statistic(STATS_PEOPLE_MOCKED)
