// Copyright (c) 2012 Ecma International.  All rights reserved.
// Ecma International makes this code available under the terms and conditions set
// forth on http://hg.ecmascript.org/tests/test262/raw-file/tip/LICENSE (the
// "Use Terms").   Any redistribution of this code must retain the above
// copyright and this notice and otherwise comply with the Use Terms.

/*---
es5id: 15.4.4.18-7-7
description: >
    Array.prototype.forEach - considers new value of elements in array
    after the call
includes: [runTestCase.js]
---*/

function testcase() {

        var result = false;
        var arr = [1, 2, 3, 4, 5];

        function callbackfn(val, Idx, obj) {
            arr[4] = 6;
            if (val >= 6) {
                result = true;
            }
        }

        arr.forEach(callbackfn);
        return result;
    }
runTestCase(testcase);
