// Copyright (c) 2012 Ecma International.  All rights reserved.
// Ecma International makes this code available under the terms and conditions set
// forth on http://hg.ecmascript.org/tests/test262/raw-file/tip/LICENSE (the
// "Use Terms").   Any redistribution of this code must retain the above
// copyright and this notice and otherwise comply with the Use Terms.

/*---
es5id: 15.2.3.6-3-141-1
description: >
    Object.defineProperty - 'Attributes' is a String object that uses
    Object's [[Get]] method to access the 'value' property of
    prototype object  (8.10.5 step 5.a)
includes: [runTestCase.js]
---*/

function testcase() {
        var obj = {};
        try {
            String.prototype.value = "String";
            var strObj = new String("abc");

            Object.defineProperty(obj, "property", strObj);

            return obj.property === "String";
        } finally {
            delete String.prototype.value;
        }
    }
runTestCase(testcase);
