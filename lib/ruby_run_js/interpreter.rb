module RubyRunJs
  class Interpreter
    
    class << self
      def run(js_code, debug = false)
        Interpreter.new.run(js_code, debug)
      end
    end

    def initialize
      @parser = Parser.new()
      @generator = ByteCodeGenerator.new
      @exe = ByteCodeExecutor.new
      @builtin = BuiltInContext.new
      @builtin.executor = @exe
      @builtin.interpreter = self
    end

    def run(js_code, debug = false)
      @debug = debug
      ast = @parser.parse(js_code)
      @generator.emit(ast)
      ori_code_count = @exe.codes.length

      output_code = @generator.output_code

      if debug
        puts "Generate Bytecodes: ----"
        output_code.each do |c|
          puts c.to_s
        end
        puts '----'
      end

      @exe.compile(output_code)
      @exe.run(@builtin.global, ori_code_count, debug)
    end

    def build_js_func_in_runtime(func_param_str, func_body_str)
      func_code = "(function (#{func_param_str}) { ; #{func_body_str} ; });"
      ast = @parser.parse(func_code)
      @generator.emit(ast)
      bytecodes = @generator.output_code

      label_start = @generator.new_label()
      label_end = @generator.new_label()

      bytecodes.unshift(OPCODES::JUMP.new(label_end), OPCODES::LABEL.new(label_start))

      bytecodes.push(OPCODES::NOP.new())
      bytecodes.push(OPCODES::LABEL.new(label_end))
      bytecodes.push(OPCODES::NOP.new())

      if @debug
        puts "Generate Bytecodes in build_js_func_in_runtime:"
        bytecodes.each do |c|
          puts c.to_s
        end
        puts '----'
      end

      @exe.compile(bytecodes)

      _, func = @exe.run_under_control(@builtin.global, label_start, label_end)
      func
   end

    def current_value
      val = @builtin.global.stack.last
      val.nil? ? undefined : val
    end

    def current_stack
      @builtin.global.stack
    end

  end
end