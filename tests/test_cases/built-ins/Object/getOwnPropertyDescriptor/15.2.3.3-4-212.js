// Copyright (c) 2012 Ecma International.  All rights reserved.
// Ecma International makes this code available under the terms and conditions set
// forth on http://hg.ecmascript.org/tests/test262/raw-file/tip/LICENSE (the
// "Use Terms").   Any redistribution of this code must retain the above
// copyright and this notice and otherwise comply with the Use Terms.

/*---
es5id: 15.2.3.3-4-212
description: >
    Object.getOwnPropertyDescriptor returns accessor desc for
    accessors on built-ins (RegExp.prototype.source)
includes: [runTestCase.js]
---*/

function testcase() {
  var desc = Object.getOwnPropertyDescriptor(RegExp.prototype, "source");

  if (desc.hasOwnProperty('writable') === false &&
      desc.enumerable === false &&
      desc.configurable === true &&
      typeof desc.get === 'function' &&
      desc.set === undefined) {
    return true;
  }
 }
runTestCase(testcase);
