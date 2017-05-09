extends Node

export var verbose = false

#Simple expression match, where ‘*’ matches zero or more arbitrary characters,
#and ‘?’ matches any single character except ‘.’.
export var script_pattern = ""
export var test_pattern = ""

#A Testing used for talking to a test.
class Testing:
	var parent = null
	var name = ""
	var failed = false
	var verbose = false

	func fail():
		failed = true

	func is_failed():
		return failed;

	func info(s):
		if verbose:
			parent.print_if()
			print(s)

	func fatal(s):
		parent.print_if()
		print(s)
		fail()

	func report():
		parent.print_if()
		if failed:
			print("xx                           " + name)
		else:
			print("ok                           " + name)

#ScriptTesting contains many Testings.
class ScriptTesting:
	var path = ""
	var tests = []
	var dp = ""
	var verbose = false

	func delay_print(s):
		dp = s

	func print_if():
		if dp != "":
			print(dp)
			dp = ""

	func info(s):
		if verbose:
			print_if()
			print(s)

#Func state for run.
var running = null

#Run if autorun be set.
func _ready():
	set_process(true)
	running = run()

func _process(delta):
	if is_func_state(running):
		running = running.resume(delta)


#Run tests, respects changes on sources.
func run():
	var scripts = []
	locate_scripts("res://",scripts)

	var ret = cocall("run_script",scripts)
	while is_func_state(ret):
		var delta = yield()
		ret = ret.resume(delta)

	var tests= []
	var failed_tests = []
	for s in ret:
		for t in s.tests:
			tests.append(t)
			if t.is_failed():
				failed_tests.append(t)

	print("sgut: " + str(ret.size()) + " scripts " + str(tests.size()) + " tests " + str(failed_tests.size()) +" failed")

	return null


#run_script run a gd script.
func run_script(path):
	var testing = ScriptTesting.new()
	testing.path = path
	testing.verbose = verbose

	#instead of direct print, it use delay_print
	testing.delay_print("sgut: " + path)

	var script = load(path).new()
	if script extends Node:
		add_child(script)

	if script.has_method("setup"):
		script.callv("setup",[testing])

	var methods = script.get_method_list()
	var args_arr = []
	for m in methods:
		if m.name.begins_with("test_"):
			if test_pattern == "" || m.name.matchn("*"+test_pattern+"*"):
				args_arr.append([script,m.name,testing])
			pass

	var ret = cocall("run_test",args_arr)
	while is_func_state(ret):
		var delta = yield()
		testing.delay_print("sgut: " + path)
		ret = ret.resume(delta)
	testing.tests = ret

	if script.has_method("teardown"):
		script.callv("teardown",[testing])

	if script extends Node:
		remove_child(script)

	return testing


#run_test run a test in a script.
func run_test(script,method,parent):
	var testing = Testing.new()
	testing.name = method
	testing.parent = parent
	testing.verbose = verbose
	var ret = script.callv(method,[testing])

	while is_func_state(ret):
		var delta = yield()
		ret = ret.resume(delta)

	testing.report()
	return testing

func cocall(fname,args_arr):
	var goings = []
	var results = []

	for args in args_arr:
		var ret
		if typeof(args) == TYPE_ARRAY:
			ret = callv(fname,args)
		else:
			ret = callv(fname,[args])

		if is_func_state(ret):
			goings.append(ret)
		else:
			results.append(ret)

	while goings.size()>0:
		var delta = yield()
		var new_goings = []
		for go in goings:
			var ret = go.resume(delta)
			if is_func_state(ret):
				new_goings.append(ret)
			else:
				results.append(ret)
		goings = new_goings
	return results

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

func is_func_state(v):
	if typeof(v) != TYPE_OBJECT:
		return false
	elif v.is_class("GDFunctionState"):
		return true
	else:
		return false
