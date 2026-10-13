# Turning on shared mode (Supabase)

Until `config.json` has your Supabase details, Harim runs exactly as before. Everything stays in each person's browser, and the demo loads by itself. Follow these steps once to share everything.

**What you get:**
- **Team space (invite-only).** People sign in with their work email. Everyone sees the same requests, approvals, users, roles, settings and audit log, and changes show up live for everyone else. The product data files are shared too.
- **Demo space ("Try the demo").** Anyone can try Harim without an account. The demo is shared with other visitors and is emptied every night.

It takes about 15 minutes. The Supabase free plan is enough.

## 1. Create the Supabase project
1. Sign up at [supabase.com](https://supabase.com), then click **New project**. Pick a name (e.g. `harim`), a database password (save it somewhere) and the region closest to you.
2. Wait about 2 minutes for it to finish.

## 2. Run the setup script
1. Open `backend/harim_setup.sql` from this repo and copy all of it.
2. Find the line marked `>>> OWNER EMAIL <<<` near the bottom, and put **your** email between the quotes in place of `YOUR-EMAIL@EXAMPLE.COM`.
3. In Supabase, open **SQL Editor**, click **New query**, paste the script and click **Run**. You should see `Harim backend is set up.`
4. If the results mention **pg_cron**, the nightly demo reset isn't on yet. Turn it on under **Database › Extensions** (search "pg_cron"), then run the script again. Running it again is safe.

## 3. Sign-in settings
1. **Authentication › Sign In / Providers:** turn on **Allow anonymous sign-ins**. This is what "Try the demo" uses. Leave **Confirm email** on.
2. **Authentication › URL Configuration:** set **Site URL** to your Harim address, e.g. `https://YOUR-NAME.github.io/harim/`, and add the same address under **Redirect URLs**.

## 4. Create your own account
1. Go to **Authentication › Users**, click **Add user**, then **Create new user**.
2. Enter the same email you put in the script, choose a password, and tick **Auto Confirm User**.

## 5. Connect Harim
1. In Supabase, go to **Settings › API Keys** and copy:
   - the **Project URL** (also shown in the **Connect** dialog)
   - the **publishable** key, which starts with `sb_publishable_`. The older "anon public" key also works.

   **Never** use the **secret** or **service_role** key. Those bypass every security rule.
2. Edit `config.json` in this repo:
   ```json
   {
     "supabaseUrl": "https://abcdefgh.supabase.co",
     "supabaseAnonKey": "sb_publishable_...",
     "team": true,
     "demo": true
   }
   ```
   The publishable key is meant to sit in a web page. The database's security rules are what protect your data. Set `"demo": false` to hide "Try the demo", or `"team": false` for a demo-only site.
3. Commit. GitHub Pages updates in a minute or two.

## 6. First sign-in and sharing the data
1. Open Harim and sign in with your email and password. You become the **Administrator**.
2. Go to **Admin › Data import**. Under **Shared data files**, click **Share files...** and choose the product export (CSV) and the reference workbooks (the same files as in `demo/`, or your own).
3. Everyone on the team now loads them automatically when they sign in.

## Adding teammates
Supabase's built-in email only reaches members of your Supabase organization, and only 2 emails an hour. Pick one of these:

**A. No email setup (quickest).** For each person:
1. In Supabase, go to **Authentication › Users › Add user › Create new user**. Enter their email and a temporary password, and tick **Auto Confirm User**.
2. In Harim, go to **Admin › Users & roles** and add them with **the same email** and their role.
3. Send them the link and the temporary password. They can change it from their name menu (top right) › **Change password**.

**B. Real emails (better for a bigger team).** Connect an email service such as Resend, Postmark, SendGrid or Brevo: **Authentication › Emails › SMTP Settings** ([Supabase guide](https://supabase.com/docs/guides/auth/auth-smtp)). Then:
1. You add a person in Harim (Users & roles, with their email).
2. They open Harim and choose **First time here? Create your password**.
3. They confirm their email. **Forgot password?** emails work too.

**Removing someone:** switch their user off in Harim. They lose access straight away.

## What's protected, and how
The database itself enforces these rules, not just the app:
- Only people whose **confirmed** email is an active user in Harim can see or change team data. Anyone else who signs up sees "No access yet".
- Only admins can change users and roles, so nobody can make themselves an admin.
- Demo visitors can only reach the demo. The audit log can be added to but never edited or deleted.
- Shared data files can only be replaced by admins. Anyone on the team can attach submitted supplier files.

Inside the team, the finer permissions (who can approve, which attribute groups a role edits) are still applied by the app, as before.

## Good to know
- **Free projects pause** after about a week with no activity. Open the project in Supabase and click **Restore** if Harim says it can't reach the database.
- **Product data:** each person's browser loads the shared files at sign-in. Approved changes go out as change files, as before. They don't change the shared product data yet. That's the next phase.
- **Your own work in progress stays in your own browser:** half-finished item loads and your table layout.
