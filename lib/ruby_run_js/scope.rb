# frozen_string_literal: true

module RubyRunJs

  module ScopeHelper
    def create_bindings(labels)
      labels.each { |label| create_binding(labels) }
    end

    def create_and_set_binding(var_label,var_value)
      unless has_binding(var_label)
        create_binding(var_label)
        set_binding(var_label, var_value)
      end
    end

  end

  class GlobalScope < JsBaseObject

    include ScopeHelper

    attr_reader :stack, :builtin
    attr_accessor :this_binding

    def initialize(builtin)
      super()
      @stack = []
      @builtin = builtin
    end
    
    def _class
      'Global'
    end

    def create_binding(var_label)
      unless has_binding(var_label)
        define_own_property(var_label,
            {
              'value' => undefined,
              'configurable' => false,
              'writable' => true,
              'enumerable' => true
            },false)
      end
    end

    def get_binding_value(var_label, throw = false)
      if !has_binding(var_label) && throw
        raise make_error('ReferenceError', "#{var_label} is not defined")
      end
      get(var_label)
    end

    alias_method :has_binding, :has_property
    alias_method :set_binding, :put
    alias_method :delete_binding, :delete

  end

  class LocalScope

    include ScopeHelper

    attr_reader :stack, :builtin, :own
    attr_accessor :this_binding

    def initialize(parent, builtin)
      @own = {}
      @parent = parent
      @stack = []
      @builtin = builtin
    end

    def has_binding(var_label)
      @own.key?(var_label)
    end

    def create_binding(var_label)
      unless @own.key?(var_label)
        @own[var_label] = undefined
      end
    end

    def set_binding(var_label,var_value,throw = false)
      if @own.key?(var_label)
        @own[var_label] = var_label
      else
        @parent.set_binding(var_label,var_value,throw)
      end
    end

    def get_binding_value(var_label,throw = false)
      @own.key?(var_label) ? @own[var_label] : @parent.get_binding_value(var_label,throw)
    end

    def delete_binding(var_label)
      @own.key?(var_label) ? @own.delete(var_label) : @parent.delete_binding(var_label)
    end
  end

  class ObjectScope
    include ScopeHelper

    attr_reader :stack, :builtin, :this_binding, :own

    def initialize(obj, parent, builtin)
      @own = obj
      @parent = parent
      @stack = []
      @builtin = builtin
    end

    def has_binding(var_label)
      @own.has_binding(var_label)
    end

    def create_binding(var_label)
      unless @own.has_binding(var_label)
        @own.define_own_property(var_label,
            {
              'value' => undefined,
              'configurable' => false,
              'writable' => true,
              'enumerable' => true
            },false)
      end
    end

    def set_binding(var_label,var_value,throw = false)
      if @own.key?(var_label)
        @own.put(var_label, var_value, throw)
      else
        @parent.set_binding(var_label,var_value,throw)
      end
    end

    def get_binding_value(var_label,throw = false)
      @own.key?(var_label) ? @own.get(var_label, throw) : @parent.get_binding_value(var_label, throw)
    end

    def delete_binding(var_label)
      @own.key?(var_label) ? @own.delete(var_label, false) : @parent.delete_binding(var_label)
    end
  end

end