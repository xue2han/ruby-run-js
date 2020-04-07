# frozen_string_literal: true

module RubyRunJs

  class JsDate < JsBaseObject

    attr_reader :rb_time

    def initialize(value, prototype)
      super()
      @prototype = prototype
      set_value(value)
      @_class = 'Date'
    end

    def set_value(value)
      @value = value
      @rb_time = value != value ? nil : Time.at(value / 1000.0)
    end
  end
end