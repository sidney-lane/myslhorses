// lsl_test_controller.lsl
// Example runtime test harness. Embed or adapt for your scripts.

integer __test_total = 0;
integer __test_passed = 0;

__emit(string level, string testId, string message)
{
    llOwnerSay(level + ": " + testId + " - " + message);
}

assert_true(integer condition, string testId, string message)
{
    __test_total += 1;
    if (condition)
    {
        __test_passed += 1;
        __emit("PASS", testId, message);
    }
    else
    {
        __emit("FAIL", testId, message);
    }
}

assert_equal_integer(integer actual, integer expected, string testId)
{
    assert_true(actual == expected, testId, "expected=" + (string)expected + ", actual=" + (string)actual);
}

assert_equal_string(string actual, string expected, string testId)
{
    assert_true(actual == expected, testId, "expected='" + expected + "', actual='" + actual + "'");
}

print_summary()
{
    llOwnerSay("SUMMARY: " + (string)__test_passed + "/" + (string)__test_total + " passed");
}

run_tests()
{
    // Sample tests. Replace with your script-specific checks.
    assert_true(TRUE, "smoke-001", "test harness boots");
    assert_equal_integer(2 + 2, 4, "math-001");
    assert_equal_string("hello", "hello", "string-001");

    print_summary();
}

default
{
    state_entry()
    {
        run_tests();
    }
}
