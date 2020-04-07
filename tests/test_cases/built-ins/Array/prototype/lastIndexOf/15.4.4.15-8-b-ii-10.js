// Copyright (c) 2012 Ecma International.  All rights reserved.
// Ecma International makes this code available under the terms and conditions set
// forth on http://hg.ecmascript.org/tests/test262/raw-file/tip/LICENSE (the
// "Use Terms").   Any redistribution of this code must retain the above
// copyright and this notice and otherwise comply with the Use Terms.

/*---
es5id: 15.4.4.15-8-b-ii-10
description: >
    Array.prototype.lastIndexOf - both array element and search
    element are booleans, and they have same value
includes: [runTestCase.js]
---*/

function testcase() {

        return [false, true].lastIndexOf(true) === 1;
    }
runTestCase(testcase);
