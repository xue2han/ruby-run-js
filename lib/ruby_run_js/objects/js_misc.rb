# frozen_string_literal: true

module RubyRunJs

  # class for null
  class JsNull
    def _type
      'object'
    end

    def _class
      'Null'
    end

    def self.instance
      @instance ||= JsNull.new
      @instance
    end
  end

  class JsUndefined
    def _type
      'undefined'
    end

    def _class
      'Undefined'
    end

    def self.instance
      @instance ||= JsUndefined.new
      @instance
    end
  end
end
