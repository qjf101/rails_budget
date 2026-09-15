class SettingsController < ApplicationController
  def edit
    @user = current_user
  end

  def update_profile
    @user = current_user
    if @user.update(profile_params)
      redirect_to settings_path, notice: "Profile updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update_password
    @user = current_user
    # update_with_password verifies :current_password before changing anything.
    if @user.update_with_password(password_params)
      bypass_sign_in(@user) # Changing the password rotates the session token.
      redirect_to settings_path, notice: "Password updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy_avatar
    current_user.avatar.purge
    redirect_to settings_path, notice: "Photo removed.", status: :see_other
  end

  def confirm_delete
    @user = current_user
  end

  def destroy_account
    if current_user.valid_password?(params[:current_password])
      user = current_user
      sign_out(user)
      user.destroy
      redirect_to root_path, notice: "Your account has been deleted.", status: :see_other
    else
      @user = current_user
      @error = "That password is not correct."
      render :confirm_delete, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:name, :email, :avatar)
  end

  def password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end
end
