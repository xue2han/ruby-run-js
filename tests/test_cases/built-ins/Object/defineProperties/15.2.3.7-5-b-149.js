// Copyright (c) 2012 Ecma International.  All rights reserved.
// Ecma International makes this code available under the terms and conditions set
// forth on http://hg.ecmascript.org/tests/test262/raw-file/tip/LICENSE (the
// "Use Terms").   Any redistribution of this code must retain the above
// copyright and this notice and otherwise comply with the Use Terms.

/*---
es5id: 15.2.3.7-5-b-149
description: >
    Object.defineProperties - 'writable' property of 'descObj' is own
    accessor property without a get function that overrides an
    inherited accessor property (8.10.5 step 6.a)
includes: [runTestCase.js]
---*/

function testcase() {
        var obj = {};

        var proto = {};

        Object.defineProperty(proto, "writable", {
            get: function () {
                return true;
            }
        });

        var Con = function () { };
        Con.prototype = proto;

        var descObj = new Con();

        Object.defineProperty(descObj, "writable", {
            set: function () { }
        });

        Object.defineProperties(obj, {
            property: descObj
        });

        obj.property = "isWritable";

        return obj.hasOwnProperty("property") && typeof (obj.property) === "undefined";
    }
runTestCase(testcase);
