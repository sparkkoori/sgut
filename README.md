# sgut
sgut (Simple Godot Unit Test) is a unit test tool for godot(gdscript)

## Usage
0. copy sgut.gd to your projects and attach to root node

0. write test foobar_test.gd anywhere

``` python
	func test_pass(t):
		pass

	func test_fail(t):
		t.fail()

	func test_yield(t):
		#do something
		yield()
		#do something
```
