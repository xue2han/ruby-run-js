# the javascript parser is manually translated from esprima.js to ruby.
# the reference code of esprima.js is from https://github.com/jquery/esprima/tree/1.0
# Note: the parser only supports ECMAScript 5.1

module RubyRunJs
    class Parser
        Token = {
            BooleanLiteral: 1,
            EOF: 2,
            Identifier: 3,
            Keyword: 4,
            NullLiteral: 5,
            NumericLiteral: 6,
            Punctuator: 7,
            StringLiteral: 8
        }
    
        TokenName = {
            Token[:BooleanLiteral] => 'Boolean',
            Token[:EOF] => '<end>',
            Token[:Identifier] => 'Identifier',
            Token[:Keyword] => 'Keyword',
            Token[:NullLiteral] => 'Null',
            Token[:NumericLiteral] => 'Numeric',
            Token[:Punctuator] => 'Punctuator',
            Token[:StringLiteral] => 'String'
        }

        Syntax = {
            AssignmentExpression: 'AssignmentExpression',
            ArrayExpression: 'ArrayExpression',
            BlockStatement: 'BlockStatement',
            BinaryExpression: 'BinaryExpression',
            BreakStatement: 'BreakStatement',
            CallExpression: 'CallExpression',
            CatchClause: 'CatchClause',
            ConditionalExpression: 'ConditionalExpression',
            ContinueStatement: 'ContinueStatement',
            DoWhileStatement: 'DoWhileStatement',
            DebuggerStatement: 'DebuggerStatement',
            EmptyStatement: 'EmptyStatement',
            ExpressionStatement: 'ExpressionStatement',
            ForStatement: 'ForStatement',
            ForInStatement: 'ForInStatement',
            FunctionDeclaration: 'FunctionDeclaration',
            FunctionExpression: 'FunctionExpression',
            Identifier: 'Identifier',
            IfStatement: 'IfStatement',
            Literal: 'Literal',
            LabeledStatement: 'LabeledStatement',
            LogicalExpression: 'LogicalExpression',
            MemberExpression: 'MemberExpression',
            NewExpression: 'NewExpression',
            ObjectExpression: 'ObjectExpression',
            Program: 'Program',
            Property: 'Property',
            ReturnStatement: 'ReturnStatement',
            SequenceExpression: 'SequenceExpression',
            SwitchStatement: 'SwitchStatement',
            SwitchCase: 'SwitchCase',
            ThisExpression: 'ThisExpression',
            ThrowStatement: 'ThrowStatement',
            TryStatement: 'TryStatement',
            UnaryExpression: 'UnaryExpression',
            UpdateExpression: 'UpdateExpression',
            VariableDeclaration: 'VariableDeclaration',
            VariableDeclarator: 'VariableDeclarator',
            WhileStatement: 'WhileStatement',
            WithStatement: 'WithStatement'
        }

        PropertyKind = {
            Data: 1,
            Get: 2,
            Set: 4
        }

        # Error messages should be identical to V8.
        Messages = {
            UnexpectedToken:  'Unexpected token %0',
            UnexpectedNumber:  'Unexpected number',
            UnexpectedString:  'Unexpected string',
            UnexpectedIdentifier:  'Unexpected identifier',
            UnexpectedReserved:  'Unexpected reserved word',
            UnexpectedEOS:  'Unexpected end of input',
            NewlineAfterThrow:  'Illegal newline after throw',
            InvalidRegExp: 'Invalid regular expression',
            UnterminatedRegExp:  'Invalid regular expression: missing /',
            InvalidLHSInAssignment:  'Invalid left-hand side in assignment',
            InvalidLHSInForIn:  'Invalid left-hand side in for-in',
            MultipleDefaultsInSwitch: 'More than one default clause in switch statement',
            NoCatchOrFinally:  'Missing catch or finally after try',
            UnknownLabel: 'Undefined label \'%0\'',
            Redeclaration: '%0 \'%1\' has already been declared',
            IllegalContinue: 'Illegal continue statement',
            IllegalBreak: 'Illegal break statement',
            IllegalReturn: 'Illegal return statement',
            StrictModeWith:  'Strict mode code may not include a with statement',
            StrictCatchVariable:  'Catch variable may not be eval or arguments in strict mode',
            StrictVarName:  'Variable name may not be eval or arguments in strict mode',
            StrictParamName:  'Parameter name eval or arguments is not allowed in strict mode',
            StrictParamDupe: 'Strict mode function may not have duplicate parameter names',
            StrictFunctionName:  'Function name may not be eval or arguments in strict mode',
            StrictOctalLiteral:  'Octal literals are not allowed in strict mode.',
            StrictDelete:  'Delete of an unqualified identifier in strict mode.',
            StrictDuplicateProperty:  'Duplicate data property in object literal not allowed in strict mode',
            AccessorDataProperty:  'Object literal may not have data and accessor property with the same name',
            AccessorGetSet:  'Object literal may not have multiple get/set accessors with the same name',
            StrictLHSAssignment:  'Assignment to eval or arguments is not allowed in strict mode',
            StrictLHSPostfix:  'Postfix increment/decrement may not have eval or arguments operand in strict mode',
            StrictLHSPrefix:  'Prefix increment/decrement may not have eval or arguments operand in strict mode',
            StrictReservedWord:  'Use of future reserved word in strict mode'
        }

        # See also tools/generate-unicode-regex[:py].
       # NonAsciiIdentifierStart = Regexp.new("[\xaa\xb5\xba\xc0-\xd6\xd8-\xf6\xf8-\u02c1\u02c6-\u02d1\u02e0-\u02e4\u02ec\u02ee\u0370-\u0374\u0376\u0377\u037a-\u037d\u0386\u0388-\u038a\u038c\u038e-\u03a1\u03a3-\u03f5\u03f7-\u0481\u048a-\u0527\u0531-\u0556\u0559\u0561-\u0587\u05d0-\u05ea\u05f0-\u05f2\u0620-\u064a\u066e\u066f\u0671-\u06d3\u06d5\u06e5\u06e6\u06ee\u06ef\u06fa-\u06fc\u06ff\u0710\u0712-\u072f\u074d-\u07a5\u07b1\u07ca-\u07ea\u07f4\u07f5\u07fa\u0800-\u0815\u081a\u0824\u0828\u0840-\u0858\u08a0\u08a2-\u08ac\u0904-\u0939\u093d\u0950\u0958-\u0961\u0971-\u0977\u0979-\u097f\u0985-\u098c\u098f\u0990\u0993-\u09a8\u09aa-\u09b0\u09b2\u09b6-\u09b9\u09bd\u09ce\u09dc\u09dd\u09df-\u09e1\u09f0\u09f1\u0a05-\u0a0a\u0a0f\u0a10\u0a13-\u0a28\u0a2a-\u0a30\u0a32\u0a33\u0a35\u0a36\u0a38\u0a39\u0a59-\u0a5c\u0a5e\u0a72-\u0a74\u0a85-\u0a8d\u0a8f-\u0a91\u0a93-\u0aa8\u0aaa-\u0ab0\u0ab2\u0ab3\u0ab5-\u0ab9\u0abd\u0ad0\u0ae0\u0ae1\u0b05-\u0b0c\u0b0f\u0b10\u0b13-\u0b28\u0b2a-\u0b30\u0b32\u0b33\u0b35-\u0b39\u0b3d\u0b5c\u0b5d\u0b5f-\u0b61\u0b71\u0b83\u0b85-\u0b8a\u0b8e-\u0b90\u0b92-\u0b95\u0b99\u0b9a\u0b9c\u0b9e\u0b9f\u0ba3\u0ba4\u0ba8-\u0baa\u0bae-\u0bb9\u0bd0\u0c05-\u0c0c\u0c0e-\u0c10\u0c12-\u0c28\u0c2a-\u0c33\u0c35-\u0c39\u0c3d\u0c58\u0c59\u0c60\u0c61\u0c85-\u0c8c\u0c8e-\u0c90\u0c92-\u0ca8\u0caa-\u0cb3\u0cb5-\u0cb9\u0cbd\u0cde\u0ce0\u0ce1\u0cf1\u0cf2\u0d05-\u0d0c\u0d0e-\u0d10\u0d12-\u0d3a\u0d3d\u0d4e\u0d60\u0d61\u0d7a-\u0d7f\u0d85-\u0d96\u0d9a-\u0db1\u0db3-\u0dbb\u0dbd\u0dc0-\u0dc6\u0e01-\u0e30\u0e32\u0e33\u0e40-\u0e46\u0e81\u0e82\u0e84\u0e87\u0e88\u0e8a\u0e8d\u0e94-\u0e97\u0e99-\u0e9f\u0ea1-\u0ea3\u0ea5\u0ea7\u0eaa\u0eab\u0ead-\u0eb0\u0eb2\u0eb3\u0ebd\u0ec0-\u0ec4\u0ec6\u0edc-\u0edf\u0f00\u0f40-\u0f47\u0f49-\u0f6c\u0f88-\u0f8c\u1000-\u102a\u103f\u1050-\u1055\u105a-\u105d\u1061\u1065\u1066\u106e-\u1070\u1075-\u1081\u108e\u10a0-\u10c5\u10c7\u10cd\u10d0-\u10fa\u10fc-\u1248\u124a-\u124d\u1250-\u1256\u1258\u125a-\u125d\u1260-\u1288\u128a-\u128d\u1290-\u12b0\u12b2-\u12b5\u12b8-\u12be\u12c0\u12c2-\u12c5\u12c8-\u12d6\u12d8-\u1310\u1312-\u1315\u1318-\u135a\u1380-\u138f\u13a0-\u13f4\u1401-\u166c\u166f-\u167f\u1681-\u169a\u16a0-\u16ea\u16ee-\u16f0\u1700-\u170c\u170e-\u1711\u1720-\u1731\u1740-\u1751\u1760-\u176c\u176e-\u1770\u1780-\u17b3\u17d7\u17dc\u1820-\u1877\u1880-\u18a8\u18aa\u18b0-\u18f5\u1900-\u191c\u1950-\u196d\u1970-\u1974\u1980-\u19ab\u19c1-\u19c7\u1a00-\u1a16\u1a20-\u1a54\u1aa7\u1b05-\u1b33\u1b45-\u1b4b\u1b83-\u1ba0\u1bae\u1baf\u1bba-\u1be5\u1c00-\u1c23\u1c4d-\u1c4f\u1c5a-\u1c7d\u1ce9-\u1cec\u1cee-\u1cf1\u1cf5\u1cf6\u1d00-\u1dbf\u1e00-\u1f15\u1f18-\u1f1d\u1f20-\u1f45\u1f48-\u1f4d\u1f50-\u1f57\u1f59\u1f5b\u1f5d\u1f5f-\u1f7d\u1f80-\u1fb4\u1fb6-\u1fbc\u1fbe\u1fc2-\u1fc4\u1fc6-\u1fcc\u1fd0-\u1fd3\u1fd6-\u1fdb\u1fe0-\u1fec\u1ff2-\u1ff4\u1ff6-\u1ffc\u2071\u207f\u2090-\u209c\u2102\u2107\u210a-\u2113\u2115\u2119-\u211d\u2124\u2126\u2128\u212a-\u212d\u212f-\u2139\u213c-\u213f\u2145-\u2149\u214e\u2160-\u2188\u2c00-\u2c2e\u2c30-\u2c5e\u2c60-\u2ce4\u2ceb-\u2cee\u2cf2\u2cf3\u2d00-\u2d25\u2d27\u2d2d\u2d30-\u2d67\u2d6f\u2d80-\u2d96\u2da0-\u2da6\u2da8-\u2dae\u2db0-\u2db6\u2db8-\u2dbe\u2dc0-\u2dc6\u2dc8-\u2dce\u2dd0-\u2dd6\u2dd8-\u2dde\u2e2f\u3005-\u3007\u3021-\u3029\u3031-\u3035\u3038-\u303c\u3041-\u3096\u309d-\u309f\u30a1-\u30fa\u30fc-\u30ff\u3105-\u312d\u3131-\u318e\u31a0-\u31ba\u31f0-\u31ff\u3400-\u4db5\u4e00-\u9fcc\ua000-\ua48c\ua4d0-\ua4fd\ua500-\ua60c\ua610-\ua61f\ua62a\ua62b\ua640-\ua66e\ua67f-\ua697\ua6a0-\ua6ef\ua717-\ua71f\ua722-\ua788\ua78b-\ua78e\ua790-\ua793\ua7a0-\ua7aa\ua7f8-\ua801\ua803-\ua805\ua807-\ua80a\ua80c-\ua822\ua840-\ua873\ua882-\ua8b3\ua8f2-\ua8f7\ua8fb\ua90a-\ua925\ua930-\ua946\ua960-\ua97c\ua984-\ua9b2\ua9cf\uaa00-\uaa28\uaa40-\uaa42\uaa44-\uaa4b\uaa60-\uaa76\uaa7a\uaa80-\uaaaf\uaab1\uaab5\uaab6\uaab9-\uaabd\uaac0\uaac2\uaadb-\uaadd\uaae0-\uaaea\uaaf2-\uaaf4\uab01-\uab06\uab09-\uab0e\uab11-\uab16\uab20-\uab26\uab28-\uab2e\uabc0-\uabe2\uac00-\ud7a3\ud7b0-\ud7c6\ud7cb-\ud7fb\uf900-\ufa6d\ufa70-\ufad9\ufb00-\ufb06\ufb13-\ufb17\ufb1d\ufb1f-\ufb28\ufb2a-\ufb36\ufb38-\ufb3c\ufb3e\ufb40\ufb41\ufb43\ufb44\ufb46-\ufbb1\ufbd3-\ufd3d\ufd50-\ufd8f\ufd92-\ufdc7\ufdf0-\ufdfb\ufe70-\ufe74\ufe76-\ufefc\uff21-\uff3a\uff41-\uff5a\uff66-\uffbe\uffc2-\uffc7\uffca-\uffcf\uffd2-\uffd7\uffda-\uffdc]",nil,'n')
       # NonAsciiIdentifierPart = Regexp.new("[\xaa\xb5\xba\xc0-\xd6\xd8-\xf6\xf8-\u02c1\u02c6-\u02d1\u02e0-\u02e4\u02ec\u02ee\u0300-\u0374\u0376\u0377\u037a-\u037d\u0386\u0388-\u038a\u038c\u038e-\u03a1\u03a3-\u03f5\u03f7-\u0481\u0483-\u0487\u048a-\u0527\u0531-\u0556\u0559\u0561-\u0587\u0591-\u05bd\u05bf\u05c1\u05c2\u05c4\u05c5\u05c7\u05d0-\u05ea\u05f0-\u05f2\u0610-\u061a\u0620-\u0669\u066e-\u06d3\u06d5-\u06dc\u06df-\u06e8\u06ea-\u06fc\u06ff\u0710-\u074a\u074d-\u07b1\u07c0-\u07f5\u07fa\u0800-\u082d\u0840-\u085b\u08a0\u08a2-\u08ac\u08e4-\u08fe\u0900-\u0963\u0966-\u096f\u0971-\u0977\u0979-\u097f\u0981-\u0983\u0985-\u098c\u098f\u0990\u0993-\u09a8\u09aa-\u09b0\u09b2\u09b6-\u09b9\u09bc-\u09c4\u09c7\u09c8\u09cb-\u09ce\u09d7\u09dc\u09dd\u09df-\u09e3\u09e6-\u09f1\u0a01-\u0a03\u0a05-\u0a0a\u0a0f\u0a10\u0a13-\u0a28\u0a2a-\u0a30\u0a32\u0a33\u0a35\u0a36\u0a38\u0a39\u0a3c\u0a3e-\u0a42\u0a47\u0a48\u0a4b-\u0a4d\u0a51\u0a59-\u0a5c\u0a5e\u0a66-\u0a75\u0a81-\u0a83\u0a85-\u0a8d\u0a8f-\u0a91\u0a93-\u0aa8\u0aaa-\u0ab0\u0ab2\u0ab3\u0ab5-\u0ab9\u0abc-\u0ac5\u0ac7-\u0ac9\u0acb-\u0acd\u0ad0\u0ae0-\u0ae3\u0ae6-\u0aef\u0b01-\u0b03\u0b05-\u0b0c\u0b0f\u0b10\u0b13-\u0b28\u0b2a-\u0b30\u0b32\u0b33\u0b35-\u0b39\u0b3c-\u0b44\u0b47\u0b48\u0b4b-\u0b4d\u0b56\u0b57\u0b5c\u0b5d\u0b5f-\u0b63\u0b66-\u0b6f\u0b71\u0b82\u0b83\u0b85-\u0b8a\u0b8e-\u0b90\u0b92-\u0b95\u0b99\u0b9a\u0b9c\u0b9e\u0b9f\u0ba3\u0ba4\u0ba8-\u0baa\u0bae-\u0bb9\u0bbe-\u0bc2\u0bc6-\u0bc8\u0bca-\u0bcd\u0bd0\u0bd7\u0be6-\u0bef\u0c01-\u0c03\u0c05-\u0c0c\u0c0e-\u0c10\u0c12-\u0c28\u0c2a-\u0c33\u0c35-\u0c39\u0c3d-\u0c44\u0c46-\u0c48\u0c4a-\u0c4d\u0c55\u0c56\u0c58\u0c59\u0c60-\u0c63\u0c66-\u0c6f\u0c82\u0c83\u0c85-\u0c8c\u0c8e-\u0c90\u0c92-\u0ca8\u0caa-\u0cb3\u0cb5-\u0cb9\u0cbc-\u0cc4\u0cc6-\u0cc8\u0cca-\u0ccd\u0cd5\u0cd6\u0cde\u0ce0-\u0ce3\u0ce6-\u0cef\u0cf1\u0cf2\u0d02\u0d03\u0d05-\u0d0c\u0d0e-\u0d10\u0d12-\u0d3a\u0d3d-\u0d44\u0d46-\u0d48\u0d4a-\u0d4e\u0d57\u0d60-\u0d63\u0d66-\u0d6f\u0d7a-\u0d7f\u0d82\u0d83\u0d85-\u0d96\u0d9a-\u0db1\u0db3-\u0dbb\u0dbd\u0dc0-\u0dc6\u0dca\u0dcf-\u0dd4\u0dd6\u0dd8-\u0ddf\u0df2\u0df3\u0e01-\u0e3a\u0e40-\u0e4e\u0e50-\u0e59\u0e81\u0e82\u0e84\u0e87\u0e88\u0e8a\u0e8d\u0e94-\u0e97\u0e99-\u0e9f\u0ea1-\u0ea3\u0ea5\u0ea7\u0eaa\u0eab\u0ead-\u0eb9\u0ebb-\u0ebd\u0ec0-\u0ec4\u0ec6\u0ec8-\u0ecd\u0ed0-\u0ed9\u0edc-\u0edf\u0f00\u0f18\u0f19\u0f20-\u0f29\u0f35\u0f37\u0f39\u0f3e-\u0f47\u0f49-\u0f6c\u0f71-\u0f84\u0f86-\u0f97\u0f99-\u0fbc\u0fc6\u1000-\u1049\u1050-\u109d\u10a0-\u10c5\u10c7\u10cd\u10d0-\u10fa\u10fc-\u1248\u124a-\u124d\u1250-\u1256\u1258\u125a-\u125d\u1260-\u1288\u128a-\u128d\u1290-\u12b0\u12b2-\u12b5\u12b8-\u12be\u12c0\u12c2-\u12c5\u12c8-\u12d6\u12d8-\u1310\u1312-\u1315\u1318-\u135a\u135d-\u135f\u1380-\u138f\u13a0-\u13f4\u1401-\u166c\u166f-\u167f\u1681-\u169a\u16a0-\u16ea\u16ee-\u16f0\u1700-\u170c\u170e-\u1714\u1720-\u1734\u1740-\u1753\u1760-\u176c\u176e-\u1770\u1772\u1773\u1780-\u17d3\u17d7\u17dc\u17dd\u17e0-\u17e9\u180b-\u180d\u1810-\u1819\u1820-\u1877\u1880-\u18aa\u18b0-\u18f5\u1900-\u191c\u1920-\u192b\u1930-\u193b\u1946-\u196d\u1970-\u1974\u1980-\u19ab\u19b0-\u19c9\u19d0-\u19d9\u1a00-\u1a1b\u1a20-\u1a5e\u1a60-\u1a7c\u1a7f-\u1a89\u1a90-\u1a99\u1aa7\u1b00-\u1b4b\u1b50-\u1b59\u1b6b-\u1b73\u1b80-\u1bf3\u1c00-\u1c37\u1c40-\u1c49\u1c4d-\u1c7d\u1cd0-\u1cd2\u1cd4-\u1cf6\u1d00-\u1de6\u1dfc-\u1f15\u1f18-\u1f1d\u1f20-\u1f45\u1f48-\u1f4d\u1f50-\u1f57\u1f59\u1f5b\u1f5d\u1f5f-\u1f7d\u1f80-\u1fb4\u1fb6-\u1fbc\u1fbe\u1fc2-\u1fc4\u1fc6-\u1fcc\u1fd0-\u1fd3\u1fd6-\u1fdb\u1fe0-\u1fec\u1ff2-\u1ff4\u1ff6-\u1ffc\u200c\u200d\u203f\u2040\u2054\u2071\u207f\u2090-\u209c\u20d0-\u20dc\u20e1\u20e5-\u20f0\u2102\u2107\u210a-\u2113\u2115\u2119-\u211d\u2124\u2126\u2128\u212a-\u212d\u212f-\u2139\u213c-\u213f\u2145-\u2149\u214e\u2160-\u2188\u2c00-\u2c2e\u2c30-\u2c5e\u2c60-\u2ce4\u2ceb-\u2cf3\u2d00-\u2d25\u2d27\u2d2d\u2d30-\u2d67\u2d6f\u2d7f-\u2d96\u2da0-\u2da6\u2da8-\u2dae\u2db0-\u2db6\u2db8-\u2dbe\u2dc0-\u2dc6\u2dc8-\u2dce\u2dd0-\u2dd6\u2dd8-\u2dde\u2de0-\u2dff\u2e2f\u3005-\u3007\u3021-\u302f\u3031-\u3035\u3038-\u303c\u3041-\u3096\u3099\u309a\u309d-\u309f\u30a1-\u30fa\u30fc-\u30ff\u3105-\u312d\u3131-\u318e\u31a0-\u31ba\u31f0-\u31ff\u3400-\u4db5\u4e00-\u9fcc\ua000-\ua48c\ua4d0-\ua4fd\ua500-\ua60c\ua610-\ua62b\ua640-\ua66f\ua674-\ua67d\ua67f-\ua697\ua69f-\ua6f1\ua717-\ua71f\ua722-\ua788\ua78b-\ua78e\ua790-\ua793\ua7a0-\ua7aa\ua7f8-\ua827\ua840-\ua873\ua880-\ua8c4\ua8d0-\ua8d9\ua8e0-\ua8f7\ua8fb\ua900-\ua92d\ua930-\ua953\ua960-\ua97c\ua980-\ua9c0\ua9cf-\ua9d9\uaa00-\uaa36\uaa40-\uaa4d\uaa50-\uaa59\uaa60-\uaa76\uaa7a\uaa7b\uaa80-\uaac2\uaadb-\uaadd\uaae0-\uaaef\uaaf2-\uaaf6\uab01-\uab06\uab09-\uab0e\uab11-\uab16\uab20-\uab26\uab28-\uab2e\uabc0-\uabea\uabec\uabed\uabf0-\uabf9\uac00-\ud7a3\ud7b0-\ud7c6\ud7cb-\ud7fb\uf900-\ufa6d\ufa70-\ufad9\ufb00-\ufb06\ufb13-\ufb17\ufb1d-\ufb28\ufb2a-\ufb36\ufb38-\ufb3c\ufb3e\ufb40\ufb41\ufb43\ufb44\ufb46-\ufbb1\ufbd3-\ufd3d\ufd50-\ufd8f\ufd92-\ufdc7\ufdf0-\ufdfb\ufe00-\ufe0f\ufe20-\ufe26\ufe33\ufe34\ufe4d-\ufe4f\ufe70-\ufe74\ufe76-\ufefc\uff10-\uff19\uff21-\uff3a\uff3f\uff41-\uff5a\uff66-\uffbe\uffc2-\uffc7\uffca-\uffcf\uffd2-\uffd7\uffda-\uffdc]",nil,'n')

        # Ensure the condition is true, otherwise throw an error.
        # This is only to have a better contract semantic, i[:e]. another safety net
        # to catch a logic error. The condition shall be fulfilled in normal case.
        # Do NOT use this to enforce a certain condition on any user input.

        def assert(condition, message)
            if (!condition) 
                raise SyntaxError.new 'ASSERT: ' + message
            end
        end

        def sliceSource(from, to) 
            return @source[from...to]
        end

        def isDecimalDigit(ch) 
            return ch && '0123456789'.include?(ch)
        end

        def isHexDigit(ch)
            return ch && '0123456789abcdefABCDEF'.include?(ch)
        end

        def isOctalDigit(ch)
            return ch && '01234567'.include?(ch)
        end


        # 7.2 White Space

        def isWhiteSpace(ch) 
            return false unless ch
            return (ch == " ") || (ch == "\u0009") || (ch == "\u000B") ||
                (ch == "\u000C") || (ch == "\u00A0") ||
                (ch.ord() >= 0x1680 &&
                "\u1680\u180E\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200A\u202F\u205F\u3000\uFEFF".include?(ch))
        end

        # 7.3 Line Terminators

        def isLineTerminator(ch)
            ["\n", "\r" ,"\u2028", "\u2029"].include?(ch)
        end

        # 7.6 Identifier Names and Identifiers

        def isIdentifierStart(ch) 
            return (ch == "$") || (ch == "_") || (ch == "\\") ||
                (ch >= "a" && ch <= "z") || (ch >= "A" && ch <= "Z") ||
             false#  ((ch.ord() >= 0x80) && NonAsciiIdentifierStart.match?(ch))
        end

        def isIdentifierPart(ch) 
            return (ch == "$") || (ch == "_") || (ch == "\\") ||
                (ch >= "a" && ch <= "z") || (ch >= "A" && ch <= "Z") ||
                ((ch >= "0") && (ch <= "9")) ||
              false#  ((ch.ord() >= 0x80) && NonAsciiIdentifierPart.match?(ch))
        end

        # 7.6.1.2 Future Reserved Words

        def isFutureReservedWord(id)
            %w(class enum export extends import super).include? id
        end

        def isStrictModeReservedWord(id)
            %w(implements interface package private protected public static yield let).include? id
        end

        def isRestrictedWord(id) 
            return id == 'eval' || id == 'arguments'
        end

        # 7.6.1.1 Keywords

        def isKeyword(id)
            keyword = false
            case id.length
            when 2
                keyword = (id == 'if') || (id == 'in') || (id == 'do')
            when 3
                keyword = (id == 'var') || (id == 'for') || (id == 'new') || (id == 'try')
            when 4
                keyword = (id == 'this') || (id == 'else') || (id == 'case') || (id == 'void') || (id == 'with')
            when 5
                keyword = (id == 'while') || (id == 'break') || (id == 'catch') || (id == 'throw')
            when 6
                keyword = (id == 'return') || (id == 'typeof') || (id == 'delete') || (id == 'switch')
            when 7
                keyword = (id == 'default') || (id == 'finally')
            when 8
                keyword = (id == 'function') || (id == 'continue') || (id == 'debugger')
            when 10
                keyword = (id == 'instanceof')
            end

            return true if keyword

            case id
            # Future reserved words.
            # 'const' is specialized as Keyword in V8.
            when 'const'
                return true
            # For compatiblity to SpiderMonkey and ES[:next]
            when 'yield','let'
                return true
            end

            if (@strict && isStrictModeReservedWord(id)) 
                return true
            end

            return isFutureReservedWord(id)
        end

        def curCharAndMoveNext
            c = @source[@index]
            @index += 1
            c
        end

        # 7.4 Comments

        def skipComment()

            blockComment = false
            lineComment = false

            while (@index < @length) do
                ch = @source[@index]

                if (lineComment) 
                    ch = curCharAndMoveNext
                    if (isLineTerminator(ch)) 
                        lineComment = false
                        if (ch == "\r" && @source[@index] == "\n")
                            @index += 1
                        end
                        @lineNumber += 1
                        @lineStart = @index
                    end
                elsif (blockComment)
                    if (isLineTerminator(ch))
                        if (ch == "\r" && @source[@index + 1] == "\n") 
                            @index += 1
                        end
                        @lineNumber += 1
                        @index += 1
                        @lineStart = @index
                        if (@index >= @length)
                            throwError(nil, Messages[:UnexpectedToken], 'ILLEGAL')
                        end
                    else
                        ch = curCharAndMoveNext
                        if (@index >= @length) 
                            throwError(nil, Messages[:UnexpectedToken], 'ILLEGAL')
                        end
                        if (ch == '*') 
                            ch = @source[@index]
                            if (ch == '/')
                                @index += 1
                                blockComment = false
                            end
                        end
                    end
                elsif (ch == '/') 
                    ch = @source[@index + 1]
                    if (ch == '/') 
                        @index += 2
                        lineComment = true
                    elsif (ch == '*') 
                        @index += 2
                        blockComment = true
                        if (@index >= @length) 
                            throwError(nil, Messages[:UnexpectedToken], 'ILLEGAL')
                        end
                    else
                        break
                    end
                elsif (isWhiteSpace(ch)) 
                    @index += 1
                elsif (isLineTerminator(ch)) 
                    @index += 1
                    if (ch == "\r" && @source[@index] == "\n") 
                        @index += 1
                    end
                    @lineNumber += 1
                    @lineStart = @index
                else
                    break
                end
            end
        end

        def scanHexEscape(prefix) 
            code = 0

            len = (prefix == 'u') ? 4 : 2
            len.times do |i|
                if (@index < @length && isHexDigit(@source[@index])) 
                    ch = curCharAndMoveNext
                    code = code * 16 + '0123456789abcdef'.index(ch.downcase())
                else
                    return nil
                end
            end
            return [code].pack('U*')
        end

        def scanIdentifier()

            ch = @source[@index]
            if (!isIdentifierStart(ch)) 
                return
            end

            start = @index
            if (ch == "\\") 
                @index += 1
                if (@source[@index] != 'u') 
                    return
                end
                @index += 1
                restore = @index
                ch = scanHexEscape('u')
                if (ch) 
                    if (ch == "\\" || !isIdentifierStart(ch)) 
                        return
                    end
                    id = ch
                else
                    @index = restore
                    id = 'u'
                end
            else
                id = curCharAndMoveNext
            end

            while (@index < @length) do
                ch = @source[@index]
                if (!isIdentifierPart(ch)) 
                    break
                end
                if (ch == "\\") 
                    @index += 1
                    if (@source[@index] != 'u') 
                        return
                    end
                    @index += 1
                    restore = @index
                    ch = scanHexEscape('u')
                    if (ch) 
                        if (ch == "\\" || !isIdentifierPart(ch)) 
                            return
                        end
                        id += ch
                    else
                        @index = restore
                        id += 'u'
                    end
                else
                    id += curCharAndMoveNext
                end
            end

            # There is no keyword or literal with only one character.
            # Thus, it must be an identifier.
            if (id.length == 1) 
                return {
                    type: Token[:Identifier],
                    value: id,
                    lineNumber: @lineNumber,
                    lineStart: @lineStart,
                    range: [start, @index]
                }
            end

            if (isKeyword(id)) 
                return {
                    type: Token[:Keyword],
                    value: id,
                    lineNumber: @lineNumber,
                    lineStart: @lineStart,
                    range: [start, @index]
                }
            end


            # 7.8.1 Null Literals

            if (id == 'null') 
                return {
                    type: Token[:NullLiteral],
                    value: id,
                    lineNumber: @lineNumber,
                    lineStart: @lineStart,
                    range: [start, @index]
                }
            end

            # 7.8.2 Boolean Literals

            if (id == 'true' || id == 'false') 
                return {
                    type: Token[:BooleanLiteral],
                    value: id,
                    lineNumber: @lineNumber,
                    lineStart: @lineStart,
                    range: [start, @index]
                }
            end

            return {
                type: Token[:Identifier],
                value: id,
                lineNumber: @lineNumber,
                lineStart: @lineStart,
                range: [start, @index]
            }
        end

        # 7.7 Punctuators

        def scanPunctuator() 
            start = @index
            ch1 = @source[@index]

            # Check for most common single-character punctuators.

            if (ch1 == ';' || ch1 == '{' || ch1 == '}') 
                @index += 1
                return {
                    type: Token[:Punctuator],
                    value: ch1,
                    lineNumber: @lineNumber,
                    lineStart: @lineStart,
                    range: [start, @index]
                }
            end

            if (ch1 == ',' || ch1 == '(' || ch1 == ')') 
                @index += 1
                return {
                    type: Token[:Punctuator],
                    value: ch1,
                    lineNumber: @lineNumber,
                    lineStart: @lineStart,
                    range: [start, @index]
                }
            end

            # Dot (.) can also start a floating-point number, hence the need
            # to check the next character.

            ch2 = @source[@index + 1]
            if (ch1 == '.' && !isDecimalDigit(ch2)) 
                return {
                    type: Token[:Punctuator],
                    value: curCharAndMoveNext,
                    lineNumber: @lineNumber,
                    lineStart: @lineStart,
                    range: [start, @index]
                }
            end

            # Peek more characters.

            ch3 = @source[@index + 2]
            ch4 = @source[@index + 3]

            # 4-character punctuator: >>>=

            if (ch1 == '>' && ch2 == '>' && ch3 == '>') 
                if (ch4 == '=') 
                    @index += 4
                    return {
                        type: Token[:Punctuator],
                        value: '>>>=',
                        lineNumber: @lineNumber,
                        lineStart: @lineStart,
                        range: [start, @index]
                    }
                end
            end

            # 3-character punctuators: == != >>> <<= >>=

            if (ch1 == '=' && ch2 == '=' && ch3 == '=') 
                @index += 3
                return {
                    type: Token[:Punctuator],
                    value: '===',
                    lineNumber: @lineNumber,
                    lineStart: @lineStart,
                    range: [start, @index]
                }
            end

            if (ch1 == '!' && ch2 == '=' && ch3 == '=') 
                @index += 3
                return {
                    type: Token[:Punctuator],
                    value: '!==',
                    lineNumber: @lineNumber,
                    lineStart: @lineStart,
                    range: [start, @index]
                }
            end

            if (ch1 == '>' && ch2 == '>' && ch3 == '>') 
                @index += 3
                return {
                    type: Token[:Punctuator],
                    value: '>>>',
                    lineNumber: @lineNumber,
                    lineStart: @lineStart,
                    range: [start, @index]
                }
            end

            if (ch1 == '<' && ch2 == '<' && ch3 == '=') 
                @index += 3
                return {
                    type: Token[:Punctuator],
                    value: '<<=',
                    lineNumber: @lineNumber,
                    lineStart: @lineStart,
                    range: [start, @index]
                }
            end

            if (ch1 == '>' && ch2 == '>' && ch3 == '=') 
                @index += 3
                return {
                    type: Token[:Punctuator],
                    value: '>>=',
                    lineNumber: @lineNumber,
                    lineStart: @lineStart,
                    range: [start, @index]
                }
            end

            # 2-character punctuators: <= >= == != ++ -- << >> && ||
            # += -= *= %= &= |= ^= /=

            if (ch2 == '=') 
                if ('<>=!+-*%&|^/'.include?(ch1)) 
                    @index += 2
                    return {
                        type: Token[:Punctuator],
                        value: ch1 + ch2,
                        lineNumber: @lineNumber,
                        lineStart: @lineStart,
                        range: [start, @index]
                    }
                end
            end

            if (ch1 == ch2 && ('+-<>&|'.include?(ch1))) 
                if ('+-<>&|'.include?(ch2)) 
                    @index += 2
                    return {
                        type: Token[:Punctuator],
                        value: ch1 + ch2,
                        lineNumber: @lineNumber,
                        lineStart: @lineStart,
                        range: [start, @index]
                    }
                end
            end

            # The remaining 1-character punctuators.

            if ('[]<>+-*%&|^!~?:=/'.include?(ch1)) 
                return {
                    type: Token[:Punctuator],
                    value: curCharAndMoveNext,
                    lineNumber: @lineNumber,
                    lineStart: @lineStart,
                    range: [start, @index]
                }
            end
        end

        # 7.8.3 Numeric Literals

        def scanNumericLiteral()

            ch = @source[@index]
            assert(isDecimalDigit(ch) || (ch == '.'),
                'Numeric literal must start with a decimal digit or a decimal point')

            start = @index
            number = ''
            if (ch != '.') 
                number = curCharAndMoveNext
                ch = @source[@index]

                # Hex number starts with '0x'.
                # Octal number starts with '0'.
                if (number == '0') 
                    if (ch == 'x' || ch == 'X') 
                        number += curCharAndMoveNext
                        while (@index < @length) 
                            ch = @source[@index]
                            if (!isHexDigit(ch)) 
                                break
                            end
                            number += curCharAndMoveNext
                        end

                        if (number.length <= 2) 
                            # only 0x
                            throwError(nil, Messages[:UnexpectedToken], 'ILLEGAL')
                        end

                        if (@index < @length) 
                            ch = @source[@index]
                            if (isIdentifierStart(ch)) 
                                throwError(nil, Messages[:UnexpectedToken], 'ILLEGAL')
                            end
                        end
                        return {
                            type: Token[:NumericLiteral],
                            value: number.to_i(16),
                            lineNumber: @lineNumber,
                            lineStart: @lineStart,
                            range: [start, @index]
                        }
                    elsif (isOctalDigit(ch)) 
                        number += curCharAndMoveNext
                        while (@index < @length) 
                            ch = @source[@index]
                            if (!isOctalDigit(ch)) 
                                break
                            end
                            number += curCharAndMoveNext
                        end

                        if (@index < @length) 
                            ch = @source[@index]
                            if (isIdentifierStart(ch) || isDecimalDigit(ch)) 
                                throwError(nil, Messages[:UnexpectedToken], 'ILLEGAL')
                            end
                        end
                        return {
                            type: Token[:NumericLiteral],
                            value: number.to_i(8),
                            octal: true,
                            lineNumber: @lineNumber,
                            lineStart: @lineStart,
                            range: [start, @index]
                        }
                    end

                    # decimal number starts with '0' such as '09' is illegal.
                    if (isDecimalDigit(ch)) 
                        throwError(nil, Messages[:UnexpectedToken], 'ILLEGAL')
                    end
                end

                while (@index < @length) 
                    ch = @source[@index]
                    if (!isDecimalDigit(ch)) 
                        break
                    end
                    number += curCharAndMoveNext
                end
            end

            if (ch == '.') 
                number += curCharAndMoveNext
                while (@index < @length) 
                    ch = @source[@index]
                    if (!isDecimalDigit(ch)) 
                        break
                    end
                    number += curCharAndMoveNext
                end
            end

            if (ch == 'e' || ch == 'E') 
                number += curCharAndMoveNext

                ch = @source[@index]
                if (ch == '+' || ch == '-') 
                    number += curCharAndMoveNext
                end

                ch = @source[@index]
                if (isDecimalDigit(ch)) 
                    number += curCharAndMoveNext
                    while (@index < @length) 
                        ch = @source[@index]
                        if (!isDecimalDigit(ch)) 
                            break
                        end
                        number += curCharAndMoveNext
                    end
                else
                    throwError(nil, Messages[:UnexpectedToken], 'ILLEGAL')
                end
            end

            if (@index < @length) 
                ch = @source[@index]
                if (isIdentifierStart(ch)) 
                    throwError(nil, Messages[:UnexpectedToken], 'ILLEGAL')
                end
            end

            return {
                type: Token[:NumericLiteral],
                value: number.to_f,
                lineNumber: @lineNumber,
                lineStart: @lineStart,
                range: [start, @index]
            }
        end

        # 7.8.4 String Literals

        def scanStringLiteral() 
            str = ''
            octal = false

            quote = @source[@index]
            assert((quote == "'" || quote == '"'),
                'String literal must starts with a quote')

            start = @index
            @index += 1

            while (@index < @length) 
                ch = curCharAndMoveNext

                if (ch == quote) 
                    quote = ''
                    break
                elsif (ch == "\\") 
                    ch = curCharAndMoveNext
                    if (!isLineTerminator(ch)) 
                        case ch
                        when 'n'
                            str += "\n"
                        when 'r'
                            str += "\r"
                        when 't'
                            str += "\t"
                        when 'u','x'
                            restore = @index
                            unescaped = scanHexEscape(ch)
                            if (unescaped) 
                                str += unescaped
                            else
                                @index = restore
                                str += ch
                            end
                        when 'b'
                            str += "\b"
                        when 'f'
                            str += "\f"
                        when 'v'
                            str += "\x0B"
                        else
                            if (isOctalDigit(ch)) 
                                code = '01234567'.index(ch)

                                # \0 is not octal escape sequence
                                if (code != 0) 
                                    octal = true
                                end

                                if (@index < @length && isOctalDigit(@source[@index])) 
                                    octal = true
                                    code = code * 8 + '01234567'.index(curCharAndMoveNext)

                                    # 3 digits are only allowed when string starts
                                    # with 0, 1, 2, 3
                                    if ('0123'.include?(ch) &&
                                            @index < @length &&
                                            isOctalDigit(@source[@index])) then
                                        code = code * 8 + '01234567'.index(curCharAndMoveNext)
                                    end
                                end
                                str += [code].pack('U*')
                            else
                                str += ch || ''
                            end
                        end
                    else
                        @lineNumber += 1
                        if (ch ==  "\r" && @source[@index] == "\n") 
                            @index += 1
                        end
                    end
                elsif (isLineTerminator(ch)) 
                    break
                else
                    str += ch
                end
            end

            if (quote != '') 
                throwError(nil, Messages[:UnexpectedToken], 'ILLEGAL')
            end

            return {
                type: Token[:StringLiteral],
                value: str,
                octal: octal,
                lineNumber: @lineNumber,
                lineStart: @lineStart,
                range: [start, @index]
            }
        end

        def scanRegExp() 
            classMarker = false
            terminated = false

            @buffer = nil
            skipComment()

            start = @index
            ch = @source[@index]
            assert(ch == '/', 'Regular expression literal must start with a slash')
            str = curCharAndMoveNext

            while (@index < @length) 
                ch = curCharAndMoveNext
                str += ch
                if (ch == "\\") 
                    ch = curCharAndMoveNext
                    # ECMA-262 7.8.5
                    if (isLineTerminator(ch)) 
                        throwError(nil, Messages[:UnterminatedRegExp])
                    end
                    str += ch
                elsif (classMarker) 
                    if (ch == ']') 
                        classMarker = false
                    end
                else
                    if (ch == '/') 
                        terminated = true
                        break
                    elsif (ch == '[') 
                        classMarker = true
                    elsif (isLineTerminator(ch)) 
                        throwError(nil, Messages[:UnterminatedRegExp])
                    end
                end
            end

            if (!terminated) 
                throwError(nil, Messages[:UnterminatedRegExp])
            end

            # Exclude leading and trailing slash.
            pattern = str[1, str.length - 2]

            flags = ''
            while (@index < @length) 
                ch = @source[@index]
                if (!isIdentifierPart(ch)) 
                    break
                end

                @index += 1
                if (ch == "\\" && @index < @length) 
                    ch = @source[@index]
                    if (ch == 'u') 
                        @index += 1
                        restore = @index
                        ch = scanHexEscape('u')
                        if (ch)
                            flags += ch
                            str += "\\u"
                            while (restore < @index)
                                str += @source[restore]
                                restore += 1
                            end
                        else
                            @index = restore
                            flags += 'u'
                            str += "\\u"
                        end
                    else
                        str += "\\"
                    end
                else
                    flags += ch
                    str += ch
                end
            end

            return {
                literal: str,
                value: sliceSource(start,@index),
                regexp: {
                    pattern: str,
                    flags: flags
                },
                range: [start, @index]
            }
        end

        def isIdentifierName(token) 
            return token[:type] == Token[:Identifier] ||
                token[:type] == Token[:Keyword] ||
                token[:type] == Token[:BooleanLiteral] ||
                token[:type] == Token[:NullLiteral]
        end

        def advance()
            skipComment()

            if (@index >= @length) 
                return {
                    type: Token[:EOF],
                    lineNumber: @lineNumber,
                    lineStart: @lineStart,
                    range: [@index, @index]
                }
            end

            token = scanPunctuator()
            if token != nil
                return token
            end

            ch = @source[@index]

            if (ch == "'" || ch == '"') 
                return scanStringLiteral()
            end

            if (ch == '.' || isDecimalDigit(ch)) 
                return scanNumericLiteral()
            end

            token = scanIdentifier()
            if token != nil
                return token
            end

            throwError(nil, Messages[:UnexpectedToken], 'ILLEGAL')
        end

        def lex()

            if (@buffer) 
                @index = @buffer[:range][1]
                @lineNumber = @buffer[:lineNumber]
                @lineStart = @buffer[:lineStart]
                token = @buffer
                @buffer = nil
                return token
            end

            @buffer = nil
            return advance()
        end

        def lookahead() 

            if (@buffer != nil) 
                return @buffer
            end

            pos = @index
            line = @lineNumber
            start = @lineStart
            @buffer = advance()
            @index = pos
            @lineNumber = line
            @lineStart = start

            return @buffer
        end

        # Return true if there is a line terminator before the next token.

        def peekLineTerminator() 
            pos = @index
            line = @lineNumber
            start = @lineStart
            skipComment()
            found = @lineNumber != line
            @index = pos
            @lineNumber = line
            @lineStart = start
            return found
        end

        # Throw an exception

        def throwError(token, messageFormat,*args)
            msg = messageFormat.gsub(/%(\d)/) do |i|
                args[i.to_i] || ''
            end

            if (token != nil) 
               # raise "Line #{token[:lineNumber]} at #{(token[:range][0] - token[:lineNumber] + 1)} : #{msg}"
                raise SyntaxError.new "Error: Line #{token[:lineNumber]}: #{msg}"
            else
              #  raise "Line #{@lineNumber} at #{@index - @lineStart + 1} : #{msg}"
                raise SyntaxError.new "Error: Line #{@lineNumber}: #{msg}"
            end
        end

        def throwErrorTolerant(token, messageFormat,*args)
            throwError(token,messageFormat,*args)
        end

        # Throw an exception because of the token.

        def throwUnexpected(token) 
            if (token[:type] == Token[:EOF]) 
                throwError(token, Messages[:UnexpectedEOS])
            end

            if (token[:type] == Token[:NumericLiteral]) 
                throwError(token, Messages[:UnexpectedNumber])
            end

            if (token[:type] == Token[:StringLiteral]) 
                throwError(token, Messages[:UnexpectedString])
            end

            if (token[:type] == Token[:Identifier]) 
                throwError(token, Messages[:UnexpectedIdentifier])
            end

            if (token[:type] == Token[:Keyword]) 
                if (isFutureReservedWord(token[:value])) 
                    throwError(token, Messages[:UnexpectedReserved])
                elsif (@strict && isStrictModeReservedWord(token[:value])) 
                    throwErrorTolerant(token, Messages[:StrictReservedWord])
                    return
                end
                throwError(token, Messages[:UnexpectedToken], token[:value])
            end

            # BooleanLiteral, NullLiteral, or Punctuator.
            throwError(token, Messages[:UnexpectedToken], token[:value])
        end

        # Expect the next token to match the specified punctuator.
        # If not, an exception will be thrown.

        def expect(value) 
            token = lex()
            if (token[:type] != Token[:Punctuator] || token[:value] != value) 
                throwUnexpected(token)
            end
        end

        # Expect the next token to match the specified keyword.
        # If not, an exception will be thrown.

        def expectKeyword(keyword) 
            token = lex()
            if (token[:type] != Token[:Keyword] || token[:value] != keyword) 
                throwUnexpected(token)
            end
        end

        # Return true if the next token matches the specified punctuator.

        def match(value) 
            token = lookahead()
            return token[:type] == Token[:Punctuator] && token[:value] == value
        end

        # Return true if the next token matches the specified keyword

        def matchKeyword(keyword) 
            token = lookahead()
            return token[:type] == Token[:Keyword] && token[:value] == keyword
        end

        # Return true if the next token is an assignment operator

        def matchAssign() 
            token = lookahead()
            op = token[:value]

            if (token[:type] != Token[:Punctuator]) 
                return false
            end
            return op == '=' ||
                op == '*=' ||
                op == '/=' ||
                op == '%=' ||
                op == '+=' ||
                op == '-=' ||
                op == '<<=' ||
                op == '>>=' ||
                op == '>>>=' ||
                op == '&=' ||
                op == '^=' ||
                op == '|='
        end

        def consumeSemicolon() 
            # Catch the very common case first.
            if (@source[@index] == ';') 
                lex()
                return
            end

            line = @lineNumber
            skipComment()
            if (@lineNumber != line) 
                return
            end

            if (match(';')) 
                lex()
                return
            end

            token = lookahead()
            if (token[:type] != Token[:EOF] && !match('}')) 
                throwUnexpected(token)
            end
        end

        # Return true if provided expression is LeftHandSideExpression

        def isLeftHandSide(expr) 
            return expr[:type] == Syntax[:Identifier] || expr[:type] == Syntax[:MemberExpression]
        end

        # 11.1.4 Array Initialiser

        def parseArrayInitialiser() 
            elements = []

            expect('[')

            while (!match(']')) 
                if (match(',')) 
                    lex()
                    elements.push(nil)
                else
                    elements.push(parseAssignmentExpression())

                    if (!match(']')) 
                        expect(',')
                    end
                end
            end

            expect(']')

            return {
                type: Syntax[:ArrayExpression],
                elements: elements
            }
        end

        # 11.1.5 Object Initialiser

        def parsePropertydef(param, first = nil)

            previousStrict = @strict
            body = parseFunctionSourceElements()
            if (first && @strict && isRestrictedWord(param[0][:name])) 
                throwErrorTolerant(first, Messages[:StrictParamName])
            end
            @strict = previousStrict

            return {
                type: Syntax[:FunctionExpression],
                id: nil,
                params: param,
                defaults: [],
                body: body,
                rest: nil,
                generator: false,
                expression: false
            }
        end

        def parseObjectPropertyKey() 
            token = lex()

            # Note: This def is called only from parseObjectProperty(), where
            # EOF and Punctuator tokens are already filtered out.

            if (token[:type] == Token[:StringLiteral] || token[:type] == Token[:NumericLiteral]) 
                if (@strict && token[:octal]) 
                    throwErrorTolerant(token, Messages[:StrictOctalLiteral])
                end
                return createLiteral(token)
            end

            return {
                type: Syntax[:Identifier],
                name: token[:value]
            }
        end

        def parseObjectProperty()

            token = lookahead()

            if (token[:type] == Token[:Identifier]) 

                id = parseObjectPropertyKey()

                # Property Assignment: Getter and Setter.

                if (token[:value] == 'get' && !match(':')) 
                    key = parseObjectPropertyKey()
                    expect('(')
                    expect(')')
                    return {
                        type: Syntax[:Property],
                        key: key,
                        value: parsePropertydef([]),
                        kind: 'get'
                    }
                elsif (token[:value] == 'set' && !match(':')) 
                    key = parseObjectPropertyKey()
                    expect('(')
                    token = lookahead()
                    if (token[:type] != Token[:Identifier]) 
                        expect(')')
                        throwErrorTolerant(token, Messages[:UnexpectedToken], token[:value])
                        return {
                            type: Syntax[:Property],
                            key: key,
                            value: parsePropertydef([]),
                            kind: 'set'
                        }
                    else
                        param = [ parseVariableIdentifier() ]
                        expect(')')
                        return {
                            type: Syntax[:Property],
                            key: key,
                            value: parsePropertydef(param, token),
                            kind: 'set'
                        }
                    end
                else
                    expect(':')
                    return {
                        type: Syntax[:Property],
                        key: id,
                        value: parseAssignmentExpression(),
                        kind: 'init'
                    }
                end
            elsif (token[:type] == Token[:EOF] || token[:type] == Token[:Punctuator]) 
                throwUnexpected(token)
            else
                key = parseObjectPropertyKey()
                expect(':')
                return {
                    type: Syntax[:Property],
                    key: key,
                    value: parseAssignmentExpression(),
                    kind: 'init'
                }
            end
        end

        def parseObjectInitialiser() 
            properties = []
            map = {}

            expect('{')

            while (!match('}')) 
                property = parseObjectProperty()

                if (property[:key][:type] == Syntax[:Identifier]) 
                    name = property[:key][:name]
                else
                    name = (property[:key][:value]).to_s
                end
                kind = (property[:kind] == 'init') ? PropertyKind[:Data] : (property[:kind] == 'get') ? PropertyKind[:Get] : PropertyKind[:Set]
                if (false)
                    if (map[name] == PropertyKind[:Data]) 
                        if (@strict && kind == PropertyKind[:Data]) 
                            throwErrorTolerant(nil, Messages[:StrictDuplicateProperty])
                        elsif (kind != PropertyKind[:Data]) 
                            throwErrorTolerant(nil, Messages[:AccessorDataProperty])
                        end
                    else
                        if (kind == PropertyKind[:Data]) 
                            throwErrorTolerant(nil, Messages[:AccessorDataProperty])
                        elsif (map[name] & kind) 
                            throwErrorTolerant(nil, Messages[:AccessorGetSet])
                        end
                    end
                    map[name] |= kind
                else
                    map[name] = kind
                end

                properties.push(property)

                if (!match('}')) 
                    expect(',')
                end
            end

            expect('}')

            return {
                type: Syntax[:ObjectExpression],
                properties: properties
            }
        end

        # 11.1.6 The Grouping Operator

        def parseGroupExpression() 
            expect('(')

            expr = parseExpression()

            expect(')')

            return expr
        end


        # 11.1 Primary Expressions

        def parsePrimaryExpression() 
            token = lookahead()
            type = token[:type]

            if (type == Token[:Identifier]) 
                return {
                    type: Syntax[:Identifier],
                    name: lex()[:value]
                }
            end

            if (type == Token[:StringLiteral] || type == Token[:NumericLiteral]) 
                if (@strict && token[:octal])
                    throwErrorTolerant(token, Messages[:StrictOctalLiteral])
                end
                return createLiteral(lex())
            end

            if (type == Token[:Keyword]) 
                if (matchKeyword('this')) 
                    lex()
                    return {
                        type: Syntax[:ThisExpression]
                    }
                end

                if (matchKeyword('function')) 
                    return parseFunctionExpression()
                end
            end

            if (type == Token[:BooleanLiteral]) 
                lex()
                token[:value] = (token[:value] == 'true')
                return createLiteral(token)
            end

            if (type == Token[:NullLiteral]) 
                lex()
                token[:value] = nil
                return createLiteral(token)
            end

            if (match('[')) 
                return parseArrayInitialiser()
            end

            if (match('{')) 
                return parseObjectInitialiser()
            end

            if (match('(')) 
                return parseGroupExpression()
            end

            if (match('/') || match('/=')) 
                return createLiteral(scanRegExp())
            end

            return throwUnexpected(lex())
        end

        # 11.2 Left-Hand-Side Expressions

        def parseArguments() 
            args = []

            expect('(')

            if (!match(')')) 
                while (@index < @length) 
                    args.push(parseAssignmentExpression())
                    if (match(')')) 
                        break
                    end
                    expect(',')
                end
            end

            expect(')')

            return args
        end

        def parseNonComputedProperty()
            token = lex()

            if (!isIdentifierName(token)) 
                throwUnexpected(token)
            end

            return {
                type: Syntax[:Identifier],
                name: token[:value]
            }
        end

        def parseNonComputedMember() 
            expect('.')

            return parseNonComputedProperty()
        end

        def parseComputedMember()

            expect('[')

            expr = parseExpression()

            expect(']')

            return expr
        end

        def parseNewExpression() 
            expectKeyword('new')

            expr = {
                type: Syntax[:NewExpression],
                callee: parseLeftHandSideExpression(),
                arguments: []
            }

            if (match('(')) 
                expr[:arguments] = parseArguments()
            end

            return expr
        end

        def parseLeftHandSideExpressionAllowCall() 

            expr = matchKeyword('new') ? parseNewExpression() : parsePrimaryExpression()

            while (match('.') || match('[') || match('(')) 
                if (match('(')) 
                    expr = {
                        type: Syntax[:CallExpression],
                        callee: expr,
                        arguments: parseArguments()
                    }
                elsif (match('[')) 
                    expr = {
                        type: Syntax[:MemberExpression],
                        computed: true,
                        object: expr,
                        property: parseComputedMember()
                    }
                else
                    expr = {
                        type: Syntax[:MemberExpression],
                        computed: false,
                        object: expr,
                        property: parseNonComputedMember()
                    }
                end
            end

            return expr
        end


        def parseLeftHandSideExpression() 

            expr = matchKeyword('new') ? parseNewExpression() : parsePrimaryExpression()

            while (match('.') || match('[')) 
                if (match('[')) 
                    expr = {
                        type: Syntax[:MemberExpression],
                        computed: true,
                        object: expr,
                        property: parseComputedMember()
                    }
                else
                    expr = {
                        type: Syntax[:MemberExpression],
                        computed: false,
                        object: expr,
                        property: parseNonComputedMember()
                    }
                end
            end

            return expr
        end

        # 11.3 Postfix Expressions

        def parsePostfixExpression() 
            expr = parseLeftHandSideExpressionAllowCall()

            token = lookahead()
            if (token[:type] != Token[:Punctuator]) 
                return expr
            end

            if ((match('++') || match('--')) && !peekLineTerminator()) 
                # 11.3.1, 11.3.2
                if (@strict && expr[:type] == Syntax[:Identifier] && isRestrictedWord(expr[:name])) 
                    throwErrorTolerant(nil, Messages[:StrictLHSPostfix])
                end
                if (!isLeftHandSide(expr)) 
                    throwErrorTolerant(nil, Messages[:InvalidLHSInAssignment])
                end

                expr = {
                    type: Syntax[:UpdateExpression],
                    operator: lex()[:value],
                    argument: expr,
                    prefix: false
                }
            end

            return expr
        end

        # 11.4 Unary Operators

        def parseUnaryExpression()

            token = lookahead()
            if (token[:type] != Token[:Punctuator] && token[:type] != Token[:Keyword]) 
                return parsePostfixExpression()
            end

            if (match('++') || match('--')) 
                token = lex()
                expr = parseUnaryExpression()
                # 11.4.4, 11.4.5
                if (@strict && expr[:type] == Syntax[:Identifier] && isRestrictedWord(expr[:name])) 
                    throwErrorTolerant(nil, Messages[:StrictLHSPrefix])
                end

                if (!isLeftHandSide(expr))
                    throwErrorTolerant(nil, Messages[:InvalidLHSInAssignment])
                end

                expr = {
                    type: Syntax[:UpdateExpression],
                    operator: token[:value],
                    argument: expr,
                    prefix: true
                }
                return expr
            end

            if (match('+') || match('-') || match('~') || match('!')) 
                expr = {
                    type: Syntax[:UnaryExpression],
                    operator: lex()[:value],
                    argument: parseUnaryExpression(),
                    prefix: true
                }
                return expr
            end

            if (matchKeyword('delete') || matchKeyword('void') || matchKeyword('typeof')) 
                expr = {
                    type: Syntax[:UnaryExpression],
                    operator: lex()[:value],
                    argument: parseUnaryExpression(),
                    prefix: true
                }
                if (@strict && expr[:operator] == 'delete' && expr[:argument][:type] == Syntax[:Identifier]) 
                    throwErrorTolerant(nil, Messages[:StrictDelete])
                end
                return expr
            end

            return parsePostfixExpression()
        end

        # 11.5 Multiplicative Operators

        def parseMultiplicativeExpression() 
            expr = parseUnaryExpression()

            while (match('*') || match('/') || match('%')) 
                expr = {
                    type: Syntax[:BinaryExpression],
                    operator: lex()[:value],
                    left: expr,
                    right: parseUnaryExpression()
                }
            end

            return expr
        end

        # 11.6 Additive Operators

        def parseAdditiveExpression() 
            expr = parseMultiplicativeExpression()

            while (match('+') || match('-')) 
                expr = {
                    type: Syntax[:BinaryExpression],
                    operator: lex()[:value],
                    left: expr,
                    right: parseMultiplicativeExpression()
                }
            end

            return expr
        end

        # 11.7 Bitwise Shift Operators

        def parseShiftExpression() 
            expr = parseAdditiveExpression()

            while (match('<<') || match('>>') || match('>>>')) 
                expr = {
                    type: Syntax[:BinaryExpression],
                    operator: lex()[:value],
                    left: expr,
                    right: parseAdditiveExpression()
                }
            end

            return expr
        end
        # 11.8 Relational Operators

        def parseRelationalExpression()
            previousAllowIn = @state[:allowIn]
            @state[:allowIn] = true

            expr = parseShiftExpression()

            while (match('<') || match('>') || match('<=') || match('>=') || (previousAllowIn && matchKeyword('in')) || matchKeyword('instanceof')) 
                expr = {
                    type: Syntax[:BinaryExpression],
                    operator: lex()[:value],
                    left: expr,
                    right: parseShiftExpression()
                }
            end

            @state[:allowIn] = previousAllowIn
            return expr
        end

        # 11.9 Equality Operators

        def parseEqualityExpression() 
            expr = parseRelationalExpression()

            while (match('==') || match('!=') || match('===') || match('!==')) 
                expr = {
                    type: Syntax[:BinaryExpression],
                    operator: lex()[:value],
                    left: expr,
                    right: parseRelationalExpression()
                }
            end

            return expr
        end

        # 11.10 Binary Bitwise Operators

        def parseBitwiseANDExpression() 
            expr = parseEqualityExpression()

            while (match('&')) 
                lex()
                expr = {
                    type: Syntax[:BinaryExpression],
                    operator: '&',
                    left: expr,
                    right: parseEqualityExpression()
                }
            end

            return expr
        end

        def parseBitwiseXORExpression() 
            expr = parseBitwiseANDExpression()

            while (match('^')) 
                lex()
                expr = {
                    type: Syntax[:BinaryExpression],
                    operator: '^',
                    left: expr,
                    right: parseBitwiseANDExpression()
                }
            end

            return expr
        end

        def parseBitwiseORExpression() 
            expr = parseBitwiseXORExpression()

            while (match('|')) 
                lex()
                expr = {
                    type: Syntax[:BinaryExpression],
                    operator: '|',
                    left: expr,
                    right: parseBitwiseXORExpression()
                }
            end

            return expr
        end

        # 11.11 Binary Logical Operators

        def parseLogicalANDExpression() 
            expr = parseBitwiseORExpression()

            while (match('&&')) 
                lex()
                expr = {
                    type: Syntax[:LogicalExpression],
                    operator: '&&',
                    left: expr,
                    right: parseBitwiseORExpression()
                }
            end

            return expr
        end

        def parseLogicalORExpression() 
            expr = parseLogicalANDExpression()

            while (match('||')) 
                lex()
                expr = {
                    type: Syntax[:LogicalExpression],
                    operator: '||',
                    left: expr,
                    right: parseLogicalANDExpression()
                }
            end

            return expr
        end

        # 11.12 Conditional Operator

        def parseConditionalExpression()

            expr = parseLogicalORExpression()

            if (match('?')) 
                lex()
                previousAllowIn = @state[:allowIn]
                @state[:allowIn] = true
                consequent = parseAssignmentExpression()
                @state[:allowIn] = previousAllowIn
                expect(':')

                expr = {
                    type: Syntax[:ConditionalExpression],
                    test: expr,
                    consequent: consequent,
                    alternate: parseAssignmentExpression()
                }
            end

            return expr
        end

        # 11.13 Assignment Operators

        def parseAssignmentExpression()

            token = lookahead()
            expr = parseConditionalExpression()

            if (matchAssign()) 
                # LeftHandSideExpression
                if (!isLeftHandSide(expr)) 
                    throwErrorTolerant(nil, Messages[:InvalidLHSInAssignment])
                end

                # 11.13.1
                if (@strict && expr[:type] == Syntax[:Identifier] && isRestrictedWord(expr[:name])) 
                    throwErrorTolerant(token, Messages[:StrictLHSAssignment])
                end

                expr = {
                    type: Syntax[:AssignmentExpression],
                    operator: lex()[:value],
                    left: expr,
                    right: parseAssignmentExpression()
                }
            end

            return expr
        end

        # 11.14 Comma Operator

        def parseExpression() 
            expr = parseAssignmentExpression()

            if (match(','))
                expr = {
                    type: Syntax[:SequenceExpression],
                    expressions: [ expr ]
                }

                while (@index < @length)
                    if (!match(','))
                        break
                    end
                    lex()
                    expr[:expressions].push(parseAssignmentExpression())
                end

            end
            return expr
        end

        # 12.1 Block

        def parseStatementList()
            list = []
            statement = nil

            while (@index < @length)
                if (match('}'))
                    break
                end
                statement = parseSourceElement()
                unless (statement)
                    break
                end
                list.push(statement)
            end

            return list
        end

        def parseBlock() 

            expect('{')

            block = parseStatementList()

            expect('}')

            return {
                type: Syntax[:BlockStatement],
                body: block
            }
        end

        # 12.2 Variable Statement

        def parseVariableIdentifier() 
            token = lex()

            if (token[:type] != Token[:Identifier])
                throwUnexpected(token)
            end

            return {
                type: Syntax[:Identifier],
                name: token[:value]
            }
        end

        def parseVariableDeclaration(kind=nil) 
            id = parseVariableIdentifier()
            init = nil

            # 12.2.1
            if (@strict && isRestrictedWord(id[:name])) 
                throwErrorTolerant(nil, Messages[:StrictVarName])
            end

            if (kind == 'const') 
                expect('=')
                init = parseAssignmentExpression()
            elsif (match('=')) 
                lex()
                init = parseAssignmentExpression()
            end

            return {
                type: Syntax[:VariableDeclarator],
                id: id,
                init: init
            }
        end

        def parseVariableDeclarationList(kind = nil) 
            list = []

            begin
                list.push(parseVariableDeclaration(kind))
                if (!match(',')) 
                    break
                end
                lex()
            end while (@index < @length)

            return list
        end

        def parseVariableStatement()
            expectKeyword('var')

            declarations = parseVariableDeclarationList()

            consumeSemicolon()

            return {
                type: Syntax[:VariableDeclaration],
                declarations: declarations,
                kind: 'var'
            }
        end

        # kind may be `const` or `let`
        # Both are experimental and not in the specification yet.
        # see http:#wiki[:ecmascript].org/doku.php?id=harmony:const
        # and http:#wiki[:ecmascript].org/doku.php?id=harmony:let
        def parseConstLetDeclaration(kind) 

            expectKeyword(kind)

            declarations = parseVariableDeclarationList(kind)

            consumeSemicolon()

            return {
                type: Syntax[:VariableDeclaration],
                declarations: declarations,
                kind: kind
            }
        end

        # 12.3 Empty Statement

        def parseEmptyStatement() 
            expect(';')

            return {
                type: Syntax[:EmptyStatement]
            }
        end

        # 12.4 Expression Statement

        def parseExpressionStatement() 
            expr = parseExpression()

            consumeSemicolon()

            return {
                type: Syntax[:ExpressionStatement],
                expression: expr
            }
        end

        # 12.5 If @statement

        def parseIfStatement()

            expectKeyword('if')

            expect('(')

            test = parseExpression()

            expect(')')

            consequent = parseStatement()

            if (matchKeyword('else')) 
                lex()
                alternate = parseStatement()
            else
                alternate = nil
            end

            return {
                type: Syntax[:IfStatement],
                test: test,
                consequent: consequent,
                alternate: alternate
            }
        end

        # 12.6 Iteration Statements

        def parseDoWhileStatement() 
            expectKeyword('do')

            oldInIteration = @state[:inIteration]
            @state[:inIteration] = true

            body = parseStatement()

            @state[:inIteration] = oldInIteration

            expectKeyword('while')

            expect('(')

            test = parseExpression()

            expect(')')

            if (match(';')) 
                lex()
            end

            return {
                type: Syntax[:DoWhileStatement],
                body: body,
                test: test
            }
        end

        def parseWhileStatement()

            expectKeyword('while')

            expect('(')

            test = parseExpression()

            expect(')')

            oldInIteration = @state[:inIteration]
            @state[:inIteration] = true

            body = parseStatement()

            @state[:inIteration] = oldInIteration

            return {
                type: Syntax[:WhileStatement],
                test: test,
                body: body
            }
        end

        def parseForVariableDeclaration() 
            token = lex()

            return {
                type: Syntax[:VariableDeclaration],
                declarations: parseVariableDeclarationList(),
                kind: token[:value]
            }
        end

        def parseForStatement() 
            init = nil
            test = nil
            update = nil
            left = nil

            expectKeyword('for')

            expect('(')

            if (match(';')) 
                lex()
            else
                if (matchKeyword('var') || matchKeyword('let')) 
                    @state[:allowIn] = false
                    init = parseForVariableDeclaration()
                    @state[:allowIn] = true

                    if (init[:declarations].length == 1 && matchKeyword('in')) 
                        lex()
                        left = init
                        right = parseExpression()
                        init = nil
                    end
                else
                    @state[:allowIn] = false
                    init = parseExpression()
                    @state[:allowIn] = true

                    if (matchKeyword('in')) 
                        # LeftHandSideExpression
                        if (!isLeftHandSide(init))
                            throwErrorTolerant(nil, Messages[:InvalidLHSInForIn])
                        end

                        lex()
                        left = init
                        right = parseExpression()
                        init = nil
                    end
                end

                if (left == nil) 
                    expect(';')
                end
            end

            if (left == nil) 

                if (!match(';')) 
                    test = parseExpression()
                end
                expect(';')

                if (!match(')')) 
                    update = parseExpression()
                end
            end

            expect(')')

            oldInIteration = @state[:inIteration]
            @state[:inIteration] = true

            body = parseStatement()

            @state[:inIteration] = oldInIteration

            if (left == nil) 
                return {
                    type: Syntax[:ForStatement],
                    init: init,
                    test: test,
                    update: update,
                    body: body
                }
            end

            return {
                type: Syntax[:ForInStatement],
                left: left,
                right: right,
                body: body,
                each: false
            }
        end

        # 12.7 The continue @statement

        def parseContinueStatement() 
            token = nil
            label = nil

            expectKeyword('continue')

            # Optimize the most common form: 'continue'.
            if (@source[@index] == ';') 
                lex()

                if (!@state[:inIteration]) 
                    throwError(nil, Messages[:IllegalContinue])
                end

                return {
                    type: Syntax[:ContinueStatement],
                    label: nil
                }
            end

            if (peekLineTerminator()) 
                if (!@state[:inIteration]) 
                    throwError(nil, Messages[:IllegalContinue])
                end

                return {
                    type: Syntax[:ContinueStatement],
                    label: nil
                }
            end

            token = lookahead()
            if (token[:type] == Token[:Identifier]) 
                label = parseVariableIdentifier()

                if (false) 
                    throwError(nil, Messages[:UnknownLabel], label[:name])
                end
            end

            consumeSemicolon()

            if (label == nil && !@state[:inIteration]) 
                throwError(nil, Messages[:IllegalContinue])
            end

            return {
                type: Syntax[:ContinueStatement],
                label: label
            }
        end

        # 12.8 The break @statement

        def parseBreakStatement() 
            token = nil
            label = nil

            expectKeyword('break')

            # Optimize the most common form: 'break'.
            if (@source[@index] == ';') 
                lex()

                if (!(@state[:inIteration] || @state[:inSwitch])) 
                    throwError(nil, Messages[:IllegalBreak])
                end

                return {
                    type: Syntax[:BreakStatement],
                    label: nil
                }
            end

            if (peekLineTerminator()) 
                if (!(@state[:inIteration] || @state[:inSwitch])) 
                    throwError(nil, Messages[:IllegalBreak])
                end

                return {
                    type: Syntax[:BreakStatement],
                    label: nil
                }
            end

            token = lookahead()
            if (token[:type] == Token[:Identifier]) 
                label = parseVariableIdentifier()

                if (false) 
                    throwError(nil, Messages[:UnknownLabel], label[:name])
                end
            end

            consumeSemicolon()

            if (label == nil && !(@state[:inIteration] || @state[:inSwitch])) 
                throwError(nil, Messages[:IllegalBreak])
            end

            return {
                type: Syntax[:BreakStatement],
                label: label
            }
        end

        # 12.9 The return @statement

        def parseReturnStatement() 
            token = nil
            argument = nil

            expectKeyword('return')

            if (!@state[:indefBody]) 
                throwErrorTolerant(nil, Messages[:IllegalReturn])
            end

            # 'return' followed by a space and an identifier is very common.
            if (@source[@index] == ' ') 
                if (isIdentifierStart(@source[@index + 1])) 
                    argument = parseExpression()
                    consumeSemicolon()
                    return {
                        type: Syntax[:ReturnStatement],
                        argument: argument
                    }
                end
            end

            if (peekLineTerminator()) 
                return {
                    type: Syntax[:ReturnStatement],
                    argument: nil
                }
            end

            if (!match(';')) 
                token = lookahead()
                if (!match('}') && token[:type] != Token[:EOF]) 
                    argument = parseExpression()
                end
            end

            consumeSemicolon()

            return {
                type: Syntax[:ReturnStatement],
                argument: argument
            }
        end

        # 12.10 The with @statement

        def parseWithStatement() 
            if (@strict) 
                throwErrorTolerant(nil, Messages[:StrictModeWith])
            end

            expectKeyword('with')

            expect('(')

            object = parseExpression()

            expect(')')

            body = parseStatement()

            return {
                type: Syntax[:WithStatement],
                object: object,
                body: body
            }
        end

        # 12.10 The swith @statement

        def parseSwitchCase() 
            consequent = []
            statement = nil

            if (matchKeyword('default')) 
                lex()
                test = nil
            else
                expectKeyword('case')
                test = parseExpression()
            end
            expect(':')

            while (@index < @length) 
                if (match('}') || matchKeyword('default') || matchKeyword('case')) 
                    break
                end
                statement = parseStatement()
                if (statement == nil) 
                    break
                end
                consequent.push(statement)
            end

            return {
                type: Syntax[:SwitchCase],
                test: test,
                consequent: consequent
            }
        end

        def parseSwitchStatement()

            expectKeyword('switch')

            expect('(')

            discriminant = parseExpression()

            expect(')')

            expect('{')

            cases = []

            if (match('}')) 
                lex()
                return {
                    type: Syntax[:SwitchStatement],
                    discriminant: discriminant,
                    cases: cases
                }
            end

            oldInSwitch = @state[:inSwitch]
            @state[:inSwitch] = true
            defaultFound = false

            while (@index < @length) 
                if (match('}')) 
                    break
                end
                clause = parseSwitchCase()
                if (clause[:test] == nil) 
                    if (defaultFound) 
                        throwError(nil, Messages[:MultipleDefaultsInSwitch])
                    end
                    defaultFound = true
                end
                cases.push(clause)
            end

            @state[:inSwitch] = oldInSwitch

            expect('}')

            return {
                type: Syntax[:SwitchStatement],
                discriminant: discriminant,
                cases: cases
            }
        end

        # 12.13 The throw @statement

        def parseThrowStatement()

            expectKeyword('throw')

            if (peekLineTerminator()) 
                throwError(nil, Messages[:NewlineAfterThrow])
            end

            argument = parseExpression()

            consumeSemicolon()

            return {
                type: Syntax[:ThrowStatement],
                argument: argument
            }
        end

        # 12.14 The try @statement

        def parseCatchClause()

            expectKeyword('catch')

            expect('(')
            if (match(')')) 
                throwUnexpected(lookahead())
            end

            param = parseVariableIdentifier()
            # 12.14.1
            if (@strict && isRestrictedWord(param[:name])) 
                throwErrorTolerant(nil, Messages[:StrictCatchVariable])
            end

            expect(')')

            return {
                type: Syntax[:CatchClause],
                param: param,
                body: parseBlock()
            }
        end

        def parseTryStatement() 
            handlers = []
            finalizer = nil

            expectKeyword('try')

            block = parseBlock()

            if (matchKeyword('catch')) 
                handlers.push(parseCatchClause())
            end

            if (matchKeyword('finally')) 
                lex()
                finalizer = parseBlock()
            end

            if (handlers.length == 0 && !finalizer) 
                throwError(nil, Messages[:NoCatchOrFinally])
            end

            return {
                type: Syntax[:TryStatement],
                block: block,
                guardedHandlers: [],
                handlers: handlers,
                finalizer: finalizer
            }
        end

        # 12.15 The debugger @statement

        def parseDebuggerStatement() 
            expectKeyword('debugger')

            consumeSemicolon()

            return {
                type: Syntax[:DebuggerStatement]
            }
        end

        # 12 Statements

        def parseStatement() 
            token = lookahead()

            if (token[:type] == Token[:EOF]) 
                throwUnexpected(token)
            end

            if (token[:type] == Token[:Punctuator]) 
                case token[:value]
                when ';'
                    return parseEmptyStatement()
                when '{'
                    return parseBlock()
                when '('
                    return parseExpressionStatement()
                end
            end

            if (token[:type] == Token[:Keyword]) 
                case token[:value]
                when 'break'
                    return parseBreakStatement()
                when 'continue'
                    return parseContinueStatement()
                when 'debugger'
                    return parseDebuggerStatement()
                when 'do'
                    return parseDoWhileStatement()
                when 'for'
                    return parseForStatement()
                when 'function'
                    return parseFunctionDeclaration()
                when 'if'
                    return parseIfStatement()
                when 'return'
                    return parseReturnStatement()
                when 'switch'
                    return parseSwitchStatement()
                when 'throw'
                    return parseThrowStatement()
                when 'try'
                    return parseTryStatement()
                when 'var'
                    return parseVariableStatement()
                when 'while'
                    return parseWhileStatement()
                when 'with'
                    return parseWithStatement()
                end
            end

            expr = parseExpression()

            # 12.12 Labelled Statements
            if ((expr[:type] == Syntax[:Identifier]) && match(':')) 
                lex()

                if (false) 
                    throwError(nil, Messages[:Redeclaration], 'Label', expr[:name])
                end

                @state[:labelSet][expr[:name]] = true
                labeledBody = parseStatement()
                @state[:labelSet].delete(expr[:name])

                return {
                    type: Syntax[:LabeledStatement],
                    label: expr,
                    body: labeledBody
                }
            end

            consumeSemicolon()

            return {
                type: Syntax[:ExpressionStatement],
                expression: expr
            }
        end

        # 13 Function Definition

        def parseFunctionSourceElements() 
            sourceElements = []
            firstRestricted = nil

            expect('{')

            while (@index < @length) 
                token = lookahead()
                if (token[:type] != Token[:StringLiteral]) 
                    break
                end

                sourceElement = parseSourceElement()
                sourceElements.push(sourceElement)
                if (sourceElement[:expression][:type] != Syntax[:Literal]) 
                    # this is not directive
                    break
                end
                directive = sliceSource(token[:range][0] + 1, token[:range][1] - 1)
                if (directive == 'use strict') 
                    @strict = true
                    if (firstRestricted) 
                        throwErrorTolerant(firstRestricted, Messages[:StrictOctalLiteral])
                    end
                else
                    if (!firstRestricted && token[:octal]) 
                        firstRestricted = token
                    end
                end
            end

            oldLabelSet = @state[:labelSet]
            oldInIteration = @state[:inIteration]
            oldInSwitch = @state[:inSwitch]
            oldIndefBody = @state[:indefBody]

            @state[:labelSet] = {}
            @state[:inIteration] = false
            @state[:inSwitch] = false
            @state[:indefBody] = true

            while (@index < @length) 
                if (match('}')) 
                    break
                end
                sourceElement = parseSourceElement()
                if (sourceElement == nil)
                    break
                end
                sourceElements.push(sourceElement)
            end

            expect('}')

            @state[:labelSet] = oldLabelSet
            @state[:inIteration] = oldInIteration
            @state[:inSwitch] = oldInSwitch
            @state[:indefBody] = oldIndefBody

            return {
                type: Syntax[:BlockStatement],
                body: sourceElements
            }
        end

        def parseFunctionDeclaration() 
            params = []

            expectKeyword('function')
            token = lookahead()
            id = parseVariableIdentifier()
            if (@strict) 
                if (isRestrictedWord(token[:value])) 
                    throwErrorTolerant(token, Messages[:StrictFunctionName])
                end
            else
                if (isRestrictedWord(token[:value])) 
                    firstRestricted = token
                    message = Messages[:StrictFunctionName]
                elsif (isStrictModeReservedWord(token[:value])) 
                    firstRestricted = token
                    message = Messages[:StrictReservedWord]
                end
            end

            expect('(')

            if (!match(')')) 
                paramSet = {}
                while (@index < @length) 
                    token = lookahead()
                    param = parseVariableIdentifier()
                    if (@strict) 
                        if (isRestrictedWord(token[:value])) 
                            stricted = token
                            message = Messages[:StrictParamName]
                        end
                        if (false)
                            stricted = token
                            message = Messages[:StrictParamDupe]
                        end
                    elsif (!firstRestricted) 
                        if (isRestrictedWord(token[:value])) 
                            firstRestricted = token
                            message = Messages[:StrictParamName]
                        elsif (isStrictModeReservedWord(token[:value])) 
                            firstRestricted = token
                            message = Messages[:StrictReservedWord]
                        elsif (false) 
                            firstRestricted = token
                            message = Messages[:StrictParamDupe]
                        end
                    end
                    params.push(param)
                    paramSet[param[:name]] = true
                    if (match(')')) 
                        break
                    end
                    expect(',')
                end
            end

            expect(')')

            previousStrict = @strict
            body = parseFunctionSourceElements()
            if (@strict && firstRestricted) 
                throwError(firstRestricted, message)
            end
            if (@strict && stricted) 
                throwErrorTolerant(stricted, message)
            end
            @strict = previousStrict

            return {
                type: Syntax[:FunctionDeclaration],
                id: id,
                params: params,
                defaults: [],
                body: body,
                rest: nil,
                generator: false,
                expression: false
            }
        end

        def parseFunctionExpression() 
             id = nil
             params = []

            expectKeyword('function')

            if (!match('(')) 
                token = lookahead()
                id = parseVariableIdentifier()
                if (@strict) 
                    if (isRestrictedWord(token[:value])) 
                        throwErrorTolerant(token, Messages[:StrictFunctionName])
                    end
                else
                    if (isRestrictedWord(token[:value])) 
                        firstRestricted = token
                        message = Messages[:StrictFunctionName]
                    elsif (isStrictModeReservedWord(token[:value])) 
                        firstRestricted = token
                        message = Messages[:StrictReservedWord]
                    end
                end
            end

            expect('(')

            if (!match(')')) 
                paramSet = {}
                while (@index < @length) 
                    token = lookahead()
                    param = parseVariableIdentifier()
                    if (@strict) 
                        if (isRestrictedWord(token[:value])) 
                            stricted = token
                            message = Messages[:StrictParamName]
                        end
                        if (false) 
                            stricted = token
                            message = Messages[:StrictParamDupe]
                        end
                    elsif (!firstRestricted) 
                        if (isRestrictedWord(token[:value])) 
                            firstRestricted = token
                            message = Messages[:StrictParamName]
                        elsif (isStrictModeReservedWord(token[:value])) 
                            firstRestricted = token
                            message = Messages[:StrictReservedWord]
                        elsif (false) 
                            firstRestricted = token
                            message = Messages[:StrictParamDupe]
                        end
                    end
                    params.push(param)
                    paramSet[param[:name]] = true
                    if (match(')')) 
                        break
                    end
                    expect(',')
                end
            end

            expect(')')

            previousStrict = @strict
            body = parseFunctionSourceElements()
            if (@strict && firstRestricted) 
                throwError(firstRestricted, message)
            end
            if (@strict && stricted) 
                throwErrorTolerant(stricted, message)
            end
            @strict = previousStrict

            return {
                type: Syntax[:FunctionExpression],
                id: id,
                params: params,
                defaults: [],
                body: body,
                rest: nil,
                generator: false,
                expression: false
            }
        end

        # 14 Program

        def parseSourceElement() 
            token = lookahead()

            if (token[:type] == Token[:Keyword]) 
                case (token[:value])
                when 'const','let'
                    return parseConstLetDeclaration(token[:value])
                when 'function'
                    return parseFunctionDeclaration()
                else
                    return parseStatement()
                end
            end

            if (token[:type] != Token[:EOF]) 
                return parseStatement()
            end
        end

        def parseSourceElements() 
            sourceElements = []
            firstRestricted = nil

            while (@index < @length) 
                token = lookahead()
                if (token[:type] != Token[:StringLiteral]) 
                    break
                end

                sourceElement = parseSourceElement()
                sourceElements.push(sourceElement)
                if (sourceElement[:expression][:type] != Syntax[:Literal]) 
                    # this is not directive
                    break
                end
                directive = sliceSource(token[:range][0] + 1, token[:range][1] - 1)
                if (directive == 'use strict') 
                    @strict = true
                    if (firstRestricted) 
                        throwErrorTolerant(firstRestricted, Messages[:StrictOctalLiteral])
                    end
                else
                    if (!firstRestricted && token[:octal]) 
                        firstRestricted = token
                    end
                end
            end

            while (@index < @length) 
                sourceElement = parseSourceElement()
                if (sourceElement == nil) 
                    break
                end
                sourceElements.push(sourceElement)
            end
            return sourceElements
        end

        def parseProgram() 
            @strict = false
            program = {
                type: Syntax[:Program],
                body: parseSourceElements()
            }
            return program
        end

        # The following defs are needed only when the option to preserve
        # the comments is active.

        def addComment(type, value, start, end1, loc) 
            assert(start.instance_of? Fixnum, 'Comment must have valid position')

            # Because the way the actual token is scanned, often the comments
            # (if any) are skipped twice during the lexical analysis.
            # Thus, we need to skip adding a comment if the comment array already
            # handled it.
            if (@extra[:comments].length > 0) 
                if (@extra[:comments][@extra[:comments].length - 1][:range][1] > start) 
                    return
                end
            end

            @extra[:comments].push({
                type: type,
                value: value,
                range: [start, end1],
                loc: loc
            })
        end

        def scanComment() 
            comment = ''
            blockComment = false
            lineComment = false

            while (@index < @length) 
                ch = @source[@index]

                if (lineComment) 
                    ch = curCharAndMoveNext
                    if (isLineTerminator(ch)) 
                        loc[:end] = {
                            line: @lineNumber,
                            column: @index - @lineStart - 1
                        }
                        lineComment = false
                        addComment('Line', comment, start, @index - 1, loc)
                        if (ch == "\r" && @source[@index] == "\n") 
                            @index += 1
                        end
                        @lineNumber += 1
                        @lineStart = @index
                        comment = ''
                    elsif (@index >= @length) 
                        lineComment = false
                        comment += ch
                        loc[:end] = {
                            line: @lineNumber,
                            column: @length - @lineStart
                        }
                        addComment('Line', comment, start, @length, loc)
                    else
                        comment += ch
                    end
                elsif (blockComment) 
                    if (isLineTerminator(ch)) 
                        if (ch == "\r" && @source[@index + 1] == "\n") 
                            @index += 1
                            comment += "\r\n"
                        else
                            comment += ch
                        end
                        @lineNumber += 1
                        @index += 1
                        @lineStart = @index
                        if (@index >= @length)
                            throwError(nil, Messages[:UnexpectedToken], 'ILLEGAL')
                        end
                    else
                        ch = curCharAndMoveNext
                        if (@index >= @length) 
                            throwError(nil, Messages[:UnexpectedToken], 'ILLEGAL')
                        end
                        comment += ch
                        if (ch == '*') 
                            ch = @source[@index]
                            if (ch == '/') 
                                comment = comment.substr(0, comment.length - 1)
                                blockComment = false
                                @index += 1
                                loc[:end] = {
                                    line: @lineNumber,
                                    column: @index - @lineStart
                                }
                                addComment('Block', comment, start, @index, loc)
                                comment = ''
                            end
                        end
                    end
                elsif (ch == '/') 
                    ch = @source[@index + 1]
                    if (ch == '/') 
                        loc = {
                            start: {
                                line: @lineNumber,
                                column: @index - @lineStart
                            }
                        }
                        start = @index
                        @index += 2
                        lineComment = true
                        if (@index >= @length) 
                            loc[:end] = {
                                line: @lineNumber,
                                column: @index - @lineStart
                            }
                            lineComment = false
                            addComment('Line', comment, start, @index, loc)
                        end
                    elsif (ch == '*') 
                        start = @index
                        @index += 2
                        blockComment = true
                        loc = {
                            start: {
                                line: @lineNumber,
                                column: @index - @lineStart - 2
                            }
                        }
                        if (@index >= @length) 
                            throwError(nil, Messages[:UnexpectedToken], 'ILLEGAL')
                        end
                    else
                        break
                    end
                elsif (isWhiteSpace(ch)) 
                    @index += 1
                elsif (isLineTerminator(ch)) 
                    @index += 1
                    if (ch ==  "\r" && @source[@index] == "\n") 
                        @index += 1
                    end
                    @lineNumber += 1
                    @lineStart = @index
                else
                    break
                end
            end
        end

        def filterCommentLocation() 
            comments = []

            @extra[:comments].length.times do |i|
                entry = @extra.comments[i]
                comment = {
                    type: entry[:type],
                    value: entry[:value]
                }
                if (@extra[:range]) 
                    comment[:range] = entry[:range]
                end
                if (@extra[:loc]) 
                    comment[:loc] = entry[:loc]
                end
                comments.push(comment)
            end

            @extra[:comments] = comments
        end

        def collectToken() 
            skipComment()
            start = @index
            loc = {
                start: {
                    line: @lineNumber,
                    column: @index - @lineStart
                }
            }

            token = @extra.advance()
            loc[:end] = {
                line: @lineNumber,
                column: @index - @lineStart
            }

            if (token[:type] != Token[:EOF]) 
                range = [token[:range][0], token[:range][1]]
                value = sliceSource(token[:range][0], token[:range][1])
                @extra[:tokens].push({
                    type: TokenName[token[:type]],
                    value: value,
                    range: range,
                    loc: loc
                })
            end

            return token
        end

        def collectRegex() 
            skipComment()

            pos = @index
            loc = {
                start: {
                    line: @lineNumber,
                    column: @index - @lineStart
                }
            }

            regex = @extra.scanRegExp()
            loc[:end] = {
                line: @lineNumber,
                column: @index - @lineStart
            }

            # Pop the previous token, which is likely '/' or '/='
            if (@extra[:tokens].length > 0) 
                token = @extra[:tokens][@extra[:tokens].length - 1]
                if (token[:range][0] == pos && token[:type] == 'Punctuator') 
                    if (token[:value] == '/' || token[:value] == '/=') 
                        @extra[:tokens].pop()
                    end
                end
            end

            @extra[:tokens].push({
                type: 'RegularExpression',
                value: regex[:literal],
                range: [pos, @index],
                loc: loc
            })

            return regex
        end

        def filterTokenLocation() 
            tokens = []

            @extra[:tokens].length.times do |i|
                entry = @extra[:tokens][i]
                token = {
                    type: entry[:type],
                    value: entry[:value]
                }
                if (@extra[:range]) 
                    token[:range] = entry[:range]
                end
                if (@extra[:loc]) 
                    token[:loc] = entry[:loc]
                end
                tokens.push(token)
            end

            @extra[:tokens] = tokens
        end

        def createLiteral(token)
            unless @extra[:raw]
                return {
                    type: Syntax[:Literal],
                    value: token[:value]
                }
            end

            return {
                type: Syntax[:Literal],
                value: token[:value],
                raw: sliceSource(token[:range][0], token[:range][1])
            }
        end

        def createLocationMarker() 
            marker = {}

            marker[:range] = [@index, @index]
            marker[:loc] = {
                start: {
                    line: @lineNumber,
                    column: @index - @lineStart
                },
                end: {
                    line: @lineNumber,
                    column: @index - @lineStart
                }
            }

            marker[:end] = lambda {
                this.range[1] = @index
                this[:loc][:end][:line] = @lineNumber
                this[:loc][:end][:column] = @index - @lineStart
            }

            marker[:applyGroup] = lambda do |node| 
                if (@extra[:range]) 
                    node[:groupRange] = [this.range[0], this.range[1]]
                end
                if (@extra[:loc]) 
                    node[:groupLoc] = {
                        start: {
                            line: this[:loc].start[:line],
                            column: this[:loc][:start][:column]
                        },
                        end: {
                            line: this[:loc].end[:line],
                            column: this[:loc][:end][:column]
                        }
                    }
                end
            end

            marker[:apply] = lambda do |node| 
                if (@extra[:range]) 
                    node[:range] = [this.range[0], this.range[1]]
                end
                if (@extra[:loc]) 
                    node[:loc] = {
                        start: {
                            line: this[:loc].start[:line],
                            column: this[:loc][:start][:column]
                        },
                        end: {
                            line: this[:loc].end[:line],
                            column: this[:loc][:end][:column]
                        }
                    }
                end
            end

            return marker
        end

        def trackGroupExpression()

            skipComment()
            marker = createLocationMarker()
            expect('(')

            expr = parseExpression()

            expect(')')

            marker[:end].call()
            marker[:applyGroup].call(expr)

            return expr
        end

        def trackLeftHandSideExpression() 

            skipComment()
            marker = createLocationMarker()

            expr = matchKeyword('new') ? parseNewExpression() : parsePrimaryExpression()

            while (match('.') || match('[')) 
                if (match('[')) 
                    expr = {
                        type: Syntax[:MemberExpression],
                        computed: true,
                        object: expr,
                        property: parseComputedMember()
                    }
                    marker[:end].call()
                    marker[:apply].call(expr)
                else
                    expr = {
                        type: Syntax[:MemberExpression],
                        computed: false,
                        object: expr,
                        property: parseNonComputedMember()
                    }
                    marker[:end].call()
                    marker[:apply].call(expr)
                end
            end

            return expr
        end

        def trackLeftHandSideExpressionAllowCall()

            skipComment()
            marker = createLocationMarker()

            expr = matchKeyword('new') ? parseNewExpression() : parsePrimaryExpression()

            while (match('.') || match('[') || match('(')) 
                if (match('(')) 
                    expr = {
                        type: Syntax[:CallExpression],
                        callee: expr,
                        arguments: parseArguments()
                    }
                    marker[:end].call()
                    marker[:apply].call(expr)
                elsif (match('[')) 
                    expr = {
                        type: Syntax[:MemberExpression],
                        computed: true,
                        object: expr,
                        property: parseComputedMember()
                    }
                    marker[:end].call()
                    marker[:apply].call(expr)
                else
                    expr = {
                        type: Syntax[:MemberExpression],
                        computed: false,
                        object: expr,
                        property: parseNonComputedMember()
                    }
                    marker[:end].call()
                    marker[:apply].call(expr)
                end
            end

            return expr
        end
=begin
        def filterGroup(node) 
            n = (node.instance_of?(Array)) ? [] : {}
            for (i in node) {
                if (node.hasOwnProperty(i) && i != 'groupRange' && i != 'groupLoc') 
                    entry = node[i]
                    if (entry == nil || typeof entry != 'object' || entry instanceof RegExp) 
                        n[i] = entry
                    else
                        n[i] = filterGroup(entry)
                    end
                end
            end
            return n
        end
=end

        def parse(code, options = nil)
            @source = code
            @index = 0
            @lineNumber = (@source.length > 0) ? 1 : 0
            @lineStart = 0
            @length = @source.length
            @buffer = nil
            @state = {
                allowIn: true,
                labelSet: {},
                indefBody: false,
                inIteration: false,
                inSwitch: false
            }

            @extra = {}

            @extra[:range] = false
            @extra[:loc] = false
            @extra[:raw] = false

            if (options) 
                @extra[:range] = options[:range] == true
                @extra[:loc] = options[:loc] == true
                @extra[:raw] = options[:raw] = true
                if (options[:tokens]) 
                    @extra[:tokens] = []
                end
                if (options[:comment]) 
                    @extra[:comments] = []
                end
                if (options[:tolerant]) 
                    @extra[:errors] = []
                end
            end

            
            program = parseProgram()

            if (@extra[:comments]) 
                filterCommentLocation()
                program[:comments] = @extra[:comments]
            end
            if (@extra[:tokens]) 
                filterTokenLocation()
                program[:tokens] = @extra[:tokens]
            end
            if (@extra[:errors]) 
                program[:errors] = @extra[:errors]
            end
            if (@extra[:range] || @extra[:loc]) 
         #       program[:body] = filterGroup(program[:body])
            end

            return program
        end
    end
end