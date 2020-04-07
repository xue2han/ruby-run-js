# frozen_string_literal: true

module RubyRunJs
  module JsStringMethods

    extend Helper

    class << self
      def constructor(builtin, this, *args)
        args.length > 0 ? to_string(args[0]) : ''
      end

      def constructor_new(builtin, this, *args)
        builtin.new_string(args.length > 0 ? to_string(args[0]) : '')
      end

      def constructor_fromCharCode(builtin, this, *chars)
        chars.map { |char| to_uint16(char).chr(Encoding::UTF_8) }.join('')
      end

      def prototype_toString(builtin, this)
        unless this.js_type == :String || this.js_type == :Object && this.js_class == 'String'
          raise make_error('TypeError', 'String.prototype.toString is not generic')
        end

        return this if this.js_type == :String
        return this.value
      end

      def prototype_valueOf(builtin, this)
        unless this.js_type == :String || this.js_type == :Object && this.js_class == 'String'
          raise make_error('TypeError', 'String.prototype.valueOf is not generic')
        end

        return this if this.js_type == :String
        return this.value
      end

      def prototype_charAt(builtin, this, pos)
        check_object(this)
        str = to_string(this)
        pos = to_integer(pos)
        size = str.length
        if pos < 0 || pos >= size
          return ''
        end
        str[pos]
      end

      def prototype_charCodeAt(builtin, this, pos)
        check_object(this)
        str = to_string(this)
        pos = to_integer(pos)
        size = str.length
        if pos < 0 || pos >= size
          return Float::NAN
        end
        str[pos].ord.to_f
      end

      def prototype_concat(builtin, this, *strings)
        check_object(this)
        to_string(this) + strings.map { |s| to_string(s) }.join('')
      end

      def prototype_indexOf(builtin, this, searchString, position)
        check_object(this)
        str = to_string(this)
        search_str = to_string(searchString)
        pos = position == undefined ? 0 : to_integer(position)
        len = str.length
        start = [[0, pos].max, len].min
        r = str.index(search_str, start)
        r.nil? ? -1.0 : r.to_f
      end

      def prototype_lastIndexOf(builtin, this, searchString, position)
        check_object(this)
        str = to_string(this)
        search_str = to_string(searchString)
        len = str.length
        pos = position == undefined ? Float::NAN : to_number(position)
        pos = pos.nan? ? len : to_integer(pos)
        start = [[0, pos].max, len].min
        r = str.rindex(search_str, start)
        r.nil? ? -1.0 : r.to_f
      end

      def prototype_localeCompare(builtin, this, that)
        check_object(this)
        str = to_string(this)
        that = to_string(that)
        if str > that
          return 1.0
        elsif str < that
          return -1.0
        else
          return 0.0
        end
      end

      def prototype_match(builtin, this, regexp)
        check_object(this)
        str = to_string(this)
        rx = regexp.js_class == 'RegExp' ? regexp : builtin.new_regexp(str, '')
        exec_func = rx.prototype.get('exec')
        unless rx.get('global')
          return exec_func.call(rx, [str])
        end
        rx.put('lastIndex', 0.0)
        results = []
        previous_last_index = 0
        n = 0
        last_match = true
        while last_match
          result = exec_func.call(rx, [str])
          if result == null 
            last_match = false
          else
            this_index = rx.get('lastIndex')
            if this_index == previous_last_index
              rx.put('lastIndex', this_index + 1)
              previous_last_index = this_index + 1
            else
              previous_last_index = this_index
            end
            match_str = result.get('0')
            results << match_str
          end
        end

        if results.empty?
          return null
        end
        js_result = builtin.new_array()
        js_result.set_items(results)
        js_result
      end

      def _replace_template(matched_string, offset_start, offset_end, captures, replace_value, whole_string)
        result = ''
        i = 0
        while i < replace_value.length - 1
          if replace_value[i] == '$'
            if replace_value[i + 1] == '$'
              result += '$'
              i += 2
              next
            elsif replace_value[i + 1] == '&'
              result += matched_string
              i += 2
              next
            elsif replace_value[i + 1] == '`'
              result += whole_string[0, offset_start]
              i += 2
              next
            elsif replace_value[i + 1] == '\''
              result += whole_string[offset_end, whole_string.length]
              i += 2
              next
            elsif replace_value[i + 1] =~ /[0-9]/
              digit = replace_value[i + 1]
              if i + 2 < replace_value.length && replace_value[i + 2] =~ /[0-9]/
                digit += replace_value[i + 2]
              end
              num = digit.to_i
              if num == 0 || num >= captures.length
                result += '$' + digit
              else
                result += captures[num - 1]
              end
              i += 1 + digit.length
              next
            end
          end
          result += replace_value[i]
          i += 1
        end
        if i < replace_value.length
          result += replace_value[-1]
        end
        result
      end

      def prototype_replace(builtin, this, searchValue, replaceValue)
        check_object(this)
        str = to_string(this)

        result = ''

        is_func = true
        unless is_callable(replaceValue)
          replaceValue = to_string(replaceValue)
          is_func = false
        end

        if searchValue.js_class == 'RegExp'
          if searchValue.get('global')
            last_index = 0
            match_data = searchValue.pattern.match(str, 0)
            while match_data
              result += str[last_index, match_data.begin(0) - last_index]

              if is_func
                args = [match_data[0]]
                args += match_data.captures
                args << match_data.begin(0)
                args << str
                result += to_string(replaceValue.call(this, args))
              else
                result += _replace_template(match_data[0], match_data.begin(0), match_data.end(0), match_data.captures, replaceValue, str)
              end

              last_index = match_data.end(0)
              match_data = searchValue.pattern.match(str, last_index)
            end
            result += str[last_index..]
            return result
          else
            match_data = searchValue.pattern.match(str)
            if match_data.nil?
              return str
            end
            captures = match_data.captures
            offset_start = match_data.begin(0)
            offset_end = match_data.end(0)
            matched_string = match_data[0]
          end
        else
          matched_string = to_string(searchValue)
          index = str.index(matched_string)
          if index.nil?
            return str
          end
          offset_start = index
          offset_end = index + matched_string.length
          captures = []
        end
        result = str[0,offset_start]
        if is_func
          args = [matched_string] + captures + [offset_start, str]
          result += to_string(replaceValue.call(this, args))
        else
          result += _replace_template(matched_string, offset_start, offset_end, captures, replaceValue, str)
        end
        result += str[offset_end..]
        result
      end

      def prototype_search(builtin, this, regexp)
        check_object(this)
        str = to_string(this)
        regexp = regexp.js_class == 'RegExp' ? regexp : builtin.new_regexp(regexp, '')
        match_data = regexp.pattern.match(str)
        if match_data
          return match_data.begin(0).to_f
        end
        return -1.0
      end

      def prototype_slice(builtin, this, i_start, i_end)
        check_object(this)
        str = to_string(this)
        start = to_integer(i_start)
        length = str.length
        i_end = i_end == undefined ? length : to_integer(i_end)
        str[start...i_end]
      end

      def _split_match(str, q, regexp)
        if regexp.js_class == 'RegExp'
          match_data = regexp.pattern.match(str, q)
          if match_data
            return [match_data.end(0), match_data.captures]
          else
            return nil
          end
        end
        # regexp must be string
        r = regexp.length
        s = str.length
        if str[q..].start_with?(regexp)
          return [q + r, []]
        end
        return nil
      end

      def prototype_split(builtin, this, separator, limit)
        check_object(this)
        str = to_string(this)
        results = []
        lim = limit == undefined ? (2**32 - 1) : to_uint32(limit)
        length = str.length
        sep = separator.js_class == 'RegExp' ? separator : to_string(separator)
        return result if lim == 0
        if separator == undefined
          results << str
        elsif length == 0
          z = _split_match(str, 0, sep)
          if z.nil?
            results << str
          end
          return builtin.new_array_with_items(results)
        end
        i = 0
        q = i
        while q != length
          z = _split_match(str, q, sep)
          if z.nil?
            q += 1
          else
            end_index = z[0]
            captures = z[1]
            if end_index == i
              q += 1
            else
              results << str[i...q]
              if results.length == lim
                return builtin.new_array_with_items(results)
              end
              i = end_index
              captures.each do |cap|
                results << cap
                if results.length == lim
                  return builtin.new_array_with_items(results)
                end
              end
              q = i
            end
          end
        end
        results << str[q..]
        builtin.new_array_with_items(results)
      end

      def prototype_substring(builtin, this, i_start, i_end)
        check_object(this)
        str = to_string(this)
        length = str.length
        i_start = to_integer(i_start)
        i_end = i_end == undefined ? length : to_integer(i_end)
        f_start = [[i_start, 0].max, length].min
        f_end = [[i_end, 0].max, length].min
        from = [f_start, f_end].min
        to = [f_start, f_end].max
        str[from...to]
      end

      def prototype_toLowerCase(builtin, this)
        check_object(this)
        str = to_string(this)
        str.downcase
      end

      def prototype_toLocaleLowerCase(builtin, this)
        prototype_toLowerCase(builtin, this)
      end

      def prototype_toUpperCase(builtin, this)
        check_object(this)
        str = to_string(this)
        str.upcase
      end

      def prototype_toLocaleUpperCase(builtin, this)
        prototype_toUpperCase(builtin, this)
      end

      def prototype_trim(builtin, this)
        check_object(this)
        str = to_string(this)
        str.strip
      end

    end
  end
end