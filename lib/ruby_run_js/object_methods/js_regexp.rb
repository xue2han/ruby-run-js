# frozen_string_literal: true

require 'set'

module RubyRunJs
  module JsRegExpMethods
    extend Helper

    class << self
      def constructor(builtin, this, pattern, flags)
        if pattern.js_class == 'RegExp' && flags == undefined
          return pattern
        end
        constructor_new(builtin, this, pattern, flags)
      end

      def constructor_new(builtin, this, pattern, flags)
        if pattern.js_class == 'RegExp' && flags == undefined
          return pattern
        elsif pattern.js_class == 'RegExp' && flags != undefined
          raise make_error('TypeError', 'cannot construct RegExp with RegExp and flags')
        else
          pattern = pattern == undefined ? '' : to_string(pattern)
          flags = flags == undefined ? '' : to_string(flags)
        end

        flags.each_char do |c| 
          unless 'gim'.include?(c)
            raise make_error('SyntaxError', "Invalid flags supplied to RegExp constructor #{flags}")
          end
        end

        if flags.chars.to_set.length != flags.length
          raise make_error('SyntaxError', "Invalid flags supplied to RegExp constructor #{flags}")
        end

        builtin.new_regexp(pattern, flags)
      end

      def prototype_exec(builtin, this, string)
        check_regexp(this)
        str = to_string(string)
        length = str.length
        last_index = this.get('lastIndex')
        i = to_integer(last_index)
        global = this.get('global')
        unless global
          i = 0
        end
        match_succeeded = false
        while !match_succeeded
          if i < 0 || i > length
            this.put('lastIndex', 0.0, true)
            return null
          end
          match_data = this.pattern.match(str, i)
          if match_data.nil?
            i += 1
          else
            match_succeeded = true
          end
        end
        e = match_data.end(0)
        if global
          this.put('lastIndex', e, true)
        end
        captures = match_data.captures
        result = builtin.new_array_with_items(captures)
        result.put('index', match_data.begin(0).to_f)
        result.put('input', str)
        result
      end

      def prototype_test(builtin, this, string)
        result = prototype_exec(builtin, this, string)
        result != null
      end

      def check_regexp(obj)
        unless this.js_type == :Object && this.js_class == 'RegExp'
          raise make_error('TypeError', 'Called on non-regexp object')
        end
      end

      def prototype_toString(builtin, this)
        check_regexp(this)
        flags = ''
        if this.flag_global
          flags += 'g'
        end
        if this.flag_ignore_case
          flags += 'i'
        end
        if this.flag_multiline
          flags += 'm'
        end
        v = this.body == '' ? '(?:)' : this.body
        "/#{v}/#{flags}"
      end

    end
  end
end