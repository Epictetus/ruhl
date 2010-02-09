module Ruhl
  class Engine
    attr_reader :layout, :layout_source, :local_object, :block_object
    attr_reader :document, :scope, :current_tag, :call_result, :ruhl_actions

    def initialize(html, options = {})
      @local_object   = options[:local_object] || options[:object]
      @block_object   = options[:block_object]
      @layout         = options[:layout]
      @layout_source  = options[:layout_source]


      if @layout || @local_object || @block_object
        @document = Nokogiri::HTML.fragment(html)
      else
        @document = Nokogiri::HTML(html)
        @document.encoding = Ruhl.encoding
      end

    end

    def render(current_scope)
      set_scope(current_scope)

      parse_doc(document)

      if @layout
        render_with_layout 
      else
        document.to_s.gsub(/\302\240/, ' ')
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
      raise LayoutNotFoundError.new(@layout) unless File.exists?(@layout)

      render_nodes Nokogiri::HTML( @layout_source || file_contents(@layout) )
    end

    def render_partial
      unless File.exists?(call_result)
        raise PartialNotFoundError.new(call_result) 
      end

      render_nodes Nokogiri::HTML.fragment( file_contents(call_result) )
    end

    def render_collection
      actions = ruhl_actions.join(",").to_s.strip if ruhl_actions

      current_tag['data-ruhl'] = actions unless actions.empty?
      html = current_tag.to_html
      
      new_content = call_result.collect do |item|
        
        if actions.empty? && current_tag.xpath('.//*[@data-ruhl]').empty?
          if item.kind_of?(Hash)
            t = current_tag.dup
            apply_hash(t, item)
            t.to_html
          else
            current_tag.inner_html = item.to_s
            current_tag.to_html
          end
        else
          Ruhl::Engine.new(html, :local_object => item).render(scope)
        end

      end.to_s

      current_tag.swap(new_content)
    end

    def render_block
      Ruhl::Engine.
        new(current_tag.inner_html, :block_object => call_result).
        render(scope)
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
  
      @current_tag = nodes.first

      @ruhl_actions = current_tag.remove_attribute('data-ruhl').value.split(',')

      process_attribute

      parse_doc(doc)
    end

    def process_attribute
      catch(:done) do
        ruhl_actions.dup.each_with_index do |action, ndx|
          # Remove action from being applied twice.
          ruhl_actions.delete_at(ndx)

          process_action(action)
        end
      end
    end

    def process_action(action)
      attribute, value = action.split(':')

      code = (value || attribute)
      @call_result = execute_ruby(code.strip)

      if value.nil?
        process_results
      else
        if attribute =~ /^_/
          send("ruhl#{attribute}")
        else
          write_tag_attribute(current_tag, attribute, call_result)
        end
      end
    rescue NoMethodError => nme
      Ruhl.logger.error "Processing Ruhl: #{action}"
      Ruhl.logger.error "Current tag.to_s: #{current_tag.to_s}"
      Ruhl.logger.error "Current tag: #{current_tag.inspect}"
      Ruhl.logger.error "Exception message: #{nme.message}"
      Ruhl.logger.error "Exception backtrace: #{nme.backtrace.join("\n")}"
      raise nme
    end

    def ruhl_use_if
      ruhl_if{ ruhl_use } 
    end

    def ruhl_use
      if call_result.kind_of?(Array)
        render_collection
        throw :done
      else
        current_tag.inner_html = render_block
      end
    end

    alias_method :ruhl_collection, :ruhl_use
     
    def ruhl_if
      if stop_processing?
        current_tag.remove
        throw :done
      else
        if continue_processing?
          # yield if block given. otherwise do nothing and have ruhl
          # continue processing
          yield if block_given?
        else
          if block_given?
            yield
          else
            process_results
          end
        end
      end
    end

    def ruhl_unless
      if call_result
        unless call_result_empty_array?
          current_tag.remove
          throw :done
        end
      end
    end

    def ruhl_partial
      current_tag.inner_html = render_partial
    end

    def ruhl_swap
      current_tag.swap(call_result)
    end

    def process_results
      if call_result.kind_of?(Hash)
        apply_hash(current_tag, call_result)
     else
        current_tag.inner_html = call_result.to_s
      end
    end

    def apply_hash(tag, hash)
      hash.each do |key, value|
        if key == :inner_html
          tag.inner_html = value.to_s
        else
          write_tag_attribute(tag, key.to_s, value)
        end
      end
    end

    def write_tag_attribute(tag, attribute, value)
      if tag[attribute] && attribute.downcase == 'class'
        tag[attribute] = "#{tag[attribute]} #{value}"
      else
        tag[attribute] = value.to_s
      end
    end

    def execute_ruby(code)
      if code == '_render_'
        _render_
      else
        args = code.strip.split('|').collect{|p| p.strip}

        [block_object, local_object, scope].compact.each do |obj|
          return call_to(obj, args) rescue NoMethodError
        end

        log_context(code)
        raise NoMethodError.new("method #{args.first} not found")
      end
    end

    def call_to(object, args)
      if object.kind_of?(Hash) && ( object.has_key?(args.first) || object.has_key?(args.first.to_sym))
        object[args.first] || object[args.first.to_sym]
      else
        object.send(*args)
      end
    end

    def set_scope(current_scope)
      raise Ruhl::NoScopeError unless current_scope
      @scope = current_scope 
    end

    def stop_processing?
      call_result.nil? || 
        call_result == false || 
          call_result_empty_array?
    end

    def continue_processing?
      call_result == true || call_result_populated_array?
    end

    def call_result_populated_array?
      call_result.kind_of?(Array) && !call_result.empty?
    end

    def call_result_empty_array?
      call_result.kind_of?(Array) && call_result.empty?
    end

    def log_context(code)
      error_message = <<CONTEXT
Context:
  tag           : #{current_tag.inspect}
  code          : #{code.inspect}
CONTEXT

      error_message << "  #{show_class_or_inspect('local_object')}\n"
      error_message << "  #{show_class_or_inspect('block_object')}\n"
      error_message << "  #{show_class_or_inspect('scope')}\n"

      Ruhl.logger.error error_message
    end

    def show_class_or_inspect(object_str)
      str = "#{object_str}   : "

      str + if Ruhl.send("inspect_#{object_str}")
              send(object_str).inspect
            else
              send(object_str).class.to_s
            end
    end

    if RUBY_VERSION == '1.8.6'
      def file_contents(path_to_file)
        File.open(path_to_file,'r') do |f|
          f.read
        end
      end
    else
      def file_contents(path_to_file)
        File.open(path_to_file, "r:#{Ruhl.encoding}") do |f|
          f.read
        end
      end
    end
  end # Engine
end # Ruhl
