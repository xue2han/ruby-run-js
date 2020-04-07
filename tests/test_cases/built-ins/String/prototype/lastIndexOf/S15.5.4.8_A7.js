// Copyright 2009 the Sputnik authors.  All rights reserved.
// This code is governed by the BSD license found in the LICENSE file.

/*---
info: String.prototype.lastIndexOf can't be used as constructor
es5id: 15.5.4.8_A7
description: Checking if creating the String.prototype.lastIndexOf object fails
includes:
    - $PRINT.js
    - $FAIL.js
---*/

var __FACTORY = String.prototype.lastIndexOf;

try {
  var __instance = new __FACTORY;
  $FAIL('#1: __FACTORY = String.prototype.lastIndexOf; __instance = new __FACTORY lead to throwing exception');
} catch (e) {
  $PRINT(e);
}
