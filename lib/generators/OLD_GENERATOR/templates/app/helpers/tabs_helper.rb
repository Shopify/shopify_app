module TabsHelper
  
  def active_nav_class(name, action = nil)
    if action.present?
      return if controller.action_name != action
    end
    
    'active' if controller.controller_name =~ /#{name}/i
  end
  
end