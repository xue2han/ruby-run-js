// Copyright (c) 2012 Ecma International.  All rights reserved.
// Ecma International makes this code available under the terms and conditions set
// forth on http://hg.ecmascript.org/tests/test262/raw-file/tip/LICENSE (the
// "Use Terms").   Any redistribution of this code must retain the above
// copyright and this notice and otherwise comply with the Use Terms.

/*---
es5id: 15.5.4.20-2-46
description: >
    String.prototype.trim - 'this' is a Function Object that converts
    to a string
includes: [runTestCase.js]
---*/

function testcase() {
        var funObj = function () { return arguments; };
        return typeof(String.prototype.trim.call(funObj)) === "string";
    }
runTestCase(testcase);
