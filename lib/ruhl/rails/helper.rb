module Ruhl
  module Rails
    module Helper
      def form_authenticity
        {:value => form_authenticity_token, :type => "hidden", :name => "authenticity_token"}
      end  
    end
  end
end