require 'ruhl'

module Ruhl
  class Plugin < ActionView::TemplateHandler

    def initialize(action_view)
      @action_view = action_view
    end
    
    def render(template, options = {})
      layout = @action_view.controller.send(:active_layout)

      options[:layout]        = layout.filename
      options[:layout_source] = layout.source

      Ruhl::Engine.new(template.source, options).render(@action_view)
    end
  end
end

ActionView::Template.register_template_handler(:ruhl, Ruhl::Plugin)

ActionView::Template.exempt_from_layout(:ruhl)

