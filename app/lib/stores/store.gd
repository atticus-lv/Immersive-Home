extends RefCounted
## Abstract class for saving and loading data to and from a file.

const VariantSerializer = preload ("res://lib/utils/variant_serializer.gd")

## Signal emitted when the data is loaded.
signal on_loaded

## Signal emitted when the data is saved.
signal on_saved

var _loaded = false
var _save_path = null

## Returns true if the data has been loaded.
func is_loaded():
	return _loaded

## Resets the data to its default state.
func clear():
	pass

func create_dict():
	var data: Dictionary = {}

	for prop_info in get_property_list():
		if prop_info.name.begins_with("_")||prop_info.hint_string != "":
			continue

		var prop = get(prop_info.name)

		if prop is Store:
			data[prop_info.name] = prop.create_dict()
		else:
			data[prop_info.name] = VariantSerializer.stringify_value(prop)

	return data

func use_dict(dict: Dictionary):
	for prop_info in get_property_list():
		if prop_info.name.begins_with("_")||prop_info.hint_string != "":
			continue

		var prop = get(prop_info.name)

		if dict.has(prop_info.name) == false:
			continue

		var prop_value = dict[prop_info.name]

		if prop is Store:
			prop.use_dict(prop_value)
		else:
			set(prop_info.name, prop_value)

func save_local(path=_save_path):
	if path == null:
		return false

	var data = create_dict()

	var save_file = FileAccess.open(path, FileAccess.WRITE)

	if save_file == null:
		return false

	var json_text = JSON.stringify(data)
	save_file.store_line(json_text)

	on_saved.emit()

	return true

func load_local(path=_save_path):
	if path == null:
		return false

	var save_file = FileAccess.open(path, FileAccess.READ)

	# In case that there is no store file yet
	if save_file == null:
		_loaded = true
		on_loaded.emit()
		return true

	var json_text = save_file.get_as_text()
	var save_data = VariantSerializer.parse_value(JSON.parse_string(json_text))

	if save_data == null:
		return false

	use_dict(save_data)

	_loaded = true
	on_loaded.emit()

	return true
