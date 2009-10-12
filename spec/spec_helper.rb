require File.expand_path(File.join(File.dirname(__FILE__), %w[.. lib ruhl]))

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


class TestUser
  attr_accessor :id, :first_name, :last_name, :email

  def initialize(first, last , email = nil)
    @first_name = first
    @last_name  = last
    @email = email
    @id = rand(100)
  end

  def radio_input(tag = nil)
    { :inner_html => first_name, :id => "user_#{id.to_s}", 
      :name => "user[id]", :value => last_name.downcase}
  end
end
 
def user(tag = nil)
  TestUser.new('Jane', 'Doe', 'jane@stonean.com')
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

  def form_partial(tag = nil)
    html(:form)
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

  def states_for_select(tag = nil)
    state = Struct.new(:abbr, :name)
    [ state.new('AL', 'Alabama'),
      state.new('AK', 'Alaska'),
      state.new('AZ', 'Arizona'),
      state.new('AR', 'Arkansas'),
      state.new('CA', 'California'),
      state.new('CO', 'Colorado'),
      state.new('CT', 'Connecticut'),
      state.new('DE', 'Delaware'),
      state.new('FL', 'Florida'),
      state.new('GA', 'Georgia'),
      state.new('HI', 'Hawaii'),
      state.new('ID', 'Idaho'),
      state.new('IL', 'Illinois'),
      state.new('IN', 'Indiana'),
      state.new('IA', 'Iowa'),
      state.new('KS', 'Kansas'),
      state.new('KY', 'Kentucky'),
      state.new('LA', 'Louisiana'),
      state.new('ME', 'Maine'),
      state.new('MD', 'Maryland'),
      state.new('MA', 'Massachusetts'),
      state.new('MI', 'Michigan'),
      state.new('MN', 'Minnesota'),
      state.new('MS', 'Mississippi'),
      state.new('MO', 'Missouri'),
      state.new('MT', 'Montana'),
      state.new('NE', 'Nebraska'),
      state.new('NV', 'Nevada'),
      state.new('NH', 'New Hampshire'),
      state.new('NJ', 'New Jersey'),
      state.new('NM', 'New Mexico'),
      state.new('NY', 'New York'),
      state.new('NC', 'North Carolina'),
      state.new('ND', 'North Dakota'),
      state.new('OH', 'Ohio'),
      state.new('OK', 'Oklahoma'),
      state.new('OR', 'Oregon'),
      state.new('PA', 'Pennsylvania'),
      state.new('RI', 'Rhode Island'),
      state.new('SC', 'South Carolina'),
      state.new('SD', 'South Dakota'),
      state.new('TN', 'Tennessee'),
      state.new('TX', 'Texas'),
      state.new('UT', 'Utah'),
      state.new('VT', 'Vermont'),
      state.new('VA', 'Virginia'),
      state.new('WA', 'Washington'),
      state.new('WV', 'West Virginia'),
      state.new('WI', 'Wisconsin'),
      state.new('WY', 'Wyoming')]
  end

end
