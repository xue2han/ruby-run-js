// Copyright (c) 2012 Ecma International.  All rights reserved.
// Ecma International makes this code available under the terms and conditions set
// forth on http://hg.ecmascript.org/tests/test262/raw-file/tip/LICENSE (the
// "Use Terms").   Any redistribution of this code must retain the above
// copyright and this notice and otherwise comply with the Use Terms.

/*---
es5id: 8.12.1-1_32
description: >
    Properties - [[HasOwnProperty]] (configurable, non-enumerable own
    setter property)
includes: [runTestCase.js]
---*/

function testcase() {

    var o = {};
    Object.defineProperty(o, "foo", {set: function() {;}, configurable:true});
    return o.hasOwnProperty("foo");

}
runTestCase(testcase);
