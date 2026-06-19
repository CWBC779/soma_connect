-- Editable "Female athlete science" content. The team adds/edits facts in the
-- Supabase Table Editor (no code change); the app reads published rows.
create table if not exists public.science_facts (
  id          bigint generated always as identity primary key,
  emoji       text,
  tag         text,
  body        text not null,
  sort_order  int  not null default 0,
  published   boolean not null default true,
  created_at  timestamptz not null default now()
);

alter table public.science_facts enable row level security;
-- Participants can read published facts. Editing is done by the team via the
-- dashboard Table Editor (service role), so no write policy is needed.
drop policy if exists "read published science facts" on public.science_facts;
create policy "read published science facts" on public.science_facts
  for select to authenticated using (published = true);

-- Seed with the facts that were previously hard-coded in the app.
insert into public.science_facts (emoji, tag, body, sort_order) values
('🧬','Physiology','Oestrogen may act as an anabolic agent, supporting muscle protein synthesis. Some research suggests female athletes recover differently across cycle phases — though individual responses vary enormously.',1),
('🩸','RED-S Awareness','Relative Energy Deficiency in Sport (RED-S) affects female runners at all levels. Under-fuelling impairs hormonal function, bone health, and performance — often invisibly at first.',2),
('❤️','Heart health','Female athletes show distinct cardiac adaptations to endurance training. Studies suggest oestrogen may have cardioprotective effects, though the mechanisms are still being actively researched.',3),
('🦴','Bone health','Bone density in female runners is influenced by training load, nutrition, and hormonal status. Running supports bone health, but energy availability matters significantly.',4),
('😴','Sleep & recovery','Research indicates that women may experience more sleep disruption in the luteal phase due to rising progesterone. Prioritising sleep during this phase may support recovery and mood.',5),
('🏃‍♀️','Research history','Until the 1990s, most exercise science research excluded women. Female performance science is growing rapidly — you are part of that movement by participating in research platforms.',6),
('🧠','Neuroscience','Brain regions governing effort perception and mood are influenced by oestrogen and progesterone. This may partly explain why perceived exertion can fluctuate across the cycle.',7),
('💧','Hydration','Plasma volume and thermoregulation shift across the menstrual cycle. Some athletes find they need slightly more fluid in the late luteal phase when core temperature is slightly elevated.',8);
