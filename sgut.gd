extends Node

export var verbose = false

#Simple expression match, where ‘*’ matches zero or more arbitrary characters,
#and ‘?’ matches any single character except ‘.’.
export var script_pattern = ""
export var test_pattern = ""

class Ticker:
	signal timeout
	var start = OS.get_ticks_msec()
	var wait = 0
	func process(d):
		if OS.get_ticks_msec() - start > wait:
			emit_signal("timeout")

#A Testing used for talking to a test.
class Testing:
	signal finish
	signal process
	signal tested

	var _tested = false

	var parent = null
	var method = ""

	var finished = false
	var processors = []
	var tickers = []
	var node = null
	var errors = []

	func _init(parent,method):
		self.parent = parent
		self.method = method

	func process(d):
		emit_signal("process", d)
		for p in processors:
			p.process(d)
		for p in tickers:
			p.process(d)

	func simulate(p):
		processors.append(p)

	func set_node(n):
		node = n
		parent.parent.sgut.add_child(n)

	func wait(ms):
		var t = Ticker.new()
		t.wait = ms
		tickers.append(t)
		t.connect("timeout",self,"_removeTicker",[t])
		return t

	func _removeTicker(t):
		var i = tickers.find(t)
		tickers.remove(i)

	func error(s):
		errors.append(s)
		info(s)

	func info(s):
		if parent.parent.sgut.verbose:
			print(s)

	func fail(s):
		error(s)
		finish()

	func is_failed():
		return errors.size() != 0;

	func finish():
		finished = true
		emit_signal("finish")

	func test():
		var ret = parent.obj.callv(method,[self])
		if !is_func_state(ret):
			if !finished:
				finish()
		else:
			yield(self,"finish")

		if node != null:
			parent.parent.sgut.remove_child(node)

		report()
		emit_signal("tested")
		_tested = true

	func report():
		if is_failed():
			print("xx  " + method)
			for e in errors:
				print("      - " + e)
		else:
			print("ok  " + method)

	func is_func_state(v):
		if typeof(v) != TYPE_OBJECT:
			return false
		elif v.is_class("GDFunctionState"):
			return true
		else:
			return false


#ScriptTesting contains many Testings.
class ScriptTesting:
	signal tested

	var _tested = false

	var parent = null
	var obj = null
	var path = ""
	var tests = []
	var current = []

	func _init(parent,path):
		self.parent = parent
		self.path = path
		self.obj = load(path).new()

		var methods = self.obj.get_method_list()
		var sgut = parent.sgut
		for m in methods:
			if m.name.begins_with("test_"):
				if sgut.test_pattern == "" || m.name.matchn("*"+sgut.test_pattern+"*"):
					var t = Testing.new(self,m.name)
					tests.append(t)

	func process(d):
		for t in current:
			t.process(d)

	func info(s):
		if parent.sgut.verbose:
			print(s)

	func test():
		print("test: " + path)

		if obj.has_method("setup"):
			obj.callv("setup",[self])

		for t in tests:
			t.test()
			current = [t]
			if !t._tested:
				yield(t,"tested")

		if obj.has_method("teardown"):
			obj.callv("teardown",[self])

		emit_signal("tested")
		_tested = true

class RootTesting:
	signal tested

	var _tested = false

	var sgut = null
	var script_tests = []
	var current = []

	func _init(sgut):
		self.sgut = sgut

		var scripts = []
		sgut.locate_scripts("res://",scripts)
		for path in scripts:
			var t = ScriptTesting.new(self,path)
			script_tests.append(t)

	func test():
		print("sgut: ----------------------------------------------------")

		for st in script_tests:
			st.test()
			current = [st]
			if !st._tested:
				yield(st,"tested")

		report()
		emit_signal("tested")
		_tested = true

	func report():
		var tests= []
		var failed_tests = []
		for s in script_tests:
			for t in s.tests:
				tests.append(t)
				if t.is_failed():
					failed_tests.append(t)

		print("sgut: " + str(script_tests.size()) + " scripts " + str(tests.size()) + " tests " + str(failed_tests.size()) +" failed")

	func process(d):
		for t in current:
			t.process(d)

var running = null

#autorun.
func _ready():
	set_process(true)
	running = run()

func _process(d):
	if running != null:
		if running._tested:
			running = null
		else:
			running.process(d)


#Run tests, respects changes on sources.
func run():
	var at = RootTesting.new(self)
	at.test()
	return at

#test_scripts recurvisly search *_test.gd
#Ignore .* and addons.
func locate_scripts(dir_path,files):
	var d = Directory.new()
	d.open(dir_path)
	d.list_dir_begin()

	var thing = d.get_next()
	var full_path = ''
	while(thing != ''):
		full_path = d.get_current_dir()
		if !full_path.ends_with("/"):
			full_path += "/";
		full_path += thing

		if thing == "." or thing == "..":
			pass
		elif thing.begins_with("."):
			pass
		elif thing == "addons":
			pass
		elif d.current_is_dir():
			locate_scripts(full_path,files)
		elif script_pattern != "" && !full_path.matchn("*"+script_pattern+"*"):
			pass
		else:
			if thing.ends_with("_test.gd"):
				files.append(full_path)
		thing = d.get_next()
	d.list_dir_end()
