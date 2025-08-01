extends RichTextLabel

func _ready():
	meta_clicked.connect(_on_URL_clicked)

func _on_URL_clicked(meta):
	OS.shell_open(meta)
