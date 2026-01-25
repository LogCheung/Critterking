extends Control

@export var price : float 

@onready var price_label: Label = $PriceLabel

func _ready() -> void:
	update_price()

func update_price() -> void:
	price_label.text = str(price)
