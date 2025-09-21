extends VBoxContainer

@export var character_avatar: Texture
@export var character_name: String
@onready var avatar: TextureRect = $Avatar
@onready var name_label: Label = $NameLabel
@onready var hit_label: Label = $HitLabel
var hit = 0

var character_key = {
	"Chick": "E",
	"Duck": "D",
	"Hippo": "K",
	"Parrot": "O"
}

func _ready():
	avatar.texture = character_avatar
	name_label.text = character_name + " (" + character_key[character_name] + ")"


func update_hit(hit_amount: int):
	hit = hit + hit_amount
	hit_label.text = "Hit:" + str(hit)
