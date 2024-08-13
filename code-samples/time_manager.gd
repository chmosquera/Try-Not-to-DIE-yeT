## Manages the in-game timing system. The game time is divided into predefined 
## intervals and emits signals to indicate the start and end of an interval. 
## Other systems can connect to the signals and execute events or actions at 
## each interval. When the final interval is reached, the game ends. 
class_name TimeManager extends Node

## Defines the duration of each time interval in seconds
@export var time_intervals : Array[int] = [30, 60]

## Creates time gaps between intervals. Useful for events or animations.
@export var gap_timer : Timer

## Duration of the gap between intervals in seconds
@export var gap_interval: int = 2

## Reference to a progress bar GUI for time
@export var text_progress_bar : TextureProgressBar

var _current_time = 0 		## The elapsed time in seconds within current interval
var _current_interval = 0 	## The index of the current interval within time_intervals
var _is_time_up = false
var _in_gap = false

signal interval_ended(idx : int)	## Emits when an interval completes
signal interval_started(idx : int)	## Emits when an interval starts
signal time_ended()					## Emits when the last interval completes

# Called when the node enters the scene tree for the first time.
func _ready():
	gap_timer.timeout.connect(_on_gap_timer_timeout)
	var total_time = 0
	for i in time_intervals:
		total_time += i
		
	text_progress_bar.max_value = total_time


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if _is_time_up == true or _in_gap == true:
		return
	
	if _current_interval >= len(time_intervals):
		end_time()
		return
		
	if _current_time >= time_intervals[_current_interval]:
		interval_ended.emit(_current_interval)
		start_gap()
		
	_current_time += delta
	if _current_interval <= 0:
		text_progress_bar.value = _current_time
	else:
		text_progress_bar.value = get_time_intervals_length(_current_interval - 1) + _current_time

func get_time_intervals_length(last_interval):
	var length = 0
	for n in last_interval + 1:
		length += time_intervals[n]
	return length

## Advances to the next interval, unless the last one was reached.
func advance_interval():
	_current_interval += 1
	
	if _current_interval >= len(time_intervals):
		return
	
	_current_time = 0
	interval_started.emit(_current_interval)
	print("Advancing to interval %d of %d seconds" % [_current_interval, time_intervals[_current_interval]])

## Starts a timer between intervals, creating a gap before the next interval
func start_gap(): 
	print("Starting gap of %d seconds" % gap_interval)
	gap_timer.start(gap_interval)
	_in_gap = true

func _on_gap_timer_timeout():
	print("Gap ended")
	gap_timer.stop()
	advance_interval()
	_in_gap = false

## Ends the time. This is reached when the last interval completes.
func end_time():
	print("Time ended")
	time_ended.emit()
	_is_time_up = true
	
	get_tree().change_scene_to_file("res://scenes/victory.tscn")

func reset_timer():
	_current_time = 0
	_current_interval = 0
	_is_time_up = false
	_in_gap = false