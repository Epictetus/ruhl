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

    protected

    def present(object_sym, action_sym)
      render  :template => "#{object_sym.to_s.pluralize}/#{action_sym}", 
        :locals => {:object => presenter_for( instance_variable_get("@#{object_sym}") )}    
    end

    def presenter_for(obj)
      eval("#{obj.class.name}Presenter").new(obj, @template)
    end
    
    helper_method :presenter_for   
  end
end
