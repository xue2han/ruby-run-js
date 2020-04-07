// Copyright (c) 2012 Ecma International.  All rights reserved.
// Ecma International makes this code available under the terms and conditions set
// forth on http://hg.ecmascript.org/tests/test262/raw-file/tip/LICENSE (the
// "Use Terms").   Any redistribution of this code must retain the above
// copyright and this notice and otherwise comply with the Use Terms.

/*---
es5id: 15.2.3.6-3-121
description: >
    Object.defineProperty - 'configurable' property in 'Attributes' is
    the Argument object  (8.10.5 step 4.b)
includes: [runTestCase.js]
---*/

function testcase() {
        var obj = {};

        var argObj = (function () { return arguments; })(1, true, "a");

        var attr = {
            configurable: argObj
        };

        Object.defineProperty(obj, "property", attr);

        var beforeDeleted = obj.hasOwnProperty("property");

        delete obj.property;

        var afterDeleted = obj.hasOwnProperty("property");

        return beforeDeleted === true && afterDeleted === false;
    }
runTestCase(testcase);
