// Copyright (c) 2012 Ecma International.  All rights reserved.
// Ecma International makes this code available under the terms and conditions set
// forth on http://hg.ecmascript.org/tests/test262/raw-file/tip/LICENSE (the
// "Use Terms").   Any redistribution of this code must retain the above
// copyright and this notice and otherwise comply with the Use Terms.

/*---
es5id: 15.2.3.5-4-156
description: >
    Object.create - 'value' property of one property in 'Properties'
    is own data property that overrides an inherited data property
    (8.10.5 step 5.a)
includes: [runTestCase.js]
---*/

function testcase() {

        var proto = {
            value: "inheritedDataProperty"
        };

        var ConstructFun = function () { };
        ConstructFun.prototype = proto;

        var descObj = new ConstructFun();

        descObj.value = "ownDataProperty";

        var newObj = Object.create({}, {
            prop: descObj
        });

        return newObj.prop === "ownDataProperty";
    }
runTestCase(testcase);
