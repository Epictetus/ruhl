module Ruhl
  class Engine
    attr_reader :layout, :layout_source, :local_object, :block_object
    attr_reader :document, :scope, :call_results, :ruhl_actions

    def initialize(html, options = {})
      @local_object   = options[:local_object] || options[:object]
      @block_object   = options[:block_object]
      @layout_source  = options[:layout_source]

      if @layout = options[:layout]
        raise LayoutNotFoundError.new(@layout) unless File.exists?(@layout)
      end

      if @layout || @local_object || @block_object
        @document = Nokogiri::HTML.fragment(html)
      else
        @document = Nokogiri::HTML(html)
      end
    end

    def render(current_scope)
      set_scope(current_scope)

      parse_doc(document)

      if @layout
        render_with_layout 
      else
        document.to_s
      end
    end

    # The _render_ method is used within a layout to inject
    # the results of the template render.
    #
    # Ruhl::Engine.new(html, :layout => path_to_layout).render(self)
    def _render_
      document.to_s
    end

    private

    def render_with_layout
      render_nodes Nokogiri::HTML( @layout_source || File.read(@layout) )
    end

    def render_partial
      unless File.exists?(call_results)
        raise PartialNotFoundError.new(call_results) 
      end

      render_nodes Nokogiri::HTML.fragment( File.read(call_results) )
    end

    def render_collection(tag)
      actions = ruhl_actions.join(",").to_s.strip if ruhl_actions

      tag['data-ruhl'] = actions if actions.length > 0
      html = tag.to_html
      
      new_content = call_results.collect do |item|
        # Call to_s on the item only if there are no other actions 
        # and there are no other nested data-ruhls
        if actions.length == 0 && tag.xpath('.//*[@data-ruhl]').length == 0
          tag.inner_html = item.to_s
          tag.to_html
        else
          Ruhl::Engine.new(html, :local_object => item).render(scope)
        end
      end.to_s

      tag.swap(new_content)
    end

    def render_block(tag)
      Ruhl::Engine.new(tag.inner_html, :block_object => call_results).render(scope)
    end

    def render_nodes(nodes)
      parse_doc(nodes)
      nodes.to_s
    end

    def parse_doc(doc)
      if (nodes = doc.xpath('*[@data-ruhl][1]')).empty?
        nodes = doc.search('*[@data-ruhl]')
      end

      return if nodes.empty?

      tag = nodes.first

      @ruhl_actions = tag.remove_attribute('data-ruhl').value.split(',')

      process_attribute(tag)

      parse_doc(doc)
    end

    def process_attribute(tag)
      catch(:done) do
        ruhl_actions.dup.each_with_index do |action, ndx|
          # Remove action from being applied twice.
          ruhl_actions.delete_at(ndx)

          process_action(tag, action)
        end
      end
    end

    def process_action(tag, action)
      attribute, value = action.split(':')

      code = (value || attribute)
      @call_results = execute_ruby(tag, code.strip)

      if value.nil?
        process_results(tag)
      else
        if attribute =~ /^_/
          process_ruhl(tag, attribute, value)
        else
          tag[attribute] = call_results.to_s
        end
      end
    end

    def process_ruhl(tag, attribute, value)
      case attribute
      when "_use_if"
      when "_use_unless"
      when "_use", "_collection"
        ruhl_use(tag)
      when "_partial"
        tag.inner_html = render_partial
      when "_if" 
        ruhl_if(tag)
      when "_unless"
        ruhl_unless(tag)
      end
    end

    def ruhl_use(tag)
      if call_results.kind_of?(Enumerable) and !call_results.instance_of?(String)
        render_collection(tag)
        throw :done
      else
        tag.inner_html = render_block(tag)
      end
    end
     
    def ruhl_if(tag)
      if stop_processing?
        tag.remove
        throw :done
      else
        unless continue_processing?
          process_results(tag)
        end
      end
    end

    def ruhl_unless(tag)
      if call_results
        unless call_results_empty?
          tag.remove
          throw :done
        end
      end
    end

    def process_results(tag)
      if call_results.is_a?(Hash)
        call_results.each do |key, value|
          if key == :inner_html
            tag.inner_html = value.to_s
          else
            tag[key.to_s] = value.to_s
          end
        end
      else
        tag.inner_html = call_results.to_s
      end
    end

    def execute_ruby(tag, code)
      if code == '_render_'
        _render_
      else
        if block_object && block_object.respond_to?(code)
          block_object.send(code)
        elsif local_object && local_object.respond_to?(code)
          local_object.send(code)
        else
          scope.send(code)
        end
      end
    rescue NoMethodError => e
      log_context(tag,code)
      raise e
    end

    def set_scope(current_scope)
      raise Ruhl::NoScopeError unless current_scope
      @scope = current_scope 
    end

    def stop_processing?
      call_results.nil? || 
        call_results == false || 
          call_results_empty?
    end

    def continue_processing?
      call_results == true || !call_results_empty?
    end

    def call_results_empty?
      call_results.kind_of?(Enumerable) && call_results.empty?
    end

    def log_context(tag,code)
      Ruhl.logger.error <<CONTEXT
Context:
  tag           : #{tag.inspect}
  code          : #{code.inspect}
  local_object  : #{local_object.inspect}
  block_object  : #{block_object.inspect}
  scope         : #{scope.class}
CONTEXT
    end
  end # Engine
end # Ruhl
