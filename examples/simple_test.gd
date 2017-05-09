
func setup(t):
	t.info("setup")

func test_pass(t):
	pass

func test_fail(t):
	t.fail()

func test_info(t):
	t.info("info")
	t.fail()

func test_yield(t):
	for i in range(60):
		yield()

	t.info("yield done")

func test_yield2(t):
	for i in range(60):
		yield()

	t.info("yield done")

func teardown(t):
	t.info("teardown")
