extends Building
class_name ColonyBuilding

signal day_ended

func _ready() -> void:
	day_ended.connect(on_day_ended)

func on_day_ended() -> void:
	time += 1
	if time >= cooldown:
		time -= cooldown
		add_resource(resourceType,resourceAmt)

func add_resource(rType : RESOURCETYPE,rAmt : int ) -> void:
	match rType:
		RESOURCETYPE.SATISFACTION:
			Global.satisfaction += rAmt
		RESOURCETYPE.MONEY:
			Global.money += rAmt
		RESOURCETYPE.FOOD:
			Global.food += rAmt
		RESOURCETYPE.CITIZEN:
			Global.citizens += rAmt
	
