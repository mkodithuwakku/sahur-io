extends PanelContainer
class_name Leaderboard

@onready var entries_root: VBoxContainer = $Margin/Entries

func set_entries(entries: Array) -> void:
	for child in entries_root.get_children():
		child.queue_free()
	if entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Waiting for brawlers..."
		entries_root.add_child(empty_label)
		return
	var rank := 1
	for entry in entries:
		var row := Label.new()
		row.text = "%d. %s  K:%d  G:%d" % [rank, entry.get("name", "Guest"), entry.get("kills", 0), entry.get("growth", 1)]
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		entries_root.add_child(row)
		rank += 1
