# RubyRunJs

RubyRunJs is Javascript interpreter written by 100% pure Ruby.
No dependency needed, so it's easy to install and use.
Full support for ECMAScript 5.1.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ruby_run_js'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ruby_run_js

## Usage

```
001 > require 'ruby_run_js'
002 > RubyRunJs::Interpreter.run("console.log('hello world')")
hello world
 => nil
003 > RubyRunJs::Interpreter.run('''
004'> var sum = 0;
005'> for(var i = 1; i < 100; i += 1){
006'>   sum += i;
007'> }
008'> sum;
009'> ''')
 => 4950.0
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/ruby_run_js. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RubyRunJs project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/ruby_run_js/blob/master/CODE_OF_CONDUCT.md).
