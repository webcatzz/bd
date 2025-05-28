extends Control


func display(condition: Condition) -> void:
	condition.changed.connect(update.bind(condition))
	condition.ended.connect(queue_free)


func update(condition: Condition) -> void:
	$Time.text = "×" + str(condition.time)
