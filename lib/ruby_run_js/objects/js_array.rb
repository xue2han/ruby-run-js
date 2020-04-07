# frozen_string_literal: true

module RubyRunJs

  class JsArray < JsBaseObject

    def initialize(length, prototype)
      super()
      @prototype = prototype
      @own['length'] = {
        'value' => length.to_f,
        'writable' => true,
        'enumerable' => false,
        'configurable' => false
      }
      @_class = 'Array'
    end

    def define_own_property(prop_name, prop_desc, throw = false)
      reject = proc {
        if throw
          raise make_error('TypeError', 'Could not define own property for array')
        end
        return false
      }
      oldLenDesc = get_own_property('length')
      oldLen = oldLenDesc['value']
      if prop_name == 'length'
        unless prop_desc.key?('value')
          return super
        end
        newLenDesc = prop_desc.clone
        newLen = to_uint32(prop_desc['value'])
        if newLen != to_number(prop_desc['value'])
          raise make_error('RangeError', 'Invalid range')
        end
        newLenDesc['value'] = newLen.to_f
        if newLen >= oldLen
          return super(prop_name, newLenDesc, throw)
        end
        unless oldLenDesc['writable']
          reject.call
        end
        if !newLenDesc.key?('writable') || newLenDesc['writable']
          newWritable = true
        else
          newWritable = false
          newLenDesc['writable'] = true
        end
        succeeded = super('length', newLenDesc, throw)
        return false unless succeeded
        while newLen < oldLen
          oldLen -= 1
          deleteSucceeded = delete(to_string(oldLen),false)
          unless deleteSucceeded
            newLenDesc['value'] = oldLen + 1
            unless newWritable
              newLenDesc['writable'] = false
            end
            super('length',newLenDesc,false)
            reject.call
          end
        end
        unless newWritable
          super('length',{'writable' => false}, false)
        end
        return true
      elsif prop_name == to_string(to_uint32(prop_name)) && to_uint32(prop_name) != 2**32 - 1
        index = to_uint32(prop_name)
        if index >= oldLen && !oldLenDesc['writable']
          reject.call
        end
        unless super(prop_name, prop_desc, false)
          reject.call
        end
        if index >= oldLen
          oldLenDesc['value'] = (index + 1).to_f
          super('length', oldLenDesc, false)
        end
        return true
      else
        return super
      end
    end
  end
end
