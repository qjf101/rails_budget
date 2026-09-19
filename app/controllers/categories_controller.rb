class CategoriesController < ApplicationController
  PALETTE = %w[#3b82f6 #ef4444 #8b5cf6 #f59e0b #f97316 #06b6d4 #22c55e #ec4899 #6b7280].freeze

  before_action :set_category, only: [ :edit, :update, :destroy ]

  def new
    @category = current_user.categories.new(category_type: :expense, icon: "more-horizontal", color: PALETTE.first)
  end

  def create
    @category = current_user.categories.new(category_params)
    @category.position ||= current_user.categories.maximum(:position).to_i + 1

    if @category.save
      close_modal_and_reload("Category added.")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @category.update(category_params)
      close_modal_and_reload("Category updated.")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Transactions are nullified rather than deleted (see Category's associations),
    # so removing a category never destroys spending history.
    @category.destroy
    redirect_to budget_path, notice: "Category removed.", status: :see_other
  end

  private

  def set_category
    @category = current_user.categories.find(params[:id])
  end

  # The form lives in a turbo frame, so a redirect would only swap the frame and
  # leave the budget page underneath stale. See TransactionsController for the
  # reason this isn't turbo_stream.refresh.
  def close_modal_and_reload(message)
    flash[:notice] = message
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.action(:refresh, "") }
      format.html { redirect_to budget_path, status: :see_other }
    end
  end

  def category_params
    params.require(:category).permit(:name, :icon, :color, :category_type)
  end
end
