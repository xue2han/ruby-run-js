# frozen_string_literal: true

module RubyRunJs

  class JsString < JsBaseObject

    def initialize(value, prototype)
      super()
      @value = to_string(value)
      @prototype = prototype
      @_class = 'String'
    end
  end
end