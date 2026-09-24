-- Gantt compartido, sin cuentas ni contraseñas.
-- Ejecutar COMPLETO en Supabase > SQL Editor, incluso si ya ejecutó la versión anterior.
-- Conserva los hitos existentes y permite que todos los visitantes los vean y editen.
BEGIN;
CREATE TABLE IF NOT EXISTS public.gantt_tasks (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
 position integer NOT NULL DEFAULT 1,
 name text NOT NULL,
 description text NOT NULL DEFAULT '',
 start_date date NOT NULL,
 end_date date NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(),
 updated_at timestamptz NOT NULL DEFAULT now(),
 CONSTRAINT gantt_task_dates CHECK(end_date >= start_date)
);
-- Compatibilidad con los datos del proyecto anterior.
ALTER TABLE public.gantt_tasks ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE public.gantt_tasks DROP CONSTRAINT IF EXISTS gantt_tasks_user_id_fkey;
ALTER TABLE public.gantt_tasks ADD CONSTRAINT gantt_tasks_user_id_fkey
 FOREIGN KEY(user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.gantt_tasks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can read own gantt tasks" ON public.gantt_tasks;
DROP POLICY IF EXISTS "Users can insert own gantt tasks" ON public.gantt_tasks;
DROP POLICY IF EXISTS "Users can update own gantt tasks" ON public.gantt_tasks;
DROP POLICY IF EXISTS "Users can delete own gantt tasks" ON public.gantt_tasks;
DROP POLICY IF EXISTS "Public shared gantt" ON public.gantt_tasks;
CREATE POLICY "Public shared gantt" ON public.gantt_tasks
 FOR ALL TO anon, authenticated USING(true) WITH CHECK(true);
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.gantt_tasks TO anon, authenticated;
CREATE INDEX IF NOT EXISTS gantt_tasks_position_idx ON public.gantt_tasks(position);
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN new.updated_at = now(); RETURN new; END;
$$;
DROP TRIGGER IF EXISTS gantt_tasks_updated_at ON public.gantt_tasks;
CREATE TRIGGER gantt_tasks_updated_at BEFORE UPDATE ON public.gantt_tasks
 FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
-- El navegador ya no inicializa proyectos por usuario.
DROP FUNCTION IF EXISTS public.initialize_gantt();
-- Marca privada para no duplicar hitos ni recrearlos tras eliminarlos.
CREATE TABLE IF NOT EXISTS public.gantt_public_setup (
 id integer PRIMARY KEY CHECK(id = 1)
);
ALTER TABLE public.gantt_public_setup ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.gantt_public_setup FROM anon, authenticated;
DO $$
BEGIN
 INSERT INTO public.gantt_public_setup(id) VALUES(1) ON CONFLICT DO NOTHING;
 IF FOUND AND NOT EXISTS(SELECT 1 FROM public.gantt_tasks) THEN
 INSERT INTO public.gantt_tasks(position,name,description,start_date,end_date) VALUES
  (1,'Diagnosticar','¿Cómo está hoy el inventario en Siigo?','2026-09-24','2026-09-30'),
  (2,'Contar','¿Qué existe realmente físicamente?','2026-10-01','2026-10-15'),
  (3,'Conciliar','Siigo vs. físico.','2026-10-16','2026-10-22'),
  (4,'Investigar','¿Por qué existen las diferencias?','2026-10-23','2026-10-29'),
  (5,'Depurar','Códigos, productos, cantidades y valores.','2026-10-30','2026-11-06'),
  (6,'Corregir Siigo','Dejar el inventario real.','2026-11-07','2026-11-13'),
  (7,'Diseñar el proceso','Cómo entran, salen y se mueven los inventarios.','2026-11-14','2026-11-27'),
  (8,'Agilizar la información','Consultar existencias rápido y sencillo.','2026-11-28','2026-12-04'),
  (9,'Asegurar disponibilidad','Inventario actualizado en cualquier momento.','2026-12-05','2026-12-11'),
  (10,'Implementar controles','Responsables, movimientos, soportes y conteos periódicos.','2026-12-12','2026-12-23'),
  (11,'Medir','Exactitud, diferencias, tiempos de consulta y actualización.','2027-01-04','2027-01-15'),
  (12,'Cerrar y mantener','Sistema funcionando y responsables definidos.','2027-01-16','2027-01-22');
 END IF;
END;
$$;
CREATE OR REPLACE FUNCTION public.shift_gantt(new_start date)
RETURNS void LANGUAGE plpgsql SECURITY INVOKER SET search_path = '' AS $$
DECLARE first_start date;
BEGIN
 IF new_start IS NULL THEN RAISE EXCEPTION 'Fecha requerida'; END IF;
 SELECT start_date INTO first_start FROM public.gantt_tasks
 ORDER BY position,created_at,id LIMIT 1;
 IF first_start IS NULL THEN RETURN; END IF;
 UPDATE public.gantt_tasks SET
 start_date = start_date + (new_start - first_start),
 end_date = end_date + (new_start - first_start);
END;
$$;
REVOKE ALL ON FUNCTION public.shift_gantt(date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.shift_gantt(date) TO anon, authenticated;
COMMIT;
