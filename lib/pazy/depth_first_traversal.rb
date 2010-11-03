# Copyright (c)2010 ANU Supercomputer Facility

require 'pazy/attributes'
require 'pazy/enumerable'
require 'pazy/accumulator'
require 'pazy/hash_map'

class Pazy::Depth_First_Traversal
  include Pazy::Enumerable
  include Pazy::Attributes

  def initialize(sources, &adjacencies)
    @sources     = sources
    @adjacencies = adjacencies
    freeze
  end

  def each(&block)
    if block_given?
      traversal.each &block
    else
      self
    end
  end

  def empty?
    traversal.empty?
  end

  def parent(v)
    traversal.info[v]
  end

  def index(v)
    dfs_index[v]
  end

  def low(v)
    min_back[v]
  end

  private

  lazy_attr :dfs_index do
    Pazy::HashMap.new + traversal.with_index
  end

  # This method implements the traversal itself via an Accumulator
  # instance.  In addition to providing an ordering of vertices via
  # the 'each' method, the result also has a method info which
  # returns a map from each vertex to its predecessor in the
  # traversal graph. Sources of the traversal point to themselves in
  # this map.
  lazy_attr :traversal do
    visit = proc do |state, e|
      u, v = e
      if state.marked?(v)
        state
      else
        adj = @adjacencies.call(v)
        adj.map { |w| [v, w] }.inject(state.with_mark(v, u), &visit).after(v)
      end
    end
    @sources.map { |s| [s, s] }.inject(Pazy::Accumulator.new, &visit)
  end

  # TODO describe this attribute
  lazy_attr :min_back do
    visit = proc do |state, edge|
      u, v = edge
      if index(v) >= index(u)
        incident = @adjacencies.call(v).map { |w| [v, w] }
        tmp_state = incident.inject(state.with_mark(v, index(v)), &visit)
        tmp_state.with_mark(u, [tmp_state.info[u], tmp_state.info[v]].min)
      elsif parent(u) != v
        state.with_mark(u, [state.info[u], index(v)].min)
      else
        state
      end
    end
    (@sources.map { |r| [r, r] }.inject(Pazy::Accumulator.new, &visit)).info
  end
end
