extends CanvasLayer

@export_category("Pref")
@export var health_bar: ProgressBar
@export var label_health: Label
@export var label_gold: Label
@export var label_silver: Label

@onready var player := $".."

func _ready():
	set_multiplayer_authority(str($"..".name).to_int())

func changed(a, v):
	if not is_multiplayer_authority(): return
	match a:
		1: # gold
			label_gold.text = str(format(v))
		2: # silver
			label_silver.text = str(format(v))
		3: # health
			health_bar.value = v
			label_health.text = str(v) + "/" + str(player.health_max)
		4: # health_max
			health_bar.max_value = v
			label_health.text = str(player.health) + "/" + str(v)


func format(value: float, decimals := 1) -> String:
	if value < 1000:
		return str(int(value))
	var units := ["K", "M", "B", "T"]
	var unit_index := -1
	var num := value
	while num >= 1000.0 and unit_index < units.size() - 1:
		num /= 1000.0
		unit_index += 1
	return "%.*f%s" % [decimals, num, units[unit_index]]
