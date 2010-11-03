# Copyright (c)2010 ANU Supercomputer Facility

require 'pazy/attributes'
require 'pazy/enumerable'
require 'pazy/hash_set'
require 'pazy/hash_map'
require 'pazy/depth_first_traversal'

# This class implements directed, acyclic graphs (DAGs) with arbitrary
# objects for vertices. The graphs need not be connected.

class Pazy::DAG
  include Pazy::Attributes

  Map = Pazy::HashMap
  Set = Pazy::HashSet
  DFS = Pazy::Depth_First_Traversal
  
  protected

  # A DAG is made (internally) a set of vertices and two maps; one
  # for the forward and one for the backward incidence lists.
  def initialize(vert = nil, forw = nil, back = nil)
    @vert = vert || Set.new
    @forw = forw || Map.new
    @back = back || Map.new
    freeze
  end

  def create(*args)
    self.class.allocate.instance_eval { initialize(*args); self }
  end

  lazy_attr :dfs do DFS.new(sources, &method(:adj)) end

  public

  def self.new
    allocate.instance_eval { initialize; self }
  end

  def with_vertex(v)
    create(@vert.with(v), @forw, @back)
  end

  def without_vertex(v)
    if isolated_vertex?(v)
      create(@vert.without(v), @forw, @back)
    else
      (self - edges.select { |u, w| u == v or v == w }).without_vertex(v)
    end
  end

  def with_edge(v, w)
    raise "the graph is not acyclic" if reachable(w).include?(v)

    create(@vert + [v, w],
           @forw.with(v, succ(v).with(w)),
           @back.with(w, pred(w).with(v)))
  end

  def without_edge(v, w)
    create(@vert,
           @forw.with(v, succ(v).without(w)),
           @back.with(w, pred(w).without(v)))
  end

  def self.with_vertex(v, w)
    self.new.with_vertex(v, w)
  end

  def self.with_edge(v, w)
    self.new.with_edge(v, w)
  end

  def +(enum)
    enum.inject(self) { |d, e| d.with_edge *e }
  end

  def -(enum)
    enum.inject(self) { |d, e| d.without_edge *e }
  end

  # The _successors_ of the given vertex _v_: all vertices _w_ such
  # that there is a directed edge from _v_ to _w_.
  def succ(v)
    @forw[v] || Set.new
  end

  # The _predecessors_ of the given vertex _v_: all vertices _w_ such
  # that there is a directed edge from _w_ to _v_.
  def pred(v)
    @back[v] || Set.new
  end

  # The successors followed by the predecessors.
  def adj(v)
    Pazy::Enumerable::Generator.new do |yielder|
      succ(v).each &yielder.method(:yield)
      pred(v).each &yielder.method(:yield)
    end
  end

  # Tests whether the given object _v_ is a vertex of this graph.
  def vertex?(v)
    @vert[v]
  end

  # Tests whether the given object _v_ is an _internal vertex_ in this
  # graph: a vertex that has both predecessors and successors.
  def internal_vertex?(v)
    not pred(v).empty? and not succ(v).empty?
  end

  def isolated_vertex?(v)
    vertex?(v) and pred(v).empty? and succ(v).empty?
  end

  # Tests whether the given object _v_ is a _source_ of this graph:
  # a vertex that has no predecessors.
  def source?(v)
    vertex?(v) and pred(v).empty?
  end

  # Tests whether the given object _v_ is a _sink_ of this graph:
  # a vertex that has no successors.
  def sink?(v)
    vertex?(v) and succ(v).empty?
  end

  # The vertices of this graph in no particular order.
  def vertices
    @vert
  end

  # All the vertices that can be reached by following a sequence of
  # directed edges (a directed path) from the given vertex _v_,
  # including _v_ itself.
  #
  # The vertices reachable from _v_ by a directed path (with the
  # exception of _v_ itself) are called its _descendants_.
  def reachable(v)
    DFS.new([v], &method(:succ))
  end

  # The sources of this graph.
  lazy_attr :sources do
    @vert.select &method(:source?)
  end

  # The sinks of this graph.
  lazy_attr :sinks do
    @vert.select &method(:sink?)
  end
  
  # The internal vertices of this graph.
  lazy_attr :internal_vertices do
    @vert.select &method(:internal_vertex?)
  end

  # The isolated vertices of this graph.
  lazy_attr :isolated_vertices do
    @vert.select &method(:isolated_vertex?)
  end

  # The edges of this graph as a list of pairs.
  lazy_attr :edges do
    Pazy::Enumerable::Generator.new do |yielder|
      @forw.each do |v, adj|
        adj.each do |w|
          yielder.yield([v, w])
        end
      end
    end
  end

  # The vertices of this graph in _topological order_: each vertex is
  # listed before its successors in the graph.
  lazy_attr :toporder do
    DFS.new(sources, &method(:succ))
  end

  # The _connected components_ of this graph, given as a list of vertex
  # lists. Two vertices are in the same component if there is some
  # path between them that ignores edge directions.
  lazy_attr :components do
    component_roots.map do |v|
      DFS.new([v], &method(:adj))
    end
  end

  # One vertex for each component.
  lazy_attr :component_roots do
    dfs.select { |v| dfs.parent(v) == v }
  end

  # Tests whether this graph is _connected_: each pair of vertices is
  # connected by some path that ignores edge directions.
  lazy_attr :connected? do
    components.size <= 1
  end

  # The _articulation points_ or _cut vertices_ of this graph. A
  # vertex is an articulation point if its removal would make the
  # graph disconnected.
  lazy_attr :articulation_points do
    vertices.select do |v|
      if dfs.parent(v) == v
        adj(v).select { |w| w != v and dfs.parent(w) == v }.size > 1
      else
        adj(v).any? { |w| dfs.parent(w) == v and dfs.low(w) >= dfs.index(v) }
      end
    end
  end

  # The _bottlenecks_ of this graph. A vertex _v_ is a bottleneck if
  # no descendant of _v_ can be reached from any source by a directed
  # path that avoids _v_.
  lazy_attr :bottlenecks do
    root = Object.new
    rooted = self + sources.map { |s| [root, s] }
    dfs = DFS.new([root], &rooted.method(:adj))

    vertices.select do |v|
      rooted.pred(v).include?(dfs.parent(v)) and
        succ(v).all? { |w| dfs.parent(w) != v or dfs.low(w) >= dfs.index(v) }
    end
  end
end

