// Copyright (c) 2012 Ecma International.  All rights reserved.
// Ecma International makes this code available under the terms and conditions set
// forth on http://hg.ecmascript.org/tests/test262/raw-file/tip/LICENSE (the
// "Use Terms").   Any redistribution of this code must retain the above
// copyright and this notice and otherwise comply with the Use Terms.

/*---
es5id: 15.2.3.3-3-9
description: >
    Object.getOwnPropertyDescriptor - 'P' is own accessor property
    without a get function
includes: [runTestCase.js]
---*/

function testcase() {

        var obj = {};
        var fun = function () { };
        Object.defineProperty(obj, "property", {
            set: fun,
            configurable: true
        });

        var desc = Object.getOwnPropertyDescriptor(obj, "property");

        return desc.set === fun;
    }
runTestCase(testcase);
