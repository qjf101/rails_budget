class GoalTransfersController < ApplicationController
  def new
    @source = find_goal(params[:from_goal_id])
    @goals = current_user.savings.goals.order(:name)
  end

  def create
    savings = current_user.savings
    source = find_goal(params[:from_goal_id])
    destination = find_goal(params[:to_goal_id])
    amount_cents = (params[:amount].to_s.delete(",$").to_f * 100).round

    if source == destination
      return redirect_to goals_path, alert: "Pick a different destination.", status: :see_other
    end

    ActiveRecord::Base.transaction do
      savings.goal_contributions.create!(goal: source, amount_cents: -amount_cents, note: "Transferred to #{label_for(destination)}")
      savings.goal_contributions.create!(goal: destination, amount_cents: amount_cents, note: "Transferred from #{label_for(source)}")
    end

    flash[:notice] = "Transferred to #{label_for(destination)}."
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.action(:refresh, "") }
      format.html { redirect_to goals_path, status: :see_other }
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to goals_path, alert: e.record.errors.full_messages.to_sentence.presence || e.message, status: :see_other
  end

  private

  # Blank means General Savings, which is modelled as a contribution with no goal.
  def find_goal(id)
    current_user.savings.goals.find(id) if id.present?
  end

  def label_for(goal) = goal&.name || "General Savings"
end
