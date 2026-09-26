extends Control 
class_name CardPurchaseSlot

@export var price : int
@export var destroySlot : bool

@onready var price_label: Label = %PriceLabel
@onready var card: Card = $Card
@onready var price_tag_texture: TextureRect = %PriceTagTexture

func _ready() -> void:
	price = card.price
	card.shop_card = true
	card.for_show = true
	card.set_up()
	card.rolltype = Card.ROLLTYPE.SHOP if !destroySlot else Card.ROLLTYPE.DESTROY
	card.purchaseSlot = self
	

func update_price() -> void:
	price = Stats.coloBuilds[card.type - Card.CARDTYPE.TRAPS + 1]["price"]
	price_label.text = str(price)
