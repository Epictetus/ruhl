require 'ruhl/rails/active_record_presenter'

class RuhlPresenter
  include ActiveRecordPresenter

  attr_reader :presentee, :context
  
  def initialize(obj, context)
    @presentee = obj
    @context = context
    define_paths(obj.class.name.underscore.downcase)
  end
  
end

module ActionController
  class Base    
    def presenter_for(obj)
      eval("#{obj.class.name}Presenter").new(obj,self)
    end
    
    helper_method :presenter_for   
  end
end
