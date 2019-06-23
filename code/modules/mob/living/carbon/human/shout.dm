/*This is used by both the whisper verb and human/say() to handle shouting
	Gets whether or not the person can be seen.
		If they can be seen, it'll be shown in bold.
		If they can't be seen, it'll say "a voice from [dir2text(get_dir(hearer, speaker))]: [message]"
*/
/mob/living/carbon/human/proc/shout_say(var/message, var/datum/language/speaking = null, var/alt_name="", var/verb="yells")

	if (istype(src.wear_mask, /obj/item/clothing/mask/muzzle))
		to_chat(src, "<span class='danger'>You're muzzled and cannot speak!</span>")
		return

	var/message_range = 12

	message = capitalize(trim(message))

	//speech problems
	if(!(speaking && (speaking.flags & NO_STUTTER)))
		var/list/message_data = list(message, verb, 1)
		if(handle_speech_problems(message_data))
			message = message_data[1]

			if(!message_data[3]) //if a speech problem like hulk forces someone to yell then everyone hears it
				verb = message_data[2]
				message_range = 18


	if(!message || message=="")
		return

	var/list/listening = hearers(message_range, src)
	listening |= src

	//ghosts
	for (var/mob/M in GLOB.player_list)
		if (istype(M, /mob/new_player))
			continue
		if (!(M.client))
			continue
		if(M.stat == DEAD && M.is_preference_enabled(/datum/client_preference/ghost_ears))
			listening |= M

	//Pass whispers on to anything inside the immediate listeners.
	for(var/mob/L in listening)
		for(var/mob/C in L.contents)
			if(istype(C,/mob/living))
				listening += C

	//pass on the message to objects that can hear us.
	for (var/obj/O in view(message_range, src))
		spawn (0)
			if (O)
				O.hear_talk(src, message, verb, speaking)

	//now mobs
	var/speech_bubble_test = say_test(message)
	var/image/speech_bubble = image('icons/mob/talk.dmi',src,"h[speech_bubble_test]")
	spawn(30) qdel(speech_bubble)

	for(var/mob/M in listening)
		M << speech_bubble
		M.hear_say(message, verb, speaking, alt_name, 0, src)