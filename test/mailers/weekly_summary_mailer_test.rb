require "test_helper"

class WeeklySummaryMailerTest < ActionMailer::TestCase
  setup do
    @user = User.create!(email: "mail@example.com", password: "password123", name: "Mail User")
    category = @user.categories.create!(name: "Groceries", icon: "utensils", color: "#ef4444", category_type: :expense)
    @user.transactions.create!(date: Date.current, amount_cents: 4_200, transaction_type: :expense, category: category)
  end

  test "renders both a plain text and an html part" do
    mail = WeeklySummaryMailer.summary(@user)

    assert_equal [ "mail@example.com" ], mail.to
    assert_equal [ "text/plain", "text/html" ], mail.parts.map { |part| part.content_type.split(";").first }
  end

  test "the body renders currency, which needs ApplicationHelper in the mailer" do
    # Regression: mailer views do not pick up app/helpers automatically, and this
    # blew up at deliver time rather than at load time.
    body = WeeklySummaryMailer.summary(@user).text_part.body.to_s

    assert_match "$42", body
    assert_match "Groceries", body
  end

  test "handles a week with no activity" do
    mail = WeeklySummaryMailer.summary(@user, 3.years.ago.to_date)

    assert_match "No transactions logged this week", mail.text_part.body.to_s
  end

  test "links back with an absolute url" do
    body = WeeklySummaryMailer.summary(@user).text_part.body.to_s

    assert_match %r{https?://}, body, "default_url_options must be set or links are relative and unusable in mail"
  end
end
