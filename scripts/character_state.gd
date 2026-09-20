class_name CharacterState
extends Resource

## Per-character runtime state feeding the compliance engine. Pure data —
## no logic lives here, which is what makes ComplianceEngine independently
## testable against arbitrary states.

@export var id: String = ""

## 0.0 = plenty of personal resources (ammo/food/water), 1.0 = desperate.
@export_range(0.0, 1.0) var scarcity: float = 0.0

## 0.0 = pessimistic, 1.0 = hopeful. Evolves slowly over the campaign for
## the younger researchers; stays flat for the team lead except for a
## one-time step change at her reciprocation beat.
@export_range(0.0, 1.0) var morale: float = 0.5

## Other character id -> bond strength (0.0-1.0+). The romantic couple and,
## post-reciprocation, the commando/team lead pair sit near or above 1.0.
## Everyone else defaults to a low baseline (squad camaraderie, not zero).
@export var bonds: Dictionary = {}

func bond_to(other_id: String) -> float:
	return bonds.get(other_id, 0.1)
