extends Node

## Shared squad ammo pool. Both the player's weapon and the teammate's
## attack draw from this single count -- this is the simplest honest version
## of "shared squad inventory" given the game doesn't have distinct typed
## weapons yet (that's the data-driven weapon layer, still a separate,
## deferred piece of the roadmap). Register as an autoload singleton
## (project.godot [autoload] section) so any script can reach it as
## `SquadInventory` without a node reference.

signal ammo_changed(current: int, max_ammo: int)

const MAX_AMMO := 90

var ammo := MAX_AMMO

func try_consume(amount: int = 1) -> bool:
	if ammo >= amount:
		ammo -= amount
		ammo_changed.emit(ammo, MAX_AMMO)
		return true
	return false

func add_ammo(amount: int) -> void:
	ammo = clampi(ammo + amount, 0, MAX_AMMO)
	ammo_changed.emit(ammo, MAX_AMMO)

func reset() -> void:
	ammo = MAX_AMMO
	ammo_changed.emit(ammo, MAX_AMMO)
