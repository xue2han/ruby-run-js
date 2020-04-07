// Copyright (c) 2012 Ecma International.  All rights reserved.
// Ecma International makes this code available under the terms and conditions set
// forth on http://hg.ecmascript.org/tests/test262/raw-file/tip/LICENSE (the
// "Use Terms").   Any redistribution of this code must retain the above
// copyright and this notice and otherwise comply with the Use Terms.

/*---
es5id: 15.4.4.14-9-b-i-29
description: >
    Array.prototype.indexOf - side-effects are visible in subsequent
    iterations on an Array-like object
includes: [runTestCase.js]
---*/

function testcase() {

        var preIterVisible = false;
        var obj = { length: 2 };

        Object.defineProperty(obj, "0", {
            get: function () {
                preIterVisible = true;
                return false;
            },
            configurable: true
        });

        Object.defineProperty(obj, "1", {
            get: function () {
                if (preIterVisible) {
                    return true;
                } else {
                    return false;
                }
            },
            configurable: true
        });

        return Array.prototype.indexOf.call(obj, true) === 1;
    }
runTestCase(testcase);
