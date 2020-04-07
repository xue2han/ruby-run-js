# frozen_string_literal: true

module RubyRunJs
  module JsNumberMethods
    extend Helper

    RADIX_SYMBOLS = {
      0 => '0',
      1 => '1',
      2 => '2',
      3 => '3',
      4 => '4',
      5 => '5',
      6 => '6',
      7 => '7',
      8 => '8',
      9 => '9',
      10 => 'a',
      11 => 'b',
      12 => 'c',
      13 => 'd',
      14 => 'e',
      15 => 'f',
      16 => 'g',
      17 => 'h',
      18 => 'i',
      19 => 'j',
      20 => 'k',
      21 => 'l',
      22 => 'm',
      23 => 'n',
      24 => 'o',
      25 => 'p',
      26 => 'q',
      27 => 'r',
      28 => 's',
      29 => 't',
      30 => 'u',
      31 => 'v',
      32 => 'w',
      33 => 'x',
      34 => 'y',
      35 => 'z'
    }.freeze


    class << self

      def property_values
        {
          'MAX_VALUE' => Float::MAX,
          'MIN_VALUE' => Float::MIN,
          'NAN' => Float::NAN,
          'NEGATIVE_INFINITY' => -Float::INFINITY,
          'POSITIVE_INFINITY' => Float::INFINITY
        }
      end

      def constructor(builtin, this, *args)
        if args.length == 0
          return 0.0
        end
        to_number(args[0])
      end

      def constructor_new(builtin, this, *args)
        builtin.new_number(args.length == 0 ? 0.0 : args[0])
      end

      def prototype_toString(builtin, this, radix)
        if this.js_class != 'Number'
          raise make_error('TypeError', 'Number.prototype.toString is not generic')
        end

        radix = radix == undefined ? 10 : to_integer(radix)
        if radix < 2 || radix > 36
          raise make_error('RangeError', 'Number.prototype.toString() radix argument must be an integer between 2 and 36')
        end

        num = to_integer(this)

        sign = ''
        if num < 0
          sign = '-'
          num = -num
        end
        result = ''
        while num > 0
          s = RADIX_SYMBOLS[num % radix]
          num = num / radix
          result = s + result
        end
        sign + (result == '' ? '0' : result)
      end

      def prototype_valueOf(builtin, this)
        if this.js_class != 'Number'
          raise make_error('TypeError', 'Number.prototype.valueOf is not generic')
        end
        if this.js_type == :Object
          this = this.value
        end
        this
      end

      def prototype_toFixed(builtin, this, fraction_digits)
        if this.js_class != 'Number'
          raise make_error('TypeError', 'Number.prototype.toFixed is not generic')
        end

        f = to_integer(fraction_digits)
        if f < 0 || f > 20
          raise make_error('RangeError', 'toFixed() digits argument must be between 0 and 20')
        end

        if this.js_type == :Object
          this = this.value
        end

        if this.infinite?
          return this > 0 ? 'Infinity' : '-Infinity'
        end

        if this.nan?
          return 'NaN'
        end

        "%0.#{f}f" % this
      end

      def prototype_toExponential(builtin, this, fraction_digits)
        if this.js_class != 'Number'
          raise make_error('TypeError', 'Number.prototype.toExponential is not generic')
        end

        f = to_integer(fraction_digits)
        if f < 0 || f > 20
          raise make_error('RangeError', 'toExponential() digits argument must be between 0 and 20')
        end

        if this.js_type == :Object
          this = this.value
        end

        if this.infinite?
          return this > 0 ? 'Infinity' : '-Infinity'
        end

        if this.nan?
          return 'NaN'
        end

        "%0.#{f}e" % this
      end

      def prototype_toPrecision(builtin, this, precision)
        if this.js_class != 'Number'
          raise make_error('TypeError', 'Number.prototype.toPrecision is not generic')
        end

        if this.js_type == :Object
          this = this.value
        end

        return to_string(this) if precision == undefined

        f = to_integer(precision)

        if this.infinite?
          return this > 0 ? 'Infinity' : '-Infinity'
        end

        if this.nan?
          return 'NaN'
        end

        if f < 1 || f > 20
          raise make_error('RangeError', 'toPrecision() digits argument must be between 1 and 20')
        end

        digs = f - this.to_i.to_s.length

        digs >= 0 ? ("%0.#{digs}f" % this) : ("%0.#{f - 1}f" % this)
      end

      alias_method :prototype_toLocaleString, :prototype_toString

    end
  end
end