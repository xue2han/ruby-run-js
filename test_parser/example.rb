require_relative '../lib/ruby_run_js/jsparser'

parser = RubyRunJs::Parser.new
raw_content = File.read File.dirname(__FILE__) + '/example.js'
puts parser.parse(raw_content)