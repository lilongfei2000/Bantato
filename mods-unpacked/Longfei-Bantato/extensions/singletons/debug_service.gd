extends "res://singletons/debug_service.gd"


# Called when the node enters the scene tree for the first time.
func _ready():
	var dir = ModLoaderMod.get_unpacked_dir().plus_file("Longfei-Bantato").plus_file("extensions")
	ModLoaderMod.install_script_extension(dir.plus_file("ui/menus/shop/coop_resume.gd"))
