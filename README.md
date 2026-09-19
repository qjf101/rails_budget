# budget app

A personal budgeting app: transactions, monthly budgets, savings goals, reports and
a calendar view. Rails 8 · Postgres · Hotwire · Tailwind · Solid Queue.

## Running it locally

```bash
bin/setup                       # bundle, prepare databases, seed
bin/dev                         # web + tailwind watcher on :3000
```

Sign in with `demo@example.com` / `password123`.

Two optional processes:

```bash
bin/jobs                        # Solid Queue worker — needed for anything in config/recurring.yml
mailcatcher                     # gem install mailcatcher; mail lands at http://127.0.0.1:1080
```

Without `bin/jobs` running, background jobs enqueue silently and never execute.
That includes the weekly summary email, the notification purge, and the demo reset.

## Demo mode

Signs every anonymous visitor into a shared account instead of showing the sign-in
page, so the app can be demoed without anyone registering. A banner says so, and
`ResetDemoDataJob` wipes that account back to seed data nightly.

```bash
DEMO_AUTO_LOGIN=true bin/dev
```

Set `DEMO_USER_EMAIL` too if the demo account is not `demo@example.com` — `db/seeds.rb`
and `ResetDemoDataJob` both read it, so they have to agree.

To sign in as yourself while it is on, sign out first: that sets a cookie which
suppresses auto-login for 24 hours and leaves the sign-in page reachable.

**This bypasses authentication for everyone who can reach the app**, and they can edit
and delete that account's data. Only point it at data you are happy for the public to
change. In production it goes in `config/deploy.yml` under `env.clear`, where a
commented line is waiting.

## Tests

```bash
bin/rails test
```

## Deploying

Kamal to a VPS.
