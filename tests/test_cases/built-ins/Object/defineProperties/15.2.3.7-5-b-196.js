// Copyright (c) 2012 Ecma International.  All rights reserved.
// Ecma International makes this code available under the terms and conditions set
// forth on http://hg.ecmascript.org/tests/test262/raw-file/tip/LICENSE (the
// "Use Terms").   Any redistribution of this code must retain the above
// copyright and this notice and otherwise comply with the Use Terms.

/*---
es5id: 15.2.3.7-5-b-196
description: >
    Object.defineProperties - 'get' property of 'descObj' is own data
    property that overrides an inherited accessor property (8.10.5
    step 7.a)
includes: [runTestCase.js]
---*/

function testcase() {
        var obj = {};

        var proto = {};

        Object.defineProperty(proto, "get", {
            get: function () {
                return function () {
                    return "inheritedAccessorProperty";
                };
            }
        });

        var Con = function () { };
        Con.prototype = proto;

        var descObj = new Con();

        Object.defineProperty(descObj, "get", {
            value: function () {
                return "ownDataProperty";
            }
        });

        Object.defineProperties(obj, {
            property: descObj
        });

        return obj.property === "ownDataProperty";
    }
runTestCase(testcase);
