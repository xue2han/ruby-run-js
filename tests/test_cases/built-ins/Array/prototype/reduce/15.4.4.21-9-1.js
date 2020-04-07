// Copyright (c) 2012 Ecma International.  All rights reserved.
// Ecma International makes this code available under the terms and conditions set
// forth on http://hg.ecmascript.org/tests/test262/raw-file/tip/LICENSE (the
// "Use Terms").   Any redistribution of this code must retain the above
// copyright and this notice and otherwise comply with the Use Terms.

/*---
es5id: 15.4.4.21-9-1
description: >
    Array.prototype.reduce doesn't consider new elements added to
    array after it is called
includes: [runTestCase.js]
---*/

function testcase() {
        function callbackfn(prevVal, curVal, idx, obj) {
            arr[5] = 6;
            arr[2] = 3;
            return prevVal + curVal;
        }

        var arr = [1, 2, , 4, '5'];
        return arr.reduce(callbackfn) === "105";
    }
runTestCase(testcase);
