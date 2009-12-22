require 'ruhl'

module Sinatra
  module Templates
    def ruhl(template, options = {}, locals = {})
      require_warn('Ruhl') unless defined?(::Ruhl::Engine)

      render :ruhl, template, options, locals
    end

    private

    def render(engine, template, options={}, locals={})
      # merge app-level options
      options = self.class.send(engine).merge(options) if self.class.respond_to?(engine)

      views = options.delete(:views) || self.class.views || "./views"

      # render template
      data, options[:filename], options[:line] = lookup_template(engine, template, views)

      __send__("render_#{engine}", template, data, options)
    end
    
    def render_ruhl(template, data, options)
      ::Ruhl::Engine.new(data, options).render(self)
    end
  end
end

module Ruhl
  class Engine
    private

    def render_partial
      views = scope.class.views || "./views"

      data, filename, line = scope.send :lookup_template, :ruhl, call_result.to_sym, views

      raise PartialNotFoundError.new(call_result) unless data

      render_nodes Nokogiri::HTML.fragment(data) 
    end
  end
end
