# ChartLoader.gd - Autoload singleton for loading song charts from JSON
extends Node

const CHARTS_PATH = "res://charts/"

# Cache loaded songs
var loaded_songs = {}
var song_list = []

signal songs_loaded(count)
signal song_load_error(song_name, error)

func _ready():
	load_all_songs()

func load_all_songs():
	"""Load all JSON chart files from the charts folder"""
	loaded_songs.clear()
	song_list.clear()
	
	var dir = Directory.new()
	if dir.open(CHARTS_PATH) == OK:
		dir.list_dir_begin(true, true)  # Skip navigation and hidden files
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".json"):
				var song_data = load_song_from_file(CHARTS_PATH + file_name)
				if song_data and not song_data.empty():
					var song_name = song_data.get("name", file_name.replace(".json", ""))
					loaded_songs[song_name] = song_data
					song_list.append(song_name)
					print("✓ Loaded song: ", song_name)
				else:
					print("✗ Failed to load: ", file_name)
					emit_signal("song_load_error", file_name, "Parse failed")
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
		
		print("════════════════════════════════")
		print("Total songs loaded: ", loaded_songs.size())
		print("════════════════════════════════")
		emit_signal("songs_loaded", loaded_songs.size())
	else:
		push_error("Failed to open charts directory: " + CHARTS_PATH)
		print("Make sure to create: res://charts/ folder")

func load_song_from_file(path: String) -> Dictionary:
	"""Load and parse a single JSON chart file"""
	var file = File.new()
	if file.open(path, File.READ) != OK:
		push_error("Failed to open file: " + path)
		return {}
	
	var text = file.get_as_text()
	file.close()
	
	# Parse JSON
	var parse_result = JSON.parse(text)
	if parse_result.error != OK:
		push_error("JSON Parse Error in " + path + " at line " + str(parse_result.error_line) + ": " + parse_result.error_string)
		return {}
	
	var data = parse_result.result
	
	# Validate required fields
	if not validate_song_data(data):
		push_error("Invalid song format in " + path)
		return {}
	
	# Process chart data
	data["chart"] = process_chart(data.get("chart", []))
	
	return data

func validate_song_data(data) -> bool:
	"""Check if song data has required fields"""
	if not data.has("name"):
		push_error("Missing 'name' field")
		return false
	if not data.has("bpm"):
		push_error("Missing 'bpm' field")
		return false
	if not data.has("chart"):
		push_error("Missing 'chart' field")
		return false
	return true

func process_chart(chart_data: Array) -> Array:
	"""Process and normalize chart data"""
	var processed = []
	
	for note in chart_data:
		if note is Dictionary:
			# Format: {"beat": 1.0, "lanes": [0, 1]}
			var beat = note.get("beat", 0.0)
			var lanes = note.get("lanes", [])
			
			# Ensure lanes is valid
			if typeof(lanes) == TYPE_INT:
				# Single lane as int
				processed.append([beat, lanes])
			elif typeof(lanes) == TYPE_ARRAY:
				# Multiple lanes or single lane in array
				if lanes.size() == 1:
					processed.append([beat, lanes[0]])
				elif lanes.size() > 1:
					processed.append([beat, lanes])
			
		elif note is Array and note.size() >= 2:
			# Format: [1.0, [0, 1]] or [1.0, 0]
			processed.append(note)
	
	# Sort by beat timing
	processed.sort_custom(self, "_sort_by_beat")
	
	return processed

func _sort_by_beat(a, b):
	"""Sort notes by beat number"""
	return a[0] < b[0]

func get_song(song_name: String) -> Dictionary:
	"""Get a song by name (returns a copy)"""
	if loaded_songs.has(song_name):
		return loaded_songs[song_name].duplicate(true)
	else:
		push_error("Song not found: " + song_name)
		return {}

func get_all_song_names() -> Array:
	"""Get list of all available song names"""
	return song_list.duplicate()

func get_songs_by_difficulty(difficulty: String) -> Array:
	"""Get all songs matching a difficulty"""
	var filtered = []
	for song_name in song_list:
		var song = loaded_songs[song_name]
		if song.get("difficulty", "").to_lower() == difficulty.to_lower():
			filtered.append(song_name)
	return filtered

func get_song_info(song_name: String) -> Dictionary:
	"""Get metadata about a song without loading the full chart"""
	if loaded_songs.has(song_name):
		var song = loaded_songs[song_name]
		return {
			"name": song.get("name", song_name),
			"artist": song.get("artist", "Unknown"),
			"bpm": song.get("bpm", 120),
			"difficulty": song.get("difficulty", "Medium"),
			"note_count": song.get("chart", []).size()
		}
	return {}

func reload_songs():
	"""Reload all songs from disk"""
	print("Reloading all songs...")
	load_all_songs()

func has_song(song_name: String) -> bool:
	"""Check if a song exists"""
	return loaded_songs.has(song_name)

func get_random_song() -> String:
	"""Get a random song name"""
	if song_list.empty():
		return ""
	return song_list[randi() % song_list.size()]
