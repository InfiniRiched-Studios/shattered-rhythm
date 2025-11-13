# Conductor.gd - Rhythm game timing conductor
extends AudioStreamPlayer

# Exported variables for easy tweaking
export var bpm := 120
export var measures := 4
export var beatsbeforestart := 0  # Lead-in beats before song starts

# Beat and song position tracking
var songPos = 0.0
var songPosInBeats = 1
var secperbeat = 60.0 / bpm
var last_rep_beat = 0
var measure = 1
var closest = 0
var time_off_beat = 0.0

# Signals for other systems to hook into
signal beat(position)
signal measure(position)
signal song_started()
signal song_ended()

# Compensates for audio buffer latency
const AUDIO_DELAY = 0.1

func _ready():
	secperbeat = 60.0 / bpm

func _process(_delta):
	if playing:
		# Calculate song position with latency compensation
		songPos = get_playback_position() + AudioServer.get_time_since_last_mix()
		songPos -= AudioServer.get_output_latency() + AUDIO_DELAY
		songPosInBeats = int(floor(songPos / secperbeat)) + beatsbeforestart
		
		# Report beats
		if last_rep_beat < songPosInBeats:
			_report_beat()
			last_rep_beat = songPosInBeats

func _report_beat():
	# Calculate how close we are to the beat (for accuracy)
	time_off_beat = songPos - (songPosInBeats - beatsbeforestart) * secperbeat
	closest = int(round((songPos / secperbeat) + beatsbeforestart))
	
	# Emit beat signal
	emit_signal("beat", songPosInBeats)
	
	# Check if we've completed a measure
	if songPosInBeats % measures == 0:
		measure += 1
		emit_signal("measure", measure)

func play_with_beat_offset(num_beats: int):
	"""Start playing with a lead-in countdown"""
	beatsbeforestart = num_beats
	$StartTimer.wait_time = secperbeat
	$StartTimer.start()

func _on_StartTimer_timeout():
	"""Countdown timer for lead-in beats"""
	beatsbeforestart -= 1
	if beatsbeforestart <= 0:
		$StartTimer.stop()
		play()
		emit_signal("song_started")
	else:
		# Emit beat for countdown
		emit_signal("beat", beatsbeforestart * -1)

func play_from_beat(beat: int, offset: int = 0):
	"""Start playing from a specific beat with optional offset"""
	if offset > 0:
		beatsbeforestart = offset
	seek(beat * secperbeat)
	play()

func get_current_beat() -> int:
	"""Returns the current beat number"""
	return songPosInBeats

func get_beat_progress() -> float:
	"""Returns progress through current beat (0.0 to 1.0)"""
	var beat_time = fmod(songPos, secperbeat)
	return beat_time / secperbeat

func is_on_beat(tolerance: float = 0.1) -> bool:
	"""Check if current time is close to a beat within tolerance"""
	var progress = get_beat_progress()
	return progress < tolerance or progress > (1.0 - tolerance)

func get_time_to_next_beat() -> float:
	"""Returns seconds until next beat"""
	var progress = get_beat_progress()
	return (1.0 - progress) * secperbeat

func set_bpm(new_bpm: int):
	"""Change BPM mid-song (use carefully!)"""
	bpm = new_bpm
	secperbeat = 60.0 / bpm

func reset():
	"""Reset all tracking variables"""
	songPos = 0.0
	songPosInBeats = 1
	last_rep_beat = 0
	measure = 1
	closest = 0
	time_off_beat = 0.0

func _on_finished():
	"""Called when song ends"""
	emit_signal("song_ended")
	reset()

# Add a Timer node as child named "StartTimer" in the scene for countdown functionality
