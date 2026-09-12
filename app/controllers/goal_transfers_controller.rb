class GoalTransfersController < ApplicationController
  def create
    from_goal = current_user.savings.goals.find(params[:from_goal_id])
    to_goal = current_user.savings.goals.find(params[:to_goal_id])
    amount_cents = (params[:amount].to_f * 100).round

    ActiveRecord::Base.transaction do
      from_goal.goal_contributions.create!(amount_cents: -amount_cents, note: "Transferred to #{to_goal.name}")
      to_goal.goal_contributions.create!(amount_cents: amount_cents, note: "Transferred from #{from_goal.name}")
    end
    redirect_to goals_path, notice: "Transferred."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to goals_path, alert: e.message
  end
end
