require "bundler/setup"
require 'ruby_run_js'
require 'timeout'
require 'parallel'

class TestCase

  INCLUDE_PATH = 'includes/'


  attr_reader :strict_only, :passed

  def initialize(path, init_code)
    @path = path

    @meta_infos = {
      'description' => nil,
      'includes' => [],
      'author' => nil,
      'es5id' => nil,
      'negative' => nil,
      'info' => nil,
      'flags' => []
    }

    @raw_content = File.read(@path, :encoding => "UTF-8")

    parse_info()

    @meta_infos['includes'].each do |include|
      init_code += File.read(File.expand_path('../includes/' + include, __FILE__))
    end

    @strict_only = @meta_infos['flags'].include?('onlyStrict')

    @code = init_code + @raw_content
  end


  def parse_info
    raw_info = @raw_content.match(/\*---(.+)---\*/m)[1]
    key = nil
    value = nil
    raw_info += '\nEND:'
    raw_info.each_line do |line|
      if line == '' 
        next
      end
      if line.start_with?('  ')
        if key.nil?
          raise "Could not parse test case info: #{@path}"
        end
        value += "\n" + line
      elsif line == 'onlyStrict'
        @strict_only = true
      else
        if key != nil
          key = key.strip
          if key == 'flags' || key == 'includes'
            value = split_content(value)
          end
          @meta_infos[key] = value
        end
        key, value = line.split(':')
        value = value.nil? ? '' : value
        value = value.tr(">", '').strip
      end
    end
  end

  def split_content(content)
    result = []
    content.each_line do |line|
      line = line.tr("\n[] -", '')
      if line != ''
        line.split(',').each do |e|
          result.push(e.strip)
        end
      end
    end
    result
  end

  def to_s
    index = @path.rindex('test_cases/') + 'test_cases/'.length
    info = @path[index..]
    if @passed
      info += ' Passed'
    else
      info += ' ' + @run_result.to_s
    end

    if @reason
      info += ' ' + @reason
    end

    info
  end

  def run_case()
    result = [false, :Timeout, 'Timeout']
    thread = Thread.new do
      result = _run_case()
    end
    lastTime = Time.now
    while thread.alive? && Time.now - lastTime < 5
      sleep(0.1)
    end
    if thread.alive?
      thread.exit
    end

    @passed, @run_result, @reason = result
  end

  def _run_case()
    # :Passed, :Failed, :Crashed, :Timeout
    run_result = nil
    reason = nil
    passed = true

    begin
      RubyRunJs::Interpreter.run(@code)
    rescue RubyRunJs::JsException => e
      if @meta_infos['negative']
        passed = true
      else
        passed = false
        if e.throw_value.nil?
          reason = e.to_s
        else
          reason = e.throw_value.get('message')
          reason = (reason == null || reason == undefined) ? '' : reason
        end
        
        backtrace = e.backtrace.join("\n")
        run_result = :Failed
      end
    rescue SyntaxError => e
      if @meta_infos['negative'] == 'SyntaxError'
        passed = true
      else
        passed = false
        reason = e.to_s
        backtrace = e.backtrace.join("\n")
        reason += "\n" + backtrace
        run_result = :Crash
      end
    rescue Timeout::Error => e
      passed = false
      reason = "Timeout"
      run_result = :Timeout
    rescue => e
      passed = false
      reason = e.to_s
      backtrace = e.backtrace.join("\n")
      reason += "\n" + backtrace
      run_result = :Crash
    end

    if passed
      run_result = :Passed
    end

    [passed, run_result, reason]
  end
end



def test_all(path)
  init_code = File.read(File.expand_path('../includes/init.js', path))

  js_full_paths = Dir.glob(File.join('**', '*.js'), base: path).sort.map { |js_path| File.join(path, js_path) }

  out_file_path = File.expand_path('../testout.txt', path)

  File.delete(out_file_path)

  Parallel.each(js_full_paths) do |js_path|
    begin
      test = TestCase.new(js_path, init_code)

      if test.strict_only
        next
      end
      test.run_case()
    rescue => e
      raise "Error when test #{js_path}: " + e.to_s
    end

    File.write(out_file_path, test.to_s + "\n", :mode => 'a')
  end
end

def test_one(dir_path, js_path)
  full_path = File.join(dir_path, js_path)
  init_code = File.read(File.expand_path('../includes/init.js', dir_path))

  begin
    test = TestCase.new(full_path, init_code)

    if test.strict_only
      return
    end
    test.run_case()
  rescue => e
    raise "Error when test #{js_path}: " + e.to_s
  end
end

test_all(File.expand_path('../test_cases', __FILE__))
#test_one(File.expand_path('../test_cases', __FILE__), 'built-ins/Array/isArray/15.4.3.2-1-15.js')