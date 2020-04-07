# frozen_string_literal: true

module RubyRunJs

  class JsRegExp < JsBaseObject

    attr_reader :pattern, :body, :flag_global, :flag_ignore_case, :flag_multiline

    def initialize(body, flags, prototype)
      super()
      @_class = 'RegExp'
      @prototype = prototype

      @flag_global = flags.include?('g')
      @flag_ignore_case = flags.include?('i') ? Regexp::IGNORECASE : 0
      @flag_multiline = flags.include?('m') ? Regexp::MULTILINE : 0
      @body = body

      begin
        @pattern = Regexp.new(@body, @flag_ignore_case | @flag_multiline)
      rescue
        raise make_error('SyntaxError', "Invalid RegExp pattern: #{@body}")
      end

      define_own_property('source', {
        'value' => @body,
        'enumerable' => false,
        'writable' => false,
        'configurable' => false
      })

      define_own_property('global',{
        'value' => @flag_global,
        'enumerable' => false,
        'writable' => false,
        'configurable' => false
      })

      define_own_property('ignoreCase',{
        'value' => @flag_ignore_case > 0,
        'enumerable' => false,
        'writable' => false,
        'configurable' => false
      })

      define_own_property('multiline',{
        'value' => @flag_multiline > 0,
        'enumerable' => false,
        'writable' => false,
        'configurable' => false
      })

      define_own_property('lastIndex',{
        'value' => 0.0,
        'enumerable' => false,
        'writable' => true,
        'configurable' => false
      })

    end

  end

end