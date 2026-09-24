-- Ejecutar completo en Supabase > SQL Editor. Compatible con el esquema original.
BEGIN;
-- Base de datos del Gantt del proyecto de inventarios.
-- Ejecutar este archivo completo en Supabase > SQL Editor.

create table if not exists public.gantt_tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  position integer not null default 1,
  name text not null,
  description text not null default '',
  start_date date not null,
  end_date date not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint gantt_task_dates check (end_date >= start_date)
);

alter table public.gantt_tasks enable row level security;

drop policy if exists "Users can read own gantt tasks" on public.gantt_tasks;
create policy "Users can read own gantt tasks"
on public.gantt_tasks for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert own gantt tasks" on public.gantt_tasks;
create policy "Users can insert own gantt tasks"
on public.gantt_tasks for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update own gantt tasks" on public.gantt_tasks;
create policy "Users can update own gantt tasks"
on public.gantt_tasks for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete own gantt tasks" on public.gantt_tasks;
create policy "Users can delete own gantt tasks"
on public.gantt_tasks for delete
to authenticated
using (auth.uid() = user_id);

create index if not exists gantt_tasks_user_position_idx
on public.gantt_tasks(user_id, position);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists gantt_tasks_updated_at on public.gantt_tasks;
create trigger gantt_tasks_updated_at
before update on public.gantt_tasks
for each row execute procedure public.set_updated_at();

GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.gantt_tasks TO authenticated;
REVOKE ALL ON public.gantt_tasks FROM anon;

-- Inicialización protegida frente a accesos simultáneos.
CREATE TABLE IF NOT EXISTS public.gantt_initialized (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE
);
ALTER TABLE public.gantt_initialized ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.gantt_initialized FROM anon, authenticated;

CREATE OR REPLACE FUNCTION public.initialize_gantt()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE current_user_id uuid := auth.uid();
BEGIN
  IF current_user_id IS NULL THEN RAISE EXCEPTION 'Debe iniciar sesión'; END IF;
  INSERT INTO public.gantt_initialized(user_id) VALUES(current_user_id) ON CONFLICT DO NOTHING;
  IF NOT FOUND THEN RETURN; END IF;
  IF EXISTS(SELECT 1 FROM public.gantt_tasks WHERE user_id = current_user_id) THEN RETURN; END IF;
  INSERT INTO public.gantt_tasks(user_id,position,name,description,start_date,end_date) VALUES
  (current_user_id,1,'Diagnosticar','¿Cómo está hoy el inventario en Siigo?','2026-09-24','2026-09-30'),
  (current_user_id,2,'Contar','¿Qué existe realmente físicamente?','2026-10-01','2026-10-15'),
  (current_user_id,3,'Conciliar','Siigo vs. físico.','2026-10-16','2026-10-22'),
  (current_user_id,4,'Investigar','¿Por qué existen las diferencias?','2026-10-23','2026-10-29'),
  (current_user_id,5,'Depurar','Códigos, productos, cantidades y valores.','2026-10-30','2026-11-06'),
  (current_user_id,6,'Corregir Siigo','Dejar el inventario real.','2026-11-07','2026-11-13'),
  (current_user_id,7,'Diseñar el proceso','Cómo entran, salen y se mueven los inventarios.','2026-11-14','2026-11-27'),
  (current_user_id,8,'Agilizar la información','Consultar existencias rápido y sencillo.','2026-11-28','2026-12-04'),
  (current_user_id,9,'Asegurar disponibilidad','Inventario actualizado en cualquier momento.','2026-12-05','2026-12-11'),
  (current_user_id,10,'Implementar controles','Responsables, movimientos, soportes y conteos periódicos.','2026-12-12','2026-12-23'),
  (current_user_id,11,'Medir','Exactitud, diferencias, tiempos de consulta y actualización.','2027-01-04','2027-01-15'),
  (current_user_id,12,'Cerrar y mantener','Sistema funcionando y responsables definidos.','2027-01-16','2027-01-22');
END;
$$;

REVOKE ALL ON FUNCTION public.initialize_gantt() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.initialize_gantt() TO authenticated;

-- Desplazamiento completo en una sola transacción; respeta RLS.
CREATE OR REPLACE FUNCTION public.shift_gantt(new_start date)
RETURNS void LANGUAGE plpgsql SECURITY INVOKER SET search_path = '' AS $$
DECLARE first_start date;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Debe iniciar sesión'; END IF;
  IF new_start IS NULL THEN RAISE EXCEPTION 'Fecha requerida'; END IF;
  SELECT start_date INTO first_start FROM public.gantt_tasks
    WHERE user_id = auth.uid() ORDER BY position, created_at, id LIMIT 1;
  IF first_start IS NULL THEN RETURN; END IF;
  UPDATE public.gantt_tasks SET
    start_date = start_date + (new_start - first_start),
    end_date = end_date + (new_start - first_start)
  WHERE user_id = auth.uid();
END;
$$;
REVOKE ALL ON FUNCTION public.shift_gantt(date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.shift_gantt(date) TO authenticated;
COMMIT;
