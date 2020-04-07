// Copyright (c) 2012 Ecma International.  All rights reserved.
// Ecma International makes this code available under the terms and conditions set
// forth on http://hg.ecmascript.org/tests/test262/raw-file/tip/LICENSE (the
// "Use Terms").   Any redistribution of this code must retain the above
// copyright and this notice and otherwise comply with the Use Terms.

/*---
es5id: 15.2.3.6-4-160
description: >
    Object.defineProperty - 'O' is an Array, 'name' is the length
    property of 'O', set the [[Value]] field of 'desc' to a value
    equal to the existing value of length (15.4.5.1 step 3.f)
includes: [runTestCase.js]
---*/

function testcase() {

        var arrObj = [0, , 2];

        Object.defineProperty(arrObj, "length", {
            value: 3
        });

        return arrObj.length === 3 && arrObj[0] === 0 && !arrObj.hasOwnProperty("1") && arrObj[2] === 2;
    }
runTestCase(testcase);
