-- Allows guests to read the relation rows needed to render public recipe details.
-- This does not grant insert/update/delete permissions.

alter table public.recipe_ingredients enable row level security;
alter table public.recipe_categories enable row level security;

drop policy if exists "read ingredients for public recipes" on public.recipe_ingredients;
create policy "read ingredients for public recipes"
on public.recipe_ingredients
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.recipes
    where recipes.id = recipe_ingredients.recipe_id
      and recipes.is_public = true
  )
);

drop policy if exists "read categories for public recipes" on public.recipe_categories;
create policy "read categories for public recipes"
on public.recipe_categories
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.recipes
    where recipes.id = recipe_categories.recipe_id
      and recipes.is_public = true
  )
);

