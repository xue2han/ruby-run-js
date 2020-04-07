// Copyright (c) 2012 Ecma International.  All rights reserved.
// Ecma International makes this code available under the terms and conditions set
// forth on http://hg.ecmascript.org/tests/test262/raw-file/tip/LICENSE (the
// "Use Terms").   Any redistribution of this code must retain the above
// copyright and this notice and otherwise comply with the Use Terms.

/*---
es5id: 15.4.4.18-5-19
description: >
    Array.prototype.forEach - the Arguments object can be used as
    thisArg
includes: [runTestCase.js]
---*/

function testcase() {

        var result = false;
        var arg;

        function callbackfn(val, idx, obj) {
            result = (this === arg);
        }

        (function fun() {
            arg = arguments;
        }(1, 2, 3));

        [11].forEach(callbackfn, arg);
        return result;
    }
runTestCase(testcase);
