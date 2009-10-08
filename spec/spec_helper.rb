require File.expand_path(File.join(File.dirname(__FILE__), %w[.. lib ruhl]))

class TestUser
  attr_accessor :first_name, :last_name, :email

  def initialize(first, last , email = nil)
    @first_name = first
    @last_name  = last
    @email = email
  end
end
 
class ContextObject
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
      TestUser.new('Paul', 'Tin', 'paul@stonean.com'),
      TestUser.new('NoMail', 'Man')
    ]
  end

  def users?(tag = nil)
    true
  end

  def no_users_message(tag = nil)
    "Sorry no users found"
  end
end


def html(name)
  File.join( File.dirname(__FILE__), 'html', "#{name}.html" )
end

def create_doc(layout = nil)
  options = {:layout => layout} 

  html = Ruhl::Engine.new(@html, :layout => layout).
    render(ContextObject.new)

  do_parse(html)
end

def do_parse(html)
  Nokogiri::HTML(html)
end

