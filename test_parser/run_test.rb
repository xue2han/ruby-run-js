require_relative 'ruby_run_js/jsparser'
require 'json'

def main2
    parser = RubyRunJs::Parser.new
    r = parser.parse('0')
end

def main

    parser = RubyRunJs::Parser.new

    raw_content = File.read File.dirname(__FILE__) + '/test.json'

    test_content = JSON.parse(raw_content)

    total_num = 0
    passed_num = 0

    test_content.each do |subject,content|
        content.each do |code,expected|
            simplifyHash(expected)
            total_num += 1

            begin
                parsed_result = parser.parse(code,{:range => true,:loc => true,:raw => true})
            rescue => e
                if expected["message"] == e.message
                    passed_num += 1
                    next
                else
                    puts "Parsing Error: #{subject} -> '#{code}'"
                    raise e
                end
            end

            if expected['type'] != "Program"
                parsed_result = parsed_result[:body][0]
            end

            parsed_result = JSON.parse JSON.generate parsed_result

            begin
                compare(expected,parsed_result)
                passed_num += 1
            rescue => e
                puts "Find parsing error: #{e.to_s}"
                puts "Under: #{subject} -> '#{code}'"
                puts "Expected: #{JSON.pretty_generate(expected)}"
                puts "But Got: #{JSON.pretty_generate(parsed_result)}"
            end
        end
    end

    puts "test passed: #{passed_num}/#{total_num}"
end

def simplifyHash(obj)
    if obj.is_a? Hash
        obj.each_key do |k|
            if %w(range loc tokens comments).include? k
                obj.delete(k)
            else
                simplifyHash(obj[k])
            end
        end
    elsif obj.is_a? Array
        obj.each {|v| simplifyHash(v)}
    end
end


def compare(obj1,obj2)

    case obj1
    when Hash
        obj1.each do |key,value|
            unless obj2.has_key?(key)
                raise "expected to have key: #{key}"
            end
            compare(obj1[key],obj2[key])
        end
        return
    when Array
        unless obj1.length == obj2.length
            raise "expected to have #{obj1.length} elements,but got: #{obj2.length}"
        end
        obj1.length.times do |i|
            compare(obj1[i],obj2[i])
        end
        return
    end

    unless obj1 == obj2
        raise "#{obj1} != #{obj2}"
    end
end

main()

