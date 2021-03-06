class RequestsController < ApplicationController
  before_filter :authenticate_user!
  before_action :set_request, only: [:show, :edit, :update, :destroy]
  skip_after_action :verify_authorized, only: [:index, :search]

  respond_to :html

  SearchQuery = Struct.new(:search, :order_by) do include ActiveModel::Model; end

  def index
    @user_requests = Request.available_to(current_user, PaginationOptions.new(params[:page]))
    @search_form = RequestSearchForm.new(SearchQuery.new)
    respond_with(@user_requests)
  end

  def show
    authorize @user_request
    @requester = @user_request.user
    @requester_offers = Offer.owned_by(@requester, PaginationOptions.new(params[:offers_page], 5))
    @requester_references = Reference.to_user(@requester, PaginationOptions.new(params[:references_page], 5))
    respond_with(@user_request)
  end

  def new
    @form = RequestForm.new(Request.new)
    @request_types = Request.type_options
    authorize @form.model
    respond_with(@user_request = @form)
  end

  def edit
    authorize @user_request
    @request_types = Request.type_options
    @user_request = RequestForm.new(@user_request)
  end

  def create
    @request_types = Request.type_options

    @form = RequestForm.new(Request.new(user: current_user))
    authorize @form.model
    if @form.validate(params[:request])
      if @form.visibility == :pod
        @form.model.pod = Pod.home_pod_for_user(current_user)
      else
        @form.model.pod = nil
      end
      @form.save
    end
    respond_with(@user_request = @form)
  end

  def update
    @request_types = Request.type_options

    @form = RequestForm.new(@user_request)
    authorize @form.model
    if @form.validate(params[:request])
      if @form.visibility == :pod
        @form.model.pod = Pod.home_pod_for_user(current_user)
      else
        @form.model.pod = nil
      end
      @form.save
    end
    respond_with(@user_request = @form)
  end

  def destroy
    authorize @user_request
    @user_request.destroy
    respond_with(@user_request)
  end

  def search
    @search_form = RequestSearchForm.new(SearchQuery.new)
    if @search_form.validate(params[:request_search])
      @search_form.save do |search_data|
        @user_requests = Request.search_results(search_data, current_user, PaginationOptions.new(params[:page]))
        render :index
      end
    else
      redirect_to requests_path
    end
  end

  private
    def set_request
      @user_request = Request.find(params[:id])
    end
end
