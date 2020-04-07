// Copyright (c) 2012 Ecma International.  All rights reserved.
// Ecma International makes this code available under the terms and conditions set
// forth on http://hg.ecmascript.org/tests/test262/raw-file/tip/LICENSE (the
// "Use Terms").   Any redistribution of this code must retain the above
// copyright and this notice and otherwise comply with the Use Terms.

/*---
es5id: 15.2.3.4-4-38
description: >
    Object.getOwnPropertyNames - own data properties are pushed into
    the returned array
includes: [runTestCase.js]
---*/

function testcase() {

        var obj = { "a": "a" };

        var result = Object.getOwnPropertyNames(obj);

        return result[0] === "a";
    }
runTestCase(testcase);
