// Copyright (c) 2014 Hank Yates. All rights reserved.
// This code is governed by the BSD license found in the LICENSE file.

/*---
es5id: 22.1.2.1_T2
description: Testing Array.from when passed an Object is passed
author: Hank Yates (hankyates@gmail.com)
includes: [runTestCase.js]
---*/

runTestCase(function () {
  var testArr = Array.from({
    'a': 1,
    'b': '2',
    'c': 'three',
    'length': '3'
  });

  if (testArr.length != 3) {
    return false;
  }

  return true;

});
