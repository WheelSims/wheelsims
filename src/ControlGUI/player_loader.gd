extends Node

func _ready():
	# Charger la scène du joueur
	var player_scene := preload("res://Player/player_on_keyboard.tscn")
	var player_instance = player_scene.instantiate()
	
	# Ajoute le joueur à la racine (pas dans le menu)
	get_tree().get_root().add_child(player_instance)

	# Gestion des écrans
	var screen_count = DisplayServer.get_screen_count()

	# Forcer le menu principal sur Display 1
	DisplayServer.window_set_current_screen(0, 0)

	# Affiche SecondDisplayWindow sur Display 2 si dispo
	var second_window := player_instance.get_node_or_null("FrontProjector")
	if second_window and screen_count > 1:
		second_window.set_current_screen(1)
		second_window.size = DisplayServer.screen_get_size(1)

	# (Optionnel) Display 3
	var third_window := player_instance.get_node_or_null("FloorProjector")
	if third_window and screen_count > 2:
		third_window.set_current_screen(2)
		third_window.size = DisplayServer.screen_get_size(2)
