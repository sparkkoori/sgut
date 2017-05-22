
func setup(t):
	t.info("setup")

func test_pass(t):
	t.finish()

func test_fail(t):
	t.error("error1")
	t.fail("error2")

func test_info(t):
	t.info("info")
	t.error("error")

func test_wait(t):
	t.info("waiting")
	yield(t.wait(1000),"timeout")
	t.finish()

func teardown(t):
	t.info("teardown")
