module RubyRunJs
  class ByteCodeExecutor

    attr_reader :codes

    def initialize()
      @label2loc = {}
      @codes = []
      @scopes = []
      @func_return_locs = []
    end

    def compile(bytecodes)
      i = 0
      length = bytecodes.length
      while i < length
        code = bytecodes[i]
        if code.is_a?(OPCODES::LABEL)
          @label2loc[code.num] = @codes.length
        else
          @codes.push(code)
        end
        i += 1
      end
    end

    def print_stack(stack)
      puts 'Stack after execute :'
      stack.each do |v|
        if v.is_a?(Array)
          puts "[#{v.map(&:to_s).join(',')}]"
        else
          puts v
        end
      end
      puts ''
    end

    def run(ctx, start_loc = 0, debug = false)
      @debug = debug
      loc = start_loc
      @current_ctx = ctx
      while loc < @codes.length
        if @debug
          puts 'Will execute: ' + @codes[loc].to_s
        end
        status = @codes[loc].eval(ctx)

        if @debug
          print_stack(ctx.stack)
        end
        if status != nil
          if status.is_a?(Integer)
            loc = @label2loc[status]
          elsif status == :Return
            return_value = ctx.stack.pop()
            ctx = @scopes.pop()
            @current_ctx = ctx
            ctx.stack.push(return_value)
            loc = @func_return_locs.pop()
          elsif status.length == 2
            @scopes.push(ctx)
            @func_return_locs.push(loc + 1)

            loc = @label2loc[status[1]]
            ctx = status[0]
            @current_ctx = ctx
          end
          next
        end

        loc += 1
      end

      if ctx.stack.length != 1
       # raise "Inernal Error: There must be exactly one value on
       #        the top of stack when codes run done " 
      end

      ctx.stack.pop
    end

    # @return [status, value]
    # status = 0 : normal
    # status = 1 : return
    # status = 2 : jump out
    # status = 3 : error
    def run_under_control(ctx, label_start, label_end)
      old_stack_length = ctx.stack.length
      old_ret_length = @func_return_locs.length
      old_scope_length = @scopes.length

      begin
        return _run_under_control(ctx, label_start, label_end)
      rescue JsException => e
        ctx.stack.pop([ctx.stack.length - old_stack_length, 0].max)
        @func_return_locs.pop([@func_return_locs.length - old_ret_length, 0].max)
        @scopes.pop([@scopes.length - old_scope_length, 0].max)

        return [3, e]
      else
        if old_stack_length != ctx.stack.length
          raise "Stack must be not changed after calling run_under_control"
        end
      end

    end

    def _run_under_control(ctx, label_start, label_end)

      loc_start = @label2loc[label_start]
      loc_end = @label2loc[label_end]
      loc = loc_start

      entry_scope = @scopes.length
      stack_length = ctx.stack.length

      if @debug
        puts "Stack when enter run_under_control: "
        print_stack(ctx.stack)
      end

      while loc < @codes.length || @codes.length == loc_end
        if loc >= loc_end && @scopes.length == entry_scope
          if loc != loc_end
            raise "run_under_control must exit from label_end"
          end
          if ctx.stack.length - stack_length != 1
            raise "Stack must have exactly one value when run_under_control exits"
          end
          return [0, ctx.stack.pop]
        end

        if @debug
          puts 'Will execute: ' + @codes[loc].to_s
        end

        status = @codes[loc].eval(ctx)

        if @debug
          print_stack(ctx.stack)
        end

        if status != nil
          if status.is_a?(Integer)
            loc = @label2loc[status]
            if @scopes.length == entry_scope
              if loc < loc_start || loc >= loc_end
                if ctx.stack.length - stack_length != 1
                  if @debug
                    puts "Stack when exit run_under_control: "
                    print_stack(ctx.stack)
                  end
                  raise "Stack must have exactly one value when run_under_control exits"
                end
                return [2, ctx.stack.pop, status]
              end
            end
          elsif status == :Return
            if @scopes.length == entry_scope
              if ctx.stack.length - stack_length != 1
                raise "Stack must have exactly one value when run_under_control exits"
              end
              return [1, ctx.stack.pop]
            end
            return_value = ctx.stack.pop()
            ctx = @scopes.pop()
            @current_ctx = ctx
            ctx.stack.push(return_value)
            loc = @func_return_locs.pop()
          elsif status.length == 2
            @scopes.push(ctx)
            @func_return_locs.push(loc + 1)

            loc = @label2loc[status[1]]
            ctx = status[0]
            @current_ctx = ctx
          end
          next
        end
        loc += 1
      end
      raise 'internal error - unexpected end of code, will crash'
    end

    def call_js_func(func, this, args)
      if func.is_native
        raise "func is native when call_js_func"
      end
      old_scopes = @scopes
      old_return_locs = @func_return_locs

      ctx = func.generate_my_scope(this, args)

      @scopes = [LocalScope.new(nil, nil)]
      @func_return_locs = [@codes.length]

      return_value = run(ctx, @label2loc[func.code], @debug)

      @scopes = old_scopes
      @func_return_locs = old_return_locs

      return_value
    end

  end
end