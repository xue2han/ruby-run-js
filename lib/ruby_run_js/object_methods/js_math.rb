# frozen_string_literal: true

module RubyRunJs
  module JsMathMethods
    extend Helper

    class << self
      
      def property_values
        {
          'E' => 2.7182818284590452354,
          'LN10' => 2.302585092994046,
          'LN2' => 0.6931471805599453,
          'LOG2E' => 1.4426950408889634,
          'LOG10E' => 0.4342944819032518,
          'PI' => 3.1415926535897932,
          'SQRT1_2' => 0.7071067811865476,
          'SQRT2' => 1.4142135623730951
        }
      end

      def constructor_abs(builtin, this, x)
        x = to_number(x)
        x.abs
      end

      def constructor_acos(builtin, this, x)
        x = to_number(x)
        begin
          return Math.acos(x)
        rescue
          return Float::NAN
        end
      end

      def constructor_asin(builtin, this, x)
        x = to_number(x)
        begin
          return Math.asin(x)
        rescue
          return Float::NAN
        end
      end

      def constructor_atan(builtin, this, x)
        x = to_number(x)
        begin
          return Math.atan(x)
        rescue
          return Float::NAN
        end
      end

      def constructor_atan2(builtin, this, y, x)
        x = to_number(x)
        y = to_number(y)
        if x.nan? || y.nan?
          return Float::NAN
        end

        Math.atan2(y, x)
      end

      def constructor_ceil(builtin, this, x)
        x = to_number(x)
        return x unless x.finite?
        x.ceil.to_f
      end

      def constructor_cos(builtin, this, x)
        x = to_number(x)
        Math.cos(x)
      end

      def constructor_exp(builtin, this, x)
        x = to_number(x)
        return x if x.nan?
        Math.exp(x)
      end

      def constructor_floor(builtin, this, x)
        x = to_number(x)
        return x unless x.finite?
        x.floor.to_f
      end

      def constructor_log(builtin, this, x)
        x = to_number(x)
        return x if x.nan?
        return Float::NAN if x < 0
        Math.log(x)
      end

      def constructor_max(builtin, this, *args)
        return -Float::INFINITY if args.length == 0
        args = args.map { |i| to_number(i) }
        return Float::NAN if args.any?(&:nan?)
        args.max
      end

      def constructor_min(builtin, this, *args)
        return Float::INFINITY if args.length == 0
        args = args.map { |i| to_number(i) }
        return Float::NAN if args.any?(&:nan?)
        args.min
      end

      def constructor_pow(builtin, this, x, y)
        x = to_number(x)
        y = to_number(y)
        x ** y
      end

      def constructor_random(builtin, this)
        Random.rand
      end

      def constructor_round(builtin, this, x)
        x = to_number(x)
        return x unless x.finite?
        x.round.to_f
      end

      def constructor_sin(builtin, this, x)
        x = to_number(x)
        Math.sin(x)
      end

      def constructor_sqrt(builtin, this, x)
        x = to_number(x)
        return Float::NAN if x < 0
        Math.sqrt(x)
      end

      def constructor_tan(builtin, this, x)
        x = to_number(x)
        Math.tan(x)
      end

    end
    
  end
end
