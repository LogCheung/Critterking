extends Control 
class_name CardPurchaseSlot

@export var price : float 

@onready var price_label: Label = $PriceLabel
@onready var card: Card = $Card

func _ready() -> void:
	card.shop_card = true
	card.for_show = true
	card.set_up()
	update_price()

func update_price() -> void:
	price_label.text = str(price)
