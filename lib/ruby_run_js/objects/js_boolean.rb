# frozen_string_literal: true

module RubyRunJs

  class JsBoolean < JsBaseObject

    def initialize(value, prototype)
      super()
      @value = to_boolean(value)
      @prototype = prototype
      @_class = 'Boolean'
    end
  end
end