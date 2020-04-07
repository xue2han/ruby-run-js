# frozen_string_literal: true

module RubyRunJs
  module JsBooleanMethods
    extend Helper

    class << self
      def constructor(builtin, this, value)
        to_boolean(value)
      end

      def constructor_new(builtin, this, value)
        builtin.new_boolean(value)
      end

      def prototype_toString(builtin, this)
        if this.js_class != 'Boolean'
          raise make_error('TypeError', 'Boolean.prototype.toString is not generic')
        end
        if this.js_type == :Object
          this = this.value
        end
        this ? 'true' : 'false'
      end

      def prototype_valueOf(builtin, this)
        if this.js_class != 'Boolean'
          raise make_error('TypeError', 'Boolean.prototype.valueOf is not generic')
        end
        if this.js_type == :Object
          this = this.value
        end
        this
      end

    end
  end
end