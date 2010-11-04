require 'rubygems'
require 'pazy/enumerable'

Stream = Pazy::Enumerable::Stream

fibonacci_numbers = Stream.new([0,1]) { |a,b| [b, a + b] }.map { |a,b| a }
tabulated = fibonacci_numbers.with_index.map { |x,n| "#{n}: #{x}" }

puts "\nThe first ten Fibonacci numbers:"
puts fibonacci_numbers.drop(1).take(10).to_a.join(' ')

puts "\nThe Fibonacci numbers at positions 50 to 59:"
puts tabulated.drop(50).take(10).to_a
