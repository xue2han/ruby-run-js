# frozen_string_literal: true

module RubyRunJs

  class JsException < StandardError
    attr_reader :type, :msg, :throw_value

    def initialize(type, msg, throw_value)
      @type = type
      @msg = msg
      @throw_value = throw_value
    end

    def to_s
      "#{@type}: #{@msg}"
    end


  end

end