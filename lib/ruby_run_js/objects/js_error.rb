# frozen_string_literal: true

module RubyRunJs

  class JsError < JsBaseObject

    def initialize(message, prototype)
      super()
      @prototype = prototype
      @_class = 'Error'

      if message != undefined
        define_own_property('message', {
          'value' => to_string(message),
          'writable' => true,
          'enumerable' => false,
          'configurable' => true
        })
      end
    end

  end
end