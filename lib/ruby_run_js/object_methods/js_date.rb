# frozen_string_literal: true

require 'time'

module RubyRunJs
  module JsDateMethods
    extend Helper

    class << self
      def constructor(builtin, this, *args)
        obj = constructor_new(builtin, this, )
        obj.get('toString').call(obj)
      end

      def constructor_new(builtin, this, *args)
        if args.length == 0
          return builtin.new_date_by_ruby_time(Time.now)
        end

        if args.length >= 2
          y = to_number(args[0])
          m = to_number(args[1])
          dt = args[2].nil? ? 1.0 : to_number(args[2]) 
          h = args[3].nil? ? 0.0 : to_number(args[3])
          min = args[4].nil? ? 0.0 : to_number(args[4])
          s = args[5].nil? ? 0.0 : to_number(args[5])
          milli = args[6].nil? ? 0.0 : to_number(args[6])
          y_int = to_integer(y)
          if y == y && y_int >= 0 && y_int <= 99
            yr = y_int + 1900
          else
            yr = y
          end
          finalDate = _make_date(_make_day(yr, m, dt), _make_time(h, min, s, milli))
          return builtin.new_date(_time_clip(_local_to_utc(finalDate)))
        end

        v = to_primitive(args[0])
        if v.js_type == :String
          time_value = constructor_parse(builtin, this, v).value
        else
          time_value = to_number(v)
        end
        builtin.new_date(_time_clip(time_value))
      end

      def constructor_parse(builtin, this, str)
        builtin.new_date_by_ruby_time(Time.parse(str))
      end

      def constructor_UTC(builtin, this, *args)
        y = to_number(args[0])
        m = to_number(args[1])
        dt = args[2].nil? ? 1.0 : to_number(args[2]) 
        h = args[3].nil? ? 0.0 : to_number(args[3])
        min = args[4].nil? ? 0.0 : to_number(args[4])
        s = args[5].nil? ? 0.0 : to_number(args[5])
        milli = args[6].nil? ? 0.0 : to_number(args[6])
        y_int = to_integer(y)
        if y == y && y_int >= 0 && y_int <= 99
          yr = y_int + 1900
        else
          yr = y
        end
        finalDate = _make_date(_make_day(yr, m, dt), _make_time(h, min, s, milli))
        _time_clip(finalDate).to_f
      end

      def constructor_now(builtin, this)
        Time.now.to_f.round(3) * 1000
      end

      def check_date(obj)
        if obj.js_class != 'Date'
          raise make_error('TypeError', 'this is not a Date object')
        end
      end

      def prototype_toString(builtin, this)
        check_date(this)
        this.rb_time.strftime('%Y-%m-%dT%H:%M:%S.%LZ')
      end

      def prototype_toDateString(builtin, this)
        check_date(this)
        this.rb_time.strftime('%d %B %Y')
      end

      def prototype_toTimeString(builtin, this)
        check_date(this)
        this.rb_time.strftime('%H:%M:%S')
      end

      def prototype_toLocaleString(builtin, this)
        check_date(this)
        this.rb_time.strftime('%d %B %Y %H:%M:%S')
      end

      def prototype_toLocaleDateString(builtin, this)
        check_date(this)
        this.rb_time.strftime('%d %B %Y')
      end

      def prototype_toLocaleTimeString(builtin, this)
        check_date(this)
        this.rb_time.strftime('%H:%M:%S')
      end

      def prototype_valueOf(builtin, this)
        check_date(this)
        this.value.to_f
      end

      def prototype_getTime(builtin, this)
        check_date(this)
        this.value.to_f
      end

      def property_get_from_time(name, t)
        r = case name
        when :FullYear
          _year_from_time(t)
        when :Month
          _month_from_time(t)
        when :Date
          _date_from_time(t)
        when :Day
          _week_day(t)
        when :Hours
          _hour_from_time(t)
        when :Minutes
          _min_from_time(t)
        when :Seconds
          _sec_from_time(t)
        when :Milliseconds
          _ms_from_time(t)
        end
        r.to_f
      end

      [:FullYear, :Month, :Date, :Day, :Hours, :Minutes, :Seconds, :Milliseconds].each do |name|
        define_method('prototype_get' + name.to_s) do |this|
          check_date(this)
          t = this.value
          return t if t != t
          t = _utc_to_local(t)
          property_get_from_time(name, t)
        end

        define_method('prototype_getUTC' + name.to_s) do |this|
          check_date(this)
          t = this.value
          return t if t != t
          property_get_from_time(name, t)
        end
      end

      def prototype_getTimezoneOffset(builtin, this)
        check_date(this)
        t = this.value
        return t if t != t
        (t - _utc_to_local(t)) / 60000.0
      end

      def prototype_setTime(builtin, this, time)
        check_date(this)
        v = _time_clip(to_number(time))
        this.set_value(v)
        v.to_f
      end

      def property_set_from_time(name, t, args)
        hour = _hour_from_time(t)
        min = _min_from_time(t)
        second = _sec_from_time(t)
        ms = _ms_from_time(t)

        year = _year_from_time(t)
        month = _month_from_time(t)
        date = _date_from_time(t)
        
        case name
        when :FullYear
          year = to_number(args[0])
          if args.length > 1
            month = to_number(args[1])
          end
          if args.length > 2
            date = to_number(args[2])
          end
        when :Month
          month = to_number(args[0])
          if args.length > 1
            date = to_number(args[1])
          end
        when :Date
          date = to_number(args[0])
        when :Day
          _week_day(t)
        when :Hours
          hour = to_number(args[0])
          if args.length > 1
            min = to_number(args[1])
          end
          if args.length > 2
            second = to_number(args[2])
          end
          if args.length > 3
            ms = to_number(args[3])
          end
        when :Minutes
          min = to_number(args[0])
          if args.length > 1
            second = to_number(args[1])
          end
          if args.length > 2
            ms = to_number(args[2])
          end
        when :Seconds
          second = to_number(args[0])
          if args.length > 1
            ms = to_number(args[1])
          end
        when :Milliseconds
          ms = to_number(args[0])
        end
        time = _make_time(hour, min, second, ms)
        _make_date(_make_day(year, month, date), time)
      end

      [:FullYear, :Month, :Date, :Day, :Hours, :Minutes, :Seconds, :Milliseconds].each do |name|
        define_method('prototype_set' + name.to_s) do |this, *args|
          check_date(this)
          t = _utc_to_local(this.value)
          date = property_set_from_time(name, t, args)
          u = _time_clip(_local_to_utc(date))
          this.set_value(u)
          u.to_f
        end

        define_method('prototype_setUTC' + name.to_s) do |this, *args|
          check_date(this)
          t = this.value
          date = property_set_from_time(name, t, args)
          u = _time_clip(date)
          this.set_value(u)
          u.to_f
        end
      end

      def prototype_toUTCString(builtin, this)
        check_date(this)
        this.rb_time.strftime('%Y-%m-%dT%H:%M:%S.%LZ')
      end

      def prototype_toISOString(builtin, this)
        check_date(this)
        this.rb_time.strftime('%Y-%m-%dT%H:%M:%S.%LZ')
      end

      def prototype_toJSON(builtin, this, key)
        obj = to_object(this, builtin)
        tv = to_primitive(obj, 'Number')
        return null if tv.js_type == :Number && !tv.finite?
        toISO = obj.get('toISOString')
        unless is_callable(toISO)
          raise make_error('TypeError', 'toISOString is not callable')
        end
        toISO.call(obj, [])
      end

      def _ms_per_day
        24 * 60 * 60 * 1000
      end

      def _ms_per_hour
        60 * 60 * 1000
      end

      def _ms_per_minute
        60 * 1000
      end

      def _ms_per_second
        1000
      end

      def _day(t)
        t / _ms_per_day
      end

      def _days_in_year(y)
        return 365 if y % 4 != 0
        return 366 if y % 4 == 0 && y % 100 != 0
        return 365 if y % 100 == 0 && y % 400 != 0
        366
      end

      def _day_from_year(y)
        y = y.to_i
        365 * (y - 1970) + (y - 1969) / 4 - (y - 1901) / 100 + (y - 1601) / 400
      end

      def _time_from_year(y)
        _day_from_year(y) * _ms_per_day
      end

      def _year_from_time(t)
        guess = 1970 + t / 31556908800  # msPerYear
        gt = _time_from_year(guess)
        if gt <= t
          while gt <= t
            guess += 1
            gt = _time_from_year(guess)
          end
          return guess - 1
        else
          while gt > t
            guess -= 1
            gt = _time_from_year(guess)
          end
          return guess
        end
      end

      def _in_leap_year(t)
        year = _year_from_time(t)
        _days_in_year(year) == 366 ? 1 : 0
      end

      def _day_within_year(t)
        _day(t) - _day_from_year(_year_from_time(t))
      end

      def _month_from_time(t)
        day_within_year = _day_within_year(t)
        leap_year = _in_leap_year(t)

        return 0 if day_within_year < 31
        day_within_year -= leap_year
        return 1 if day_within_year < 59
        return 2 if day_within_year < 90
        return 3 if day_within_year < 120
        return 4 if day_within_year < 151
        return 5 if day_within_year < 181
        return 6 if day_within_year < 212
        return 7 if day_within_year < 243
        return 8 if day_within_year < 273
        return 9 if day_within_year < 304
        return 10 if day_within_year < 334
        return 11
      end

      def _date_from_time(t)
        month = _month_from_time(t)
        day = _day_within_year(t)
        leap_year = _in_leap_year(t)
        case month
        when 0
          day + 1
        when 1
          day - 30
        when 2
          day - 58 - leap_year
        when 3
          day - 89 - leap_year
        when 4
          day - 119 - leap_year
        when 5
          day - 150 - leap_year
        when 6
          day - 180 - leap_year
        when 7
          day - 211 - leap_year
        when 8
          day - 242 - leap_year
        when 9
          day - 272 - leap_year
        when 10
          day - 303 - leap_year
        when 11
          day - 333 - leap_year
        end
      end

      def _week_day(t)
        (_day(t) + 4 ) % 7
      end

      def _hour_from_time(t)
        (t / _ms_per_hour) % 24
      end

      def _min_from_time(t)
        (t / _ms_per_minute) % 60
      end

      def _sec_from_time(t)
        (t / _ms_per_second) % 60
      end

      def _ms_from_time(t)
        t % 1000
      end

      def _make_time(hour, min, sec, ms)
        if !hour.finite? || !min.finite? || !sec.finite? || !ms.finite?
          return Float::NAN
        end
        h = to_integer(hour)
        m = to_integer(min)
        s = to_integer(sec)
        milli = to_integer(ms)
        h * 60 * 60 * 1000 + m * 60 * 1000 + s * 1000 + milli
      end

      CUM = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]

      def _make_day(year, month, date)
        if !year.finite? || !month.finite? || !date.finite?
          return Float::NAN
        end
        y = to_integer(year)
        m = to_integer(month)
        dt = to_integer(date)
        ym = y + (m / 12).floor
        mn = m % 12
        _day_from_year(ym) + CUM[mn] + dt - 1 + ((_days_in_year(ym) == 366 && mn >= 2) ? 1 : 0)
      end

      def _make_date(day, time)
        if !day.finite? || !time.finite?
          return Float::NAN
        end
        day * 24 * 60 * 60 * 1000 + time
      end

      def _time_clip(time)
        if !time.finite? || time.abs > 8.64e15
          return Float::NAN
        end
        to_integer(time)
      end

      def localTZA
        @localTZA ||= ((Time.local(2000) - Time.utc(2000)).to_f * 1000).to_i
      end

      # DaylightSavingTime is ignored
      def _local_to_utc(t)
        t - localTZA
      end

      # DaylightSavingTime is ignored
      def _utc_to_local(t)
        t + localTZA
      end

    end
  end
end