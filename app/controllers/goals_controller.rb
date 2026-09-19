class GoalsController < ApplicationController
  PALETTE = %w[#3b82f6 #ef4444 #8b5cf6 #f59e0b #f97316 #06b6d4 #22c55e #ec4899 #6b7280].freeze

  before_action :set_goal, only: [ :edit, :update, :destroy ]

  def index
    @savings = current_user.savings
    @goals = @savings.goals.order(:target_date)
    @completed_goals = @goals.select(&:completed?)
    @active_goals = @goals.reject(&:completed?)
  end

  def new
    @goal = current_user.savings.goals.new(icon: "target", color: PALETTE.first)
  end

  def create
    @goal = current_user.savings.goals.new(goal_params)
    if @goal.save
      close_modal_and_reload("Goal added.")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @goal.update(goal_params)
      # Lowering a target can cross a milestone with no new contribution.
      sweep_notifications
      close_modal_and_reload("Goal updated.")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @goal.destroy
    redirect_to goals_path, notice: "Goal removed.", status: :see_other
  end

  private

  def set_goal
    @goal = current_user.savings.goals.find(params[:id])
  end

  def close_modal_and_reload(message)
    flash[:notice] = message
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.action(:refresh, "") }
      format.html { redirect_to goals_path, status: :see_other }
    end
  end

  def goal_params
    params.require(:goal).permit(:name, :target, :target_date, :icon, :color)
  end
end
