extends Node

signal sig

func _ready():
	var btn = Button.new()
	btn.set_text("pass")
	btn.set_size(Vector2(100, 36))
	btn.set_position(Vector2(200, 200))
	btn.connect("pressed",self,"_pass")
	add_child(btn)

	var btn2 = Button.new()
	btn2.set_text("fail")
	btn2.set_size(Vector2(100, 36))
	btn2.set_position(Vector2(320, 200))
	btn2.connect("pressed",self,"_fail")
	add_child(btn2)

func test_foo(t):
	t.add_node(self)

	var ok = yield(self,"sig")
	if !ok:
		t.fail("fail")
		return

	t.finish()

func _pass():
	emit_signal("sig", true)

func _fail():
	emit_signal("sig", false)
