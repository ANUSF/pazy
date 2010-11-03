require 'pazy'
include Pazy

describe "A List" do
  context "when empty" do
    before :all do
      @list = List.new
    end

    it "should have size 0" do
      @list.size.should == 0
    end

    it "should be empty" do
      @list.should be_empty
    end

    it "should contain no elements" do
      @list.should have(0).items
    end

    it "should still be empty when without is called" do
      @list.without(5).should be_empty
    end
  end

  context "when create from the range 1..10" do
    before :all do
      @list = List.from_enum 1..10
    end

    it "should have size 10" do
      @list.size.should == 10
    end

    it "should not be empty" do
      @list.should_not be_empty
    end

    it "should contain the numbers from 1 to 10" do
      @list.should have(10).items
      (1..10).each { |i| @list.should include(i) }
    end

    context "after which the number 5 is removed" do
      before :all do
        @list = @list.without 5
      end

      it "should have size 9" do
        @list.size.should == 9
      end

      it "should not be empty" do
        @list.should_not be_empty
      end

      it "should contain the numbers from 1 to 10 except 5" do
        @list.should have(9).items
        (1..10).each { |i| @list.should include(i) unless i == 5 }
        @list.should_not include(5)
      end
    end

    context "after which the number 12 is removed" do
      before :all do
        @old_list = @list
        @list = @list.without 12
      end

      it "should have size 10" do
        @list.size.should == 10
      end

      it "should not be empty" do
        @list.should_not be_empty
      end

      it "should contain the numbers from 1 to 10" do
        @list.should have(10).items
        (1..10).each { |i| @list.should include(i) }
      end

      it "should be the same Ruby object after the removal" do
        @list.should be_equal(@old_list)
      end
    end

    context "after which all items are removed" do
      before :all do
        @list = (1..10).inject(@list) { |l,i| l.without i }
      end

      it "should have size 0" do
        @list.size.should == 0
      end

      it "should be empty" do
        @list.should be_empty
      end

      it "should contain no items" do
        @list.should have(0).items
      end
    end

    context "after which the number 12 is prepended" do
      before :all do
        @list = @list.after 12
      end

      it "should have size 11" do
        @list.size.should == 11
      end

      it "should not be empty" do
        @list.should_not be_empty
      end

      it "should contain the numbers from 1 to 10 and the number 12" do
        @list.should have(11).items
        (1..10).each { |i| @list.should include(i) }
        @list.should include(12)
      end
    end
  end
end
