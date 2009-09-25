require File.join(File.dirname(__FILE__), 'spec_helper')

def generate_h1(tag = nil)
  "data from presenter"     
end

def data_from_method(tag = nil)
  "I am data from a method"
end

def generate_description(tag = nil)
  "I am a custom meta description"
end

def generate_keywords(tag = nil)
  "I, am, custom, keywords"
end

def my_content(tag = nil)
  "hello from my content."
end

def sidebar_partial(tag = nil)
  html(:sidebar)
end

def user_list(tag = nil)
  [ 
    TestUser.new('Jane', 'Doe', 'jane@stonean.com'),
    TestUser.new('John', 'Joe', 'john@stonean.com'),
    TestUser.new('Jake', 'Smo', 'jake@stonean.com'),
    TestUser.new('Paul', 'Tin', 'paul@stonean.com')
  ]

end

describe Ruhl do

  describe "basic.html" do
    before do
      @html = File.read html(:basic) 
    end

    it "content of p should be content from data_from_method" do
       doc = create_doc
       doc.xpath('//h1').first.content.should == generate_h1
    end
  end

  describe "seo.html" do
    before do
      @html = File.read html(:seo)
    end

    it "meta keywords should be replaced" do
      doc = create_doc
      doc.xpath('//meta[@name="keywords"]').first['content'].
        should == generate_keywords 
    end

    it "meta title should be replaced" do
      doc = create_doc
      doc.xpath('//meta[@name="description"]').first['content'].
        should == generate_description
    end
  end

  describe "medium.html" do
    before do
      @html = File.read html(:medium)
    end

    it "ul content should have new li's" do
      doc = create_doc
      #ul = doc.xpath('//ul').first
      #ul.inner_html.should ==  "<li>line item 1</li>\n<li>line item 2</li>\n"
    end
  end

  describe "fragment.html" do
    before do
      @html = File.read html(:fragment)
    end

    it "will be injected into layout.html" do
      doc  = create_doc( html(:layout) )
      doc.xpath('//h1').should_not be_empty
      doc.xpath('//p').should_not be_empty
    end
  end

  describe "main_with_sidebar.html" do
    before do
      @html = File.read html(:main_with_sidebar)
    end

    it "should replace sidebar with partial contents" do
      doc = create_doc
    end
  end
end



