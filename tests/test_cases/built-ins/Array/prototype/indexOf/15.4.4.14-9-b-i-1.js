// Copyright (c) 2012 Ecma International.  All rights reserved.
// Ecma International makes this code available under the terms and conditions set
// forth on http://hg.ecmascript.org/tests/test262/raw-file/tip/LICENSE (the
// "Use Terms").   Any redistribution of this code must retain the above
// copyright and this notice and otherwise comply with the Use Terms.

/*---
es5id: 15.4.4.14-9-b-i-1
description: >
    Array.prototype.indexOf - element to be retrieved is own data
    property on an Array-like object
includes: [runTestCase.js]
---*/

function testcase() {
        var obj = { 0: 0, 1: 1, 2: 2, length: 3 };
        return Array.prototype.indexOf.call(obj, 0) === 0 &&
            Array.prototype.indexOf.call(obj, 1) === 1 &&
            Array.prototype.indexOf.call(obj, 2) === 2;
    }
runTestCase(testcase);
