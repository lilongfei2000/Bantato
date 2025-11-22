extends Node


const LOONGFLY_BANTATO_DIR := "LoongFly-Bantato"
const LOONGFLY_BANTATO_LOG := "LoongFly-Bantato:Main"

var mod_dir_path := ""
var extensions_dir_path := ""
var translations_dir_path := ""

# Before v6.1.0
# func _init(modLoader = ModLoader) -> void:
func _init() -> void:
	mod_dir_path = ModLoaderMod.get_unpacked_dir().plus_file(LOONGFLY_BANTATO_DIR)
	# Add extensions
	install_script_extensions()
	# Add translations
	add_translations()


func install_script_extensions() -> void:
	extensions_dir_path = mod_dir_path.plus_file("extensions")

	ModLoaderMod.install_script_extension(extensions_dir_path.plus_file("singletons/item_service.gd"))
	ModLoaderMod.install_script_extension(extensions_dir_path.plus_file("singletons/player_run_data.gd"))
	ModLoaderMod.install_script_extension(extensions_dir_path.plus_file("singletons/run_data.gd"))
	
	ModLoaderMod.install_script_extension(extensions_dir_path.plus_file("ui/menus/shop/shop_item.gd"))
	ModLoaderMod.install_script_extension(extensions_dir_path.plus_file("ui/menus/shop/player_gear_container.gd"))
	ModLoaderMod.install_script_extension(extensions_dir_path.plus_file("ui/menus/shop/item_popup.gd"))
	ModLoaderMod.install_script_extension(extensions_dir_path.plus_file("ui/menus/global/popup_manager.gd"))
	ModLoaderMod.install_script_extension(extensions_dir_path.plus_file("ui/menus/shop/shop_items_container.gd"))

	ModLoaderMod.install_script_extension(extensions_dir_path.plus_file("ui/menus/shop/base_shop.gd"))
	ModLoaderMod.install_script_extension(extensions_dir_path.plus_file("ui/menus/shop/shop.gd"))
	ModLoaderMod.install_script_extension(extensions_dir_path.plus_file("ui/menus/shop/coop_shop.gd"))
	ModLoaderMod.install_script_extension(extensions_dir_path.plus_file("ui/menus/shop/coop_shop_player_container.gd"))
	# extensions_dir_path = mod_dir_path.path_join("extensions") # Godot 4


func add_translations() -> void:
	translations_dir_path = mod_dir_path.plus_file("extensions/resources/translations")
	ModLoaderMod.add_translation(translations_dir_path.plus_file("bantato_translation.en.translation"))
	ModLoaderMod.add_translation(translations_dir_path.plus_file("bantato_translation.zh_Hans_CN.translation"))
	ModLoaderMod.add_translation(translations_dir_path.plus_file("bantato_translation.zh_Hant_TW.translation"))


func _ready() -> void:
	ModLoaderLog.info("Ready!", LOONGFLY_BANTATO_LOG)
