require 'ruhl'
require 'ruhl/rails/ruhl_presenter'

module Ruhl
  class Plugin < ActionView::TemplateHandler

    def initialize(action_view)
      @action_view = action_view
    end
    
    def render(template, options = {})
      if layout = options[:layout]
        layout_template = @action_view.controller.send(:find_layout, layout, 
                                                        @action_view.controller.send(:default_template_format) )
      else
        layout_template = @action_view.controller.active_layout
      end

      if layout_template
        options[:layout]        = layout_template.filename 
        options[:layout_source] = layout_template.source
      end

      Ruhl::Engine.new(template.source, options).render(@action_view)
    end
  end
end

ActionView::Template.register_template_handler(:ruhl, Ruhl::Plugin)

ActionView::Template.exempt_from_layout(:ruhl)


module Ruhl
  class Engine
    private

    def render_partial
      template = scope.view_paths.find_template(call_result)

      raise PartialNotFoundError.new(call_result) unless template

      render_nodes Nokogiri::HTML.fragment( template.source )
    end

  end
end
