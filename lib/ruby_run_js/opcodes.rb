require 'set'

module RubyRunJs
  module OPCODES

    extend Helper
  
    class OP_CODE

      include Helper
      include Operation

      def to_s
        vars = instance_variables.map { |v| instance_variable_get(v) }
        self.class.name.split('::')[2] + '(' + vars.join(',') + ')'
      end

      # @return nil means the interpreter should just execute the next code
      # @return [Int] means the interpreter should jump to label
      # @return [Scope, function_label] means the interpreter should call the function with the context
      # @return :Return means the js function should be returned
      def eval(ctx)
      end

    end

    
    class NOP < OP_CODE
      def eval(ctx)
      end
    end


    class UNARY_OP < OP_CODE

      def initialize(operator)
        @operator = operator
      end

      def eval(ctx)
        val = ctx.stack.pop()
        ctx.stack.append(unary_operation(@operator, val))
        nil
      end
    end


  # special unary operations


    class TYPEOF < OP_CODE

      def initialize(identifier)
          @identifier = identifier
      end

      def eval(ctx)
        # typeof something_undefined  does not throw reference error
        val = ctx.get_binding_value(@identifier, false)
        ctx.stack.append(typeof_uop(val))
        nil
      end
    end
      


    class POSTFIX < OP_CODE
        
      def initialize(post, incr, identifier)
        @identifier = identifier
        @cb = incr ? 1 : -1
        @ca = post ? -@cb : 0
      end

      def eval(ctx)
        target = to_number(ctx.get_binding_value(@identifier)) + @cb
        ctx.set_binding(@identifier, target)
        ctx.stack.append(target + @ca)
        nil
      end
    end


    class POSTFIX_MEMBER < OP_CODE

      def initialize(post, incr)
        @cb = incr ? 1 : -1
        @ca = post ? -@cb : 0
      end

      def eval(ctx)
        name = ctx.stack.pop()
        left = ctx.stack.pop()

        target = to_number(get_member(left, name, ctx.builtin)) + @cb
        if left.js_type == :Object
          left.put(name, target)
        end

        ctx.stack.append(target + @ca)
        nil
       end
    end
        


    class POSTFIX_MEMBER_DOT < OP_CODE

      def initialize(post, incr, prop)
        @cb = incr ? 1 : -1
        @ca = post ? -@cb : 0
        @prop = prop
      end

      def eval(ctx)
        left = ctx.stack.pop()

        target = to_number(get_member_dot(left, @prop, ctx.builtin)) + @cb
        if left.js_type == :Object
        left.put(@prop, target)
        end

        ctx.stack.append(target + @ca)
        nil
       end
    end


    class DELETE < OP_CODE

      def initialize(name)
        @name = name
      end

      def eval(ctx)
        ctx.stack.append(ctx.delete(@name))
        nil
      end

    end


    class DELETE_MEMBER < OP_CODE
      def eval(ctx)
        prop = to_string(ctx.stack.pop())
        obj = to_object(ctx.stack.pop(), ctx.builtin)
        ctx.stack.append(obj.delete(prop, false))
        nil
      end
    end


  # --------------------- BITWISE ----------------------


    class BINARY_OP < OP_CODE

      def initialize(operator)
        @operator = operator
      end

      def eval(ctx)
        right = ctx.stack.pop()
        left = ctx.stack.pop()
        ctx.stack.append(binary_operation(@operator, left, right))
        nil
      end
    end


  # &&, || and conditional are implemented in bytecode

  # --------------------- JUMPS ----------------------


  # simple label that will be removed from code after compilation. labels ID will be translated
  # to source code position.
    class LABEL < OP_CODE

      attr_reader :num

      def initialize(num)
        @num = num
      end
    end

  # I implemented interpreter in the way that when an integer is returned by eval operation the execution will jump
  # to the location of the label (it is loc = label_locations[label])


    class BASE_JUMP < OP_CODE

      def initialize(label)
        @label = label
      end

    end


    class JUMP < BASE_JUMP
      def eval(ctx)
        @label
      end
    end


    class JUMP_IF_TRUE < BASE_JUMP
      def eval(ctx)
        val = ctx.stack.pop()
        if to_boolean(val)
          return @label
        end
      end
    end


    class JUMP_IF_EQ < BASE_JUMP
      # this one is used in switch statement - compares last 2 values using === operator and jumps popping both if true else pops last.
      def eval(ctx)
        cmp = ctx.stack.pop()
        if strict_equality_op(ctx.stack[-1], cmp)
          ctx.stack.pop()
          return @label
        end
      end
    end


    class JUMP_IF_TRUE_WITHOUT_POP < BASE_JUMP
      def eval(ctx)
        val = ctx.stack[-1]
        if to_boolean(val)
          return @label
        end
      end
    end



    class JUMP_IF_FALSE < BASE_JUMP
      def eval(ctx)
        val = ctx.stack.pop()
        if not to_boolean(val)
          return @label
        end
      end
    end


    class JUMP_IF_FALSE_WITHOUT_POP < BASE_JUMP

      def eval(ctx)
        val = ctx.stack[-1]
        unless to_boolean(val)
          return @label
        end
      end
    end


    class POP < OP_CODE
      def eval(ctx)
        ctx.stack.pop
        nil
      end
    end


  # class REDUCE < OP_CODE
  #     def eval(ctx)
  #         assert len(ctx.stack)==2
  #         ctx.stack[0] = ctx.stack[1]
  #         del ctx.stack[1]

  # --------------- LOADING --------------


    class LOAD_NONE < OP_CODE  # be careful with this :)

      def eval(ctx)
        ctx.stack.append(nil)
        nil
      end
    end


  class LOAD_N_TUPLE < OP_CODE
      # loads the tuple composed of n last elements on stack. elements are popped.

      def initialize(n)
        @n = n
      end

      def eval(ctx)
        tup = ctx.stack.pop(@n)
        ctx.stack.append(tup)
        nil
      end
    end

   class LOAD_UNDEFINED < OP_CODE
      def eval(ctx)
        ctx.stack.append(undefined)
        nil
      end
    end


    class LOAD_NULL < OP_CODE
      def eval(ctx)
        ctx.stack.append(null)
        nil
      end
    end


    class LOAD_BOOLEAN < OP_CODE

      def initialize(val)
        @val = to_boolean(val)
      end

      def eval(ctx)
        ctx.stack.append(@val)
        nil
      end
    end


    class LOAD_STRING < OP_CODE

      def initialize(val)
        @val = to_string(val)
      end

      def eval(ctx)
        ctx.stack.append(@val)
        nil
      end
    end


    class LOAD_NUMBER < OP_CODE
      def initialize(val)
        @val = val.to_f
      end

      def eval(ctx)
        ctx.stack.append(@val)
        nil
      end
    end


    class LOAD_REGEXP < OP_CODE
      def initialize(body, flags)
        @body = body
        @flags = flags
      end

      def eval(ctx)
        ctx.stack.append(ctx.builtin.new_regexp(@body, @flags))
        nil
      end
    end


    class LOAD_FUNCTION < OP_CODE

      def initialize(start, params, name, is_declaration, definitions)
        @start = start  # its an ID of label pointing to the beginning of the function bytecode
        @params = params
        @name = name
        @is_declaration = is_declaration
        @definitions = (definitions + params).to_set.to_a
      end

      def eval(ctx)
        ctx.stack.push(
            ctx.builtin.new_function(
                @start, ctx, @params, @name, @is_declaration, @definitions))
        nil
      end
    end


    class LOAD_OBJECT < OP_CODE
      # props are string pairs (prop_name, kind) kind can be either i, g or s. (init, get, set)

      def initialize(props)
        @props = props
      end

      def eval(ctx)
        obj = ctx.builtin.new_object()
        if @props.length > 0
          obj.init_with_props(@props, ctx.stack.pop(@props.length))
        end
        ctx.stack.append(obj)
        nil
      end
    end


    class LOAD_ARRAY < OP_CODE

      def initialize(num)
        @num = num
      end

      def eval(ctx)
        arr = @num > 0 ? ctx.builtin.new_array_with_items(ctx.stack.pop(@num)) : ctx.builtin.new_array()
        ctx.stack.append(arr)
        nil
      end
    end
        


    class LOAD_THIS < OP_CODE
      def eval(ctx)
        ctx.stack.append(ctx.this_binding)
        nil
      end
    end


    class LOAD < OP_CODE  # todo check!

      def initialize(identifier)
        @identifier = identifier
      end

      # 11.1.2
      def eval(ctx)
        ctx.stack.append(ctx.get_binding_value(@identifier, true))
        nil
      end
    end


    class LOAD_MEMBER < OP_CODE
      def eval(ctx)
        prop = ctx.stack.pop()
        obj = ctx.stack.pop()
        ctx.stack.append(get_member(obj, prop, ctx.builtin))
        nil
      end
    end


    class LOAD_MEMBER_DOT < OP_CODE

      def initialize(prop)
        @prop = prop
      end

      def eval(ctx)
        obj = ctx.stack.pop()
        ctx.stack.append(get_member_dot(obj, @prop, ctx.builtin))
        nil
      end
    end


  # --------------- STORING --------------


    class STORE < OP_CODE

      def initialize(identifier)
        @identifier = identifier
      end

      def eval(ctx)
        value = ctx.stack[-1]  # don't pop
        ctx.set_binding(@identifier, value)
        nil
      end
    end


    class STORE_MEMBER < OP_CODE
      def eval(ctx)
        value = ctx.stack.pop()
        name = ctx.stack.pop()
        left = ctx.stack.pop()

        name = to_string(name)

        if is_primitive(left)
          if left.js_type == :Null
              raise make_error('TypeError',
                              "Cannot set property '#{name}' of null")
          elsif left.js_type == :Undefined
              raise make_error('TypeError',
                              "Cannot set property '#{name}' of undefined")
          end
          # just ignore...
        else
          left.put(name, value)
        end
        ctx.stack.append(value)
        nil
      end
    end
        


    class STORE_MEMBER_DOT < OP_CODE

      def initialize(prop)
        @prop = prop
      end

      def eval(ctx)
        value = ctx.stack.pop()
        left = ctx.stack.pop()

        if is_primitive(left)
          if left.js_type == :Null
              raise make_error('TypeError',
                              "Cannot set property '#{@prop}' of null")
          elsif left.js_type == :Undefined
              raise make_error('TypeError',
                              "Cannot set property '#{@prop}' of undefined")
          end
          # just ignore...
        else
          left.put(@prop, value)
        end
        ctx.stack.append(value)
        nil
      end
    end


    class STORE_OP < OP_CODE

      def initialize(identifier, op)
        @identifier = identifier
        @op = op
      end

      def eval(ctx)
        value = ctx.stack.pop()
        new_value = binary_operation(@op, ctx.get_binding_value(@identifier), value)
        ctx.set_binding(@identifier, new_value)
        ctx.stack.append(new_value)
        nil
      end

    end


    class STORE_MEMBER_OP < OP_CODE
      
      def initialize(op)
        @op = op
      end

      def eval(ctx)
        value = ctx.stack.pop()
        name = ctx.stack.pop()
        left = ctx.stack.pop()

        if is_primitive(left)
          if left.js_type == :Null
              raise make_error('TypeError',
                              "Cannot set property '#{name}' of null")
          elsif left.js_type == :Undefined
              raise make_error('TypeError',
                              "Cannot set property '#{name}' of undefined")
          end
          ctx.stack.append(binary_operation(@op, get_member(left, name, ctx.builtin), value))
        else
          ctx.stack.append(binary_operation(@op, get_member(left, name, ctx.builtin), value))
          left.put(name, ctx.stack[-1])
        end
        nil
      end
    end


    class STORE_MEMBER_DOT_OP < OP_CODE

      def initialize(prop, op)
        @prop = prop
        @op = op
      end

      def eval(ctx)
        value = ctx.stack.pop()
        left = ctx.stack.pop()

        if is_primitive(left)
          if left.js_type == :Null
              raise make_error('TypeError',
                              "Cannot set property '#{@prop}' of null")
          elsif left.js_type == :Undefined
              raise make_error('TypeError',
                              "Cannot set property '#{@prop}' of undefined")
          end
          ctx.stack.append(binary_operation(@op, get_member(left, @prop, ctx.builtin), value))
        else
          ctx.stack.append(binary_operation(@op, get_member(left, @prop, ctx.builtin), value))
          left.put(@prop, ctx.stack[-1])
        end
        nil
      end
    end

  # --------------- CALLS --------------

    def self.bytecode_call(ctx, func, this, args)
      if func.js_class != 'Function'
        raise make_error('TypeError', "#{func.js_class} is not a function")
      end
      if func.is_native  # call to built-in function or method
        ctx.stack.append(func.call(this, args))
        return nil
      end
      # therefore not native. we have to return [new_context, function_label] to instruct interpreter to call
      return func.generate_my_scope(this, args), func.code
    end

    class CALL < OP_CODE
      def eval(ctx)
        args = ctx.stack.pop()
        func = ctx.stack.pop()
        return OPCODES.bytecode_call(ctx, func, ctx.builtin.global, args)
      end
    end


    class CALL_METHOD < OP_CODE
      def eval(ctx)
        args = ctx.stack.pop()
        prop = ctx.stack.pop()
        base = ctx.stack.pop()

        func = get_member(base, prop, ctx.builtin)

        return OPCODES.bytecode_call(ctx, func, base, args)
      end
    end


    class CALL_METHOD_DOT < OP_CODE

      def initialize(prop)
        @prop = prop
      end

      def eval(ctx)
        args = ctx.stack.pop()
        base = ctx.stack.pop()

        func = get_member_dot(base, @prop, ctx.builtin)

        return OPCODES.bytecode_call(ctx, func, base, args)
      end
    end


    class CALL_NO_ARGS < OP_CODE
      def eval(ctx)
        func = ctx.stack.pop()
        return OPCODES.bytecode_call(ctx, func, ctx.builtin.global, [])
      end
    end



    class CALL_METHOD_NO_ARGS < OP_CODE
      def eval(ctx)
        prop = ctx.stack.pop()
        base = ctx.stack.pop()

        func = get_member(base, prop, ctx.builtin)

        return OPCODES.bytecode_call(ctx, func, base, [])
      end
    end


    class CALL_METHOD_DOT_NO_ARGS < OP_CODE
      def initialize(prop)
        @prop = prop
      end

      def eval(ctx)
        base = ctx.stack.pop()
        func = get_member_dot(base, @prop, ctx.builtin)

        return OPCODES.bytecode_call(ctx, func, base, [])
      end
    end


    class NOP < OP_CODE
      def eval(ctx)
      end
    end


    class RETURN < OP_CODE

      def eval(ctx)  # remember to load the return value on stack before using RETURN op.
        return :Return
      end
    end

    class NEW < OP_CODE
      def eval(ctx)
        args = ctx.stack.pop()
        constructor = ctx.stack.pop()
        if is_primitive(constructor) || !constructor.methods.include?(:construct)
          raise make_error('TypeError',
                            "#{constructor.js_class} is not a constructor")
        end
        ctx.stack.append(constructor.construct(args))
        nil
      end
    end


    class NEW_NO_ARGS < OP_CODE
      def eval(ctx)
        constructor = ctx.stack.pop()
        if is_primitive(constructor) || !constructor.methods.include?(:construct)
          raise make_error('TypeError',
                            "#{constructor.js_class} is not a constructor")
        end
        ctx.stack.append(constructor.construct([]))
        nil
      end
    end


  # --------------- EXCEPTIONS --------------

    class THROW < OP_CODE
      def eval(ctx)
        raise make_error(nil, nil, ctx.stack.pop())
      end
    end

    class TRY_CATCH_FINALLY < OP_CODE
      def initialize(label_try, label_catch, catch_var_name, label_finally,
                  has_finally, label_end)
        @label_try = label_try
        @label_catch = label_catch
        @catch_var_name = catch_var_name
        @label_finally = label_finally
        @has_finally = has_finally
        @label_end = label_end
      end

      # @return [status, value]
      # status = 0 : normal
      # status = 1 : return
      # status = 2 : jump out
      # status = 3 : error
      def eval(ctx)
        
        ctx.stack.pop()

        # execute try statement
        try_status = ctx.builtin.executor.run_under_control(
            ctx, @label_try, @label_catch)

        errors = try_status[0] == 3

        # catch
        if errors and @catch_var_name != nil
          # generate catch block context...
          catch_scope = LocalScope.new(ctx, ctx.builtin)
          js_error = try_status[1].throw_value.nil? ? ctx.builtin.new_error(try_status[1].type, try_status[1].msg) : try_status[1].throw_value
          catch_scope.own[@catch_var_name] = js_error
          catch_scope.this_binding = ctx.this_binding
          catch_status = ctx.builtin.executor.run_under_control(
            catch_scope, @label_catch, @label_finally)
        else
          catch_status = nil
        end

        # finally
        if @has_finally
          finally_status = ctx.builtin.executor.run_under_control(
              ctx, @label_finally, @label_end)
        else
          finally_status = nil
        end

        # now return controls
        other_status = catch_status || try_status
        if finally_status == nil || (finally_status[0] == 0 \
                                      && other_status[0] != 0)
          winning_status = other_status
        else
          winning_status = finally_status
        end

        type, return_value, label = winning_status
        if type == 0  # normal
          ctx.stack.append(return_value)
          return @label_end
        elsif type == 1  # return
          ctx.stack.append(return_value)
          return :Return  # send return signal
        elsif type == 2  # jump outside
          ctx.stack.append(return_value)
          return label
        elsif type == 3
            # throw is made with empty stack as usual
          raise return_value
        else
          raise "Unexpected Type: #{type}"
        end
      end
    end

  # ------------ WITH + ITERATORS ----------


    class WITH < OP_CODE
      
      def initialize(label_start, label_end)
        @label_start = label_start
        @label_end = label_end
      end

      def eval(ctx)
        obj = to_object(ctx.stack.pop(), ctx.builtin)

        scope = ObjectScope.new(obj, ctx, ctx.builtin)

        scope.this_binding = ctx.this_binding
        status = ctx.builtin.executor.run_under_control( \
            scope, @label_start, @label_end)

        ctx.stack.pop()

        type, return_value, label = status
        if type == 0  # normal
          ctx.stack.append(return_value)
          return nil
        elsif type == 1  # return
          ctx.stack.append(return_value)
          return :Return  # send return signal
        elsif type == 2  # jump outside
          ctx.stack.append(return_value)
          return label
        elsif type == 3
            # throw is made with empty stack as usual
          raise return_value
        else
          raise "Unexpected Type: #{type}"
        end
      end
    end
  


    class FOR_IN < OP_CODE
      def initialize(name, label_start, label_continue, label_break)
        @name = name
        @label_start = label_start
        @label_continue = label_continue
        @label_break = label_break
      end

      def eval(ctx)
        iterable = ctx.stack.pop()
        if iterable == null || iterable == undefined
          ctx.stack.pop()
          ctx.stack.append(undefined)
          return @label_break
        end

        obj = to_object(iterable, ctx.builtin)

        obj.own.keys.sort.each do |k|
          unless obj.own[k]['enumerable']
            next
          end

          ctx.set_binding(@name, k)

          status = ctx.builtin.executor.run_under_control(\
            ctx, @label_start, @label_break)

          ctx.stack.pop()

          type, return_value, label = status
          if type == 0  # normal
            ctx.stack.append(return_value)
            return nil
          elsif type == 1  # return
            ctx.stack.append(return_value)
            return :Return  # send return signal
          elsif type == 2  # jump outside
            ctx.stack.append(return_value)
            if label == @label_continue
              next
            end
            return label
          elsif type == 3
            raise return_value
          else
            raise "Unexpected Type: #{type}"
          end
        end

        return @label_break
      end
    end
  end
end