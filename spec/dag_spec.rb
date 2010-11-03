require 'pazy'
include Pazy

class FunnyKey
  attr_reader :value

  def initialize(value)
    @value = value
  end

  def hash
    @value % 256
  end

  def ==(other)
    other.is_a?(FunnyKey) and @value == other.value
  end
end

shared_examples_for "an empty DAG" do
  specify { @dag.should have(0).vertices }
  specify { @dag.should have(0).sources }
  specify { @dag.should have(0).sinks }
  specify { @dag.should have(0).internal_vertices }
  specify { @dag.should have(0).isolated_vertices }
  specify { @dag.should have(0).edges }
  specify { @dag.should have(0).components }
  specify { @dag.should have(0).bottlenecks }
  specify { @dag.should be_connected }

  it "should have an empty topological order" do
    @dag.toporder.should be_empty
  end
end

shared_examples_for "a DAG with an isolated vertex A" do
  specify { @dag.should have(1).vertices }
  specify { @dag.should have(1).sources }
  specify { @dag.should have(1).sinks }
  specify { @dag.should have(0).internal_vertices }
  specify { @dag.should have(1).isolated_vertices }
  specify { @dag.should have(0).edges }
  specify { @dag.should have(1).components }
  specify { @dag.should have(1).bottlenecks }
  specify { @dag.should be_connected }

  it "should have A as source" do
    @dag.sources.should include('A')
  end

  it "should have A as sink" do
    @dag.sinks.should include('A')
  end

  it "should have A as an isolated vertex" do
    @dag.isolated_vertices.should include('A')
  end

  it "should have A as a vertex" do
    @dag.vertices.should include('A')
  end

  it "should respond to toporder with A" do
    @dag.toporder.to_a.should == ['A']
  end
end

shared_examples_for "a DAG with a single edge from A to B" do
  specify { @dag.should have(2).vertices }
  specify { @dag.should have(1).sources }
  specify { @dag.should have(1).sinks }
  specify { @dag.should have(0).internal_vertices }
  specify { @dag.should have(0).isolated_vertices }
  specify { @dag.should have(1).edges }
  specify { @dag.should have(1).components }
  specify { @dag.should have(2).bottlenecks }
  specify { @dag.should be_connected }

  it "should have A as a source" do
    @dag.sources.should include('A')
  end

  it "should have B as a sink" do
    @dag.sinks.should include('B')
  end

  it "should have A and B as bottlenecks" do
    @dag.bottlenecks.should include('A')
    @dag.bottlenecks.should include('B')
  end

  it "should respond to toporder with A followed by B" do
    @dag.toporder.to_a.should == ['A', 'B']
  end

  it "should recognize A and B as vertices" do
    @dag.vertex?('A').should be_true
    @dag.vertex?('B').should be_true
  end

  it "should not recognize C and D as vertices, sources or sinks" do
    @dag.vertex?('C').should be_false
    @dag.vertex?('D').should be_false
    @dag.source?('C').should be_false
    @dag.source?('D').should be_false
    @dag.sink?('C').should be_false
    @dag.sink?('D').should be_false
  end
end

shared_examples_for "a DAG with an edge from A to B and a vertex C" do
  specify { @dag.should have(3).vertices }
  specify { @dag.should have(2).sources }
  specify { @dag.should have(2).sinks }
  specify { @dag.should have(0).internal_vertices }
  specify { @dag.should have(1).isolated_vertices }
  specify { @dag.should have(1).edges }
  specify { @dag.should have(2).components }
  specify { @dag.should have(3).bottlenecks }
  specify { @dag.should_not be_connected }

  it "should have A and C as sources" do
    @dag.sources.should include('A')
    @dag.sources.should include('C')
  end

  it "should have B and C as a sinks" do
    @dag.sinks.should include('B')
    @dag.sinks.should include('C')
  end

  it "should have C as an isolated vertex" do
    @dag.isolated_vertices.should include('C')
  end

  it "should have A, B and C as bottlenecks" do
    @dag.bottlenecks.should include('A')
    @dag.bottlenecks.should include('B')
    @dag.bottlenecks.should include('C')
  end

  it "should list A before B in reply to toporder" do
    a = @dag.toporder.to_a
    a.index('A').should < a.index('B')
  end

  it "should recognize A, B and C as vertices" do
    @dag.vertex?('A').should be_true
    @dag.vertex?('B').should be_true
    @dag.vertex?('C').should be_true
  end

  it "should not recognize D as a vertex" do
    @dag.vertex?('D').should be_false
  end

  it "should not list any predecessors or successors for C" do
    @dag.pred('C').size.should == 0
    @dag.succ('C').size.should == 0
  end
end

describe "A DAG" do
  context "created with no arguments" do
    before :all do
      @dag = DAG.new
    end

    it_should_behave_like "an empty DAG"

    context "to which an edge from A to B is added" do
      before :all do
        @dag = @dag.with_edge('A', 'B')
      end

      it_should_behave_like "a DAG with a single edge from A to B"
    end

    context "to which a vertex A is added" do
      before :all do
        @dag = @dag.with_vertex 'A'
      end

      it_should_behave_like "a DAG with an isolated vertex A"
    end

    context "to which a vertex A and an edge from A to B is added" do
      before :all do
        @dag = @dag.with_vertex('A').with_edge('A', 'B')
      end

      it_should_behave_like "a DAG with a single edge from A to B"
    end
  end

  context "created with a single edge A->B" do
    before :all do
      @dag = DAG.with_edge 'A', 'B'
    end

    it_should_behave_like "a DAG with a single edge from A to B"

    context "to which a vertex C is added" do
      before :all do
        @dag = @dag.with_vertex 'C'
      end

      it_should_behave_like "a DAG with an edge from A to B and a vertex C"
    end
  end

  context "created with two edges A->B and B->C" do
    before :all do
      @dag = DAG.new.+('A' => 'B', 'B' => 'C')
    end

    specify { @dag.should have(3).vertices }
    specify { @dag.should have(1).sources }
    specify { @dag.should have(1).sinks }
    specify { @dag.should have(1).internal_vertices }
    specify { @dag.should have(2).edges }
    specify { @dag.should have(1).components }
    specify { @dag.should have(3).bottlenecks }
    specify { @dag.should be_connected }

    it "should have A as a source" do
      @dag.sources.should include('A')
    end

    it "should have C as a sink" do
      @dag.sinks.should include('C')
    end

    it "should have B as an internal vertex" do
      @dag.sinks.should include('C')
    end

    it "should have A, B and C as bottlenecks" do
      @dag.bottlenecks.should include('A')
      @dag.bottlenecks.should include('B')
      @dag.bottlenecks.should include('C')
    end

    it "should respond to toporder with the order A, B, C" do
      @dag.toporder.to_a.should == ['A', 'B', 'C']
    end

    it "should not allow addition of the edge C->A" do
      lambda { @dag.with_edge('C', 'A') }.should raise_error(/not acyclic/)
    end

    context "from which the vertex C is removed" do
      before :all do
        @dag = @dag.without_vertex 'C'
      end

      it_should_behave_like "a DAG with a single edge from A to B"
    end

    context "from which the edge B->C is removed" do
      before :all do
        @dag = @dag.without_edge 'B', 'C'
      end

      it_should_behave_like "a DAG with an edge from A to B and a vertex C"
    end
  end

  context "created with two edges A->C and B->C" do
    before :all do
      @dag = DAG.new.+('A' => 'C', 'B' => 'C')
    end

    specify { @dag.should have(3).vertices }
    specify { @dag.should have(2).sources }
    specify { @dag.should have(1).sinks }
    specify { @dag.should have(0).internal_vertices }
    specify { @dag.should have(2).edges }
    specify { @dag.should have(1).components }
    specify { @dag.should have(1).bottlenecks }
    specify { @dag.should be_connected }
  end

  context "created with two edges A->B and C->D" do
    before :all do
      @dag = DAG.new.+('A' => 'B', 'C' => 'D')
    end

    specify { @dag.should have(4).vertices }
    specify { @dag.should have(2).sources }
    specify { @dag.should have(2).sinks }
    specify { @dag.should have(0).internal_vertices }
    specify { @dag.should have(2).edges }
    specify { @dag.should have(2).components }
    specify { @dag.should have(4).bottlenecks }
    specify { @dag.should_not be_connected }
  end

  context "with some interesting bottlenecks" do
    before :all do
      @dag = DAG.new + [ [1,2], [3,4], [2,4], [2,5], [4,6],
                         [6,7], [6,8], [7,9], [8,9] ]
    end

    specify { @dag.should have(9).vertices }
    specify { @dag.should have(2).sources }
    specify { @dag.should have(2).sinks }
    specify { @dag.should have(5).internal_vertices }
    specify { @dag.should have(9).edges }
    specify { @dag.should have(1).components }
    specify { @dag.should have(3).articulation_points }
    specify { @dag.should have(4).bottlenecks }
    specify { @dag.should be_connected }

    it "should have the articulation points 2, 4, 6" do
      @dag.articulation_points.should include(2)
      @dag.articulation_points.should include(4)
      @dag.articulation_points.should include(6)
    end

    it "should have the bottlenecks 2, 4, 5, 6, 8" do
      @dag.bottlenecks.should include(4)
      @dag.bottlenecks.should include(5)
      @dag.bottlenecks.should include(6)
      @dag.bottlenecks.should include(9)
    end
  end

  context "with another set of interesting bottlenecks" do
    before :all do
      @dag = DAG.new + [ [1,2], [3,4], [3,2], [2,5], [4,5], [4,6] ]
    end

    specify { @dag.should have(6).vertices }
    specify { @dag.should have(2).sources }
    specify { @dag.should have(2).sinks }
    specify { @dag.should have(2).internal_vertices }
    specify { @dag.should have(6).edges }
    specify { @dag.should have(1).components }
    specify { @dag.should have(2).articulation_points }
    specify { @dag.should have(2).bottlenecks }
    specify { @dag.should be_connected }

    it "should have the articulation points 2, 4" do
      @dag.articulation_points.should include(2)
      @dag.articulation_points.should include(4)
    end

    it "should have the bottlenecks 5, 6" do
      @dag.bottlenecks.should include(5)
      @dag.bottlenecks.should include(6)
    end
  end

  context "with a third set of interesting bottlenecks" do
    before :all do
      @dag = DAG.new + [ [0,1], [0,3], [1,2], [3,4], [3,2], [2,5], [4,5], [4,6] ]
    end

    specify { @dag.should have(7).vertices }
    specify { @dag.should have(1).sources }
    specify { @dag.should have(2).sinks }
    specify { @dag.should have(4).internal_vertices }
    specify { @dag.should have(8).edges }
    specify { @dag.should have(1).components }
    specify { @dag.should have(1).articulation_points }
    specify { @dag.should have(3).bottlenecks }
    specify { @dag.should be_connected }

    it "should have the articulation point 4" do
      @dag.articulation_points.should include(4)
    end

    it "should have the bottlenecks 0, 5, 6" do
      @dag.bottlenecks.should include(0)
      @dag.bottlenecks.should include(5)
      @dag.bottlenecks.should include(6)
    end
  end
end
