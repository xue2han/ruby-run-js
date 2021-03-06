// Copyright (c) 2012 Ecma International.  All rights reserved.
// Ecma International makes this code available under the terms and conditions set
// forth on http://hg.ecmascript.org/tests/test262/raw-file/tip/LICENSE (the
// "Use Terms").   Any redistribution of this code must retain the above
// copyright and this notice and otherwise comply with the Use Terms.

/*---
es5id: 15.2.3.6-4-123
description: >
    Object.defineProperty - 'O' is an Array, 'name' is the length
    property of 'O', the [[Value]] field of 'desc' is absent, test
    TypeError is thrown when updating the [[Writable]] attribute of
    the length property from false to true (15.4.5.1 step 3.a.i)
includes: [runTestCase.js]
---*/

function testcase() {

        var arrObj = [];
        try {
            Object.defineProperty(arrObj, "length", {
                writable: false
            });
            Object.defineProperty(arrObj, "length", {
                writable: true
            });

            return false;
        } catch (e) {
            return e instanceof TypeError;
        }
    }
runTestCase(testcase);
