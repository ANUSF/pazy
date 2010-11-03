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

  def <=>(other)
    @value - other.value
  end
end

describe "A Hash" do
  it "with two items the first of which is removed should not be empty" do
    @hash = HashSet.with('A').with('B').without('A')
    @hash.should_not be_empty
  end

  context "when empty" do
    before :all do
      @hash = HashSet.new
    end

    it "should have size 0" do
      @hash.size.should == 0
    end

    it "should be empty" do
      @hash.empty?.should be_true
    end

    it "should return false on get" do
      @hash.get("first").should be_false
    end

    it "should return false on []" do
      @hash["first"].should be_false
    end

    it "should still be empty when without is called" do
      @hash.without("first").size.should == 0
    end

    it "should report no elements" do
      @hash.should have(0).items
    end
  end

  context "containing one item" do
    before :all do
      @hash = HashSet.with("first")
    end

    it "should have size 1" do
      @hash.size.should == 1
    end

    it "should not be empty" do
      @hash.empty?.should_not be_true
    end

    it "should return true for the key" do
      @hash.get("first").should be_true
    end

    it "should return false when fed another key" do
      @hash.get("second").should be_false
    end

    it "should contain the key" do
      @hash.should have(1).item
      @hash.should include("first")
    end
  end

  context "containing two items with different hash values" do
    before :all do
      @key_a = FunnyKey.new(1)
      @key_b = FunnyKey.new(33)
      @hash = HashSet.with(@key_a).with(@key_b)
    end

    it "should not change when an item not included is removed" do
      @hash = @hash.without(FunnyKey.new(5))
      @hash.should have(2).items
      @hash.should include(@key_a)
      @hash.should include(@key_b)
    end

    it "should not be empty when the first item is removed" do
      @hash = @hash.without(@key_a)
      @hash.should have(1).items
    end

    it "should be empty when all items are removed" do
      @hash = @hash.without(@key_a).without(@key_b)
      @hash.should have(0).items
    end
  end

  context "containing three items with identical hash values" do
    before :all do
      @key_a = FunnyKey.new(257)
      @key_b = FunnyKey.new(513)
      @key_c = FunnyKey.new(769)
      @hash = HashSet.with(@key_a).with(@key_b).with(@key_c)
    end

    it "should contain the remaining two items when one is removed" do
      @hash = @hash.without(@key_a)
      @hash.should have(2).items
      @hash.should include(@key_b)
      @hash.should include(@key_c)
    end

    it "should contain four items when one with a new hash value is added" do
      @key_d = FunnyKey.new(33)
      @hash = @hash.with(@key_d)
      @hash.should have(4).items
      @hash.should include(@key_a)
      @hash.should include(@key_b)
      @hash.should include(@key_c)
      @hash.should include(@key_d)
    end
  end

  context "containing a wild mix of items" do
    before :all do
      @keys = (0..16).map { |x| FunnyKey.new(x * 5 + 7) }
      @hash = HashSet.new + @keys
    end

    it "should have the right number of items" do
      @hash.should have(@keys.size).items
    end

    it "should return true for each key" do
      @hash.sort.should == @keys.sort
      @keys.each { |key| @hash.get(key).should be_true }
    end
  end

  context "containing lots of items" do
    before :all do
      @keys = (0..300).map { |x| FunnyKey.new(x) }
      @hash = HashSet.new + @keys
    end

    it "should have the correct number of keys" do
      @hash.size.should == @keys.size
    end

    it "should not be empty" do
      @hash.empty?.should_not be_true
    end

    it "should return true for each key" do
      @keys.each { |key| @hash.get(key).should be_true }
    end

    it "should return false when fed another key" do
      @hash.get("third").should be_false
    end

    it "should contain all the keys" do
      @hash.should have(@keys.size).items
      @keys.each { |key| @hash.should include(key) }
    end

    context "some of which are then removed" do
      before :all do
        @ex_keys = @keys[0,100]
        @hash = @hash - @ex_keys
      end

      it "should have the correct size" do
        @hash.size.should == @keys.size - @ex_keys.size
      end

      it "should not be empty" do
        @hash.empty?.should_not be_true
      end

      it "should return true for the remaining keys" do
        (@keys - @ex_keys).each { |key| @hash.get(key).should be_true }
      end

      it "should return false for the removed keys" do
        @ex_keys.each { |key| @hash.get(key).should be_false }
      end

      it "should contain the remaining keys" do
        @hash.should have(@keys.size - @ex_keys.size).items
        (@keys - @ex_keys).each { |key| @hash.should include(key) }
      end
    end

    context "after which some nonexistent keys are removed" do
      before :all do
        @ex_keys = (1000..1100).map { |x| FunnyKey.new(x) }
        @old_hash = @hash
        @hash = @ex_keys.inject(@hash) { |h, key| h.without(key) }
      end

      it "should be the same object as before" do
        @hash.should equal(@old_hash)
      end

      it "should have the correct size" do
        @hash.size.should == @keys.size
      end

      it "should not be empty" do
        @hash.empty?.should_not be_true
      end
    end

    context "all of which are then removed" do
      before :all do
        @hash = @keys.inject(@hash) { |h, key| h.without(key) }
      end

      it "should have size 0" do
        @hash.size.should == 0
      end

      it "should be empty" do
        @hash.empty?.should be_true
      end

      it "should return false for the removed keys" do
        @keys.each { |key| @hash.get(key).should be_false }
      end

      it "should contain no keys" do
        @hash.should have(0).items
      end
    end

    context "some of which are then inserted again" do
      before :all do
        @ex_keys = @keys[0,100]
        @old_hash = @hash
        @hash = @ex_keys.inject(@hash) { |h, k| h.with(k) }
      end

      it "should be the same object as before" do
        @hash.should equal(@old_hash)
      end

      it "should have the same size as before" do
        @hash.size.should == @keys.size
      end

      it "should not be empty" do
        @hash.empty?.should_not be_true
      end
    end
  end
end
