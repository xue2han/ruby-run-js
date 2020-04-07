module RubyRunJs
  class ByteCodeGenerator

    attr_reader :declared_vars

    def initialize
      init()
      @label_id = 0
    end

    def init
      @bytecodes = []

      @implicit_breaks = []
      @implicit_continues = []
    
      @declared_continue_labels = {}
      @declared_break_labels = {}

      @function_declaration_codes = []
      @declared_vars = []

      @state = []
    end

    def output_code
      codes = @bytecodes
      init()
      codes
    end

    def push_state()
      @state << [ @implicit_breaks, @implicit_continues,\
       @declared_continue_labels, @declared_break_labels,\
       @function_declaration_codes, @declared_vars ]

       @implicit_breaks = []
       @implicit_continues = []
       @declared_continue_labels = {}
       @declared_break_labels = {}
       @function_declaration_codes = []
       @declared_vars = []
    end

    def pop_state()
      @implicit_breaks, @implicit_continues, \
      @declared_continue_labels, @declared_break_labels,\
      @function_declaration_codes, @declared_vars = @state.pop()
    end

    def new_label
      id = @label_id
      @label_id += 1
      id
    end


    def parseArrayExpression(elements, node)
      elements.each do |e|
        if e.nil?
          emit(OPCODES::LOAD_UNDEFINED)
        else
          emit(e)
        end
      end
      emit(OPCODES::LOAD_ARRAY, elements.length)
    end

    def parseAssignmentExpression(operator, left, right, node)
      if left[:type] == 'MemberExpression'
        emit(left[:object])
        if left[:computed]
          emit(left[:property])
          emit(right)
          if operator.length > 1 && operator[-1] == '='
            emit(OPCODES::STORE_MEMBER_OP, operator[0...-1])
          else
            emit(OPCODES::STORE_MEMBER)
          end
        else
          emit(right)
          if operator.length > 1 && operator[-1] == '='
            emit(OPCODES::STORE_MEMBER_DOT_OP, left[:property][:name], operator[0...-1])
          else
            emit(OPCODES::STORE_MEMBER_DOT, left[:property][:name])
          end
        end
      elsif left[:type] == 'Identifier'
        if ['true', 'false', 'this'].include?(left[:name])
          raise make_error('SyntaxError', 'Invalid left-hand side in assignment')
        end
        emit(right)
        if operator.length > 1 && operator[-1] == '='
          emit(OPCODES::STORE_OP, left[:name], operator[0...-1])
        else
          emit(OPCODES::STORE, left[:name])
        end
      else
        raise make_error('SyntaxError', 'Invalid left-hand side in assignment')
      end
    end

    def parseBinaryExpression(operator, left, right, node)
      emit(left)
      emit(right)
      emit(OPCODES::BINARY_OP, operator)
    end

    def parseBlockStatement(body, node)
      emit(body)
    end

    def parseBreakStatement(label, node)
      if label.nil?
        emit(OPCODES::JUMP, @implicit_breaks[-1])
      else
        label = label[:name]
        unless @declared_break_labels.key?(label)
          raise make_error('SyntaxError', "Undefined label '#{label}'")
        else
          emit(OPCODES::JUMP, @declared_break_labels[label])
        end
      end
    end

    def parseCallExpression(callee, arguments, node)
      if callee[:type] == 'MemberExpression'
        emit(callee[:object])
        if callee[:computed]
          emit(callee[:property])
          if arguments.length > 0
            arguments.each do |a|
              emit(a)
            end
            emit(OPCODES::LOAD_N_TUPLE, arguments.length)
            emit(OPCODES::CALL_METHOD)
          else
            emit(OPCODES::CALL_METHOD_NO_ARGS)
          end
        else
          prop_name = callee[:property][:name]
          if arguments.length > 0
            arguments.each do |a|
              emit(a)
            end
            emit(OPCODES::LOAD_N_TUPLE, arguments.length)
            emit(OPCODES::CALL_METHOD_DOT, prop_name)
          else
            emit(OPCODES::CALL_METHOD_DOT_NO_ARGS, prop_name)
          end
        end
      else
        emit(callee)
        if arguments.length > 0
          arguments.each do |a|
            emit(a)
          end
          emit(OPCODES::LOAD_N_TUPLE, arguments.length)
          emit(OPCODES::CALL)
        else
          emit(OPCODES::CALL_NO_ARGS)
        end
      end
    end

    def parseConditionalExpression(test, consequent, alternate, node)
      label_alt = new_label()
      label_end = new_label()
      emit(test)
      emit(OPCODES::JUMP_IF_FALSE, label_alt)

      emit(consequent)
      emit(OPCODES::JUMP, label_end)

      emit(OPCODES::LABEL, label_alt)
      emit(alternate)

      emit(OPCODES::LABEL, label_end)
    end

    def parseContinueStatement(label, node)
      if label.nil?
        emit(OPCODES::JUMP, @implicit_continues[-1])
      else
        label = label[:name]
        if @declared_continue_labels.key?(label)
          raise make_error('SyntaxError', "Undefined label '#{label}'")
        else
          emit(OPCODES::JUMP, @declared_continue_labels[label])
        end
      end
    end

    def parseDebuggerStatement(node)
      parseEmptyStatement(node)
    end

    def parseDoWhileStatement(body, test, node)
      label_continue = new_label()
      label_break = new_label()
      label_do = new_label()

      emit(OPCODES::JUMP, label_do)
      emit(OPCODES::LABEL, label_continue)
      emit(test)
      emit(OPCODES::JUMP_IF_FALSE, label_break)
      emit(OPCODES::LABEL, label_do)

      @implicit_continues.push(label_continue)
      @implicit_breaks.push(label_break)
      emit(body)
      @implicit_continues.pop()
      @implicit_continues.pop()

      emit(OPCODES::JUMP, label_continue)
      emit(OPCODES::LABEL, label_break)
    end

    def parseEmptyStatement(node)
    end

    def parseExpressionStatement(expression, node)
      emit(OPCODES::POP)
      emit(expression)
    end

    def parseForStatement(init, test, update, body, node)
      label_continue = new_label()
      label_break = new_label()
      label_start = new_label()

      unless init.nil?
        emit(init)
        if init[:type] != 'VariableDeclaration'
          emit(OPCODES::POP)
        end
      end

      emit(OPCODES::JUMP, label_start)

      emit(OPCODES::LABEL, label_continue)
      
      unless update.nil?
        emit(update)
        emit(OPCODES::POP)
      end

      emit(OPCODES::LABEL, label_start)

      unless test.nil?
        emit(test)
        emit(OPCODES::JUMP_IF_FALSE, label_break)
      end

      @implicit_continues.push(label_continue)
      @implicit_breaks.push(label_break)
      emit(body)
      @implicit_continues.pop()
      @implicit_continues.pop()

      emit(OPCODES::JUMP, label_continue)
      emit(OPCODES::LABEL, label_break)

    end

    def parseForInStatement(left, right, body, node)
      label_continue = new_label()
      label_break = new_label()
      label_start = new_label()

      if left[:type] == 'VariableDeclaration'
        if left[:declarations].length != 1
          raise make_error(
            'SyntaxError', 
            ' Invalid left-hand side in for-in loop: Must have a single binding.'
          )
        end
        emit(left)
        name = left[:declarations][0][:id][:name]
      elsif left[:type] == 'Identifier'
        name = left[:name]
      else
        raise make_error('SyntaxError',
                         'Invalid left-hand side in for-loop')
      end
      emit(right)
      emit(OPCODES::FOR_IN, name, label_start, label_continue, label_break)

      emit(OPCODES::LABEL, label_continue)
      emit(OPCODES::NOP)

      emit(OPCODES::LABEL, label_start)

      @implicit_continues.push(label_continue)
      @implicit_breaks.push(label_break)
      emit(OPCODES::LOAD_UNDEFINED)
      emit(body)
      @implicit_continues.pop()
      @implicit_breaks.pop()
      emit(OPCODES::LABEL, label_break)
    end

    def parseFunctionDeclaration(id, params, defaults, body, node)
      
      push_state()

      function_start = new_label()
      function_end = new_label()

      # just skip the function code when the function is not called
      emit(OPCODES::JUMP, function_end)

      emit(OPCODES::LABEL, function_start)

      cur_index = @bytecodes.length

      emit(body)
      emit(OPCODES::RETURN)

      @bytecodes = @bytecodes[0...cur_index].concat(@function_declaration_codes, @bytecodes[cur_index..])
      
      emit(OPCODES::LABEL, function_end)

      declared_vars = @declared_vars

      pop_state()

      name = id[:name]
      @declared_vars.push(name)

      # init the function declarations
      @function_declaration_codes.push(
        OPCODES::LOAD_FUNCTION.new(function_start, params.map { |p| p[:name] },\
           name, true, declared_vars )
      )
      @function_declaration_codes.push(
        OPCODES::STORE.new(name)
      )
      @function_declaration_codes.push(
        OPCODES::POP.new()
      )
    end

    def parseFunctionExpression(id, params, defaults, body, node)
      push_state()

      function_start = new_label()
      function_end = new_label()

      # just skip the function code when the function is not being called
      emit(OPCODES::JUMP, function_end)

      emit(OPCODES::LABEL, function_start)

      cur_index = @bytecodes.length

      emit(body)
      emit(OPCODES::RETURN)

      @bytecodes = @bytecodes[0...cur_index].concat(@function_declaration_codes, @bytecodes[cur_index..])
      
      emit(OPCODES::LABEL, function_end)

      declared_vars = @declared_vars

      pop_state()

      name = id.nil? ? nil : id[:name]

      emit(OPCODES::LOAD_FUNCTION, function_start, params.map { |p| p[:name] },\
        name, false, declared_vars)
    end

    def parseIdentifier(name, node)
      if name == 'undefined'
        emit(OPCODES::LOAD_UNDEFINED)
      else
        emit(OPCODES::LOAD, name)
      end
    end

    def parseIfStatement(test, consequent, alternate, node)
      label_alt = new_label()
      label_end = new_label()

      emit(test)
      emit(OPCODES::JUMP_IF_FALSE, label_alt)

      emit(consequent)
      emit(OPCODES::JUMP, label_end)

      emit(OPCODES::LABEL, label_alt)
      unless alternate.nil?
        emit(alternate)
      else
        emit(OPCODES::NOP)
      end
      emit(OPCODES::LABEL, label_end)
    end

    def parseLabeledStatement(label, body, node)
      label = label[:name]
      if ['WhileStatement', 'DoWhileStatement', \
          'ForStatement', 'ForInStatement'].include?(body[:type])
          @declared_continue_labels[label] = @label_id + 1
          @declared_break_labels[label] = @label_id + 2
          emit(body)
          @declared_break_labels.delete(label)
          @declared_continue_labels.delete(label)
      else
        label_break = new_label()
        @declared_break_labels[label] = label_break
        emit(body)
        emit(OPCODES::LABEL, label_break)
        @declared_break_labels.delete(label)
      end
    end

    def parseLiteral(value, node)
      if value == nil
        emit(OPCODES::LOAD_NULL)
      elsif value == true || value == false
        emit(OPCODES::LOAD_BOOLEAN, value)
      elsif value.is_a?(String)
        emit(OPCODES::LOAD_STRING, value)
      elsif value.is_a?(Numeric)
        emit(OPCODES::LOAD_NUMBER, value.to_f)
      elsif node[:regexp] != nil
        emit(OPCODES::LOAD_REGEXP, node[:regexp][:pattern], node[:regexp][:flags])
      else
        raise "Unsupported literal: #{value}"
      end
    end

    def parseLogicalExpression(left, right, operator, node)
      label_end = new_label()
      if operator == '&&'
        emit(left)
        emit(OPCODES::JUMP_IF_FALSE_WITHOUT_POP, label_end)
        emit(OPCODES::POP)
        emit(right)
        emit(OPCODES::LABEL, label_end)
      elsif operator == '||'
        emit(left)
        emit(OPCODES::JUMP_IF_TRUE_WITHOUT_POP, label_end)
        emit(OPCODES::POP)
        emit(right)
        emit(OPCODES::LABEL, label_end)
      else
        raise "Unknown logical expression: #{operator}"
      end
    end

    def parseMemberExpression(computed, object, property, node)
      if computed
        emit(object)
        emit(property)
        emit(OPCODES::LOAD_MEMBER)
      else
        emit(object)
        emit(OPCODES::LOAD_MEMBER_DOT, property[:name])
      end
    end

    def parseNewExpression(callee, arguments, node)
      emit(callee)
      if arguments.length > 0
        arguments.each do |a|
          emit(a)
        end
        emit(OPCODES::LOAD_N_TUPLE, arguments.length)
        emit(OPCODES::NEW)
      else
        emit(OPCODES::NEW_NO_ARGS)
      end
    end

    def to_key(node)
      if node[:type] == 'Identifier'
        return node[:name]
      end
      if node[:type] == 'Literal'
        v = node[:value]
        if v.js_type == :Number && v.to_i == v
          return v.to_i.to_s
        elsif node[:regexp] != nil
          return "/#{node[:body]}/#{node[:flags]}"
        elsif v == nil
          return 'null'
        end
        return v.to_s
      end
    end

    def parseObjectExpression(properties, node)
      data = properties.map do |prop|
        emit(prop[:value])
        [to_key(prop[:key]), prop[:kind]]
      end
      emit(OPCODES::LOAD_OBJECT, data)
    end

    def parseProgram(body, node)
      cur_index = @bytecodes.length
      emit(OPCODES::LOAD_UNDEFINED)
      emit(body)
      @bytecodes = @bytecodes[0...cur_index].concat(@function_declaration_codes, @bytecodes[cur_index..])
    end

    def parseProperty(kind, key, computed, value, method, shorthand, node)
      raise "Not available in ECMA 5.1"
    end

    def parseRestElement(argument, node)
      raise "Not available in ECMA 5.1"
    end

    def parseReturnStatement(argument, node)
      emit(OPCODES::POP)
      if argument.nil?
        emit(OPCODES::LOAD_UNDEFINED)
      else
        emit(argument)
      end
      emit(OPCODES::RETURN)
    end

    def parseSequenceExpression(expressions, node)
      expressions.each_index do |i|
        emit(expressions[i])
        if i < expressions.length - 1
          emit(OPCODES::POP)
        end
      end
    end

    def parseSwitchCase(test, consequent, node)
      raise "Already implemented in SwitchStatement"
    end

    def parseSwitchStatement(discriminant, cases, node)
      emit(discriminant)
      labels = cases.map { |c| new_label() }
      tests = cases.map { |c| c[:test] }
      consequents = cases.map { |c| c[:consequent] }
      label_switch_end = new_label()

      cases.length.times do |i|
        test = tests[i]
        if test.nil?
          # default
          emit(OPCODES::POP)
          emit(OPCODES::JUMP, labels[i])
        else
          emit(test)
          emit(OPCODES::JUMP_IF_EQ, labels[i])
        end
      end

      emit(OPCODES::POP)
      emit(OPCODES::JUMP, label_switch_end)

      @implicit_breaks << label_switch_end

      labels.length.times do |i|
        emit(OPCODES::LABEL, labels[i])
        consequents[i].each do |c|
          emit(c)
        end
      end
      @implicit_breaks.pop()

      emit(OPCODES::LABEL, label_switch_end)
    end

    def parseThisExpression(node)
      emit(OPCODES::LOAD_THIS)
    end

    def parseThrowStatement(argument, node)
      emit(OPCODES::POP)
      emit(argument)
      emit(OPCODES::THROW)
    end

    def parseTryStatement(block, handlers, finalizer, node)
      label_try = new_label()
      label_catch = new_label()
      label_finally = new_label()
      label_end = new_label()

      handler = handlers[0]

      catch_var_name = handler != nil ? handler[:param][:name] : nil

      emit(OPCODES::TRY_CATCH_FINALLY, label_try, label_catch, catch_var_name, label_finally, finalizer != nil, label_end)

      emit(OPCODES::LABEL, label_try)
      emit(OPCODES::LOAD_UNDEFINED)
      emit(block)
      emit(OPCODES::NOP)

      emit(OPCODES::LABEL, label_catch)
      emit(OPCODES::LOAD_UNDEFINED)
      if handler != nil
        emit(handler[:body])
      end
      emit(OPCODES::NOP)

      emit(OPCODES::LABEL, label_finally)
      emit(OPCODES::LOAD_UNDEFINED)
      if finalizer != nil
        emit(finalizer)
      end
      emit(OPCODES::NOP)

      emit(OPCODES::LABEL, label_end)

    end

    def parseUnaryExpression(operator, argument, node)
      if operator == 'typeof' && argument[:type] == 'Identifier'
        emit(OPCODES::TYPEOF, argument[:name])
      elsif operator == 'delete'
        if argument[:type] == 'MemberExpression'
          emit(argument[:object])
          if argument[:property][:type] == 'Identifier'
            emit(OPCODES::LOAD_STRING, argument[:property][:name])
          else
            emit(argument[:property])
          end
          emit(OPCODES::DELETE_MEMBER)
        elsif argument[:type] == 'Identifier'
          emit(OPCODES::DELETE, argument[:name])
        else
          emit(OPCODES::LOAD_BOOLEAN, true)
        end
      elsif ['+', '-', '!', '~', 'void', 'typeof'].include?(operator)
        emit(argument)
        emit(OPCODES::UNARY_OP, operator)
      else
        raise make_error('SyntaxError', \
                         "Unknown unary operator #{operator}")
      end
    end

    def parseUpdateExpression(operator, argument, prefix, node)
      incr = operator == '++'
      post = !prefix
      if argument[:type] == 'MemberExpression'
        if argument[:computed]
          emit(argument[:object])
          emit(argument[:property])
          emit(OPCODES::POSTFIX_MEMBER, post, incr)
        else
          emit(argument[:object])
          name = to_key(argument[:property])
          emit(OPCODES::POSTFIX_MEMBER_DOT, post, incr, name)
        end
      elsif argument[:type] == 'Identifier'
        name = to_key(argument)
        emit(OPCODES::POSTFIX, post, incr, name)
      else
        raise make_error('SyntaxError',
                        'Invalid left-hand side in assignment')
      end
    end

    def parseVariableDeclaration(declarations, kind, node)
      declarations.each do |d|
        emit(d)
      end
    end

    def parseLexicalDeclaration(declarations, kind, node)
      raise "'Not supported by ECMA 5.1"
    end

    def parseVariableDeclarator(id, init, node)
      name = id[:name]
      if ['true', 'false', 'this'].include?(name)
        raise make_error('SyntaxError',
          'Invalid left-hand side in assignment')
      end
      @declared_vars.push(name)
      if init != nil
        emit(init)
        emit(OPCODES::STORE, name)
        emit(OPCODES::POP)
      end
    end

    def parseWhileStatement(test, body, node)
      label_continue = new_label()
      label_break = new_label()

      emit(OPCODES::LABEL, label_continue)
      emit(test)
      emit(OPCODES::JUMP_IF_FALSE, label_break)

      @implicit_continues.append(label_continue)
      @implicit_breaks.append(label_break)
      emit(body)
      @implicit_continues.pop()
      @implicit_breaks.pop()

      emit(OPCODES::JUMP, label_continue)
      emit(OPCODES::LABEL, label_break)
    end

    def parseWithStatement(object, body, node)
      label_start = new_label()
      label_end = new_label()

      emit(body)

      emit(OPCODES::WITH, label_start, label_end)

      emit(OPCODES::LABEL, label_start)
      emit(OPCODES::LOAD_UNDEFINED)
      emit(body)
      emit(OPCODES::NOP)
      emit(OPCODES::LABEL, label_end)
    end

    def emit(target, *args)
      if target.is_a?(Class)
        @bytecodes.push(target.new(*args))
      elsif target.is_a?(Array)
        target.each do |i|
          emit(i)
        end
      else
        method_symbol = ('parse' + target[:type].to_s).to_sym
        send_method = method(method_symbol)
        args = send_method.parameters.map { |param| target[param[1]] }
        args[-1] = target
        send(method_symbol, *args)
      end
    end
  end
end