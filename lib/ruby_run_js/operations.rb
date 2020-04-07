module RubyRunJs
  module Operation

    include Helper

    def unary_operation(operator, target)
      case operator
      when '+'
        plus_uop(target)
      when '-'
        minus_uop(target)
      when '!'
        logical_negation_uop(target)
      when '~'
        bit_invert_uop(target)
      when 'void'
        void_op(target)
      when 'typeof'
        typeof_uop(target)
      else
        raise 'Unkown operator: ' + operator
      end
    end

    def binary_operation(operator, p1, p2)
      case operator
      when '+'
        add_op(p1, p2)
      when '-'
        sub_op(p1, p2)
      when '*'
        mul_op(p1, p2)
      when '/'
        div_op(p1, p2)
      when '%'
        mod_op(p1, p2)
      when '<<'
        bit_lshift_op(p1, p2)
      when '>>'
        bit_rshift_op(p1, p2)
      when '>>>'
        bit_bshift_op(p1, p2)
      when '|'
        bit_or_op(p1, p2)
      when '&'
        bit_and_op(p1, p2)
      when '^'
        bit_xor_op(p1, p2)
      when '=='
        abstract_equality_op(p1, p2)
      when '!='
        abstract_inequality_op(p1, p2)
      when '==='
        strict_equality_op(p1, p2)
      when '!=='
        strict_inequality_op(p1, p2)
      when '<'
        less_op(p1, p2)
      when '<='
        less_eq_op(p1, p2)
      when '>'
        greater_op(p1, p2)
      when '>='
        greater_eq_op(p1, p2)
      when 'in'
        in_op(p1, p2)
      when 'instanceof'
        instanceof_op(p1, p2)
      end
    end

    # -x
    def minus_uop(target)
        -to_number(target)
    end
    # +x
    def plus_uop(target)  # +u
      to_number(target)
    end

    # !x
    def logical_negation_uop(target)  # !u  cant do 'not u' :(
      !to_boolean(target)
    end

    # typeof x
    def typeof_uop(target)
      if is_callable(target)
          return 'function'
      end
      typ = target.js_type.to_s.downcase
      if typ == 'null'
          typ = 'object'  # absolutely idiotic...
      end
      typ
    end

    # ~u
    def bit_invert_uop(target)
      target = ~to_int32(target)
      target = to_int32(target.to_f)
      target.to_f
    end

    # void
    def void_op(target)
      undefined
    end

# ------------------------------------------------------------------------------
# ----- binary ops -------

# Bitwise operat||s
#  <<, >>,  &, ^, |, ~


# <<
    def float(x)
      x.to_f
    end

    def bit_lshift_op(p1, p2)
      lnum = to_int32(p1)
      rnum = to_uint32(p2)
      shiftCount = rnum & 0x1F
      float(to_int32(float(lnum << shiftCount)))
    end
  
    # >>
    def bit_rshift_op(p1, p2)
      lnum = to_int32(p1)
      rnum = to_uint32(p2)
      shiftCount = rnum & 0x1F
      float(to_int32(float(lnum >> shiftCount)))
    end
    
    
    # >>>
    def bit_bshift_op(p1, p2)
      lnum = to_uint32(p1)
      rnum = to_uint32(p2)
      shiftCount = rnum & 0x1F
      float(to_uint32(float(lnum >> shiftCount)))
    end
    
    
    # &
    def bit_and_op(p1, p2)
      lnum = to_int32(p1)
      rnum = to_int32(p2)
      float(to_int32(float(lnum & rnum)))
    end
    
    
    # ^
    def bit_xor_op(p1, p2)
      lnum = to_int32(p1)
      rnum = to_int32(p2)
      float(to_int32(float(lnum ^ rnum)))
    end
    
    
    # |
    def bit_or_op(p1, p2)
      lnum = to_int32(p1)
      rnum = to_int32(p2)
      float(to_int32(float(lnum | rnum)))
    end
    
    
    # Additive operat||s
    # + && - are implemented here
    
    
    # +
    def add_op(p1, p2)
      if p1.js_type == :Float && p2.js_type == :Float
          return p1 + p2
      end
      if p1.js_type == :String && p2.js_type == :String
          return p1 + p2
      end
      # st&&ard way...
      a = to_primitive(p1)
      b = to_primitive(p2)
      if a.js_type == :String || b.js_type == :String  # string wins hehe
        return to_string(a) + to_string(b)
      end
      to_number(a) + to_number(b)
    end
    
    # -
    def sub_op(p1, p2)
      return to_number(p1) - to_number(p2)
    end
    
    
    # Multiplicative operat||s
    # *, / && % are implemented here
    
    # *
    def mul_op(p1, p2)
      return to_number(p1) * to_number(p2)
    end
    
    # /
    def div_op(p1, p2)
      a = to_number(p1)
      b = to_number(p2)
      a / b
    end
    
    # %
    def mod_op(p1, p2)
      a = to_number(p1)
      b = to_number(p2)
      if a.abs == Float::INFINITY || b == 0.0
        return Float::NAN
      end
      if b.abs == Float::INFINITY
        return a
      end
      res = a % b  # different signs in python && javascript
      # python has the same sign as b && js has the same
      # sign as a.
      if a < 0 && res > 0
        res -= b.abs
      elsif a > 0 && res < 0
        res += b.abs
      end
      return float(res)
    end
    
    
    # Comparisons
    # <, <=, !=, ==, >=, > are implemented here.

    def abstract_relational_comparison(p1, p2, p1_first = true)  # todo speed up!
      ''' p1<p2 if p1_first else p2<p1.
        Returns the result of the question: is p1 smaller than p2?
        in case p1_first is false it returns the answer of:
                                            is p2 smaller than p1.
        result is PyJs type: bool || undefined'''
  
      px = to_primitive(p1, :Number)
      py = to_primitive(p2, :Number)
      if !p1_first  # reverse ||der
        px, py = py, px
      end
      unless (px.js_type == :String && py.js_type == :String)
        px = to_number(px)
        py = to_number(py)
        if px.nan? || py.nan?
          return nil  # watch out here!
        end
        return px < py  # same cmp alg||ithm
      else
        return px < py
      end
    end
    
    
    # <
    def less_op(p1, p2)
      res = abstract_relational_comparison(p1, p2, true)
      if res.nil?
        return false
      end
      return res
    end
    
    
    # <=
    def less_eq_op(p1, p2)
      res = abstract_relational_comparison(p1, p2, false)
      if res.nil?
        return false
      end
      return !res
    end
    
    
    # >=
    def greater_eq_op(p1, p2)
      res = abstract_relational_comparison(p1, p2, true)
      if res.nil?
        return false
      end
      return !res
    end
    
    
    # >
    def greater_op(p1, p2)
      res = abstract_relational_comparison(p1, p2, false)
      if res.nil?
        return false
      end
      return res
    end
    
    # equality
    
    
    def abstract_equality_op(p1, p2)
      ''' returns the result of JS == compare.
        result is PyJs type: bool'''
      tx, ty = p1.js_type, p2.js_type
      if tx == ty
        if tx == :Undefined || tx == :Null
          return true
        end
        if tx == :Number || tx == :String || tx == :Boolean
          return p1 == p2
        end
        return p1.equal?(p2)
      elsif (tx == :Undefined && ty == :Null) || (ty == :Undefined && tx == :Null)
        return true
      elsif tx == :Number && ty == :String
        return abstract_equality_op(p1, to_number(p2))
      elsif tx == :String && ty == :Number
        return abstract_equality_op(to_number(p1), p2)
      elsif tx == :Boolean
        return abstract_equality_op(to_number(p1), p2)
      elsif ty == :Boolean
        return abstract_equality_op(p1, to_number(p2))
      elsif (tx == :String || tx == :Number) && p2.js_type == :Object
        return abstract_equality_op(p1, to_primitive(p2))
      elsif (ty == :String || ty == :Number) && p1.js_type == :Object
        return abstract_equality_op(to_primitive(p1), p2)
      else
        return false
      end
    end
    
    def abstract_inequality_op(p1, p2)
      !abstract_equality_op(p1, p2)
    end
    
    def strict_equality_op(p1, p2)
      typ = p1.js_type
      if typ != p2.js_type
        return false
      end
      if typ == :Undefined || typ == :Null
        return true
      end
      if typ == :Boolean || typ == :String || typ == :Number
        return p1 == p2
      else  # object
        return p1.equal?(p2)  # Id compare.
      end
    end
    
    def strict_inequality_op(p1, p2)
      !strict_equality_op(p1, p2)
    end
    
    def instanceof_op(p1, p2)
      '''checks if p1 is instance of p2'''
      if p2.js_type != :Object
        raise make_error('TypeError', 'instanceof called on a non-object')
      end
      unless p2.methods.include?(:has_instance)
        raise make_error('TypeError', 'instanceof called on a non-object')
      end
      return p2.has_instance(p1)
    end
    
    def in_op(p1, p2)
      '''checks if p1 is in p2'''
      if p2.js_type != :Object
        raise make_error('TypeError', "You can\'t use 'in' operator to search in non-objects")
      end
      p2.has_property(to_string(p1))
    end

  end
end