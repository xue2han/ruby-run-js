// Copyright (c) 2012 Ecma International.  All rights reserved.
// Ecma International makes this code available under the terms and conditions set
// forth on http://hg.ecmascript.org/tests/test262/raw-file/tip/LICENSE (the
// "Use Terms").   Any redistribution of this code must retain the above
// copyright and this notice and otherwise comply with the Use Terms.

/*---
es5id: 15.4.3.2-0-5
description: >
    Array.isArray return false if its argument is not an Array
    (Array.prototype)
includes: [runTestCase.js]
---*/

function testcase() {
  var b = Array.isArray(Array.prototype);
  if (b === false) {
    return true;
  }
 }
runTestCase(testcase);
