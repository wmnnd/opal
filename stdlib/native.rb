module Native
  def self.is_a?(object, klass)
    %x{
      try {
        return #{object} instanceof #{try_convert(klass)};
      }
      catch (e) {
        return false;
      }
    }
  end

  def self.try_convert(value)
    %x{
      if (#{native?(value)}) {
        return #{value};
      }
      else if (#{value.respond_to? :to_n}) {
        return #{value.to_n};
      }
      else {
        return nil;
      }
    }
  end

  def self.convert(value)
    %x{
      if (#{native?(value)}) {
        return #{value};
      }
      else if (#{value.respond_to? :to_n}) {
        return #{value.to_n};
      }
      else {
        #{raise ArgumentError, "#{value.inspect} isn't native"};
      }
    }
  end

  def self.call(obj, key, *args, &block)
    %x{
      var prop = #{obj}[#{key}];

      if (prop instanceof Function) {
        var converted = new Array(args.length);

        for (var i = 0, length = args.length; i < length; i++) {
          var item = args[i],
              conv = #{try_convert(`item`)};

          converted[i] = conv === nil ? item : conv;
        }

        if (block !== nil) {
          converted.push(block);
        }

        return #{Native(`prop.apply(#{obj}, converted)`)};
      }
      else {
        return #{Native(`prop`)};
      }
    }
  end

  module Helpers
    def alias_native(new, old = new, options = {})
      if old.end_with? ?=
        define_method new do |value|
          `#@native[#{old[0 .. -2]}] = #{Native.convert(value)}`

          value
        end
      else
        if as = options[:as]
          define_method new do |*args, &block|
            if value = Native.call(@native, old, *args, &block)
              as.new(value.to_n)
            end
          end
        else
          define_method new do |*args, &block|
            Native.call(@native, old, *args, &block)
          end
        end
      end
    end
  end

  def self.included(klass)
    klass.extend Helpers
  end

  def initialize(native)
    unless Kernel.native?(native)
      Kernel.raise ArgumentError, "#{native.inspect} isn't native"
    end

    @native = native
  end

  def to_n
    @native
  end
end

module Kernel
  def native?(value)
    `value == null || !value._klass`
  end

  def Native(obj)
    if `#{obj} == null`
      nil
    elsif native?(obj)
      Native::Object.new(obj)
    else
      obj
    end
  end
end

class Native::Object < BasicObject
  include Native

  def ==(other)
    `#@native === #{Native.try_convert(other)}`
  end

  def has_key?(name)
    `#@native.hasOwnProperty(#{name})`
  end

  alias key? has_key?
  alias include? has_key?
  alias member? has_key?

  def each(*args)
    if block_given?
      %x{
        for (var key in #@native) {
          #{yield `key`, `#@native[key]`}
        }
      }

      self
    else
      method_missing(:each, *args)
    end
  end

  def [](key)
    %x{
      var prop = #@native[key];

      if (prop instanceof Function) {
        return prop;
      }
      else {
        return #{::Native.call(@native, key)}
      }
    }
  end

  def []=(key, value)
    native = Native.try_convert(value)

    if `#{native} === nil`
      `#@native[key] = #{value}`
    else
      `#@native[key] = #{native}`
    end
  end

  def respond_to?(name, include_all = false)
    Kernel.instance_method(:respond_to?).bind(self).call(name, include_all)
  end

  def respond_to_missing?(name)
    `#@native.hasOwnProperty(#{name})`
  end

  def method_missing(mid, *args, &block)
    %x{
      if (mid.charAt(mid.length - 1) === '=') {
        return #{self[mid.slice(0, mid.length - 1)] = args[0]};
      }
      else {
        return #{::Native.call(@native, mid, *args, &block)};
      }
    }
  end

  def nil?
    false
  end

  def is_a?(klass)
    klass == Native
  end

  alias kind_of? is_a?

  def instance_of?(klass)
    klass == Native
  end

  def class
    `self._klass`
  end

  def inspect
    "#<Native:#{`String(#@native)`}>"
  end
end

class Numeric
  def to_n
    `self.valueOf()`
  end
end

class Proc
  def to_n
    self
  end
end

class String
  def to_n
    `self.valueOf()`
  end
end

class Regexp
  def to_n
    `self.valueOf()`
  end
end

class MatchData
  def to_n
    @matches
  end
end

class Struct
  def to_n
    result = `{}`

    each_pair {|name, value|
      `#{result}[#{name}] = #{value.to_n}`
    }

    result
  end
end

class Array
  def to_n
    %x{
      var result = [];

      for (var i = 0, length = self.length; i < length; i++) {
        var obj = self[i];

        if (#{`obj`.respond_to? :to_n}) {
          result.push(#{`obj`.to_n});
        }
        else {
          result.push(obj);
        }
      }

      return result;
    }
  end
end

class Boolean
  def to_n
    `self.valueOf()`
  end
end

class Time
  def to_n
    self
  end
end

class NilClass
  def to_n
    `null`
  end
end

class Hash
  # TODO: move to Hash.from() or JSON.from() or something similar
  def initialize(defaults = undefined, &block)
    %x{
      if (defaults != null) {
        if (defaults.constructor === Object) {
          var map  = self.map,
              keys = self.keys;

          for (var key in defaults) {
            var value = defaults[key];

            if (value && value.constructor === Object) {
              map[key] = #{Hash.new(`value`)};
            }
            else {
              map[key] = #{Native(`defaults[key]`)};
            }

            keys.push(key);
          }
        }
        else {
          self.none = defaults;
        }
      }
      else if (block !== nil) {
        self.proc = block;
      }

      return self;
    }
  end

  def to_n
    %x{
      var result = {},
          keys   = self.keys,
          map    = self.map,
          bucket,
          value;

      for (var i = 0, length = keys.length; i < length; i++) {
        var key = keys[i],
            obj = map[key];

        if (#{`obj`.respond_to? :to_n}) {
          result[key] = #{`obj`.to_n};
        }
        else {
          result[key] = obj;
        }
      }

      return result;
    }
  end
end

class Module
  def native_module
    `Opal.global[#{self.name}] = #{self}`
  end
end

class Class
  def native_alias(jsid, mid)
    `#{self}._proto[#{jsid}] = #{self}._proto['$' + #{mid}]`
  end

  alias native_class native_module
end

# native global
$$ = $global = Native(`Opal.global`)
