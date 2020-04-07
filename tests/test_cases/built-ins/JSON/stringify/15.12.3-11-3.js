// Copyright (c) 2012 Ecma International.  All rights reserved.
// Ecma International makes this code available under the terms and conditions set
// forth on http://hg.ecmascript.org/tests/test262/raw-file/tip/LICENSE (the
// "Use Terms").   Any redistribution of this code must retain the above
// copyright and this notice and otherwise comply with the Use Terms.

/*---
es5id: 15.12.3-11-3
description: A JSON.stringify correctly works on top level string values.
includes: [runTestCase.js]
---*/

function testcase() {
  return JSON.stringify("a string") === '"a string"';
  }
runTestCase(testcase);
