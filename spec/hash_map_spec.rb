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
    @hash = HashMap.with('A', true).with('B', true).without('A')
    @hash.should_not be_empty
  end

  context "when empty" do
    before :all do
      @hash = HashMap.new
    end

    it "should have size 0" do
      @hash.size.should == 0
    end

    it "should be empty" do
      @hash.empty?.should be_true
    end

    it "should return nil on get" do
      @hash.get("first").should == nil
    end

    it "should return nil on []" do
      @hash["first"].should == nil
    end

    it "should still be empty when without is called" do
      @hash.without("first").size.should == 0
    end

    it "should return an empty array when map is called" do
      @hash.should have(0).items
    end
  end

  context "containing one item" do
    before :all do
      @hash = HashMap.with("first", 1)
    end

    it "should have size 1" do
      @hash.size.should == 1
    end

    it "should not be empty" do
      @hash.empty?.should_not be_true
    end

    it "should retrieve the associated value for the key" do
      @hash.get("first").should == 1
    end

    it "should return nil when fed another key" do
      @hash.get("second").should == nil
    end

    it "should contain the key-value pair" do
      @hash.should have(1).item
      @hash.should include(["first", 1])
    end

    context "the value of which is then changed" do
      before :all do
        @hash = @hash.with("first", "one")
      end

      it "should have size 1" do
        @hash.size.should == 1
      end

      it "should not be empty" do
        @hash.empty?.should_not be_true
      end

      it "should retrieve the associated value for the key" do
        @hash.get("first").should == "one"
      end

      it "should return nil when fed another key" do
        @hash.get("second").should == nil
      end

      it "should contain the new key-value pair" do
        @hash.should have(1).item
        @hash.should include(["first", "one"])
      end
    end
  end

  context "containing two items with different hash values" do
    before :all do
      @key_a = FunnyKey.new(1)
      @key_b = FunnyKey.new(33)
      @hash = HashMap.with(@key_a, "a").with(@key_b, "b")
    end

    it "should not change when an item not included is removed" do
      @hash = @hash.without(FunnyKey.new(5))
      @hash.should have(2).items
      @hash.should include([@key_a, "a"])
      @hash.should include([@key_b, "b"])
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
      @hash = HashMap.with(@key_a, "a").with(@key_b, "b").with(@key_c, "c")
    end

    it "should contain the remaining two items when one is removed" do
      @hash = @hash.without(@key_a)
      @hash.should have(2).items
      @hash.should include([@key_b, "b"])
      @hash.should include([@key_c, "c"])
    end

    it "should contain four items when one with a new hash value is added" do
      @key_d = FunnyKey.new(33)
      @hash = @hash.with(@key_d, "d")
      @hash.should have(4).items
      @hash.should include([@key_a, "a"])
      @hash.should include([@key_b, "b"])
      @hash.should include([@key_c, "c"])
      @hash.should include([@key_d, "d"])
    end
  end

  context "containing a wild mix of items" do
    before :all do
      @keys = (0..16).map { |x| FunnyKey.new(x * 5 + 7) }
      @hash = HashMap.new + @keys.map { |key| [key, key.value] }
    end

    it "should have the right number of items" do
      @hash.should have(@keys.size).items
    end

    it "should retrieve the associated value for each key" do
      @hash.keys.sort.should == @keys.sort
      @hash.values.sort.should == @keys.sort.map { |key| key.value }
      @hash.entries.sort.should == @keys.sort.map { |key| [key, key.value] }
      @hash.keys.each { |key| @hash.get(key).should == key.value }
    end
  end

  context "containing lots of items" do
    before :all do
      @keys = (0..300).map { |x| FunnyKey.new(x) }
      @hash = @keys.inject(HashMap.new) { |h, key| h.with(key, key.value) }
    end

    it "should have the correct number of keys" do
      @hash.size.should == @keys.size
    end

    it "should not be empty" do
      @hash.empty?.should_not be_true
    end

    it "should retrieve the associated value for each key" do
      @keys.each { |key| @hash.get(key).should == key.value }
    end

    it "should return nil when fed another key" do
      @hash.get("third").should == nil
    end

    it "should contain all the key-value pairs" do
      @hash.should have(@keys.size).items
      @keys.each { |key| @hash.should include([key, key.value]) }
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

      it "should retrieve the associated values for the remaining keys" do
        (@keys - @ex_keys).each { |key| @hash.get(key).should == key.value }
      end

      it "should return nil for the removed keys" do
        @ex_keys.each { |key| @hash.get(key).should == nil }
      end

      it "should contain the remaining key-value pair" do
        @hash.should have(@keys.size - @ex_keys.size).items
        (@keys - @ex_keys).each { |key| @hash.should include([key, key.value]) }
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

      it "should retrieve the original values for all existing keys" do
        @keys.each { |key| @hash.get(key).should == key.value }
      end

      it "should return nil for the 'removed' keys" do
        @ex_keys.each { |key| @hash.get(key).should == nil }
      end

      it "should contain the original key-value pair" do
        @hash.should have(@keys.size).items
        @keys.each { |key| @hash.should include([key, key.value]) }
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

      it "should return nil for the removed keys" do
        @keys.each { |key| @hash.get(key).should == nil }
      end

      it "should contain no key-value pairs" do
        @hash.should have(0).items
      end
    end

    context "some of which are then replaced" do
      before :all do
        @ex_keys = @keys[0,100]
        @hash = @ex_keys.inject(@hash) { |h, k| h.with(k, k.value.to_s) }
      end

      it "should have the same size as before" do
        @hash.size.should == @keys.size
      end

      it "should not be empty" do
        @hash.empty?.should_not be_true
      end

      it "should retrieve the original values for the untouched keys" do
        (@keys - @ex_keys).each { |key| @hash.get(key).should == key.value }
      end

      it "should return the new values for the modified keys" do
        @ex_keys.each { |key| @hash.get(key).should == key.value.to_s }
      end

      it "should contain the appropriate key-value pair" do
        @hash.should have(@keys.size).items
        (@keys - @ex_keys).each { |key| @hash.should include([key, key.value]) }
        @ex_keys.each { |key| @hash.should include([key, key.value.to_s]) }
      end
    end

    context "some of which are then overwritten with the original value" do
      before :all do
        @ex_keys = @keys[0,100]
        @old_hash = @hash
        @hash = @ex_keys.inject(@hash) { |h, k| h.with(k, k.value) }
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

      it "should retrieve the original values for all keys" do
        @keys.each { |key| @hash.get(key).should == key.value }
      end

      it "should contain the appropriate key-value pair" do
        @hash.should have(@keys.size).items
        @keys.each { |key| @hash.should include([key, key.value]) }
      end
    end
  end
end
