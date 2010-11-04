require 'pazy/enumerable'
require 'pazy/list'
require 'pazy/hash_map'

# This helper class allows us to implement traversal methods in a
# functional way without relying on mutable state. It maintains a set
# of 'marked' (visited) vertices and a list of 'members'.
class Pazy::Accumulator
  include Pazy::Enumerable

  attr_reader :info

  # Initializes with members as in _list_ and data for each visited
  # entity as in _info_.
  def initialize(list = Pazy::List.new, info = Pazy::HashMap.new)
    @list = list
    @info = info
    freeze
  end

  # A new State instance in which _v_ is marked and which is
  # otherwise identical to this one.
  def with_mark(v, data = true)
    self.class.new(@list, @info.with(v, data))
  end

  # A new State instance in which _v_ is added to the list of
  # members and which is otherwise identical to this one.
  def after(v)
    self.class.new(@list.after(v), @info)
  end

  # Tests if _v_ is marked in this instance.
  def marked?(v)
    not @info[v].nil?
  end

  def size
    @list.size
  end

  def empty?
    @list.empty?
  end

  # The list of members.
  def each(&block)
    if block_given?
      @list.each &block
    else
      @list
    end
  end
end
