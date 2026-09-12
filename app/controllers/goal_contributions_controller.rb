class GoalContributionsController < ApplicationController
  before_action :set_goal

  def create
    contribution = @goal.goal_contributions.new(contribution_params)
    if contribution.save
      redirect_to goals_path, notice: "#{@goal.name} updated."
    else
      redirect_to goals_path, alert: contribution.errors.full_messages.to_sentence
    end
  end

  def destroy
    @goal.goal_contributions.find(params[:id]).destroy
    redirect_to goals_path, notice: "Contribution removed."
  end

  private

  def set_goal
    @goal = current_user.savings.goals.find(params[:goal_id])
  end

  def contribution_params
    params.require(:goal_contribution).permit(:amount, :note)
  end
end
