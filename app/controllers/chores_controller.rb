class ChoresController < ApplicationController
  # Swagger Documentation
  swagger_controller :chore, "Chore Management"

  swagger_api :index do
    summary "Fetches all Chores"
    notes "This lists all the chores"
  end

  swagger_api :show do
    summary "Shows one chore"
    param :path, :id, :integer, :required, "Chore ID"
    notes "This lists details of one chore"
    response :not_found
  end

  swagger_api :create do
    summary "Creates a new Chore"
    param :form, :child_id, :integer, :required, "Child"
    param :form, :task_id, :integer, :required, "Task"
    param :form, :due_on, :date, :required, "Due_on"
    param :form, :completed, :boolean, :required, "Completed"
    response :not_acceptable
  end

  swagger_api :update do
    summary "Updates an existing Chore"
      param :path, :id, :integer, :required, "Chore Id"
      param :form, :child_id, :integer, :optional, "Child"
      param :form, :task_id, :integer, :optional, "Task"
      param :form, :due_on, :date, :optional, "Due_on"
      param :form, :completed, :boolean, :optional, "Completed"
    response :not_found
    response :not_acceptable
  end

  swagger_api :destroy do
    summary "Deletes an existing Chore"
    param :path, :id, :integer, :required, "Chore Id"
    response :not_found
  end

  # Main controller actions
  before_action :set_chore, only: [:show, :update, :destroy]

  # GET /chores
  def index
    @chores = Chore.all
    # render json: @chores
    render json: ChoreSerializer.new(@chores)
  end

  # GET /chores/:id
  def show
    # render json: @chore
    render json: ChoreSerializer.new(@chore)
  end

  # POST /chores
  def create
    @chore = Chore.new(chore_params)

    if @chore.save
      render json: @chore, status: :created
    else
      render json: @chore.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /chores/:id
  def update
    if @chore.update(chore_params)
      render json: @chore
    else
      render json: @chore.errors, status: :unprocessable_entity
    end
  end

  # DELETE /chores/:id
  def destroy
    @chore.destroy
    head :no_content
  end

  private

  def set_chore
    @chore = Chore.find(params[:id])
  end

  def chore_params
    params.permit(:child_id, :task_id, :due_on, :completed)
  end
end