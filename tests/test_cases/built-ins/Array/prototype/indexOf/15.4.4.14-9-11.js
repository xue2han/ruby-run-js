// Copyright (c) 2012 Ecma International.  All rights reserved.
// Ecma International makes this code available under the terms and conditions set
// forth on http://hg.ecmascript.org/tests/test262/raw-file/tip/LICENSE (the
// "Use Terms").   Any redistribution of this code must retain the above
// copyright and this notice and otherwise comply with the Use Terms.

/*---
es5id: 15.4.4.14-9-11
description: >
    Array.prototype.indexOf - the length of iteration isn't changed by
    adding elements to the array during iteration
includes: [runTestCase.js]
---*/

function testcase() {

        var arr = [20];

        Object.defineProperty(arr, "0", {
            get: function () {
                arr[1] = 1;
                return 0;
            },
            configurable: true
        });

        return arr.indexOf(1) === -1;
    }
runTestCase(testcase);
