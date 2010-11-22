def suspend(&code)
  force = lambda do
    val = code.call
    force = lambda { val }
    val
  end
  lambda { force.call }
end


class Stream
  def initialize(first, &rest)
    @first = first
    @rest = suspend &rest
  end

  def first; @first; end
  def rest; @rest.call; end

  def self.from(start)
    new(start) { from(start.next) }
  end

  def take(n)
    Stream.new(first) { rest.take(n-1) if rest } if n > 0
  end

  def drop(n)
    if n > 0
      rest.drop(n-1) if rest
    else
      self
    end
  end

  def get(n)
    drop(n).first
  end

  def map(&func)
    Stream.new(func.call(first)) { rest.map(&func) if rest }
  end

  def select(&pred)
    if pred.call(first)
      Stream.new(first) { rest.filter(&pred) if rest }
    elsif rest
      rest.filter(&pred)
    end
  end

  def take_while(&pred)
    Stream.new(first) { rest.take_while(&pred) if rest } if pred.call(first)
  end

  def drop_while(&pred)
    if pred.call(first)
      rest.drop_while(&pred) if rest
    else
      self
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
  def arrays; accumulate([], &:<<) end

  def merge(other)
    Stream.new(self.first) { other.merge(self.rest) if other }
  end

  # CAUTION: don't call the following methods on an infinite stream.
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


fibonacci = Stream.new(0) { Stream.new(1) { fibonacci.rest + fibonacci } }

puts "The first 100 Fibonacci numbers:"
puts fibonacci.take(100).to_s
puts

puts "The Fibonacci numbers between and 1000 and 100000:"
puts fibonacci.drop_while { |n| n < 1000 }.take_while { |n| n < 100000 }.to_s
puts

puts "The squares of the number from 101 to 110:"
puts Stream.from(1).drop(100).map { |n| n * n }.take(10).to_s
puts

puts "The accumulated products of the numbers from 1 to 10:"
puts Stream.from(1).products.take(10).to_s
puts

puts "The first 15 Fibonacci numbers as an array:"
puts fibonacci.arrays.get(14).inspect
puts

puts "The first 12 Fibonacci numbers with running positions:"
puts fibonacci.combine(Stream.from(0)) { |x, i| "#{i}: #{x}" }.take(12).to_s
puts

puts "The same merged into a single sequence:"
puts Stream.from(0).merge(fibonacci).take(24).to_s
puts

puts "A consecutive sequence of four-letter words:"
puts Stream.from('hazy').take(12).to_s
