require 'ruhl/rails/active_record'
require 'ruhl/rails/helper'

module Ruhl
  module Rails
    class Presenter
      include Ruhl::Rails::ActiveRecord
      include Ruhl::Rails::Helper
  
      attr_reader :presentee, :context
  
      def initialize(context, obj = nil)
        @context = context

        # May only want to use the form helper
        if obj
          @presentee = obj
          define_paths(obj.class.name.underscore.downcase)
        end
      end
    
      def method_missing(name, *args)
        if presentee.respond_to?(name)
          # Pass presenter method call to model so you don't have to
          # redefine every model method in the presenter class.
          presentee.send(name, *args)
        elsif context.respond_to?(name)
          # Instead of saying context.link_to('Some site', some_path)
          # can just use link_to
          context.send(name, *args)
        end
      end

      # Extend scope of respond_to? to model.
      def respond_to?(name)  
        if super
          true
        else
          presentee.respond_to?(name)
        end
      end  
    end
  end
end

module ActionController
  class Base    

    protected

    def present(action_sym = action_name, object = nil)
      object_sym = controller_name.singularize unless object

      render  :template => "#{object_sym.to_s.pluralize}/#{action_sym}", 
        :locals => {:object => presenter_for(object_sym) }    
    end

    def presenter_for(object_sym)
      # Set instance variable if it exists
      if instance_variables.include?("@#{object_sym}")
        obj = instance_variable_get("@#{object_sym}")
      end

      Object.const_get("#{object_sym.to_s.camelize}Presenter").new(@template, obj)
    end

    helper_method :presenter_for   
  end
end
