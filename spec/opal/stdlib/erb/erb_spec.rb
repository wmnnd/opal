require 'erb'

require File.expand_path('../simple', __FILE__)
require File.expand_path('../quoted', __FILE__)
require File.expand_path('../inline_block', __FILE__)
require File.expand_path('../with_locals', __FILE__)

describe "ERB files" do
  before :each do
    @simple = Template['stdlib/erb/simple']
    @quoted = Template['stdlib/erb/quoted']
    @inline_block = Template['stdlib/erb/inline_block']
    @with_locals = Template['stdlib/erb/with_locals']
  end

  it "should be defined by their filename on Template namespace" do
    @simple.should be_kind_of(Template)
  end

  it "calling the block with a context should render the block" do
    @some_data = "hello"
    @simple.render(self).should == "<div>hello</div>\n"
  end

  it "should accept quotes in strings" do
    @name = "adam"
    @quoted.render(self).should == "<div class=\"foo\">hello there adam</div>\n"
  end

  it "should be able to handle inline blocks" do
    @inline_block.should be_kind_of(Template)
  end

  describe "locals" do
    it "can be passed to a compiled template" do
      def self.non_local; 'Ford'; end
      @with_locals.render(self, {is_local: 'Prefect'}).should == "Ford Prefect\n"
    end
  end
end
