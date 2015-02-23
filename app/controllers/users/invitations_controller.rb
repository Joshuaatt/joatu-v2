class Users::InvitationsController < Devise::InvitationsController
  def edit
    @form = NewUserForm.new(self.resource)
    super
  end

  def update
    form = accept_form
    self.resource = form.model
    invitation_accepted = form.errors.empty?

    yield resource if block_given?

    if invitation_accepted
      flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
      set_flash_message :notice, flash_message if is_flashing_format?
      sign_in(resource_name, resource)
      respond_with resource, :location => after_accept_path_for(resource)
    else
      respond_with_navigational(form){ render :edit }
    end
  end

  private

  # this is called when accepting invitation
  # should return a form holding an instance 
  # of resource class
  def accept_form
    resource = resource_class.find_by_invitation_token(update_resource_params[:invitation_token], false)
    @form = NewUserForm.new(resource)
    if @form.validate(update_resource_params)
      @form.save do |data|
        data = data.reject {|k,v| %w(tou_agreement).include? k }
        @form.model.update(data)
        @form.model.accept_invitation!
      end
    end
    
    @form
  end
end