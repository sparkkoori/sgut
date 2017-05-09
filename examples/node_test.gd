extends Node

var quit = false
var t = null

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
	self.t = t
	while !quit:
		yield()

func _pass():
	quit = true

func _fail():
	self.t.fail()
	quit = true
