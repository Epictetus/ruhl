module Ruhl
  class Plugin < ActionView::TemplateHandler

    def initialize(action_view)
      @action_view = action_view
    end
    
    def render(template, options)
      layout = @action_view.controller.send(:active_layout)

      puts "==========> @action_view: #{@action_view.controller.response.inspect}"
      puts "==========> template: #{template.inspect}"
      puts "==========> options: #{options.inspect}"
    end
  end
end

ActionView::Template.register_template_handler(:ruhl, Ruhl::Plugin)

ActionView::Template.exempt_from_layout(:ruhl)

