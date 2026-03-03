-- COLLE TOUT CA DANS SUPABASE > SQL EDITOR > NEW QUERY > RUN

create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  username text unique not null,
  bio text default '',
  avatar_url text default '',
  created_at timestamp with time zone default timezone('utc', now())
);

create table public.articles (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade,
  author_name text,
  author_title text,
  date_display text,
  content text,
  image_data text,
  created_at timestamp with time zone default timezone('utc', now())
);

alter table public.profiles enable row level security;
alter table public.articles enable row level security;

create policy "Profils visibles par tous" on public.profiles for select using (true);
create policy "Creer son profil" on public.profiles for insert with check (auth.uid() = id);
create policy "Modifier son profil" on public.profiles for update using (auth.uid() = id);

create policy "Articles visibles par tous" on public.articles for select using (true);
create policy "Publier un article" on public.articles for insert with check (auth.uid() = user_id);
create policy "Modifier ses articles" on public.articles for update using (auth.uid() = user_id);
create policy "Supprimer ses articles" on public.articles for delete using (auth.uid() = user_id);

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username)
  values (new.id, coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)));
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
