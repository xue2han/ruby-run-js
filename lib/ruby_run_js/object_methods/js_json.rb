# frozen_string_literal: true

require 'json'

module RubyRunJs
  module JsJsonMethods
    extend Helper

    class << self

      def constructor_parse(builtin, this, str, reviver)
        begin
          obj = JSON.parse(str)
        rescue
          raise make_error('SyntaxError', 'JSON.parse could not parse JSON string - Invalid syntax')
        end
        unfiltered = convert_to_js_type(builtin, obj)

        if is_callable(reviver)
          result = builtin.new_object()
          result.put('': unfiltered)
          return _walk(result, '', reviver)
        else
          return unfiltered
        end
      end

      def constructor_stringify(builtin, this, value, replacer, space)
        stack = []
        @indent = ''
        property_list = undefined
        replacer_function = undefined
        if replacer.js_type == :Object
          if is_callable(replacer)
            replacer_function = replacer
          elsif replacer.js_class == 'Array'
            property_list = []
            replacer.get_items.each do |v|
              item = undefined
              if v.js_type == :String
                item = v
              elsif v.js_type == :Number
                item = to_string(v)
              elsif v.js_type == :Object
                if v.js_class == 'String' || v.js_class == 'Number'
                  item = to_string(v)
                end
              end
              if item != undefined && !property_list.include?(item)
                property_list << item
              end
            end
          end
        end
        if space.js_type == :Object
          if space.js_class == 'Number'
            space = to_number(space)
          elsif space.js_class == 'String'
            space = to_string(space)
          end
        end

        if space.js_type == :Number
          space = [10, to_integer(space)].min
          gap = ' ' * [0, space].max
        elsif space.js_type == :String
          gap = space.length <= 10 ? space : space[0...10]
        else
          gap = ''
        end

        wrapper = builtin.new_object()
        wrapper.put('', value)
        _str('', wrapper, replacer_function, stack, gap, property_list, space)
      end

      def _walk(holder, name, reviver)
        val = holder.get(name)
        if val.js_type == :Object
          if val.js_class == 'Array'
            i = 0
            len = val.get('length')
            while i < len
              new_element = _walk(val, i.to_s, reviver)
              if new_element == undefined
                val.delete(i.to_s, false)
              else
                val.put(i.to_s, new_element)
              end
              i += 1
            end
          else
            keys = val.own.keys.filter { |k| val.own[k]['enumerable'] }
            keys.each do |key|
              new_element = _walk(val, key, reviver)
              if new_element == undefined
                val.delete(key, false)
              else
                val.put(key, new_element)
              end
            end
          end
        end
        return reviver.call(holder, [name, val])
      end

      def _str(key, holder, replacer_function, stack, gap, property_list, space)
        value = holder.get(key)
        if value.js_type == :Object
          toJSON = value.get('toJSON')
          if is_callable(toJSON)
            value = toJSON.call(value, [key])
          end
        end
        if replacer_function != undefined
          value = replacer_function.call(holder, [key, value])
        end

        if value.js_type == :Object
          if value.js_class == 'Number'
            value = to_number(value)
          elsif value.js_class == 'String'
            value = to_string(value)
          elsif value.js_class == 'Boolean'
            value = value.value
          end
        end
        return 'null' if value == null
        return 'true' if value == true
        return 'false' if value == false
        if value.js_type == :String
          return _quote(value)
        end
        if value.js_type == :Number
          return value.finite? ? to_string(value) : 'null'
        end
        if value.js_type == :Object && !is_callable(value)
          if value.js_class == 'Array'
            return _ja(value, stack, gap, property_list, replacer_function, space)
          else
            return _jo(value, stack, gap, property_list, replacer_function, space)
          end
        end
        undefined
      end

      # @param [String]
      def _quote(value)
        JSON.dump(value)
      end

      def _jo(value, stack, gap, property_list, replacer_function, space)
        if stack.include?(value)
          raise make_error('TypeError', 'Converting circular structure to JSON')
        end
        stack << value
        stepback = @indent
        @indent += gap
        keys = property_list != undefined ? property_list : value.own.keys.filter { |k| value.own[k]['enumerable'] }
        partial = []
        keys.each do |k|
          str_k = _str(k, value, replacer_function, stack, gap, property_list, space)
          if str_k != undefined
            member = _quote(k)
            member += ':'
            if gap != ''
              member += gap
            end
            member += str_k
            partial << member
          end
        end

        if partial.length == 0
          final = '{}'
        else
          if gap == ''
            final = '{' + partial.join(',') + '}'
          else
            separator = ',\n' + @indent
            properties = partial.join(separator)
            final = '{\n' + @indent + properties + '\n' + stepback + '}'
          end
        end
        stack.pop()
        @indent = stepback
        final
      end

      def _ja(value, stack, gap, property_list, replacer_function, space)
        if stack.include?(value)
          raise make_error('TypeError', 'Converting circular structure to JSON')
        end
        stack << value
        stepback = @indent
        @indent += gap
        partial = []
        len = value.get('length')
        index = 0
        while index < len
          str_k = _str(index.to_s, value, replacer_function, stack, gap, property_list, space)
          if str_k == undefined
            partial << 'null'
          else
            partial << str_k
          end
          index += 1
        end
        if partial.length == 0
          final = '[]'
        else
          if gap == ''
            final = '[' + partial.join(',') + ']'
          else
            separator = ',\n' + @indent
            properties = partial.join(separator)
            final = '[\n' + @indent + properties + '\n' + stepback + ']'
          end
        end
        stack.pop()
        @indent = stepback
        final
      end
    end
  end
end
