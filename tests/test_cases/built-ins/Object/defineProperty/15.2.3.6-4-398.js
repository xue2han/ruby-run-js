// Copyright (c) 2012 Ecma International.  All rights reserved.
// Ecma International makes this code available under the terms and conditions set
// forth on http://hg.ecmascript.org/tests/test262/raw-file/tip/LICENSE (the
// "Use Terms").   Any redistribution of this code must retain the above
// copyright and this notice and otherwise comply with the Use Terms.

/*---
es5id: 15.2.3.6-4-398
description: ES5 Attributes - [[Value]] attribute of data property is -Infinity
includes: [runTestCase.js]
---*/

function testcase() {
        var obj = {};

        Object.defineProperty(obj, "prop", {
            value: -Infinity
        });

        var desc = Object.getOwnPropertyDescriptor(obj, "prop");

        return obj.prop === -Infinity && desc.value === -Infinity;
    }
runTestCase(testcase);
