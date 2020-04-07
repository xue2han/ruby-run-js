# frozen_string_literal: true

module RubyRunJs

  class JsFunction < JsBaseObject
    
    attr_reader :code, :parent_scope, :params, :name, :is_native

    def initialize( code, parent_scope, params, name, builtin, is_declaration, definitions, prototype = nil )
      super()
      @_class = 'Function'
      @prototype = prototype
      @code = code
      @builtin = builtin
      @parent_scope = parent_scope
      @params = params
      @name = name
      @is_declaration = is_declaration
      @definitions = definitions
      @is_native = code.is_a?(Proc) || code.is_a?(Method)

      unless name.nil? || name.empty?
        define_own_property('name',{
          'value' => name,
          'writable' => false,
          'enumerable' => false,
          'configurable' => true
        })
      end

      define_own_property('length',{
        'value' => params.nil? ? 0.0 : params.size.to_f,
        'writable' => true,
        'enumerable' => false,
        'configurable' => true
      })

      unless @is_native
        proto = builtin.new_object
        proto.define_own_property('constructor',{
          'value' => self,
          'writable' => true,
          'enumerable' => false,
          'configurable' => true
        })
        define_own_property('prototype',{
          'value' => proto,
          'writable' => true,
          'enumerable' => false,
          'configurable' => false
        })
      end
      
    end

    def call(this, args = [])
      if @is_native # native ruby function
        native_method = code
        params = native_method.parameters
        if params.empty?
          return native_method.call
        end
        js_args = [this] + args
        js_param_size = js_args.size
        native_param_size = params.size - 1
        last_is_rest = params[-1][0] == :rest

        native_params = [@builtin]
        if last_is_rest
          param_size = native_param_size - 1 > js_param_size ? native_param_size - 1 : js_param_size
          (0...param_size).each do |i|
            native_params.append(i < js_param_size ? js_args[i] : undefined)
          end
        else
          native_param_size.times do |i|
            native_params.append(i < js_param_size ? js_args[i] : undefined)
          end
        end
        return native_method.call(*native_params)
      else
        return @builtin.executor.call_js_func(self, this, args)
      end
    end

    # @param [JsObject]
    def has_instance(other)
      return false if other.js_type != :Object
      o = get('prototype')
      if o.js_type != :Object
        raise make_error('TypeError','Function has non-object prototype in instanceof check')
      end
      loop do
        other = other.prototype
        unless other
          return false
        end
        if other == o
          return true
        end
      end
    end

    def construct(args)
      native_constructor = get('__new__')
      if native_constructor != undefined
        return native_constructor.call(undefined, args)
      end
      proto = get('prototype')
      if proto.js_type != :Object
        proto = @builtin.object_prototype
      end
      obj = JsObject.new(proto)
      res = call(obj, args)
      if res.js_type == :Object
        return res
      end
      obj
    end

    def generate_my_scope(this, args)
      scope = LocalScope.new(@parent_scope, @builtin)
      scope.create_bindings(@definitions)

      @params.length.times do |i|
        # params have been created
        scope.set_binding(@params[i], args[i])
      end
      scope.this_binding = this
      unless @params.include?('arguments')
        scope.own['arguments'] = @builtin.new_arguments_obj(args)
      end
      if !@is_declaration && @name != nil && @name != '' && !scope.own.key?(@name)
        scope.own[@name] = self
      end
      scope
    end

  end
end