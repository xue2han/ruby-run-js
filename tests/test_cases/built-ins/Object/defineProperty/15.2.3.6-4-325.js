// Copyright (c) 2012 Ecma International.  All rights reserved.
// Ecma International makes this code available under the terms and conditions set
// forth on http://hg.ecmascript.org/tests/test262/raw-file/tip/LICENSE (the
// "Use Terms").   Any redistribution of this code must retain the above
// copyright and this notice and otherwise comply with the Use Terms.

/*---
es5id: 15.2.3.6-4-325
description: >
    Object.defineProperty - 'O' is an Arguments object, 'name' is own
    property of [[ParameterMap]] of 'O', test 'name' is deleted if
    'name' is configurable and 'desc' is accessor descriptor (10.6
    [[DefineOwnProperty]] step 5.a.i)
includes: [runTestCase.js]
---*/

function testcase() {
        var argObj = (function () { return arguments; })(1, 2, 3);
        var accessed = false;

        Object.defineProperty(argObj, 0, {
            get: function () {
                accessed = true;
                return 12;
            }
        });

        return argObj[0] === 12 && accessed;
    }
runTestCase(testcase);
