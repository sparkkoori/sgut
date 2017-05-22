# sgut
sgut (Simple Godot Unit Test) is a unit test tool for godot(gdscript)

## Usage
0. Copy sgut.gd to your projects and attach it to a scene.

0. Write foobar_test.gd at anywhere.

	``` python
		func test_pass(t):
			pass

		func test_fail(t):
			t.fail()

		func test_yield(t):
			#do something
			yield(obj,"signal")
			#do something
			t.finish()
	```
0. Run the scene.
