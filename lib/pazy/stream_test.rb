class Stream
  def initialize(first, &rest)
    @first = first
    if rest.is_a? Proc
      @rest = rest
    else
      force_rest(rest)
    end
  end

  def first
    @first
  end

  private

  def force_rest(val)
    class << self; self end.class_eval { define_method(:rest) { val } }
    val
  end

  public

  def rest
    force_rest(@rest.call)
  end

  def self.iterate(start, &step)
    new(start) { self.iterate(step.call(start), &step) }
  end

  def self.from(start); self.iterate(start, &:next) end

  def take_while(&pred)
    Stream.new(first) { rest.take_while(&pred) if rest } if pred.call(first)
  end

  def take(n)
    Stream.new(first) { rest.take(n-1) if rest } if n > 0
  end

  def drop_while(&pred)
    stream = self
    while stream and pred.call(stream.first)
      stream = stream.rest
    end
    stream
  end

  def drop(n)
    stream = self
    n.times {
      break unless stream
      stream = stream.rest
    }
    stream
  end

  def get(n)
    drop(n).first
  end

  def map(&func)
    Stream.new(func.call(first)) { rest.map(&func) if rest }
  end

  def select(&pred)
    if pred.call(first)
      Stream.new(first) { rest.select(&pred) if rest }
    elsif rest
      rest.select(&pred)
    end
  end

  def combine(other, &op)
    Stream.new(op.call(self.first, other.first)) {
      self.rest.combine(other.rest, &op) if self.rest and other.rest
    }
  end

  def +(other); combine(other, &:+) end
  def -(other); combine(other, &:-) end
  def *(other); combine(other, &:*) end
  def /(other); combine(other, &:/) end

  def accumulate(start, &op)
    new_start = op.call(start, first)
    Stream.new(new_start) { rest.accumulate(new_start, &op) if rest }
  end

  def sums; accumulate(0, &:+) end
  def products; accumulate(1, &:*) end

  def merge(other)
    Stream.new(self.first) { other.merge(self.rest) if other }
  end

  def concat(other)
    Stream.new(first) { if rest then rest.concat(other) else other end }
  end

  # CAUTION: don't call the following methods on an infinite stream.
  def last
    stream = self
    while stream.rest
      stream = stream.rest
    end
    stream.first
  end

  def to_a
    stream = self
    results = []
    while stream do
      results << stream.first
      stream = stream.rest
    end
    results
  end

  def to_s; to_a.join(', ') end
end


puts "A stream with just the numbers 1 and 2:"
puts Stream.new(1) { Stream.new(2) }
puts

fibonacci = Stream.new(0) { Stream.new(1) { fibonacci.rest + fibonacci } }

puts "The first 100 Fibonacci numbers:"
puts fibonacci.take(100)
puts

puts "The Fibonacci numbers between and 1000 and 100000:"
puts fibonacci.drop_while { |n| n < 1000 }.take_while { |n| n < 100000 }
puts

puts "The squares of the number from 101 to 110:"
puts Stream.from(1).drop(100).map { |n| n * n }.take(10)
puts

puts "The accumulated products of the numbers from 1 to 10:"
puts Stream.from(1).products.take(10)
puts

puts "The first 12 Fibonacci numbers with running positions:"
puts fibonacci.combine(Stream.from(0)) { |x, i| "#{i}: #{x}" }.take(12)
puts

puts "The same merged into a single sequence:"
puts Stream.from(0).merge(fibonacci).take(24)
puts

puts "The concatenation of the two streams:"
puts Stream.from(0).take(12).concat(fibonacci.take(12))
puts

puts "The first 10 even fibonacci numbers:"
puts fibonacci.select { |n| n % 2 == 0 }.take(10)
puts

puts "The largest Fibonacci number under 1,000,000:"
puts fibonacci.take_while { |n| n < 1000000 }.last
puts

def test(p); lambda { |n| n % p != 0 } end
def sieve(s); Stream.new(s.first) { sieve(s.rest.select &test(s.first)) } end
primes = sieve(Stream.from(2))

puts "The prime numbers between 1000 and 1100:"
puts primes.drop_while { |n| n < 1000 }.take_while { |n| n < 1100 }
puts()
