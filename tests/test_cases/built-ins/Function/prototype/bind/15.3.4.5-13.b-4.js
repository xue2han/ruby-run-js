// Copyright (c) 2012 Ecma International.  All rights reserved.
// Ecma International makes this code available under the terms and conditions set
// forth on http://hg.ecmascript.org/tests/test262/raw-file/tip/LICENSE (the
// "Use Terms").   Any redistribution of this code must retain the above
// copyright and this notice and otherwise comply with the Use Terms.

/*---
es5id: 15.3.4.5-13.b-4
description: >
    Function.prototype.bind, 'length' set to remaining number of
    expected args (target takes 0 args)
includes: [runTestCase.js]
---*/

function testcase() {
  function foo() { }
  var o = {};
  
  var bf = foo.bind(o);
  if (bf.length === 0) {
    return true;
  }
 }
runTestCase(testcase);
