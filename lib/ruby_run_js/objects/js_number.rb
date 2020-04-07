# frozen_string_literal: true

module RubyRunJs

  class JsNumber < JsBaseObject

    def initialize(value, prototype)
      super()
      @value = to_number(value)
      @prototype = prototype
      @_class = 'Number'
    end
  end
end