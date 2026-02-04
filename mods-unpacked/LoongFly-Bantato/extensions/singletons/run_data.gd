extends "res://singletons/run_data.gd"

# Access BantatoService
onready var BantatoService = get_node("/root/ModLoader/LoongFly-Bantato/BantatoService")

# Override get_state to include Bantato data
func get_state() -> Dictionary:
	var state = .get_state()

	# Add Bantato data to save state with unique key
	if BantatoService:
		state["loongfly_bantato_mod_data"] = BantatoService.serialize()

	return state


# Override resume_from_state to restore Bantato data
func resume_from_state(state: Dictionary) -> void:
	.resume_from_state(state)

	# Restore Bantato data if present
	if state.has("loongfly_bantato_mod_data") and BantatoService:
		BantatoService.deserialize(state["loongfly_bantato_mod_data"])


# Hook reset() to initialize BantatoService
func reset(restart: bool = false) -> void:
	.reset(restart)

	# Initialize BantatoService for the new run
	if BantatoService:
		var player_count = get_player_count()
		BantatoService.reset_run(player_count)