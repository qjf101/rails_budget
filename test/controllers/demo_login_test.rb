require "test_helper"

class DemoLoginTest < ActionDispatch::IntegrationTest
  setup do
    @demo = User.create!(email: "demo-test@example.com", password: "password123")
    @other = User.create!(email: "other@example.com", password: "password123")
    ENV["DEMO_USER_EMAIL"] = @demo.email
  end

  teardown do
    ENV.delete("DEMO_AUTO_LOGIN")
    ENV.delete("DEMO_USER_EMAIL")
  end

  def with_demo_login
    ENV["DEMO_AUTO_LOGIN"] = "true"
    yield
  end

  test "off by default: an anonymous visitor is sent to sign in" do
    get root_path
    assert_redirected_to new_user_session_path
  end

  test "enabled: an anonymous visitor is signed in as the demo user" do
    with_demo_login do
      get root_path
      assert_response :success
      assert_equal @demo.id, session["warden.user.user.key"]&.first&.first
    end
  end

  test "enabled: an existing session for another user is left alone" do
    sign_in @other

    with_demo_login do
      get root_path
      assert_response :success
      assert_equal @other.id, session["warden.user.user.key"]&.first&.first
    end
  end

  test "enabled: the sign-in page stays reachable" do
    with_demo_login do
      get new_user_session_path
      assert_response :success, "auto-login must skip devise controllers or nobody can sign in as themselves"
    end
  end

  test "enabled: signing out is not undone on the next request" do
    with_demo_login do
      get root_path
      assert_equal @demo.id, session["warden.user.user.key"]&.first&.first

      delete destroy_user_session_path
      get root_path
      assert_redirected_to new_user_session_path, "the suppression cookie should outlive the session reset"
    end
  end

  test "enabled but the demo account is missing: falls back to normal auth" do
    @demo.destroy

    with_demo_login do
      get root_path
      assert_redirected_to new_user_session_path
    end
  end

  test "the demo banner shows for the shared account but not for your own" do
    with_demo_login do
      get root_path
      assert_select "p", { text: /viewing a shared demo/, count: 1 }, "demo session should be labelled"
    end
  end

  test "no banner when signed in as yourself, even with the feature on" do
    sign_in @other

    with_demo_login do
      get root_path
      assert_select "p", { text: /viewing a shared demo/, count: 0 }
    end
  end

  test "only an explicitly truthy value enables it" do
    ENV["DEMO_AUTO_LOGIN"] = "false"
    assert_not DemoLogin.enabled?
    ENV["DEMO_AUTO_LOGIN"] = "1"
    assert DemoLogin.enabled?
  end
end
