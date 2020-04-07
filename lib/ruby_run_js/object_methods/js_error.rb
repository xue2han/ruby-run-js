# frozen_string_literal: true

module RubyRunJs
  module JsErrorMethods
    extend Helper

    class << self
      def constructor(builtin, this, message)
        constructor_new(builtin, this, message)
      end

      def constructor_new(builtin, this, message)
        builtin.new_error('Error', message == undefined ? message : to_string(message))
      end

      def prototype_toString(builtin, this)
        if this.js_type != :Object
          raise make_error('TypeError', 'Error.prototype.toString called on non-object')
        end

        name = this.get('name')
        name = name == undefined ? 'Error' : to_string(name)
        msg = this.get('message')
        msg = msg == undefined ? '' : to_string(msg)
        if name == ''
          return msg
        end
        if msg == ''
          return name
        end
        "#{name}: #{msg}"
      end

    end
  end
end