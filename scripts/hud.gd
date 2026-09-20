extends CanvasLayer

@onready var health_label: Label = $HealthLabel
@onready var ammo_label: Label = $AmmoLabel

func _ready() -> void:
	SquadInventory.ammo_changed.connect(_on_ammo_changed)
	_on_ammo_changed(SquadInventory.ammo, SquadInventory.MAX_AMMO)

func set_health(value: int) -> void:
	health_label.text = "HEALTH: %d" % value

func _on_ammo_changed(current: int, max_ammo: int) -> void:
	ammo_label.text = "AMMO: %d / %d" % [current, max_ammo]
