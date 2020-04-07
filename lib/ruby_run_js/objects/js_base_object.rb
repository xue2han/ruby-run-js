# frozen_string_literal: true

module RubyRunJs

  class JsBaseObject
    attr_accessor :prototype, :extensible, :value, :own, :_class

    include Helper

    def initialize
      @prototype = nil
      @extensible = true
      @value = nil
      # @type [Hash]
      @own = {}
      @_class = 'Object'
    end

    def _type
      'object'
    end

    def get(prop_name)
      prop_desc = get_property(prop_name)

      return undefined if prop_desc == undefined

      if is_data_descriptor(prop_desc)
        return prop_desc['value']
      end

      if prop_desc['get'] == undefined
        return undefined
      end

      prop_desc['get'].call(self, [])
    end

    def get_own_property(prop_name)
      if @own.key?(prop_name)
        return @own[prop_name].clone()
      end

      undefined
    end

    def get_property(prop_name)
      cand = get_own_property(prop_name)
      result = undefined

      if cand != undefined
        result = cand
      elsif @prototype != nil
        result = @prototype.get_property(prop_name)
      end
      result
    end

    def put(prop_name, value, throw = false)
      unless can_put(prop_name)
        raise make_error('TypeError', 'Could not define own property') if throw

        return
      end

      ownDesc = get_own_property(prop_name)

      if is_data_descriptor(ownDesc)
        valueDesc = { 'value'=> value }
        define_own_property(prop_name, valueDesc, throw)
        return
      end
      desc = get_property(prop_name)
      if is_accessor_descriptor(desc)
        desc['set'].call(self, [value])
      else
        newDesc = {
          'value' => value,
          'writable' => true,
          'enumerable' => true,
          'configurable' => true
        }
        define_own_property(prop_name, newDesc, throw)
      end
    end

    def can_put(prop_name)
      prop_desc = get_own_property(prop_name)
      if prop_desc != undefined
        if is_accessor_descriptor(prop_desc)
          return prop_desc['set'] != undefined
        else
          return prop_desc['writable']
        end
      end
      return extensible if prototype.nil?

      inherited = prototype.get_property(prop_name)

      return extensible if inherited == undefined

      return inherited['set'] != undefined if is_accessor_descriptor(inherited)

      return false unless extensible

      inherited['writable']
    end

    def has_property(prop_name)
      get_property(prop_name) != undefined
    end

    def delete(prop_name, throw = false)
      desc = get_own_property(prop_name)
      unless desc != undefined
        return true
      end

      if desc['configurable']
        @own.delete(prop_name)
        return true
      elsif throw
        raise make_error('TypeError', 'Could not delete property')
      end
      false
    end

    def default_value(hint = nil)
      order = %w[valueOf toString]
      if hint == 'String' || (hint.nil? && _class == 'Date')
        order = %w[toString valueOf]
      end

      order.each do |method_name|
        func = get(method_name)
        if func != undefined && is_callable(func)
          str = func.call(self, [])

          return str if is_primitive(str)
        end
      end

      raise make_error('TypeError', 'Could not find default value')
    end

    # @param [String]
    # @param [Hash]
    def define_own_property(prop_name, prop_desc, throw = false)
      current = get_own_property(prop_name)

      reject = proc {
        if throw
          raise make_error('TypeError', 'Could not define own property')
        end

        return false
      }

      if current == undefined && !extensible
        reject.call
      end
      if current == undefined && extensible
        if is_data_descriptor(prop_desc) || is_generic_descriptor(prop_desc)
          @own[prop_name] = {
            'value' => prop_desc.fetch('value', undefined),
            'writable' => prop_desc.fetch('writable',false),
            'enumerable' => prop_desc.fetch('enumerable',false),
            'configurable' => prop_desc.fetch('configurable',false)
          }
        else
          @own[prop_name] = {
            'get' => prop_desc.fetch('get', undefined),
            'set' => prop_desc.fetch('set', undefined),
            'enumerable' => prop_desc.fetch('enumerable',false),
            'configurable' => prop_desc.fetch('configurable',false)
          }
        end
        return true
      end

      return true if prop_desc.empty? || prop_desc == current

      unless current['configurable']
        if prop_desc['configurable']
          reject.call
        end
        if prop_desc.key?('enumerable') && prop_desc['enumerable'] != current['enumerable']
          reject.call
        end
      end

      if is_generic_descriptor(prop_desc)

      elsif is_data_descriptor(current) != is_data_descriptor(prop_desc)
        unless current['configurable']
          reject.call
        end
        if is_data_descriptor(current)
          current.delete('value')
          current.delete('writable')
          current['set'] = undefined
          current['get'] = undefined
        else
          current.delete('get')
          current.delete('set')
          current['value'] = undefined
          current['writable'] = false
        end
      elsif is_data_descriptor(current) && is_data_descriptor(prop_desc)
        unless current['configurable']
          if !current['writable'] && prop_desc['writable']
            reject.call
          end
          if !current['writable']
            if prop_desc.key?('value') && prop_desc['value'] != current['value']
              reject.call
            end
          end
        end
      elsif is_accessor_descriptor(current) && is_accessor_descriptor(prop_desc)
        unless current['configurable']
          if prop_desc.key?('set') && prop_desc['set'] != current['set']
            reject.call
          end
          if prop_desc.key?('get') && prop_desc['get'] != current['get']
            reject.call
          end
        end
      end
      prop_desc.each do |k, v|
        current[k] = v
      end
      @own[prop_name] = current
      true
    end

    def set_items(elements)
      elements.each_with_index do |item, index|
        @own[index.to_s] = {
          'value' => item,
          'writable'=> true,
          'enumerable'=> true,
          'configurable'=> true
        }
      end
      @own['length']['value'] = elements.size.to_f
    end

    def get_items
      (0...to_uint32(get('length'))).map { |i| get(i.to_s) }
    end

  end
end