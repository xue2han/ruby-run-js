# frozen_string_literal: true

module RubyRunJs

  class JsMath < JsBaseObject

    def _class
      
    end

    def initialize(prototype)
      super()
      @prototype = prototype
      @_class = 'Math'
    end
  end
end