// Copyright (c) 2012 Ecma International.  All rights reserved.
// Ecma International makes this code available under the terms and conditions set
// forth on http://hg.ecmascript.org/tests/test262/raw-file/tip/LICENSE (the
// "Use Terms").   Any redistribution of this code must retain the above
// copyright and this notice and otherwise comply with the Use Terms.

/*---
es5id: 15.4.4.20-0-2
description: Array.prototype.filter.length must be 1
includes: [runTestCase.js]
---*/

function testcase() {
  if (Array.prototype.filter.length === 1) {
    return true;
  }
 }
runTestCase(testcase);
