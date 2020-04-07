require "bundler/setup"
require "ruby_run_js"

js_code = File.read(File.expand_path('../one_test.js', __FILE__))

def run(js_code)
  RubyRunJs::Interpreter.run(js_code, true)
end

run(js_code)