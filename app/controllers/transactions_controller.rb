class TransactionsController < ApplicationController
  before_action :set_transaction, only: [:edit, :update, :destroy]

  def index
    @transactions = current_user.transactions.order(date: :desc)
    @transactions = @transactions.where(category_id: params[:category_id]) if params[:category_id].present?
  end

  def new
    @transaction = current_user.transactions.new
  end

  def create
    @transaction = current_user.transactions.new(transaction_params)
    if @transaction.save
      redirect_to transactions_path, notice: "Transaction added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @transaction.update(transaction_params)
      redirect_to transactions_path, notice: "Transaction updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @transaction.destroy
    redirect_to transactions_path, notice: "Transaction removed."
  end

  private

  def set_transaction
    @transaction = current_user.transactions.find(params[:id])
  end

  def transaction_params
    params.require(:transaction).permit(:date, :amount, :transaction_type, :category_id, :description, :notes,
      goal_contributions_attributes: [:id, :goal_id, :amount, :_destroy])
  end
end