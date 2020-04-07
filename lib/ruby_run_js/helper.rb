# frozen_string_literal: true
require_relative './objects/js_exception'
require_relative './conversion'

module RubyRunJs
  
  module Helper

    include ConversionHelper

    def make_error(error_type, message = 'no info', throw_value = nil)
      JsException.new(error_type, message, throw_value)
    end

    def is_data_descriptor(desc)
      desc && desc != undefined && (desc.key?('value') || desc.key?('writable'))
    end

    def is_accessor_descriptor(desc)
      desc && desc != undefined && (desc.key?('get') || desc.key?('set'))
    end

    def is_generic_descriptor(desc)
      desc && desc != undefined && !(is_data_descriptor(desc) || is_accessor_descriptor(desc))
    end

    def is_callable(func)
      func.respond_to? :call
    end

    def is_primitive(value)
      [:Undefined, :Null, :Boolean, :Number, :String].include?(value.js_type)
    end

    def strict_equality(a, b)
      type = a.js_type
      if type != b.js_type
        return false
      end
      case type
      when :Undefined, :Null
        return true
      when :Boolean, :String, :Number
        return a == b
      else
        return a.equal?(b)
      end
    end

    def check_object(obj)
      if obj.js_type == :Undefined || obj.js_type == :Null
        raise make_error('TypeError', 'undefined or null can\'t be converted to object')
      end
    end

    def get_member(obj, prop, builtin)
      type = obj.js_type
      if is_primitive(obj)
        case type
        when :String
          if prop.js_type == :Number && prop.finite?
            index = prop.to_i
            if index == prop && index >= 0 && index < obj.length
              return obj[index]
            end
          end

          s_prop = to_string(prop)
          if s_prop == 'length'
            obj.length.to_f
          elsif s_prop =~ /^\d+$/
            index = s_prop.to_i
            if index >= 0 && index < obj.length
              return obj[index]
            end
          end

          return builtin.string_prototype.get(s_prop)
        when :Number
          return builtin.number_prototype.get(to_string(prop))
        when :Boolean
          return builtin.boolean_prototype.get(to_string(prop))
        when :Null
          raise make_error('TypeError', "Cannot read property '#{prop}' of null")
        when :Undefined
          raise make_error('TypeError', "Cannot read property '#{prop}' of undefined")
        end
      end
      obj.get(to_string(prop))
    end

    def get_member_dot(obj, prop, builtin)
      if is_primitive(obj)
        case obj.js_type
        when :String
          if prop == 'length'
            obj.length.to_f
          elsif prop =~ /^\d+$/
            index = prop.to_i
            if index >= 0 && index < obj.length
              return obj[index]
            end
          end
          return builtin.string_prototype.get(prop)
        when :Number
          return builtin.number_prototype.get(to_string(prop))
        when :Boolean
          return builtin.boolean_prototype.get(to_string(prop))
        when :Null
          raise make_error('TypeError', "Cannot read property '#{prop}' of null")
        when :Undefined
          raise make_error('TypeError', "Cannot read property '#{prop}' of undefined")
        end
      end
      obj.get(prop)
    end

  end
end

module Kernel
  def js_type
    return :Undefined if is_a?(RubyRunJs::JsUndefined)
    return :Null if is_a?(RubyRunJs::JsNull)
    return :Boolean if is_a?(TrueClass) || is_a?(FalseClass)
    return :Number if is_a?(Float)
    return :String if is_a?(String)
    return :Object if is_a?(RubyRunJs::JsBaseObject)

    :Native
  end

  def js_class
    return 'Undefined' if is_a?(RubyRunJs::JsUndefined)
    return 'Null' if is_a?(RubyRunJs::JsNull)
    return 'Boolean' if is_a?(TrueClass) || is_a?(FalseClass)
    return 'Number' if is_a?(Float)
    return 'String' if is_a?(String)
    self._class
  end

  def null
    RubyRunJs::JsNull.instance
  end

  def undefined
    RubyRunJs::JsUndefined.instance
  end
end