// Copyright (c) 2012 Ecma International.  All rights reserved.
// Ecma International makes this code available under the terms and conditions set
// forth on http://hg.ecmascript.org/tests/test262/raw-file/tip/LICENSE (the
// "Use Terms").   Any redistribution of this code must retain the above
// copyright and this notice and otherwise comply with the Use Terms.

/*---
es5id: 15.2.3.7-5-b-110
description: >
    Object.defineProperties - value of 'configurable' property of
    'descObj' is a string (value is 'false') which is treated as true
    value (8.10.5 step 4.b)
includes: [runTestCase.js]
---*/

function testcase() {
        var obj = {};

        Object.defineProperties(obj, {
            property: {
                configurable: "false"
            }
        });
        var preCheck = obj.hasOwnProperty("property");
        delete obj.property;

        return preCheck && !obj.hasOwnProperty("property");
    }
runTestCase(testcase);
