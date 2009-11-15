module ActiveRecordPresenter
  def error_messages?
    !presentee.errors.empty?
  end
  
  def error_messages
    return if presentee.errors.empty?
    presentee.errors.full_messages
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
  
  def define_paths(model)
    define_action(model, 'show')                      # show_path(@user)
    define_action(model, 'update')                    # update_path(@user)
    define_action(model, 'delete')                    # delete_path(@user)
    define_action("edit_#{model}", 'edit')            # edit_path(@user)
    define_action(model.pluralize, 'index', false)    # index_path
    define_action(model.pluralize, 'create', false)   # create_path
    define_action("new_#{model}", 'new', false)       # new_path
  end
  
  private
  
  def define_action(model, action, use_presentee = true)
    if use_presentee
      self.class.send(:define_method, "#{action}_path") do
        context.send("#{model}_path", presentee)
      end      
      self.class.send(:define_method, "#{action}_url") do
        context.send("#{model}_url", presentee)
      end      
    else
      self.class.send(:define_method, "#{action}_path") do
        context.send("#{model}_path")
      end      
      self.class.send(:define_method, "#{action}_url") do
        context.send("#{model}_url")
      end      
    end
  end
end
