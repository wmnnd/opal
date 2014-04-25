require 'corelib/enumerable'

class Range
  include Enumerable

  `def._isRange = true;`

  attr_reader :begin, :end

  def initialize(first, last, exclude = false)
    @begin   = first
    @end     = last
    @exclude = exclude
  end

  def ==(other)
    %x{
      if (!other._isRange) {
        return false;
      }

      return self.exclude === other.exclude &&
             self.begin   ==  other.begin &&
             self.end     ==  other.end;
    }
  end

  def ===(value)
    @begin <= value && (@exclude ? value < @end : value <= @end)
  end

  alias :cover? :===

  def each(&block)
    return enum_for :each unless block_given?

    current = @begin
    last    = @end

    while current < last
      yield current

      current = current.succ
    end

    yield current if !@exclude && current == last

    self
  end

  def eql?(other)
    return false unless Range === other

    @exclude === other.exclude_end? &&
    @begin.eql?(other.begin) &&
    @end.eql?(other.end)
  end

  def exclude_end?
    @exclude
  end

  alias :first :begin

  alias :include? :cover?

  alias :last :end

  # FIXME: currently hardcoded to assume range holds numerics
  def max
    if block_given?
      super
    else
      `#@exclude ? #@end - 1 : #@end`
    end
  end

  alias :member? :cover?

  def min
    if block_given?
      super
    else
      @begin
    end
  end

  alias member? include?

  def size
    _begin = @begin
    _end   = @end
    _end  -= 1 if @exclude

    return nil unless Numeric === _begin && Numeric === _end
    return 0 if _end < _begin
    infinity = Float::INFINITY
    return infinity if infinity == _begin.abs || _end.abs == infinity

    (`Math.abs(_end - _begin) + 1`).to_i
  end

  def step(step = 1)
    return enum_for :step, step unless block_given?

    _begin  = @begin
    _end    = @end
    current = _begin

    p ['>>>>', inspect, step]

    # if Numeric === _begin && (Float === step && !(Integer === step))
    p ['Numeric === _begin', Numeric === _begin]
    if Numeric === _begin
      unless Numeric === step
        step = Opal.coerce_to step, Integer, :to_int
        raise TypeError, "step's not a number" unless Numeric === step
      end
    else
      step = Opal.coerce_to step, Integer, :to_int
      raise TypeError, "step's not an Integer"  unless Integer === step
      # raise TypeError, "step's not a number" unless Float === step
    end

    raise ArgumentError, "step can't be negative" if step < 0
    raise ArgumentError, "step can't be zero"     if step == 0

    if Numeric === _begin && Numeric === _end && Numeric === step # fixnums are special
      _end += step / 2.0 unless @exclude
      %x{
        while (current < _end) {
          #{yield(current)};
          current += step;
        }
      }
    else
      raise TypeError, 'range begin does not respond to #succ' unless _begin.respond_to? :succ
      _end = _end.succ unless @exclude
      yield current
      until `((#{current <=> _end}) < 0)`
        %x{
          for (var i = step; i > 0; i--) {
            #{current = current.succ};
          }
        }
        yield current
      end
    end
    self
  end

  def to_s
    `#{@begin.inspect} + (#@exclude ? '...' : '..') + #{@end.inspect}`
  end

  alias inspect to_s
end
