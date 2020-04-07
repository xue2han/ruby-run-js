# frozen_string_literal: true

module RubyRunJs

  class JsObject < JsBaseObject

    def initialize(prototype = nil)
      super()
      @prototype = prototype
    end

    def init_with_props(props, vals)
      i = 0
      props.each do |kv|
        prop, kind = kv
        if @own.key?(prop)
          if is_data_descriptor(@own[prop])
            if kind != 'init'
              raise make_error('SyntaxError', "Invalid object initializer! Duplicate property name #{prop}")
            end
          else
            if kind == 'init' || (kind == 'get' && @own.key?('get')) || (kind == 'set' && @own.key?('set'))
              raise make_error('SyntaxError', "Invalid object initializer! Duplicate setter/getter of prop: #{prop}")
            end
          end
        end

        if kind == 'init'
          define_own_property(prop, {
            'value' => vals[i],
            'writable' => true,
            'enumerable' => true,
            'configurable' => true
          }, false)
        elsif kind == 'get'
          define_own_property(prop,{
            'get' => vals[i],
            'enumerable' => true,
            'configurable' => true
          }, false)
        elsif kind == 'set'
          define_own_property(prop,{
            'set' => vals[i],
            'enumerable' => true,
            'configurable' => true
          }, false)
        else
          raise "Invalid property kind - #{kind}. Expected one of init, get, set."
        end

        i += 1
      end
    end

  end
end