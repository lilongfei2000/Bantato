extends Node


const LOONGFLY_BANTATO_DIR := "LoongFly-Bantato"
const LOONGFLY_BANTATO_LOG := "LoongFly-Bantato:Main"

var mod_dir_path := ""
var extensions_dir_path := ""
var translations_dir_path := ""
var _bantato_service: Node = null

# Before v6.1.0
# func _init(modLoader = ModLoader) -> void:
func _init() -> void:
	mod_dir_path = ModLoaderMod.get_unpacked_dir().plus_file(LOONGFLY_BANTATO_DIR)

	# Create and add BantatoService as child node
	_add_bantato_service()

	# Add extensions
	install_script_extensions()
	# Add translations
	add_translations()


func _add_bantato_service() -> void:
	"""Create and add BantatoService as a child node."""
	var service_script = load(mod_dir_path.plus_file("services/bantato_service.gd"))

	if service_script == null:
		ModLoaderLog.error("Failed to load BantatoService script", LOONGFLY_BANTATO_LOG)
		return

	_bantato_service = service_script.new()
	_bantato_service.name = "BantatoService"

	# Add as child to main (makes it globally accessible via get_node)
	add_child(_bantato_service)

	ModLoaderLog.info("BantatoService added as child node", LOONGFLY_BANTATO_LOG)


func install_script_extensions() -> void:
	extensions_dir_path = mod_dir_path.plus_file("extensions")

	# REMOVE: These extensions are now handled by BantatoService
	# ModLoaderMod.install_script_extension(extensions_dir_path.plus_file("singletons/run_data.gd"))
	# ModLoaderMod.install_script_extension(extensions_dir_path.plus_file("singletons/player_run_data.gd"))

	# KEEP: ItemService extension (modified to use BantatoService)
	ModLoaderMod.install_script_extension(extensions_dir_path.plus_file("singletons/item_service.gd"))

	# NEW: RunData hook for save/load
	ModLoaderMod.install_script_extension(extensions_dir_path.plus_file("singletons/run_data.gd"))

	# UI Extensions (will be modified to use BantatoService)
	ModLoaderMod.install_script_extension(extensions_dir_path.plus_file("ui/menus/shop/shop_item.gd"))
	ModLoaderMod.install_script_extension(extensions_dir_path.plus_file("ui/menus/shop/player_gear_container.gd"))
	ModLoaderMod.install_script_extension(extensions_dir_path.plus_file("ui/menus/shop/item_popup.gd"))
	ModLoaderMod.install_script_extension(extensions_dir_path.plus_file("ui/menus/shop/shop_items_container.gd"))
	ModLoaderMod.install_script_extension(extensions_dir_path.plus_file("ui/menus/shop/base_shop.gd"))
	ModLoaderMod.install_script_extension(extensions_dir_path.plus_file("ui/menus/shop/shop.gd"))
	ModLoaderMod.install_script_extension(extensions_dir_path.plus_file("ui/menus/shop/coop_shop.gd"))
	ModLoaderMod.install_script_extension(extensions_dir_path.plus_file("ui/menus/shop/coop_shop_player_container.gd"))
	ModLoaderMod.install_script_extension(extensions_dir_path.plus_file("ui/menus/global/popup_manager.gd"))


func add_translations() -> void:
	translations_dir_path = mod_dir_path.plus_file("extensions/resources/translations")
	ModLoaderMod.add_translation(translations_dir_path.plus_file("bantato_translation.en.translation"))
	ModLoaderMod.add_translation(translations_dir_path.plus_file("bantato_translation.zh_Hans_CN.translation"))
	ModLoaderMod.add_translation(translations_dir_path.plus_file("bantato_translation.zh_Hant_TW.translation"))


func _ready() -> void:
	ModLoaderLog.info("Ready!", LOONGFLY_BANTATO_LOG)
