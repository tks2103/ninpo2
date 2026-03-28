extends Node2D

var tilemap_layer: TileMapLayer
var tileset: TileSet

## Horizontal radius of the oval in tiles. Wider = more tiles side-to-side.
@export var radius_x: float = 28.0
 
## Vertical radius of the oval in tiles. Smaller = flatter/more oval.
@export var radius_y: float = 12.0
 
## World-space origin of the patch centre (in tile coordinates).
@export var patch_centre: Vector2i = Vector2i(0, 0)
 
## Randomise which tiles within the oval are placed (creates a natural edge).
@export var use_natural_edge: bool = true
 
## Edge falloff: probability of placing a tile drops off near the oval boundary.
## 0.0 = hard edge, 1.0 = very fuzzy/natural edge.
@export_range(0.0, 1.0) var edge_softness: float = 0.35

## Random seed for the natural edge. Change to get different shapes.
@export var random_seed: int = 42

func _ready() -> void:
	set_player_location()
	#generate_map()

func _physics_process(delta: float) -> void:
	var player: CharacterBody2D = get_node("Player")
	var player_tile: Vector2i = Vector2i(player.position.x / 16, player.position.y / 16)
	if(player_tile.x > 185 && player_tile.x < 191 && player_tile.y > 46 && player_tile.y < 51):
		get_tree().change_scene_to_file("res://scenes/jungle/jungle.tscn")
		print("Changing to jungle")
	elif(player_tile.x == 41 && player_tile.y == 85):
		get_tree().change_scene_to_file("res://scenes/grotto/grotto.tscn")
		print("Changing to Grotto")

func set_player_location() -> void:
	var player: CharacterBody2D = get_node("Player")
	player.position = Vector2(23*16, 23*16)

func add_layer() -> void:
	tilemap_layer = TileMapLayer.new()
	tilemap_layer.name = "Ground"
	
	add_child(tilemap_layer)
	
	var tileset_path = "res://scenes/grassland/assets/grassland_tileset.tres"
	if ResourceLoader.exists(tileset_path):
		tileset = load(tileset_path)
		tilemap_layer.tile_set = tileset
	else:
		print("Error no tileset found")

func generate_patch_of_grass() -> void:
 
	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed
 
	var placed := 0
 
	# Iterate over the bounding rectangle of the oval.
	var ix_min := patch_centre.x - int(ceil(radius_x))
	var ix_max := patch_centre.x + int(ceil(radius_x))
	var iy_min := patch_centre.y - int(ceil(radius_y))
	var iy_max := patch_centre.y + int(ceil(radius_y))
 
	for ty in range(iy_min, iy_max + 1):
		for tx in range(ix_min, ix_max + 1):
			var dx: float = (tx - patch_centre.x) / radius_x
			var dy: float = (ty - patch_centre.y) / radius_y
			var dist_sq: float = dx * dx + dy * dy   # 1.0 = exactly on the ellipse
 
			if dist_sq > 1.0:
				continue   # outside oval, skip
 
			if use_natural_edge:
				# The closer to the edge, the lower the probability.
				# dist_sq=0 (centre) → prob=1.0; dist_sq=1 (edge) → prob depends on softness.
				var edge_factor: float = 1.0 - dist_sq          # 0..1, high at centre
				var threshold: float = 1.0 - edge_softness * (1.0 - edge_factor)
				if rng.randf() > threshold:
					continue   # probabilistically skip near the edge
 
			rng.randomize()

			var atlas_x: int = rng.randi_range(0, 6)
			var atlas_y: int = rng.randi_range(0, 1)

			tilemap_layer.set_cell(Vector2i(tx, ty), 0, Vector2i(atlas_x, atlas_y))
			placed += 1
 
	print("GrassPatchGenerator: placed %d tiles." % placed)
	
func generate_map() -> void:
	add_layer()
	
	generate_patch_of_grass()
