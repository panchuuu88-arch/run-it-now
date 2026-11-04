<!-- LOVABLE:BEGIN -->
> [!IMPORTANT]
> This project is connected to [Lovable](https://lovable.dev). Avoid rewriting
> published git history — force pushing, or rebasing/amending/squashing commits
> that are already pushed — as it rewrites history on Lovable's side and the
> user will likely lose their project history.
>
> Commits you push to the connected branch sync back to Lovable and show up in
> the editor, so keep the branch in a working state.
<!-- LOVABLE:END -->

The G.K Mart app was imported from a code archive (local-first POS, Dexie + cloud sync).
Its backend tables are `profiles`, `user_roles` and `shop_records` (created in
drizzle/migrations/0000_create_profiles_roles_and_shop_records.sql); keep sync and staff
logic aligned with that schema, and keep role checks in `user_roles`, never on profiles.
