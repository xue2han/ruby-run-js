# frozen_string_literal: true

module RubyRunJs
  module ConversionHelper
    def to_primitive(value, hint = nil)
      return value if is_primitive(value)
      return value.to_f if value.is_a?(Integer)

      value.default_value(hint)
    end

    def to_boolean(value)
      type = value.js_type
      return false if [:Null, :Undefined].include?(type)
      return value if type == :Boolean
      return !value.zero? && !value.nan? if type == :Number
      return !value.empty? if type == :String

      true
    end

    def to_number(value)
      type = value.js_type
      return Float::NAN if type == :Undefined
      return 0.0 if type == :Null
      return (value ? 1.0 : 0.0) if type == :Boolean
      return value if type == :Number
      return value.to_f if value.is_a?(Numeric)

      if type == :String
        s = value.strip
        return 0.0 if s.empty?

        if s[0, 3].include?('x') || s[0, 3].include?('X')
          begin
            num = Integer(s)
          rescue
            return Float::NAN
          end
          return num.to_f
        end

        if s == '+Infinity' || s == 'Infinity'
          return Float::INFINITY
        end
        if s == '-Infinity'
          return -Float::INFINITY
        end

        begin
          num = Float(s)
        rescue
          return Float::NAN
        end
        return num
      end

      to_number(to_primitive(value, 'Number'))
    end

    def to_integer(value)
      number = to_number(value)
      return 0 if number.nan?

      if number.infinite? != nil
        return number.infinite? > 0 ? 10**20 : -10**20
      end

      number.to_i
    end

    def to_int32(value)
      number = to_number(value)
      return 0 if number.nan? || number.infinite? != nil

      int32 = number.to_i % 2**32

      int32 >= 2**31 ? int32 - 2**32 : int32
    end

    def to_uint32(value)
      number = to_number(value)
      return 0 if number.nan? || number.infinite? != nil

      number.abs.to_i % 2**32
    end

    def to_uint16(value)
      number = to_number(value)
      return 0 if number.nan? || number.infinite? != nil

      number.abs.to_i % 2**16
    end

    def to_string(value)
      type = value.js_type
      case type
      when :String
        return value
      when :Null
        return 'null'
      when :Undefined
        return 'undefined'
      when :Boolean
        return value ? 'true' : 'false'
      when :Number
        return 'NaN' if value.nan?

        return '0' if value == 0

        prefix = ''
        if value < 0
          prefix = '-'
          value = -value
        end

        return prefix + 'Infinity' if value.infinite? != nil

        if value < 1e-6 || value >= 1e21
          frac, exponent = value.to_s.split('e')
          exp = exponent.to_i
          return prefix + frac + (exp < 0 ? 'e' : '-e') + exp.to_s
        elsif value < 1e-4
          frac, exponent = value.to_s.split('e-')
          base = '0.' + '0' * (exponent.to_i - 1) + frac.sub(/[-\.]/, '')
          return prefix + base
        elsif value == value.to_i
          return prefix + value.to_i.to_s
        end
        prefix + value.to_s
      when :Object
        to_string(to_primitive(value, 'String'))
      else
        value.to_s
      end
    end

    def to_object(value, builtin)
      case value.js_type
      when :Object
        return value
      when :Boolean
        builtin.new_boolean(value)
      when :String
        builtin.new_string(value)
      when :Number
        builtin.new_number(value)
      when :Null, :Undefined
        raise make_error('TypeError', 'undefined or null cannot be converted to object')
      else
        raise 'Unknown Js Type: ' + value.js_type.to_s
      end
    end

    def convert_to_js_type(builtin, obj)
      if obj.js_type != :Native
        return obj
      end

      case obj.class
      when Integer
        obj.to_f
      when Array
        builtin.new_array_with_items(obj.map { |i| convert_to_js_type(builtin, i) } )
      when Hash
        # @type [Hash]
        result = builtin.new_object()
        obj.each_pair do |k, v|
          result.put(to_string(convert_to_js_type(builtin, k)), convert_to_js_type(builtin, v))
        end
        result
      else
        raise make_error('TypeError', 'Could not convert to js type!')
      end
    end

  end
end
