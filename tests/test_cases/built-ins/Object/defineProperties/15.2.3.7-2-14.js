// Copyright (c) 2012 Ecma International.  All rights reserved.
// Ecma International makes this code available under the terms and conditions set
// forth on http://hg.ecmascript.org/tests/test262/raw-file/tip/LICENSE (the
// "Use Terms").   Any redistribution of this code must retain the above
// copyright and this notice and otherwise comply with the Use Terms.

/*---
es5id: 15.2.3.7-2-14
description: Object.defineProperties - argument 'Properties' is the JSON object
includes: [runTestCase.js]
---*/

function testcase() {

        var obj = {};
        var result = false;

        try {
            Object.defineProperty(JSON, "prop", {
                get: function () {
                    result = (this === JSON);
                    return {};
                },
                enumerable: true,
                configurable: true
            });

            Object.defineProperties(obj, JSON);
            return result;
        } finally {
            delete JSON.prop;
        }
    }
runTestCase(testcase);
