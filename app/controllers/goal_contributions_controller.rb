class GoalContributionsController < ApplicationController
  DIRECTIONS = %w[add withdraw].freeze

  before_action :set_goal

  def new
    @direction = direction
    @contribution = contributions_scope.new
  end

  def create
    @direction = direction
    @contribution = contributions_scope.new(contribution_params)
    # One form serves both directions; withdrawals are stored as negative amounts.
    @contribution.amount_cents = -@contribution.amount_cents.to_i if withdrawing?

    if @contribution.save
      sweep_notifications
      close_modal_and_reload(withdrawing? ? "Withdrawn." : "Funds added.")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @goal.goal_contributions.find(params[:id]).destroy
    redirect_to goals_path, notice: "Contribution removed.", status: :see_other
  end

  private

  # A nil goal means General Savings — the contribution hangs off savings alone.
  def set_goal
    @goal = current_user.savings.goals.find(params[:goal_id]) if params[:goal_id].present?
  end

  def contributions_scope
    @goal ? @goal.goal_contributions : current_user.savings.goal_contributions
  end

  def direction
    DIRECTIONS.include?(params[:direction]) ? params[:direction] : "add"
  end

  def withdrawing? = direction == "withdraw"

  def close_modal_and_reload(message)
    flash[:notice] = message
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.action(:refresh, "") }
      format.html { redirect_to goals_path, status: :see_other }
    end
  end

  def contribution_params
    params.require(:goal_contribution).permit(:amount, :note).merge(savings: current_user.savings)
  end
end
