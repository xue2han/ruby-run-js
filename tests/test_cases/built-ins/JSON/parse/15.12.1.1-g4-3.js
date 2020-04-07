// Copyright (c) 2012 Ecma International.  All rights reserved.
// Ecma International makes this code available under the terms and conditions set
// forth on http://hg.ecmascript.org/tests/test262/raw-file/tip/LICENSE (the
// "Use Terms").   Any redistribution of this code must retain the above
// copyright and this notice and otherwise comply with the Use Terms.

/*---
es5id: 15.12.1.1-g4-3
description: >
    The JSON lexical grammar does not allow a JSONStringCharacter to
    be any of the Unicode characters U+0010 thru U+0017
includes: [runTestCase.js]
---*/

function testcase() {
  try {
    JSON.parse('"\u0010\u0011\u0012\u0013\u0014\u0015\u0016\u0017"'); // invalid string characters should produce a syntax error
    }
  catch (e) {
      return true; // treat any exception as a pass, other tests ensure that JSON.parse throws SyntaxError exceptions
      }
  }
runTestCase(testcase);
