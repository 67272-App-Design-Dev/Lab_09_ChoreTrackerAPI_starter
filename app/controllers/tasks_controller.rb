class TasksController < ApplicationController
  # Swagger Docs
  swagger_controller :task, "Task Management"

  swagger_api :index do
    summary "Fetches all tasks"
    notes "This lists all the tasks"
  end

  swagger_api :show do
    summary "Shows one task"
    param :path, :id, :integer, :required, "Task ID"
    notes "This lists details of one task"
    response :not_found
  end

  swagger_api :create do
    summary "Creates a new task"
    param :form, :name, :string, :required, "Name"
    param :form, :points, :integer, :required, "Points"
    param :form, :active, :boolean, :required, "Active"
    response :not_acceptable
  end

  swagger_api :update do
    summary "Updates an existing task"
      param :path, :id, :integer, :required, "task Id"
      param :form, :name, :string, :optional, "Name"
      param :form, :points, :integer, :optional, "Points"
      param :form, :active, :boolean, :optional, "Active"
    response :not_found
    response :not_acceptable
  end
  
  swagger_api :destroy do
    summary "Deletes an existing task"
    param :path, :id, :integer, :required, "task Id"
    response :not_found
  end

  # Main controller actions
  before_action :set_task, only: [:show, :update, :destroy]

  # GET /tasks
  def index
    @tasks = Task.all
    # render json: @tasks
    render json: TaskSerializer.new(@tasks)
  end

  # GET /tasks/:id
  def show
    # render json: @task
    render json: TaskSerializer.new(@task)
  end

  # POST /tasks
  def create
    @task = Task.new(task_params)

    if @task.save
      render json: @task, status: :created
    else
      render json: @task.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /tasks/:id
  def update
    if @task.update(task_params)
      render json: @task
    else
      render json: @task.errors, status: :unprocessable_entity
    end
  end

  # DELETE /tasks/:id
  def destroy
    @task.destroy
    head :no_content
  end

  private

  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.permit(:name, :points, :active)
  end
end