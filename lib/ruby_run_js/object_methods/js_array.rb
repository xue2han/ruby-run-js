# frozen_string_literal: true

module RubyRunJs
  module JsArrayMethods
    extend Helper

    class << self

      def constructor(builtin, this, *args)
        constructor_new(builtin, this, *args)
      end

      def constructor_new(builtin, this, *args)
        if args.length == 1 && args[0].js_type == :Number
          if to_uint32(args[0]) == args[0]
            return builtin.new_array(to_uint32(args[0]))
          else
            raise make_error('RangeError', 'the length of Array is not integer')
          end
        end
        array = builtin.new_array
        array.set_items(args)
        array
      end

      def constructor_isArray(builtin, this, arg)
        arg.js_type == :Object && arg.js_class == 'Array'
      end

      def prototype_toString(builtin, this)
        array = to_object(this, builtin)
        func = array.get('join')
        unless is_callable(func)
          func = builtin.object_prototype.get('toString')
        end
        func.call(this, [])
      end

      def prototype_toLocaleString(builtin, this)
        array, len = _to_array(this, builtin)
        return '' if len == 0
        res = []
        len.times do |i|
          item = array.get(i.to_s)
          if item == undefined || item == null
            res << ''
          else
            item_obj = to_object(item, builtin)
            str_func = item_obj.get('toLocaleString')
            unless is_callable(str_func)
              raise make_error('TypeError', "toLocaleString method of item at index #{i} is not callable")
            end
            res << to_string(str_func.call(item_obj, []))
          end
        end
        res.join(',')
      end

      def _move_item(array, from, to)
        from_s = from.to_s
        to_s = to.to_s
        if array.has_property(from_s)
          array.put(to_s, array.get(from_s), true)
        else
          array.delete(to_s, true)
        end
      end

      def _to_array(obj, builtin)
        array = to_object(obj, builtin)
        return array, to_uint32(array.get('length'))
      end

      def prototype_concat(builtin, this, *args)
        array = to_object(this, builtin)
        result = []
        ([array] + args).each do |item|
          if item.js_type == :Object && item.js_class == 'Array'
            (0...item.get('length')).each do |i|
              i_str = i.to_s
              if item.has_property(i_str)
                result.append(item.get(i_str))
              end
            end
          else
            result.append(item)
          end
        end
        res_array = builtin.new_array
        res_array.set_items(result)
        res_array
      end

      def prototype_join(builtin, this, separator)
        array, len = _to_array(this, builtin)
        if separator == undefined
          separator = ','
        end
        sep = to_string(separator)
        res = []
        array.get_items.each do |item|
          res << ((item == undefined || item == null) ? '' : to_string(item))
        end
        res.join(sep)
      end

      def prototype_pop(builtin, this)
        array, len = _to_array(this, builtin)
        if len == 0
          array.put('length', 0.0, true)
          return undefined
        end
        len = (len - 1).to_f
        index = to_string(len)
        element = array.get(index)
        array.delete(index, true)
        array.put('length', len, true)
        element
      end

      def prototype_push(builtin, this, *args)
        array, len = _to_array(this, builtin)
        args.each do |item|
          array.put(len.to_s, item, true)
          len += 1
        end
        array.put('length', len.to_f, true)
        len.to_f
      end

      def prototype_reverse(builtin, this)
        array = to_object(this, builtin)
        items = array.get_items
        items.reverse!
        len = to_uint32(array.get('length'))
        has_props = len.times.map { |i| array.has_property(i.to_s) }
        has_props.reverse!
        items.each_index do |index|
          if has_props[index]
            array.put(index.to_s, items[index], true)
          else
            array.delete(index.to_s)
          end
        end
        array
      end

      def prototype_shift(builtin, this)
        array, len = _to_array(this, builtin)
        if len == 0
          array.put('length', 0.0, true)
          return undefined
        end
        first = array.get('0')
        (1...len).each do |k|
          _move_item(array, k, k - 1)
        end
        array.delete((len-1).to_s, true)
        array.put('length', (len-1).to_f, true)
        first
      end

      def prototype_slice(builtin, this, i_start, i_end)
        array, len = _to_array(this, builtin)
        relativeStart = to_integer(i_start)
        k = relativeStart < 0 ? [0, len + relativeStart].max : [len, relativeStart].min
        relativeEnd = i_end == undefined ? len : to_integer(i_end)
        final = relativeEnd < 0 ? [len + relativeEnd,0].max : [len, relativeEnd].min
        res = []
        (k...final).each do |i|
          if array.has_property(i.to_s)
            res << array.get(i.to_s)
          end
        end
        result = builtin.new_array
        result.set_items(res)
        result
      end

      def _internal_sort(a, b, cmpfn)
        if a.nil?
          return b.nil? ? 0 : 1
        end
        if b.nil?
          return a.nil? ? 0 : -1
        end
        if a == undefined
          return b == undefined ? 0 : 1
        end
        if b == undefined
          return a == undefined ? 0 : -1
        end
        if cmpfn != undefined
          unless is_callable(cmpfn)
            raise make_error('TypeError', 'the compare function used by Array.sort is not callable')
          end
          return cmpfn.call(undefined, [a, b])
        end
        to_string(a) <=> to_string(b)
      end

      def prototype_sort(builtin, this, comparefn)
        obj, len = _to_array(this, builtin)
        items = len.times.map { |i| obj.has_property(i.to_s) ? obj.get(i.to_s) : nil }
        items.sort! { |a, b| _internal_sort(a, b, comparefn) }
        len.times do |i|
          if items[i].nil?
            obj.delete(i.to_s, true)
          else
            obj.put(i.to_s, items[i], true)
          end
        end
        obj
      end

      def prototype_splice(builtin, this, start, deleteCount, *args)
        obj, len = _to_array(this, builtin)
        relativeStart = to_integer(start)
        actualStart = relativeStart < 0 ? [0, len + relativeStart].max : [len, relativeStart].min
        actualDeleteCount = [[to_integer(deleteCount), 0].max, len - actualStart].min
        
        k = 0
        new_array = builtin.new_array
        while k < actualDeleteCount
          from = (actualStart + k).to_s
          if obj.has_property(from)
            new_array.put(k.to_s, obj.get(from))
          end
          k += 1
        end

        if args.length < actualDeleteCount
          k = actualStart
          while k < len - actualDeleteCount
            _move_item(obj, k + actualDeleteCount, k + args.length)
            k += 1
          end
        elsif args.length > actualDeleteCount
          k = len - actualDeleteCount
          while k > actualStart
            _move_item(obj, k + actualDeleteCount - 1, k + args.length - 1)
            k -= 1
          end
        end
        k = actualStart
        args.each do |item|
          obj.put(k.to_s, item, true)
          k += 1
        end
        obj.put('length', (len - actualDeleteCount + args.length).to_f, true)
        new_array
      end

      def prototype_unshift(builtin, this, *args)
        array, len = _to_array(this, builtin)
        arg_count = args.length
        len.downto(1) { |k| _move_item(array, k - 1, k + arg_count - 1) }
        args.each_index { |i| array.put(i.to_s, args[i], true) }
        array.put('length', len + arg_count, true)
        (len + arg_count).to_f
      end

      def prototype_indexOf(builtin, this, searchElement, *fromIndex)
        array, len = _to_array(this, builtin)
        return -1.0 if len == 0
        fromIndex = fromIndex.length > 0 ? to_integer(fromIndex[0]) : 0
        if fromIndex >= len
          return -1.0
        elsif fromIndex >= 0
          k = fromIndex
        else
          k = len + fromIndex
          k = k >= 0 ? k : 0
        end
        while k < len
          if array.has_property(k.to_s)
            if strict_equality(array.get(k.to_s), searchElement)
              return k.to_f
            end
          end
          k += 1
        end
        -1.0
      end

      def prototype_lastIndexOf(builtin, this, searchElement, *fromIndex)
        array, len = _to_array(this, builtin)
        return -1.0 if len == 0
        fromIndex = fromIndex.length > 0 ? to_integer(fromIndex[0]) : len - 1
        if fromIndex >= 0
          k = [fromIndex, len - 1].min
        else
          k = len + fromIndex
        end
        while k >= 0
          if array.has_property(k.to_s)
            if strict_equality(array.get(k.to_s), searchElement)
              return k.to_f
            end
          end
          k -= 1
        end
        -1.0
      end

      def prototype_every(builtin, this, callbackfn, thisArg)
        array, len = _to_array(this, builtin)
        unless is_callable(callbackfn)
          raise make_error('TypeError', 'callbackfn must be a function')
        end
        len.times do |k|
          if array.has_property(k.to_s)
            unless to_boolean(callbackfn.call(thisArg, [array.get(k.to_s), k.to_f, array]))
              return false
            end
          end
        end
        true
      end

      def prototype_some(builtin, this, callbackfn, thisArg)
        array, len = _to_array(this, builtin)
        unless is_callable(callbackfn)
          raise make_error('TypeError', 'callbackfn must be a function')
        end
        len.times do |k|
          if array.has_property(k.to_s)
            if to_boolean(callbackfn.call(thisArg, [array.get(k.to_s), k.to_f, array]))
              return true
            end
          end
        end
        false
      end

      def prototype_forEach(builtin, this, callbackfn, thisArg)
        array, len = _to_array(this, builtin)
        unless is_callable(callbackfn)
          raise make_error('TypeError', 'callbackfn must be a function')
        end
        len.times do |k|
          if array.has_property(k.to_s)
            callbackfn.call(thisArg, [array.get(k.to_s), k.to_f, array])
          end
        end
        undefined
      end

      def prototype_map(builtin, this, callbackfn, thisArg)
        array, len = _to_array(this, builtin)
        unless is_callable(callbackfn)
          raise make_error('TypeError', 'callbackfn must be a function')
        end
        new_array = builtin.new_array(len)
        len.times do |k|
          if array.has_property(k.to_s)
            value = callbackfn.call(thisArg, [array.get(k.to_s), k.to_f, array])
            new_array.put(k.to_s, value, false)
          end
        end
        new_array
      end

      def prototype_filter(builtin, this, callbackfn, thisArg)
        array, len = _to_array(this, builtin)
        unless is_callable(callbackfn)
          raise make_error('TypeError', 'callbackfn must be a function')
        end
        res = []
        len.times do |k|
          if array.has_property(k.to_s)
            kValue = array.get(k.to_s)
            if to_boolean(callbackfn.call(thisArg, [kValue, k.to_f, array]))
              res << kValue
            end
          end
        end
        new_array = builtin.new_array
        new_array.set_items(res)
        new_array
      end

      def prototype_reduce(builtin, this, callbackfn, *initialValue)
        array, len = _to_array(this, builtin)
        unless is_callable(callbackfn)
          raise make_error('TypeError', 'callbackfn must be a function')
        end
        if len == 0 && initialValue.length == 0
          raise make_error('TypeError', 'Reduce of empty array with no initial value')
        end

        k = 0

        if initialValue.length > 0
          accumulator = initialValue[0]
        else
          k_present = false
          while k < len && !k_present
            if array.has_property(k.to_s)
              accumulator = array.get(k.to_s)
            else
              k_present = true
            end
            k += 1
          end
          unless k_present
            raise make_error('TypeError', 'Reduce of empty array with no initial value')
          end
        end
        while k < len
          if array.has_property(k.to_s)
            accumulator = callbackfn.call(undefined, [accumulator, array.get(k.to_s), k.to_f, array])
          end
          k += 1
        end
        accumulator
      end

      def prototype_reduceRight(builtin, this, callbackfn, *initialValue)
        array, len = _to_array(this, builtin)
        unless is_callable(callbackfn)
          raise make_error('TypeError', 'callbackfn must be a function')
        end
        if len == 0 && initialValue.length == 0
          raise make_error('TypeError', 'Reduce of empty array with no initial value')
        end

        k = len - 1

        if initialValue.length > 0
          accumulator = initialValue[0]
        else
          k_present = false
          while k >= 0 && !k_present
            if array.has_property(k.to_s)
              accumulator = array.get(k.to_s)
            else
              k_present = true
            end
            k -= 1
          end
          unless k_present
            raise make_error('TypeError', 'Reduce of empty array with no initial value')
          end
        end
        while k >= 0
          if array.has_property(k.to_s)
            accumulator = callbackfn.call(undefined, [accumulator, array.get(k.to_s), k.to_f, array])
          end
          k -= 1
        end
        accumulator
      end
    end
  end
end