# Title::     ActsAsWizard
# Author::    Amos King  (mailto:damos.l.king@gmail.com)
# Copyright:: Copyright (c) 2008 A. King Software Development and Consulting, LC
# License::   Distributed under the MIT licencse


module AmosKing #:nodoc:
  module Acts #:nodoc:
    module Wizard #:nodoc:
      
      # The Exception raised if there are no arguments passed to acts_as_wizard
      class ErrPages < Exception #:nodoc:
        def message
          "ErrPages: At least one pages must be specified"
        end
      end
      
      def self.included(base)        #:nodoc:
        base.extend ActMacro
      end
      
      module ActMacro #:nodoc:
        # Sets up the main wizard model with the correct states ad transitions. 
        def acts_as_wizard(*opts)
          raise ErrPages unless opts.size > 0
          class_inheritable_reader :pages
          write_inheritable_attribute :pages, opts
           
          self.send(:include, AmosKing::Acts::Wizard::InstanceMethods)
        end
      end
      
      module InstanceMethods
        # returns a symbol for the current wizard page
        def get_current_wizard_step
          pages[self.page || 0]
        end
        
        def next!
          self.page ||= 0
          self.page += 1 unless self.page + 1 >= pages.size
          self
        end
        
        def previous!
          self.page ||= 0
          self.page -= 1 unless self.page <= 0
          self
        end

        # Returns the class of the current page
        # if the state is :favorite_color the class FavoriteColor is returned
        # and can then have methods called on it.  ie: page_class.new 
        def page_class
          current_template.classify.constantize
        end

        # Returns the current page
        def current_page
          self.page ||= 0
          self.page + 1
        end

        # Returns total pages of wizard
        def total_pages
          pages.size
        end

        # current_page - 1 or nil if there is no previous page
        def previous_page
          current_page > 1 ? (current_page - 1) : nil
        end

        # current_page + 1 or nil if there is no next page
        def next_page
          current_page < total_pages ? (current_page + 1) : nil
        end

        # Returns the current state as a string
        def current_template
          get_current_wizard_step.to_s
        end
        
        # Returns the existing wizard page model or a new one if it doesn't exist
        def get_wizard_page
          self.current_template ||= self.page_class.new
        end

        def get_page_template( page )
          pages[ page ]
        end

        # Updates the current page to the next/prevous page and returns the model for that page.
        # The returned model will be a new model if one doesn't already exist.
        def switch_wizard_page(direction)
          send(direction)
        end
      end
    end
    
    module WizardHelper
        # Creates a button to go to the previous page in the wizard.
        # Also creates a hidden field used to tell the controller which direction to go.
        def previous_wizard_button(main_wizard_model, label = 'Previous', options={}, html_options={} )
          unless main_wizard_model.page && main_wizard_model.page > 0
            html_options = { :disabled => true }
          end
          html_options.merge!( {
                     :onclick => "document.getElementById('direction').value = 'previous!';",
          })
          button_to("&#8592; #{label}", 
                    { :controller=>self.controller_name, :action => self.action_name}, 
                    html_options
                    )
        end
        
        # Creates a button to go to the next page in the wizard.
        # Also creates a hidden field used to tell the controller which direction to go.
        def next_wizard_button(main_wizard_model, label = 'Next')
          submit_tag("#{label} &#8594;") +
          hidden_direction_field
        end
        
        # Generates a hidden field with the default value next!, and is used in conjunction javascript
        # to pass the correct movement in the wizard to the controller.
        def hidden_direction_field
          hidden_field_tag(:direction, "next!", :class => 'direction')
        end
        
        # Renders the proper partial for the current wizard page
        # pages are stored in app/views/wizard_model_name_wizard_pages/_wizard_page_model_name.html.erb
        def render_wizard_partial(main_wizard_model, f)
          @page = main_wizard_model.page || 0
          path = @controller.class.controller_path

          template = ""
          (0...@page).each { |i|
            fname = "#{path}/sub_pages/#{main_wizard_model.get_page_template(i)}_hidden"
            template << "<%= yield :included_wizard_page_#{i+1} %>"
            content_for "included_wizard_page_#{i+1}" do
              render :partial=>fname, :locals=>{:main_form=>f} rescue ""
            end
          }

          template << "<%= yield :included_wizard_page_#{@page+1} %>"
          content_for "included_wizard_page_#{@page+1}" do
            render :partial=>wizard_page_template(main_wizard_model), :locals=>{:main_form=>f}
          end

          render :inline=>template
        end
        
        # Returns the path to the partial for the current tempalte
        # pages are stored in app/views/wizard_model_name_wizard_pages/_wizard_page_model_name.html.erb
        def wizard_page_template(main_wizard_model) 
#          "#{main_wizard_model.class.to_s.underscore}_wizard_pages/#{main_wizard_model.current_template}" 
          path = @controller.class.controller_path

          "#{path}/sub_pages/#{main_wizard_model.current_template}" 
        end
    end
  end
end
