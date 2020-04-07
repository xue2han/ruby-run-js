# frozen_string_literal: true

module RubyRunJs
  class BuiltInContext

    attr_reader :object_prototype, :funtion_prototype, :array_prototype, :string_prototype, :boolean_prototype, :number_prototype, :date_prototype, :regexp_prototype, :error_prototype
    attr_reader :object_constructor, :funtion_constructor, :array_constructor, :string_constructor, :boolean_constructor, :number_constructor, :date_constructor, :regexp_constructor, :error_constructor
    attr_reader :math, :json, :global

    attr_accessor :executor, :interpreter

    include Helper

    def initialize

      @object_prototype = JsObject.new(nil)
      @function_prototype = JsFunction.new(proc { |*_| undefined }, nil, nil, 'Function', self, false, nil, @object_prototype)
      @array_prototype = JsArray.new(0, @object_prototype)
      @string_prototype = JsString.new('', @object_prototype)
      @boolean_prototype = JsBoolean.new(false, @object_prototype)
      @number_prototype = JsNumber.new(0.0, @object_prototype)
      @date_prototype = JsDate.new(Float::NAN, @object_prototype)
      @regexp_prototype = JsRegExp.new('', '', @object_prototype)
      @error_prototype = JsError.new('', @object_prototype)

      @math = JsMath.new(@object_prototype)
      @json = JsJson.new(@object_prototype)
      @global = GlobalScope.new(self)
      @global.this_binding = @global

      @object_constructor = new_construct_function(JsObjectMethods, 'Object')
      @function_constructor = new_construct_function(JsFunctionMethods, 'Function')
      @array_constructor = new_construct_function(JsArrayMethods, 'Array')
      @string_constructor = new_construct_function(JsStringMethods, 'String')
      @boolean_constructor = new_construct_function(JsBooleanMethods, 'Boolean')
      @number_constructor = new_construct_function(JsNumberMethods, 'Number')
      @date_constructor = new_construct_function(JsDateMethods, 'Date')
      @regexp_constructor = new_construct_function(JsRegExpMethods, 'RegExp')
      @error_constructor = new_construct_function(JsErrorMethods, 'Error')

      fill_constructor(@object_constructor, JsObjectMethods, 1, @object_prototype)
      fill_constructor(@function_constructor, JsFunctionMethods, 1, @function_prototype)
      set_freeze(@function_constructor, 'length', 1.0)

      fill_constructor(@array_constructor, JsArrayMethods, 1, @array_prototype)
      fill_constructor(@string_constructor, JsStringMethods, 1, @string_prototype)
      fill_constructor(@boolean_constructor, JsBooleanMethods, 1, @boolean_prototype)
      fill_constructor(@number_constructor, JsNumberMethods, 1, @number_prototype)
      fill_constructor(@date_constructor, JsDateMethods, 7, @date_prototype)
      fill_constructor(@regexp_constructor, JsRegExpMethods, 2, @regexp_prototype)
      fill_constructor(@error_constructor, JsErrorMethods, 1, @error_prototype)

      fill_constructor_with_properties(@math, JsMathMethods)
      fill_constructor_with_properties(@json, JsJsonMethods)
      fill_constructor_with_properties(@global, JsGlobalMethods)

      fill_prototype(@object_prototype, JsObjectMethods, @object_constructor)
      fill_prototype(@function_prototype, JsFunctionMethods, @function_constructor)
      set_freeze(@function_prototype, 'length', 0.0)

      fill_prototype(@array_prototype, JsArrayMethods, @array_constructor)
      fill_prototype(@string_prototype, JsStringMethods, @string_constructor)
      fill_prototype(@boolean_prototype, JsBooleanMethods, @boolean_constructor)
      fill_prototype(@number_prototype, JsNumberMethods, @number_constructor)
      fill_prototype(@date_prototype, JsDateMethods, @date_constructor)
      fill_prototype(@regexp_prototype, JsRegExpMethods, @regexp_constructor)
      fill_prototype(@error_prototype, JsErrorMethods, @error_constructor)

      set_non_enumerable(@error_prototype, 'name', 'Error')
      set_non_enumerable(@error_prototype, 'message', '')

      @native_error_constructors = {}
      @native_error_prototypes = {}

      ['EvalError', 'RangeError',\
      'ReferenceError', 'SyntaxError', 'TypeError',\
      'URIError'].each do |error_name|

        prototype = JsError.new('', @error_prototype)

        @native_error_prototypes[error_name] = prototype

        constructor_func = proc do |_, _, message|
          JsError.new(message == undefined ? message : to_string(message), prototype)
        end

        constructor = new_native_function(constructor_func, error_name)

        set_non_enumerable(constructor, '__new__', constructor)

        set_freeze(constructor, 'length', 1.0)
        set_freeze(constructor, 'prototype', prototype)

        set_non_enumerable(prototype, 'constructor', constructor)
        set_non_enumerable(prototype, 'name', error_name)
        set_non_enumerable(prototype, 'message', '')

        @native_error_constructors[error_name] = constructor

      end

      js_log_func = new_native_function(proc { |_, _, c| puts(c) }, 'log')

      console = new_object()
      console.put('log', js_log_func)

      set_non_enumerable(@global, 'Object', @object_constructor)
      set_non_enumerable(@global, 'Function', @function_constructor)
      set_non_enumerable(@global, 'Array', @array_constructor)
      set_non_enumerable(@global, 'String', @string_constructor)
      set_non_enumerable(@global, 'Boolean', @boolean_constructor)
      set_non_enumerable(@global, 'Number', @number_constructor)
      set_non_enumerable(@global, 'Date', @date_constructor)
      set_non_enumerable(@global, 'RegExp', @regexp_constructor)
      set_non_enumerable(@global, 'Error', @error_constructor)
      set_non_enumerable(@global, 'Math', @math)
      set_non_enumerable(@global, 'JSON', @json)
      set_non_enumerable(@global, 'console', console)
      
      @native_error_constructors.each_pair do |name, constructor|
        set_non_enumerable(@global, name, constructor)
      end
    end

    def new_object()
      JsObject.new(@object_prototype)
    end

    def new_function(code, scope, params, name, is_declaraion, definitions)
      JsFunction.new(code, scope, params, name, self, is_declaraion, definitions, @function_prototype)
    end

    def new_construct_function(js_class, name)
      new_native_function(js_class.method(:constructor), name)
    end

    def new_native_function(native_func, name)
      new_function(native_func, nil, native_func.parameters[2..], name, false, nil)
    end

    def new_array(length = 0)
      JsArray.new(length, @array_prototype)
    end

    def new_array_with_items(items)
      arr = JsArray.new(0, @array_prototype)
      arr.set_items(items)
      arr
    end
    
    def new_string(value = '')
      JsString.new(value, @string_prototype)
    end

    def new_regexp(body, flags)
      JsRegExp.new(body, flags, @regexp_prototype)
    end

    def new_boolean(value)
      JsBoolean.new(value, @boolean_prototype)
    end

    def new_number(value)
      JsNumber.new(value, @number_prototype)
    end

    def new_date(value)
      JsDate.new(value, @date_prototype)
    end

    def new_date_by_ruby_time(rb_time)
      JsDate.new((rb_time.to_f.round(3) * 1000).to_i, @date_prototype)
    end

    def new_error(type, msg)
      prototype = @error_prototype
      if @native_error_prototypes.key?(type)
        prototype = @native_error_prototypes[type]
      end
      JsError.new(msg, prototype)
    end

    def new_arguments_obj(args)
      obj = new_object()
      obj._class = 'Arguments'
      obj.define_own_property('length', {
        'value' => args.length.to_f,
        'writable' => true,
        'enumerable' => false,
        'configurable' => true
      }, false)
      args.length.times do |i|
        obj.put(i.to_s, args[i])
      end
      obj
    end

    private

    def set_non_enumerable(obj, name, value)
      obj.define_own_property(name, {
        'value' => value,
        'writable' => true,
        'enumerable' => false,
        'configurable' => true
      })
    end

    def set_only_configurable(obj, name, value)
      obj.define_own_property(name, {
        'value' => value,
        'writable' => false,
        'enumerable' => false,
        'configurable' => true
      })
    end

    def set_freeze(obj, name, value)
      obj.define_own_property(name, {
        'value' => value,
        'writable' => false,
        'enumerable' => false,
        'configurable' => false
      })
    end

    def fill_constructor(constructor, methods, length, prototype)
      set_only_configurable(constructor, 'length', length.to_f)
      set_freeze(constructor, 'prototype', prototype)

      fill_constructor_with_properties(constructor, methods)
    end

    def fill_constructor_with_properties(constructor, methods)
      methods.singleton_methods.each do |method_symbol|
        method_name = method_symbol.to_s
        if method_name.start_with?('constructor_')
          name = method_name['constructor_'.length..]
          if name == 'new'
            name = '__new__'
          end
          set_non_enumerable(constructor, name, 
            new_native_function(methods.singleton_method(method_symbol), name)
          )
        end
        if method_name == 'property_values'
          values = methods.singleton_method(method_symbol).call
          values.each_pair do |k, v|
            set_freeze(constructor, k, v)
          end
        end
      end
    end

    def fill_prototype(prototype, methods, constructor)
      set_non_enumerable(prototype, 'constructor', constructor)

      methods.singleton_methods.each do |method_symbol|
        method_name = method_symbol.to_s
        if method_name.start_with?('prototype_')
          name = method_name['prototype_'.length..]
          set_non_enumerable(prototype, name, 
            new_native_function(methods.singleton_method(method_symbol), name)
          )
        end
      end
    end

  end
end