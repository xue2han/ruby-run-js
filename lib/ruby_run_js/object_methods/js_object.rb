# frozen_string_literal: true

module RubyRunJs

  module JsObjectMethods

    extend Helper

    class << self

      def constructor(builtin, this, value)
        if value == null || value == undefined
          return constructor_new(builtin, this, value)
        end
        to_object(value, builtin)
      end

      def constructor_new(builtin, this, value)
        if value != undefined
          case value.js_type
          when :Object
            return value
          when :String, :Boolean, :Number
            return to_object(value, builtin)
          end
        end
        builtin.new_object
      end

      def constructor_getPrototypeOf(builtin, this, obj)
        if obj.js_type != :Object
          raise make_error('TypeError', 'Object.getPrototypeOf called on non-object')
        end
        obj.prototype
      end

      # @param [JsObject]
      def constructor_getOwnPropertyDescriptor(builtin, this, obj, prop_name)
        if obj.js_type != :Object
          raise make_error('TypeError', 'Object.getOwnPropertyDescriptor called on non-object')
        end
        prop_name = to_string(prop_name)
        desc = obj.get_own_property(prop_name)
        fromPropertyDescriptor(builtin, desc)
      end

      # @param [JsObject]
      # @return [JsArray]
      def constructor_getOwnPropertyNames(builtin, this, obj)
        if obj.js_type != :Object
          raise make_error('TypeError', 'Object.getOwnPropertyNames called on non-object')
        end
        array = builtin.new_array()
        array.set_items(obj.own.keys)
        array
      end

      def constructor_create(builtin, this, obj, properties)
        if obj.js_type != :Object && obj.js_type != :Null
          raise make_error('TypeError', 'Object.create called on non-object prototype')
        end
        result = JsObject.new(obj == null ? nil : obj)
        unless properties == undefined
          constructor_defineProperties(builtin, this, result, properties)
        end
        result
      end

      def constructor_defineProperty(builtin, this, obj, prop_name, attributes)
        if obj.js_type != :Object
          raise make_error('TypeError', 'Object.defineProperty called on non-object')
        end
        obj.define_own_property(to_string(prop_name), toPropertyDescriptor(attributes), true)
        obj
      end

      def constructor_defineProperties(builtin, this, obj, properties)
        if obj.js_type != :Object
          raise make_error('TypeError', 'Object.defineProperties called on non-object')
        end
        # @type [JsObject]
        props = to_object(properties, builtin)
        props.own.each do |k, v|
          unless v['enumerable']
            next
          end
          desc = toPropertyDescriptor(v)
          obj.define_own_property(k, desc, true)
        end
        obj
      end

      # @param [JsObject]
      def constructor_seal(builtin, this, obj)
        if obj.js_type != :Object
          raise make_error('TypeError', 'Object.seal called on non-object')
        end
        obj.own.each_value do |v|
          v['configurable'] = false
        end
        obj.extensible = false
        obj
      end

      # @param [JsObject]
      def constructor_freeze(builtin, this, obj)
        if obj.js_type != :Object
          raise make_error('TypeError', 'Object.freeze called on non-object')
        end
        obj.own.each_value do |v|
          v['configurable'] = false
          if is_data_descriptor(v)
            v['writable'] = false
          end
        end
        obj.extensible = false
        obj
      end

      def constructor_preventExtensions(builtin, this, obj)
        if obj.js_type != :Object
          raise make_error('TypeError', 'Object.preventExtensions called on non-object')
        end
        obj.extensible = false
        obj
      end

      def constructor_isSealed(builtin, this, obj)
        if obj.js_type != :Object
          raise make_error('TypeError', 'Object.isSealed called on non-object')
        end
        return false if obj.extensible
        obj.own.each_value do |v|
          return false if v['configurable']
        end
        true
      end

      def constructor_isFrozen(builtin, this, obj)
        if obj.js_type != :Object
          raise make_error('TypeError', 'Object.isFrozen called on non-object')
        end
        return false if obj.extensible
        obj.own.each_value do |v|
          return false if v['configurable']
          return false if is_data_descriptor(v) && v['writable']
        end
        true
      end

      def constructor_isExtensible(builtin, this, obj)
        if obj.js_type != :Object
          raise make_error('TypeError', 'Object.isExtensible called on non-object')
        end
        obj.extensible
      end

      def constructor_keys(builtin, this, obj)
        if obj.js_type != :Object
          raise make_error('TypeError', 'Object.keys called on non-object')
        end
        array = builtin.new_array()
        array.set_items(obj.own.keys.filter { |k| obj.own[k]['enumerable'] })
        array
      end

      def prototype_toString(builtin, this)
        "[object #{this.js_class}]"
      end

      def prototype_valueOf(builtin, this)
        to_object(this, builtin)
      end

      def prototype_toLocaleString(builtin, this)
        o = to_object(this, builtin)
        toString = o.get('toString')
        unless is_callable(toString)
          raise make_error('TypeError', 'toString of this is not callcable')
        end
        toString.call(this)
      end

      def prototype_hasOwnProperty(builtin, this, prop_name)
        o = to_object(this, builtin)
        o.get_own_property(to_string(prop_name)) != undefined
      end

      # @param [JsObject]
      # @param [JsObject]
      def prototype_isPrototypeOf(builtin, this, obj)
        return false if obj.js_type != :Object
        o = to_object(this, builtin)
        loop do
          obj = obj.prototype
          return false if obj.nil? || obj == null
          return true if obj == o
        end
      end

      def prototype_propertyIsEnumerable(builtin, this, prop_name)
        o = to_object(this, builtin)
        desc = o.get_own_property(to_string(prop_name))
        return false if desc == undefined
        desc['enumerable']
      end

      private 

      def fromPropertyDescriptor(builtin, desc)
        return undefined if desc == undefined

        obj = builtin.new_object()
        define = proc do |prop_name|
          obj.define_own_property(prop_name,{
            'value' => desc[prop_name],
            'writable' => true,
            'enumerable' => true,
            'configurable' => true
          },false)
        end
        if is_data_descriptor(desc)
          define.call('value')
          define.call('writable')
        else
          define.call('get')
          define.call('set')
        end
        define.call('enumerable')
        define.call('configurable')
      end
      
      # @param [JsObject]
      def toPropertyDescriptor(obj)
        if obj.js_type != :Object
          raise make_error('TypeError', 'Object.toPropertyDescriptor called on non-object')
        end

        desc = {}

        %w(enumerable configurable writable value get set).each do |prop_name|
          if obj.has_property(prop_name)
            value = obj.get(prop_name)
            if %w(enumerable configurable writable).include?(prop_name)
              desc[prop_name] = to_boolean(value)
            elsif prop_name == 'value'
              desc[prop_name] = value
            else
              if value != undefined && !is_callable(value)
                raise make_error('TypeError', "#{prop_name} of the object is not callable")
              else
                desc[prop_name] = value
              end
            end
          end
        end

        if (desc.key?('get') || desc.key?('set')) &&
          (desc.key?('value') || desc.key?('writable'))
          raise make_error('TypeError', 'the property descriptor cannot be data descriptor and accessor descriptor')
        end
        desc
      end
    end
  end
end
