class_name PronounResolver
extends RefCounted

const SETS := {
	"they_them": {"subject":"they", "object":"them", "possessive_adjective":"their", "possessive_pronoun":"theirs", "reflexive":"themself", "plural":true},
	"she_her": {"subject":"she", "object":"her", "possessive_adjective":"her", "possessive_pronoun":"hers", "reflexive":"herself", "plural":false},
	"he_him": {"subject":"he", "object":"him", "possessive_adjective":"his", "possessive_pronoun":"his", "reflexive":"himself", "plural":false},
}


static func resolve(text: String, profile: CharacterProfile) -> String:
	var pronouns: Dictionary = SETS.get(String(profile.pronoun_set_id), SETS.they_them)
	var result := text.replace("{player_name}", profile.character_name)
	for key: String in ["subject", "object", "possessive_adjective", "possessive_pronoun", "reflexive"]:
		var value := String(pronouns[key])
		result = result.replace("{%s}" % key, value)
		result = result.replace("{%s_cap}" % key, value.capitalize())
	var plural := bool(pronouns.plural)
	result = result.replace("{be}", "are" if plural else "is")
	result = result.replace("{be_cap}", "Are" if plural else "Is")
	result = result.replace("{have}", "have" if plural else "has")
	result = result.replace("{do}", "do" if plural else "does")
	return result
