# frozen_string_literal: true

module RubyRunJs
  module JsGlobalMethods
    extend Helper


    RADIX_CHARS = {
      '1'=> 1,
      '0'=> 0,
      '3'=> 3,
      '2'=> 2,
      '5'=> 5,
      '4'=> 4,
      '7'=> 7,
      '6'=> 6,
      '9'=> 9,
      '8'=> 8,
      'a'=> 10,
      'c'=> 12,
      'b'=> 11,
      'e'=> 14,
      'd'=> 13,
      'g'=> 16,
      'f'=> 15,
      'i'=> 18,
      'h'=> 17,
      'k'=> 20,
      'j'=> 19,
      'm'=> 22,
      'l'=> 21,
      'o'=> 24,
      'n'=> 23,
      'q'=> 26,
      'p'=> 25,
      's'=> 28,
      'r'=> 27,
      'u'=> 30,
      't'=> 29,
      'w'=> 32,
      'v'=> 31,
      'y'=> 34,
      'x'=> 33,
      'z'=> 35,
      'A'=> 10,
      'C'=> 12,
      'B'=> 11,
      'E'=> 14,
      'D'=> 13,
      'G'=> 16,
      'F'=> 15,
      'I'=> 18,
      'H'=> 17,
      'K'=> 20,
      'J'=> 19,
      'M'=> 22,
      'L'=> 21,
      'O'=> 24,
      'N'=> 23,
      'Q'=> 26,
      'P'=> 25,
      'S'=> 28,
      'R'=> 27,
      'U'=> 30,
      'T'=> 29,
      'W'=> 32,
      'V'=> 31,
      'Y'=> 34,
      'X'=> 33,
      'Z'=> 35
    }.freeze

    class << self

      def property_values
        {
          'NaN' => Float::NAN,
          'Infinity' => Float::INFINITY,
          'undefined' => undefined
        }
      end

      def constructor_eval(builtin, this, x)
        # Todo
        raise make_error('TypeError', 'eval is not currently supported')
      end


      def constructor_parseInt(builtin, this, string, radix)
        input_string = to_string(string).lstrip
        sign = 1
        if input_string.length > 0 && input_string[0] == '-'
          sign = -1
        end
        if input_string.length > 0 && (input_string[0] == '+' || input_string[0] == '-')
          input_string = input_string[1..]
        end
        radix = to_int32(radix)
        strip_prefix = true
        if radix != 0
          if radix < 2 || radix > 36
            return Float::NAN
          end
          if radix != 16
            strip_prefix = false
          end
        else
          radix = 10
        end
        if strip_prefix
          if input_string.length >= 2 && (input_string[0..1] == '0x' || input_string[0..1] == '0X')
            input_string = input_string[2..]
            radix = 16
          end
        end
        n = 0
        num = 0
        while n < input_string.length
          cand = RADIX_CHARS[input_string[n]]
          if cand.nil? || cand >= radix
            break
          end
          num = cand + num * radix
          n += 1
        end
        if n == 0
          return Float::NAN
        end
        (sign * num).to_f
      end

      def constructor_parseFloat(builtin, this, string)
        input_string = to_string(string)
        sign = 1
        if input_string.length > 0 && input_string[0] == '-'
          sign = -1
        end
        if input_string.length > 0 && (input_string[0] == '+' || input_string[0] == '-')
          input_string = input_string[1..]
        end
        num = nil
        if input_string.start_with?('Infinity')
          num = Float::INFINITY
        else
          match_data = /^\d+\.\d*([eE][+-]?\d+)?/.match(input_string) ||
                      /^\.\d+([eE][+-]?\d+)?/.match(input_string) ||
                      /^\d+([eE][+-]?\d+)?/.match(input_string)
          if match_data
            num = match_data[0].to_f
          end
        end
        if num.nil?
          return Float::NAN
        end
        return num * sign
      end

      def constructor_isNaN(builtin, this, number)
        to_number(number).nan?
      end

      def constructor_isFinite(builtin, this, number)
        to_number(number).finite?
      end

      def constructor_encodeURI(builtin, this, str)
        str
      end

      def constructor_decodeURI(builtin, this, str)
        str
      end

      def constructor_encodeURIComponent(builtin, this, str)
        str
      end

      def constructor_decodeURIComponent(builtin, this, str)
        str
      end

    end
  end
end
