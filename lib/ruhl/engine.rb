module Ruhl
  class Engine
    attr_reader :document, :scope, :layout, :layout_source, 
      :local_object, :block_object

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
      render_file( @layout_source || File.read(@layout) ) 
    end

    def render_partial(tag, code)
      file = execute_ruby(tag, code)
      raise PartialNotFoundError.new(file) unless File.exists?(file)

      render_file( File.read(file) )
    end

    def render_collection(tag, code, actions = nil)
      results = execute_ruby(tag, code)

      actions = actions.to_s.strip

      tag['data-ruhl'] = actions if actions.length > 0
      html = tag.to_html
      
      new_content = results.collect do |item|
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

    def render_block(tag, code)
      bo = execute_ruby(tag, code) 
      Ruhl::Engine.new(tag.inner_html, :block_object => bo).render(scope)
    end

    def render_file(contents)
      doc = Nokogiri::HTML( contents ) 
      parse_doc(doc)
      doc.to_s
    end

    def parse_doc(doc)
      if (nodes = doc.xpath('*[@data-ruhl][1]')).empty?
        nodes = doc.search('*[@data-ruhl]')
      end

      return if nodes.empty?

      tag = nodes.first
      code = tag.remove_attribute('data-ruhl') 
      process_attribute(tag, code.value)

      parse_doc(doc)
    end

    def process_attribute(tag, code)
      actions = code.split(',')
      actions.dup.each_with_index do |pair, ndx|
        attribute, value = pair.split(':')
        
        attribute.strip!

        if value.nil?
          results = execute_ruby(tag, attribute)
          process_results(tag, results)
        else
          value.strip!
          
          unless attribute =~ /^_/
            tag[attribute] = execute_ruby(tag, value)
          else
            case attribute
            when "_use"
              tag.inner_html =  render_block(tag, value)
            when "_partial"
              tag.inner_html = render_partial(tag, value)
            when "_collection"
              actions.delete_at(ndx)
              render_collection(tag, value, actions.join(','))
              return
            when "_if" 
              return unless process_if(tag, value)
            when "_unless"
              return if process_unless(tag, value)
            end
          end
        end
      end
    end
     
    def process_if(tag, value)
      contents = execute_ruby(tag, value)
      if contents 
        process_results(tag, contents) unless contents == true
        true
      else
        tag.remove
        false
      end
    end

    def process_unless(tag, value)
      contents = execute_ruby(tag, value)
      if contents
        tag.remove
        true
      else
        false
      end
    end

    def process_results(tag, results)
      if results.is_a?(Hash)
        results.each do |key, value|
          if key == :inner_html
            tag.inner_html = value
          else
            tag[key.to_s] = value
          end
        end
      else
        tag.inner_html = results.to_s
      end
    end

    def execute_ruby(tag, code)
      unless code == '_render_'
        if local_object && local_object.respond_to?(code)
          local_object.send(code)
        elsif block_object && block_object.respond_to?(code)
          block_object.send(code)
        else
          scope.send(code)
        end
      else
        _render_
      end
    rescue NoMethodError => e
      log_context(tag,code)
      raise e
    end

    def set_scope(current_scope)
      raise Ruhl::NoScopeError unless current_scope
      @scope = current_scope 
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
