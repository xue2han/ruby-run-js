// Copyright (c) 2012 Ecma International.  All rights reserved.
// Ecma International makes this code available under the terms and conditions set
// forth on http://hg.ecmascript.org/tests/test262/raw-file/tip/LICENSE (the
// "Use Terms").   Any redistribution of this code must retain the above
// copyright and this notice and otherwise comply with the Use Terms.

/*---
es5id: 15.2.3.6-4-442
description: >
    ES5 Attributes - property ([[Get]] is undefined, [[Set]] is
    undefined, [[Enumerable]] is false, [[Configurable]] is true) is
    non-enumerable
includes: [runTestCase.js]
---*/

function testcase() {
        var obj = {};

        Object.defineProperty(obj, "prop", {
            get: undefined,
            set: undefined,
            enumerable: false,
            configurable: true
        });

        var propertyDefineCorrect = obj.hasOwnProperty("prop");
        var desc = Object.getOwnPropertyDescriptor(obj, "prop");

        for (var p in obj) {
            if (p === "prop") {
                return false;
            }
        }

        return propertyDefineCorrect && desc.enumerable === false;
    }
runTestCase(testcase);
