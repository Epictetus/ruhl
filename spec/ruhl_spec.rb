require File.join(File.dirname(__FILE__), 'spec_helper')

describe Ruhl do
  before do
    @co = ContextObject.new
  end

  describe "basic.html" do
    before do
      @html = File.read html(:basic) 
    end

    it "content of p should be content from data_from_method" do
       doc = create_doc
       doc.xpath('//h1').first.content.should == @co.generate_h1
    end
  end

  describe "seo.html" do
    before do
      @html = File.read html(:seo)
    end

    it "meta keywords should be replaced" do
      doc = create_doc
      doc.xpath('//meta[@name="keywords"]').first['content'].
        should == @co.generate_keywords 
    end

    it "meta title should be replaced" do
      doc = create_doc
      doc.xpath('//meta[@name="description"]').first['content'].
        should == @co.generate_description
    end
  end

  describe "medium.html" do
    before do
      @html = File.read html(:medium)
      @doc = create_doc
    end

    it "first data row should equal first user " do
      table = @doc.xpath('/html/body/table/tr//td')
      table.children[0].to_s.should == "Jane"
      table.children[1].to_s.should == "Doe"
      table.children[2].to_s.should == "jane@stonean.com"
    end

    it "last data row should equal last user " do
      table = @doc.xpath('/html/body/table/tr//td')
      table.children[9].to_s.should == "Paul"
      table.children[10].to_s.should == "Tin"
      table.children[11].to_s.should == "paul@stonean.com"
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
      html = %{<div id="sidebar">
<h3>Real Sidebarlinks</h3>
<ul>
<li><a href="#">Real Link 1</a></li>
  <li><a href="#">Real Link 2</a></li>
  <li><a href="#">Real Link 3</a></li>
  <li><a href="#">Real Link 4</a></li>
</ul>
</div>}
      doc.xpath('//div[@id="sidebar"]').to_s.should == html
    end
  end

  describe "if.html" do
    describe "no users" do
      before do
        class ContextObject
          def users?(tag = nil)
            false
          end
        end

        @html = File.read html(:if)
        @doc = create_doc
      end

      it "table should not render" do
        nodes = @doc.xpath('/html/body//*')
        nodes.children.length.should == 2
        nodes.children[0].to_s.should == "This is the header template"
      end

      it "no user message should render" do
        nodes = @doc.xpath('/html/body//*')
        nodes.children[1].to_s.should == @co.no_users_message
      end
    end

    describe "has users" do
      before do
        class ContextObject
          def users?(tag = nil)
            true
          end
        end

        @html = File.read html(:if)
        @doc = create_doc
      end

      it "table should render" do
        nodes = @doc.xpath('/html/body//*')
        nodes.children.length.should > 1

        table = @doc.xpath('/html/body/table/tr//td')
        table.children[12].to_s.should == "NoMail"
        table.children[13].to_s.should == "Man"
      end
    end
  end

  describe "loop.html" do
    before do
      @html = File.read html(:loop)
    end

    it "will be injected into layout.html" do
      doc  = create_doc
      options = doc.xpath('/html/body/select//option')
      options.children.length.should == @co.states_for_select.length
    end
  end

  describe "form.html" do
    before do
      @html = File.read html(:main_with_form)
      @doc  = create_doc
    end

    it "first name will be set" do
      @doc.xpath('/html/body/div//input')[0]['value'].should == "Jane"
    end

    it "last name will be set" do
      @doc.xpath('/html/body/div//input')[1]['value'].should == "Doe"
    end

    it "email will be set" do
      @doc.xpath('/html/body/div//input')[2]['value'].should == "jane@stonean.com"
    end
  end

  describe "hash.html" do
    before do
      @html = File.read html(:hash)
    end

    it "have radio inputsi with proper attributes" do
      doc  = create_doc
      nodes = doc.xpath('/html/body/label//input')
      nodes[0]['value'].should == 'doe'
      nodes[1]['value'].should == 'joe'
      nodes[2]['value'].should == 'smo'
      nodes[3]['value'].should == 'tin'
      nodes[4]['value'].should == 'man'
    end
  end

  
  describe "use.html" do
    before do
      @html = File.read html(:use)
      @doc  = create_doc
    end

    it "first name will be set" do
      @doc.xpath('/html/body/div//input')[0]['value'].should == "Jane"
    end

    it "last name will be set" do
      @doc.xpath('/html/body/div//input')[1]['value'].should == "Doe"
    end

    it "email will be set" do
      @doc.xpath('/html/body/div//input')[2]['value'].should == "jane@stonean.com"
    end
  end
end



