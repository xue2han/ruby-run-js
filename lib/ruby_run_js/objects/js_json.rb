# frozen_string_literal: true

module RubyRunJs

  class JsJson < JsBaseObject

    def initialize(prototype)
      super()
      @prototype = prototype
      @_class = 'Json'
    end

  end
end