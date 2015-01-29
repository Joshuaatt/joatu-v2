class MessagesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :get_box, except: [:new]

  respond_to :html

  def new
    @form = MessageForm.new(Message.new)
    if params[:receiver].present?
      receiver = User.find_by_id(params[:receiver])
      @form.recipients = receiver.id
    end
    authorize @form.model
    @message = @form
  end

  def create
    @form = MessageForm.new(Message.new(sender: authenticated_user))
    if @form.validate(params[:message])
      authorize @form.model
      @message = @form.save
      flash[:success] = t('mailboxer.sent')
      redirect_to conversation_path(@message.conversation, :box => :sentbox)
    else
      render action: :new
    end
  end

  private

  def get_box
    if params[:box].blank? or !["inbox","sentbox","trash"].include?params[:box]
      params[:box] = 'inbox'
    end

    @box = params[:box]
  end
end
