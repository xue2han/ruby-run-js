
var __string = "123";
__re = /1|12/;

//CHECK#0
if (__re.test(__string) !== (__re.exec(__string) !== null)) {
	console.log('#0: var __string = "123";__re = /1|12/; __re.test(__string) === (__re.exec(__string) !== null)');
}