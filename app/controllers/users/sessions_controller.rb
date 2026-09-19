module Users
  class SessionsController < Devise::SessionsController
    # Without this, signing out would bounce straight back into the demo account on
    # the next request and there would be no way to reach the sign-in page.
    def destroy
      if DemoLogin.enabled?
        cookies[DemoLogin::SUPPRESSION_COOKIE] = {
          value: "1", expires: DemoLogin::SUPPRESSION_WINDOW.from_now, httponly: true
        }
      end

      super
    end
  end
end
