# frozen_string_literal: true

module RubyRunJs
  module JsFunctionMethods
    extend Helper

    class << self
      def constructor(builtin, this, *args)
        constructor_new(builtin, this, *args)
      end

      def constructor_new(builtin, this, *args)
        argCount = args.length
        body = ''
        param = ''
        if argCount > 0
          body = args[-1]
          if argCount > 1
            param = args[0, argCount - 1].join(',')
          end
        end
        body = to_string(body)

        builtin.interpreter.build_js_func_in_runtime(param, body)
      end

      # @type [JsFunction]
      def prototype_toString(builtin, this)
        unless is_callable(this)
          raise make_error('TypeError', 'Function.prototype.toString is not generic')
        end

        args = this.params.join(',')
        "function #{this.name}(#{args}) { [native code] }"
      end

      def prototype_call(builtin, this, this_arg, *args)
        unless is_callable(this)
          raise make_error('TypeError', 'Function.prototype.call is not generic')
        end

        this.call(this_arg, args)
      end

      # @param [JsFunction]
      def prototype_apply(builtin, this, this_arg, arg_array)
        unless is_callable(this)
          raise make_error('TypeError', 'Function.prototype.apply is not generic')
        end
        if arg_array == null || arg_array == undefined
          return this.call(this_arg, [])
        end
        unless arg_array.js_type == :Object
          raise make_error('TypeError', 'argList argument to Function.prototype.apply must an Object')
        end

        n = to_uint32(arg_array.get('length'))

        this.call(this_arg, n.times.map { |i| arg_array.get(to_string(i)) })
      end

      # @param [JsFunction]
      def prototype_bind(builtin, this, this_arg, *args)
        unless is_callable(this)
          raise make_error('TypeError', 'Function.prototype.bind is not generic')
        end
        bound_method = proc { |_, _, _dummy_this, *extra_args|
          this.call(this_arg, args + extra_args)
        }
        js_bound = builtin.new_native_function(bound_method, 'boundFunc')
        js_bound.own['length'] = {
          'value' => [0, this.get('length') - args.length].max.to_f,
          'writable' => false,
          'enumerable' => false,
          'configurable' => false
        }
        js_bound
      end
    end
  end
end
