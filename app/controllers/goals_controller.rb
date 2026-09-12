class GoalsController < ApplicationController
  before_action :set_goal, only: [:edit, :update, :destroy]

  def index
    @goals = current_user.savings.goals.order(:target_date)
  end

  def new
    @goal = current_user.savings.goals.new
  end

  def create
    @goal = current_user.savings.goals.new(goal_params)
    if @goal.save
      redirect_to goals_path, notice: "Goal added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @goal.update(goal_params)
      redirect_to goals_path, notice: "Goal updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @goal.destroy
    redirect_to goals_path, notice: "Goal removed."
  end

  private

  def set_goal
    @goal = current_user.savings.goals.find(params[:id])
  end

  def goal_params
    params.require(:goal).permit(:name, :target, :target_date, :icon, :color)
  end
end
