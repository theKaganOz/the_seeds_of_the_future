extends CanvasLayer

@onready var health_label: Label = $HealthLabel
@onready var ammo_label: Label = $AmmoLabel
@onready var status_label: Label = $StatusLabel

func _ready() -> void:
	SquadInventory.ammo_changed.connect(_on_ammo_changed)
	_on_ammo_changed(SquadInventory.ammo, SquadInventory.MAX_AMMO)

func set_health(value: int) -> void:
	health_label.text = "HEALTH: %d" % value

func set_down_status(down: bool) -> void:
	status_label.text = "DOWN -- press E near an ally to revive, or wait" if down else ""

func _on_ammo_changed(current: int, max_ammo: int) -> void:
	ammo_label.text = "AMMO: %d / %d" % [current, max_ammo]
