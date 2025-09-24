extends Control

@onready var song_container: GridContainer = $VBoxContainer/ScrollContainer/GridContainer
@onready var scroll_container: ScrollContainer = $VBoxContainer/ScrollContainer

var song_item_scene = preload("res://views/song_item.tscn")
var songs: Array[SongData] = []
var song_items: Array[SongItem] = []
var current_selected_index: int = 0
var grid_columns: int = 3

func _ready():
	load_songs()
	display_songs()
	
	# 设置初始选中项
	if song_items.size() > 0:
		select_song_item(0)

func _input(event):
	if event.is_action_pressed("up"):
		navigate_up()
	elif event.is_action_pressed("down"):
		navigate_down()
	elif event.is_action_pressed("left"):
		navigate_left()
	elif event.is_action_pressed("right"):
		navigate_right()
	elif event.is_action_pressed("ok"):
		if song_items.size() > current_selected_index:
			_on_song_selected(songs[current_selected_index])
			

func load_songs():
	# 加载所有歌曲数据
	var song_data_path = "res://resources/song_data/"
	var dir = DirAccess.open(song_data_path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".tres"):
				var song_resource = load(song_data_path + file_name) as SongData
				if song_resource:
					songs.append(song_resource)
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	# 按歌名排序
	songs.sort_custom(func(a, b): return a.name < b.name)

func display_songs():
	# 清除现有的歌曲项
	for child in song_container.get_children():
		child.queue_free()
	
	song_items.clear()
	
	# 创建歌曲项
	for song in songs:
		var song_item = song_item_scene.instantiate()
		song_container.add_child(song_item)
		song_item.setup_song_data(song)
		song_item.song_selected.connect(_on_song_selected)
		song_items.append(song_item)

func select_song_item(index: int):
	if index < 0 or index >= song_items.size():
		return
	
	# 清除所有选中状态
	for i in range(song_items.size()):
		song_items[i].set_selected(i == index)
	
	current_selected_index = index
	
	# 确保选中项在视图中可见
	ensure_item_visible(index)

func ensure_item_visible(index: int):
	if index >= song_items.size():
		return
	
	var item = song_items[index]
	var item_rect = item.get_rect()
	var container_rect = scroll_container.get_rect()
	var scroll_pos = scroll_container.scroll_vertical
	
	# 计算项目在容器中的位置
	var item_top = item_rect.position.y
	var item_bottom = item_rect.position.y + item_rect.size.y
	
	# 如果项目在视图上方，向上滚动
	if item_top < scroll_pos:
		scroll_container.scroll_vertical = item_top
	# 如果项目在视图下方，向下滚动
	elif item_bottom > scroll_pos + container_rect.size.y:
		scroll_container.scroll_vertical = item_bottom - container_rect.size.y

func navigate_up():
	var new_index = current_selected_index - grid_columns
	if new_index >= 0:
		select_song_item(new_index)

func navigate_down():
	var new_index = current_selected_index + grid_columns
	if new_index < song_items.size():
		select_song_item(new_index)

func navigate_left():
	if current_selected_index % grid_columns > 0:
		select_song_item(current_selected_index - 1)

func navigate_right():
	if current_selected_index % grid_columns < grid_columns - 1 and current_selected_index + 1 < song_items.size():
		select_song_item(current_selected_index + 1)

func _on_song_selected(song: SongData):
	print("选中歌曲: ", song.name, " BPM: ", song.BPM)
	Global.selected_song = songs[current_selected_index]
	get_tree().change_scene_to_file("res://scenes/main.tscn")
