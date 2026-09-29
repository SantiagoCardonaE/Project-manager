-- Proyecto: Project-manager | Supabase: nzbpcyriwrsjceematrg
-- Organización: santiagocardona.15.98@gmail.com | Web: https://xtensorproject.vercel.app/
-- Cronograma base actualizado al 2026-09-28: 23 hitos. Fechas futuras estimadas.
-- En bases existentes conserva las ediciones; los 23 hitos ya se guardaron en el proyecto indicado.
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
 INSERT INTO public.gantt_tasks(id,position,name,description,start_date,end_date) VALUES
  ('61dcc985-1ca3-4e45-9fb7-eb1ceb595673',1,'Diagnóstico y línea base de Siigo','Conservar período registrado. Entregable: existencias, valoración y movimientos de referencia; validar cierre documental, sin asumir diagnóstico terminado.','2026-09-24','2026-09-25'),
  ('f1f5c62d-ddc7-4b3a-8695-d503275ab4d1',2,'Validar alcance, secciones y responsables','Plan estimado: confirmar cobertura del catálogo, ubicaciones, unidades, responsables y pendientes. Definir corte y tratamiento de entradas y salidas durante el conteo.','2026-09-28','2026-09-30'),
  ('d903cd15-93fe-4f4f-baea-3f32b1a80301',3,'Conteo físico por secciones — en curso','Al corte del 28/09 el usuario reporta avance parcial en pintura. El 28/09 representa el corte de seguimiento, no el inicio histórico comprobado. Meta estimada: completar cobertura y materiales fuera de Siigo.','2026-09-28','2026-10-15'),
  ('95170e0b-37ee-406a-aed8-ee5762317744',4,'Pintura: completar conteo y pendientes','En curso según reporte del usuario; porcentaje y fecha real de inicio pendientes de verificar en la app. Meta estimada: revisar referencias pendientes, unidades, envases abiertos y materiales agregados.','2026-09-28','2026-10-02'),
  ('91aa4300-3a75-44bd-a0f1-05b01525622d',5,'Pintura: reconteo y validación de la sección','Plan estimado: reconteo de diferencias y validación por responsable. Conciliar únicamente referencias contadas; cerrar la sección cuando todas las excepciones tengan soporte.','2026-10-01','2026-10-06'),
  ('861cee69-766b-4384-b61b-0e8884c083fc',6,'Conteo de tubería y materiales de torno','Plan estimado sujeto a responsables: verificar ubicación, unidad y equivalencias de longitudes, peso y piezas. Registrar material no catalogado y pendientes explícitos.','2026-09-29','2026-10-09'),
  ('1489c15a-bb50-47d4-a88b-ed1ed9836b76',7,'Conteo de ensamble, varios y ubicaciones pendientes','Plan estimado: completar secciones restantes y validar ubicación de referencias sin clasificar. No tratar ausencia de registro como cantidad cero.','2026-10-01','2026-10-15'),
  ('b442665e-32e1-4899-a287-7ce9fbd7cc5a',8,'Cerrar cobertura y reconteos del inventario','Plan estimado: verificar todas las secciones, duplicados, materiales fuera de Siigo y referencias sin conteo. Entregable: listado final validado y excepciones identificadas.','2026-10-13','2026-10-20'),
  ('9c20cce5-414f-476c-9f03-126a60ac8c81',9,'Conciliar Siigo vs. físico por secciones','Plan estimado: iniciar con pintura validada y sumar secciones cerradas. Alinear fecha de corte y movimientos; comparar cantidades y valores. Cierre posterior a cobertura y reconteos.','2026-10-02','2026-10-22'),
  ('de62d820-cff6-4e33-babb-d9a797ef5ae8',10,'Investigar causas de las diferencias','Plan estimado en paralelo con conciliación: rastrear entradas, consumos, devoluciones, traslados, unidades y soportes. Entregable: causa y tratamiento por diferencia.','2026-10-05','2026-10-29'),
  ('a5f12b04-cbf4-4a4d-98d7-017e10c93858',11,'Depurar catálogo y unidades de medida','Plan estimado: resolver códigos duplicados, descripciones, unidades, ubicaciones y materiales agregados. Validar equivalencias antes de preparar ajustes.','2026-10-05','2026-11-06'),
  ('09bf562d-ec2f-453f-abd5-e8fa7eceb317',12,'Revisar y aprobar ajustes de inventario','Plan estimado: consolidar diferencias justificadas, soportes y archivo de importación; aprobación del responsable antes de modificar Siigo. Depende del cierre de conciliación y depuración.','2026-11-03','2026-11-10'),
  ('cc931ab0-0e4c-406c-8b2c-4ce431f2584e',13,'Aplicar ajustes aprobados en Siigo','Plan estimado: registrar únicamente ajustes aprobados y conservar soportes y comprobantes. Este hito no autoriza ajustes automáticos en Siigo.','2026-11-11','2026-11-13'),
  ('2d9a8823-13e6-466e-9958-0740900a59e9',14,'Verificar saldos después del ajuste','Plan estimado: exportar saldos nuevos, comparar con inventario validado y movimientos posteriores al corte; resolver excepciones antes de aceptar la línea base.','2026-11-16','2026-11-18'),
  ('3dec6a94-def8-49da-8d1b-0919eea3d4b6',15,'Diseñar entradas, salidas y traslados','Plan estimado en paralelo al conteo: definir registro oportuno de movimientos, responsables, soportes y tratamiento de consumos, devoluciones y materiales nuevos.','2026-09-29','2026-10-16'),
  ('ea8f5fcf-39e0-4ad4-92ca-08e8bcbe48ae',16,'Pilotear el proceso en pintura','Plan estimado condicionado al cierre del conteo de pintura: probar entradas, consumos y devoluciones con trazabilidad. Documentar errores y mejoras antes de extender el proceso.','2026-10-19','2026-10-30'),
  ('5e6b9dae-c3b0-4538-982d-816070785e1d',17,'Estandarizar el proceso y capacitar responsables','Plan estimado: incorporar resultados del piloto; validar procedimiento, responsabilidades y capacitación para las demás secciones.','2026-11-02','2026-11-20'),
  ('59506303-3c6d-44e0-ab8b-edc6d317144c',18,'Mejorar consulta y seguimiento del inventario','Plan estimado: partir de la app de conteo existente y validar consultas por código, sección y pendientes. Diferenciar avance de conteo de inventario operativo actualizado.','2026-10-19','2026-11-13'),
  ('fa06354f-ca48-4765-8708-e6ab20a6f673',19,'Asegurar actualización y disponibilidad','Plan estimado: validar acceso de responsables, oportunidad de registro, respaldo y recuperación. Comprobar consistencia con saldos ajustados y movimientos reales.','2026-11-19','2026-12-04'),
  ('5d1dd933-15f4-4835-8967-7de5ac0c9914',20,'Implementar controles y conteos cíclicos','Plan estimado: definir calendario por criticidad, revisión de movimientos, soportes y responsables. Establecer cómo detectar y resolver diferencias recurrentes.','2026-11-23','2026-12-11'),
  ('b0b59c6d-cdea-44b8-a27b-ac39f07a5a51',21,'Estabilizar la operación y corregir incidencias','Plan estimado: seguimiento de registros, reconteos selectivos y cierre de incidencias. Asegurar responsables y continuidad durante el cierre de año.','2026-12-07','2026-12-23'),
  ('b77c889f-da04-4908-adf5-ab026ddd489a',22,'Medir exactitud y tiempos de actualización','Plan estimado: medir exactitud por referencia y valor, diferencias repetidas y tiempos de consulta y registro. Definir metas con responsables y usar evidencia del período de operación.','2027-01-04','2027-01-15'),
  ('6f31118c-c27c-4f7f-be38-1c2d882c93fb',23,'Cerrar proyecto y entregar mantenimiento','Cierre objetivo conservado al 22/01/2027. Condiciones: resultados revisados, incidencias críticas resueltas, procedimiento aceptado y responsables de controles y continuidad definidos.','2027-01-18','2027-01-22');
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




BEGIN;
CREATE TABLE IF NOT EXISTS public.pm_templates (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), name text NOT NULL CHECK(length(trim(name))>0),
 description text NOT NULL DEFAULT '', tasks jsonb NOT NULL DEFAULT '[]'::jsonb CHECK(jsonb_typeof(tasks)='array'),
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.pm_projects (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), name text NOT NULL CHECK(length(trim(name))>0),
 objective text NOT NULL DEFAULT '', start_date date NOT NULL, template_id uuid REFERENCES public.pm_templates(id) ON DELETE SET NULL,
 created_at timestamptz NOT NULL DEFAULT now()
);
INSERT INTO public.pm_projects(id,name,objective,start_date)
VALUES('11111111-1111-4111-8111-111111111111','Inventario','Inventario confiable y operativo',coalesce((SELECT min(start_date) FROM public.gantt_tasks),'2026-09-24')) ON CONFLICT DO NOTHING;
ALTER TABLE public.gantt_tasks ADD COLUMN IF NOT EXISTS project_id uuid REFERENCES public.pm_projects(id);
ALTER TABLE public.gantt_tasks ADD COLUMN IF NOT EXISTS plan jsonb NOT NULL DEFAULT '{}'::jsonb;
UPDATE public.gantt_tasks SET project_id='11111111-1111-4111-8111-111111111111' WHERE project_id IS NULL;
ALTER TABLE public.gantt_tasks ALTER COLUMN project_id SET DEFAULT '11111111-1111-4111-8111-111111111111';
ALTER TABLE public.gantt_tasks ALTER COLUMN project_id SET NOT NULL;
CREATE INDEX IF NOT EXISTS gantt_tasks_project_position ON public.gantt_tasks(project_id,position);
ALTER TABLE public.pm_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pm_templates ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS shared_projects ON public.pm_projects;
CREATE POLICY shared_projects ON public.pm_projects FOR ALL TO anon,authenticated USING(true) WITH CHECK(true);
DROP POLICY IF EXISTS shared_templates ON public.pm_templates;
CREATE POLICY shared_templates ON public.pm_templates FOR ALL TO anon,authenticated USING(true) WITH CHECK(true);
GRANT SELECT,INSERT,UPDATE ON public.pm_projects,public.pm_templates TO anon,authenticated;
CREATE OR REPLACE FUNCTION public.pm_create_project(p_id uuid,p_name text,p_objective text,p_start date,p_template uuid)
RETURNS uuid LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $$
DECLARE spec jsonb; item jsonb; ids uuid[]; n integer; i integer:=0; predecessors jsonb;
BEGIN
 IF p_id IS NULL OR p_start IS NULL OR length(trim(p_name))=0 THEN RAISE EXCEPTION 'Nombre y fecha obligatorios'; END IF;
 IF EXISTS(SELECT 1 FROM public.pm_projects WHERE id=p_id) THEN RETURN p_id; END IF;
 IF p_template IS NULL THEN spec:='[]'::jsonb; ELSE
  SELECT tasks INTO spec FROM public.pm_templates WHERE id=p_template;
  IF spec IS NULL THEN RAISE EXCEPTION 'Plantilla no encontrada'; END IF;
 END IF;
 n:=jsonb_array_length(spec);
 IF n>200 THEN RAISE EXCEPTION 'Máximo 200 actividades por plantilla'; END IF;
 SELECT array_agg(gen_random_uuid()) INTO ids FROM generate_series(1,n);
 INSERT INTO public.pm_projects(id,name,objective,start_date,template_id) VALUES(p_id,trim(p_name),p_objective,p_start,p_template);
 FOR item IN SELECT value FROM jsonb_array_elements(spec) LOOP
  i:=i+1;
  IF (item->>'offset')::integer<0 OR (item->>'days')::integer<1 OR (item->>'days')::integer>3660 OR length(trim(item->>'name'))=0 THEN RAISE EXCEPTION 'Actividad inválida'; END IF;
  IF EXISTS(SELECT 1 FROM jsonb_array_elements_text(coalesce(item->'after','[]')) a WHERE a.value::integer<1 OR a.value::integer>=i) THEN RAISE EXCEPTION 'Dependencia inválida'; END IF;
  SELECT coalesce(jsonb_agg(ids[a.value::integer]),'[]'::jsonb) INTO predecessors FROM jsonb_array_elements_text(coalesce(item->'after','[]')) a;
  INSERT INTO public.gantt_tasks(id,project_id,position,name,description,start_date,end_date,plan)
  VALUES(ids[i],p_id,i,item->>'name',coalesce(item->>'description',''),p_start+(item->>'offset')::integer,p_start+(item->>'offset')::integer+(item->>'days')::integer-1,
   jsonb_build_object('after',predecessors,'cycle',coalesce(item->>'cycle',''),'condition',coalesce(item->>'condition',''),'phase',coalesce(item->>'phase','Sin fase'),'phaseOrder',coalesce((item->>'phaseOrder')::integer,99)));
 END LOOP;
 RETURN p_id;
END; $$;
REVOKE ALL ON FUNCTION public.pm_create_project(uuid,text,text,date,uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.pm_create_project(uuid,text,text,date,uuid) TO anon,authenticated;
CREATE OR REPLACE FUNCTION public.shift_gantt_project(p_project uuid,new_start date)
RETURNS void LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $$
DECLARE old_start date;
BEGIN
 SELECT start_date INTO old_start FROM public.pm_projects WHERE id=p_project FOR UPDATE;
 IF old_start IS NULL OR new_start IS NULL THEN RAISE EXCEPTION 'Proyecto o fecha inválidos'; END IF;
 UPDATE public.gantt_tasks SET start_date=start_date+(new_start-old_start),end_date=end_date+(new_start-old_start) WHERE project_id=p_project;
 UPDATE public.pm_projects SET start_date=new_start WHERE id=p_project;
END; $$;
REVOKE ALL ON FUNCTION public.shift_gantt_project(uuid,date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.shift_gantt_project(uuid,date) TO anon,authenticated;
-- Compatibilidad: el endpoint antiguo nunca desplaza otros proyectos.
CREATE OR REPLACE FUNCTION public.shift_gantt(new_start date) RETURNS void LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $$
BEGIN PERFORM public.shift_gantt_project('11111111-1111-4111-8111-111111111111',new_start); END; $$;
COMMIT;

BEGIN;
INSERT INTO public.pm_templates(id,name,description,tasks) VALUES
('22222222-2222-4222-8222-222222222221','Automatización de procesos','Digitalización y automatización de flujos de Xtensor. Seleccionar un proceso piloto antes de implementar.','[{"name":"Definir proceso piloto","description":"Elegir compras, inventario, producción, calidad o despacho. Definir problema, alcance, responsable y resultado esperado.","offset":0,"days":3,"after":[],"cycle":"","condition":"","phase":"Diagnóstico","phaseOrder":1},{"name":"Mapear proceso actual","description":"Documentar pasos, datos, responsables, decisiones y excepciones con los operarios.","offset":3,"days":5,"after":[1],"cycle":"","condition":"","phase":"Diagnóstico","phaseOrder":1},{"name":"Medir tiempos y errores","description":"Establecer línea base: minutos por operación, retrabajos y errores por registro. Medir mientras se documenta el flujo.","offset":3,"days":7,"after":[1],"cycle":"Diaria durante diagnóstico","condition":"","phase":"Diagnóstico","phaseOrder":1},{"name":"Priorizar oportunidades","description":"Comparar impacto, esfuerzo, costo y riesgo. Entregar caso de mejora con meta y alcance del piloto.","offset":10,"days":3,"after":[2,3],"cycle":"","condition":"","phase":"Diseño de la solución","phaseOrder":2},{"name":"Diseñar solución","description":"Definir flujo futuro, integraciones con Siigo cuando aplique, permisos, trazabilidad y recuperación ante fallos.","offset":13,"days":5,"after":[4],"cycle":"","condition":"","phase":"Diseño de la solución","phaseOrder":2},{"name":"Construir piloto","description":"Configurar formularios, registros y automatizaciones del proceso seleccionado. Mantener revisión humana en decisiones críticas.","offset":18,"days":10,"after":[5],"cycle":"","condition":"","phase":"Construcción del piloto","phaseOrder":3},{"name":"Probar casos y excepciones","description":"Validar datos incompletos, duplicados, fallos de conexión y recuperación. Si interviene maquinaria, exigir evaluación especializada antes de operar.","offset":28,"days":5,"after":[6],"cycle":"","condition":"","phase":"Validación","phaseOrder":4},{"name":"Validar con usuarios","description":"Operarios y responsable verifican resultado y criterios de aceptación. Decidir ajustes o aprobación del piloto.","offset":33,"days":5,"after":[7],"cycle":"","condition":"","phase":"Validación","phaseOrder":4},{"name":"Capacitar y desplegar","description":"Documentar uso, responsables, soporte y procedimiento manual de contingencia.","offset":38,"days":5,"after":[8],"cycle":"","condition":"","phase":"Implementación","phaseOrder":5},{"name":"Medir y estabilizar","description":"Comparar con línea base, revisar errores y ahorro de tiempo; cerrar incidencias antes de ampliar alcance.","offset":43,"days":14,"after":[9],"cycle":"Semanal","condition":"","phase":"Seguimiento y mejora","phaseOrder":6},{"name":"Entregar y replicar","description":"Aceptar resultados, asignar mantenimiento y seleccionar siguiente proceso a automatizar.","offset":57,"days":3,"after":[10],"cycle":"","condition":"","phase":"Seguimiento y mejora","phaseOrder":6}]'::jsonb),
('22222222-2222-4222-8222-222222222222','Inventario y trazabilidad','Conteo por secciones, conciliación y control de materiales, componentes y producto terminado.','[{"name":"Definir alcance y corte","description":"Definir bodegas, secciones, responsables y control de movimientos durante el conteo.","offset":0,"days":3,"after":[],"cycle":"","condition":"","phase":"Preparación","phaseOrder":1},{"name":"Revisar catálogo Siigo","description":"Validar códigos, unidades y ubicaciones de tubería, torno, pintura, ensamble y demás secciones.","offset":3,"days":5,"after":[1],"cycle":"","condition":"","phase":"Preparación","phaseOrder":1},{"name":"Contar por secciones","description":"Registrar cantidades físicas y materiales fuera de catálogo, con soporte y responsable.","offset":3,"days":12,"after":[1],"cycle":"Diaria","condition":"","phase":"Conteo físico","phaseOrder":2},{"name":"Conciliar y recontar","description":"Comparar físico con sistema; investigar diferencias por cada sección validada.","offset":5,"days":14,"after":[],"cycle":"Por sección validada","condition":"Puede iniciar al validar la primera sección; cerrar después de completar el conteo.","phase":"Conciliación","phaseOrder":3},{"name":"Aprobar ajustes","description":"Consolidar causas, soportes y aprobación antes de cambiar saldos.","offset":19,"days":3,"after":[2,3,4],"cycle":"","condition":"","phase":"Ajustes y verificación","phaseOrder":4},{"name":"Actualizar y verificar Siigo","description":"Aplicar ajustes aprobados y comprobar saldos y movimientos posteriores al corte.","offset":22,"days":3,"after":[5],"cycle":"","condition":"","phase":"Ajustes y verificación","phaseOrder":4},{"name":"Activar controles","description":"Definir entradas, consumos, traslados y responsables; programar conteos cíclicos según criticidad.","offset":25,"days":5,"after":[6],"cycle":"","condition":"","phase":"Control y seguimiento","phaseOrder":5},{"name":"Medir exactitud","description":"Comparar diferencias por referencia y valor; documentar acciones y responsables.","offset":30,"days":14,"after":[7],"cycle":"Semanal","condition":"","phase":"Control y seguimiento","phaseOrder":5}]'::jsonb),
('22222222-2222-4222-8222-222222222223','Métodos, tiempos y capacidad','Mejora de corte, soldadura, torno, pintura o ensamble sin asumir producción por lotes.','[{"name":"Elegir operación","description":"Seleccionar familia de producto y operación; acordar alcance y meta.","offset":0,"days":3,"after":[],"cycle":"","condition":"","phase":"Diagnóstico","phaseOrder":1},{"name":"Observar método y tiempos","description":"Registrar secuencia, recorridos, esperas y variabilidad con participación del operario.","offset":3,"days":7,"after":[1],"cycle":"Diaria durante observación","condition":"","phase":"Diagnóstico","phaseOrder":1},{"name":"Analizar restricciones","description":"Determinar causas de espera, retrabajo, abastecimiento y capacidad disponible.","offset":10,"days":4,"after":[2],"cycle":"","condition":"","phase":"Diagnóstico","phaseOrder":1},{"name":"Diseñar método mejorado","description":"Proponer distribución, herramientas, abastecimiento y secuencia; revisar ergonomía y seguridad con responsables.","offset":14,"days":5,"after":[3],"cycle":"","condition":"","phase":"Diseño del método","phaseOrder":2},{"name":"Probar método","description":"Pilotear en condiciones comparables, registrar tiempo, calidad y dificultades.","offset":19,"days":7,"after":[4],"cycle":"","condition":"","phase":"Prueba piloto","phaseOrder":3},{"name":"Estandarizar y formar","description":"Documentar método validado y entrenar a los responsables.","offset":26,"days":4,"after":[5],"cycle":"","condition":"","phase":"Estandarización","phaseOrder":4},{"name":"Controlar resultados","description":"Revisar productividad, variabilidad y cumplimiento del método.","offset":30,"days":14,"after":[6],"cycle":"Semanal","condition":"","phase":"Seguimiento","phaseOrder":5}]'::jsonb),
('22222222-2222-4222-8222-222222222224','Calidad y estandarización','Prevención de defectos y retrabajos en fabricación y montaje de equipos y parques.','[{"name":"Definir defecto y alcance","description":"Identificar familia, operación y problema; registrar criterios de aceptación acordados.","offset":0,"days":3,"after":[],"cycle":"","condition":"","phase":"Diagnóstico","phaseOrder":1},{"name":"Medir defectos","description":"Clasificar rechazos y retrabajos, frecuencia e impacto; asegurar trazabilidad.","offset":3,"days":7,"after":[1],"cycle":"Diaria","condition":"","phase":"Diagnóstico","phaseOrder":1},{"name":"Analizar causas","description":"Validar causas con evidencia de proceso, materiales, método y medición.","offset":10,"days":5,"after":[2],"cycle":"","condition":"","phase":"Diagnóstico","phaseOrder":1},{"name":"Diseñar acciones","description":"Definir responsables, cambios y verificaciones; revisar requisitos técnicos aplicables con especialistas.","offset":15,"days":4,"after":[3],"cycle":"","condition":"","phase":"Plan de acción","phaseOrder":2},{"name":"Validar acciones","description":"Ejecutar piloto y comprobar reducción del defecto sin trasladarlo a otra operación.","offset":19,"days":7,"after":[4],"cycle":"","condition":"","phase":"Validación","phaseOrder":3},{"name":"Estandarizar controles","description":"Actualizar instrucciones, puntos de inspección y formación.","offset":26,"days":5,"after":[5],"cycle":"","condition":"","phase":"Estandarización","phaseOrder":4},{"name":"Verificar eficacia","description":"Revisar defectos y reincidencias con responsables y evidencias.","offset":31,"days":14,"after":[6],"cycle":"Semanal","condition":"","phase":"Seguimiento","phaseOrder":5}]'::jsonb),
('22222222-2222-4222-8222-222222222225','Producto, fabricación e instalación','Máquinas de gimnasio, bioparques, calistenia y parques infantiles: de requisitos a entrega.','[{"name":"Definir requisitos","description":"Precisar familia, uso, usuarios, sitio, alcance y criterios de aceptación con cliente y responsables técnicos.","offset":0,"days":5,"after":[],"cycle":"","condition":"","phase":"Requisitos","phaseOrder":1},{"name":"Desarrollar diseño","description":"Preparar planos, materiales, uniones y lista de componentes; validar requisitos técnicos aplicables.","offset":5,"days":10,"after":[1],"cycle":"","condition":"","phase":"Diseño y revisión","phaseOrder":2},{"name":"Revisar diseño y riesgos","description":"Revisión por responsables competentes antes de fabricar; registrar cambios y aprobación.","offset":15,"days":5,"after":[2],"cycle":"","condition":"","phase":"Diseño y revisión","phaseOrder":2},{"name":"Preparar fabricación","description":"Confirmar materiales, proveedores, herramientas y secuencia de operaciones.","offset":20,"days":5,"after":[3],"cycle":"","condition":"","phase":"Preparación","phaseOrder":3},{"name":"Fabricar y controlar","description":"Ejecutar corte, soldadura, mecanizado, acabados y ensamble según el producto; registrar inspecciones.","offset":25,"days":15,"after":[4],"cycle":"Por operación","condition":"","phase":"Fabricación","phaseOrder":4},{"name":"Verificar producto","description":"Inspecciones y ensayos definidos por responsables técnicos; resolver no conformidades antes de entregar.","offset":40,"days":5,"after":[5],"cycle":"","condition":"","phase":"Verificación","phaseOrder":5},{"name":"Preparar sitio e instalación","description":"Confirmar condiciones del sitio, coordinación y recursos; completar antes del montaje.","offset":30,"days":15,"after":[3],"cycle":"","condition":"","phase":"Instalación","phaseOrder":6},{"name":"Instalar y aceptar","description":"Realizar montaje según diseño aprobado, inspección final y aceptación documentada.","offset":45,"days":5,"after":[6,7],"cycle":"","condition":"","phase":"Instalación","phaseOrder":6},{"name":"Entregar mantenimiento","description":"Entregar instrucciones, plan de inspección, responsables y atención de incidencias.","offset":50,"days":3,"after":[8],"cycle":"","condition":"","phase":"Entrega y mantenimiento","phaseOrder":7}]'::jsonb)
ON CONFLICT(id) DO NOTHING;
UPDATE public.gantt_tasks SET plan='{"name":"Diagnóstico Siigo","original":"Diagnóstico y línea base de Siigo","after":[],"cycle":"","condition":"","phase":"Diagnóstico y preparación","phaseOrder":1}'::jsonb WHERE id='61dcc985-1ca3-4e45-9fb7-eb1ceb595673' AND plan='{}'::jsonb;
UPDATE public.gantt_tasks SET plan='{"name":"Alcance y responsables","original":"Validar alcance, secciones y responsables","after":[],"cycle":"","condition":"","phase":"Diagnóstico y preparación","phaseOrder":1}'::jsonb WHERE id='f1f5c62d-ddc7-4b3a-8695-d503275ab4d1' AND plan='{}'::jsonb;
UPDATE public.gantt_tasks SET plan='{"name":"Conteo general","original":"Conteo físico por secciones — en curso","after":[],"cycle":"Seguimiento diario","condition":"Actividad general que agrupa el conteo de las secciones; no se suma como trabajo adicional.","phase":"Conteo y validación","phaseOrder":2}'::jsonb WHERE id='d903cd15-93fe-4f4f-baea-3f32b1a80301' AND plan='{}'::jsonb;
UPDATE public.gantt_tasks SET plan='{"name":"Contar pintura","original":"Pintura: completar conteo y pendientes","after":[],"cycle":"","condition":"","phase":"Conteo y validación","phaseOrder":2}'::jsonb WHERE id='95170e0b-37ee-406a-aed8-ee5762317744' AND plan='{}'::jsonb;
UPDATE public.gantt_tasks SET plan='{"name":"Validar pintura","original":"Pintura: reconteo y validación de la sección","after":["95170e0b-37ee-406a-aed8-ee5762317744"],"cycle":"","condition":"","phase":"Conteo y validación","phaseOrder":2}'::jsonb WHERE id='91aa4300-3a75-44bd-a0f1-05b01525622d' AND plan='{}'::jsonb;
UPDATE public.gantt_tasks SET plan='{"name":"Contar tubería y torno","original":"Conteo de tubería y materiales de torno","after":[],"cycle":"","condition":"","phase":"Conteo y validación","phaseOrder":2}'::jsonb WHERE id='861cee69-766b-4384-b61b-0e8884c083fc' AND plan='{}'::jsonb;
UPDATE public.gantt_tasks SET plan='{"name":"Contar demás secciones","original":"Conteo de ensamble, varios y ubicaciones pendientes","after":[],"cycle":"","condition":"","phase":"Conteo y validación","phaseOrder":2}'::jsonb WHERE id='1489c15a-bb50-47d4-a88b-ed1ed9836b76' AND plan='{}'::jsonb;
UPDATE public.gantt_tasks SET plan='{"name":"Cerrar conteos","original":"Cerrar cobertura y reconteos del inventario","after":["91aa4300-3a75-44bd-a0f1-05b01525622d","861cee69-766b-4384-b61b-0e8884c083fc","1489c15a-bb50-47d4-a88b-ed1ed9836b76"],"cycle":"","condition":"","phase":"Conteo y validación","phaseOrder":2}'::jsonb WHERE id='b442665e-32e1-4899-a287-7ce9fbd7cc5a' AND plan='{}'::jsonb;
UPDATE public.gantt_tasks SET plan='{"name":"Conciliar por secciones","original":"Conciliar Siigo vs. físico por secciones","after":[],"cycle":"Por cada sección validada","condition":"Inicia con la primera sección validada; no requiere terminar todo el conteo.","phase":"Conciliación y ajustes","phaseOrder":3}'::jsonb WHERE id='9c20cce5-414f-476c-9f03-126a60ac8c81' AND plan='{}'::jsonb;
UPDATE public.gantt_tasks SET plan='{"name":"Investigar diferencias","original":"Investigar causas de las diferencias","after":[],"cycle":"Por cada diferencia","condition":"Inicia al detectar diferencias en la conciliación.","phase":"Conciliación y ajustes","phaseOrder":3}'::jsonb WHERE id='de62d820-cff6-4e33-babb-d9a797ef5ae8' AND plan='{}'::jsonb;
UPDATE public.gantt_tasks SET plan='{"name":"Depurar catálogo","original":"Depurar catálogo y unidades de medida","after":[],"cycle":"Por cada hallazgo","condition":"Se ejecuta a medida que aparecen problemas del catálogo.","phase":"Conciliación y ajustes","phaseOrder":3}'::jsonb WHERE id='a5f12b04-cbf4-4a4d-98d7-017e10c93858' AND plan='{}'::jsonb;
UPDATE public.gantt_tasks SET plan='{"name":"Aprobar ajustes","original":"Revisar y aprobar ajustes de inventario","after":["b442665e-32e1-4899-a287-7ce9fbd7cc5a","9c20cce5-414f-476c-9f03-126a60ac8c81","de62d820-cff6-4e33-babb-d9a797ef5ae8","a5f12b04-cbf4-4a4d-98d7-017e10c93858"],"cycle":"","condition":"","phase":"Conciliación y ajustes","phaseOrder":3}'::jsonb WHERE id='09bf562d-ec2f-453f-abd5-e8fa7eceb317' AND plan='{}'::jsonb;
UPDATE public.gantt_tasks SET plan='{"name":"Ajustar Siigo","original":"Aplicar ajustes aprobados en Siigo","after":["09bf562d-ec2f-453f-abd5-e8fa7eceb317"],"cycle":"","condition":"","phase":"Conciliación y ajustes","phaseOrder":3}'::jsonb WHERE id='cc931ab0-0e4c-406c-8b2c-4ce431f2584e' AND plan='{}'::jsonb;
UPDATE public.gantt_tasks SET plan='{"name":"Verificar saldos","original":"Verificar saldos después del ajuste","after":["cc931ab0-0e4c-406c-8b2c-4ce431f2584e"],"cycle":"","condition":"","phase":"Conciliación y ajustes","phaseOrder":3}'::jsonb WHERE id='2d9a8823-13e6-466e-9958-0740900a59e9' AND plan='{}'::jsonb;
UPDATE public.gantt_tasks SET plan='{"name":"Diseñar movimientos","original":"Diseñar entradas, salidas y traslados","after":[],"cycle":"","condition":"","phase":"Procesos y capacitación","phaseOrder":4}'::jsonb WHERE id='3dec6a94-def8-49da-8d1b-0919eea3d4b6' AND plan='{}'::jsonb;
UPDATE public.gantt_tasks SET plan='{"name":"Pilotear en pintura","original":"Pilotear el proceso en pintura","after":["91aa4300-3a75-44bd-a0f1-05b01525622d","3dec6a94-def8-49da-8d1b-0919eea3d4b6"],"cycle":"","condition":"","phase":"Procesos y capacitación","phaseOrder":4}'::jsonb WHERE id='ea8f5fcf-39e0-4ad4-92ca-08e8bcbe48ae' AND plan='{}'::jsonb;
UPDATE public.gantt_tasks SET plan='{"name":"Capacitar responsables","original":"Estandarizar el proceso y capacitar responsables","after":["ea8f5fcf-39e0-4ad4-92ca-08e8bcbe48ae"],"cycle":"","condition":"","phase":"Procesos y capacitación","phaseOrder":4}'::jsonb WHERE id='5e6b9dae-c3b0-4538-982d-816070785e1d' AND plan='{}'::jsonb;
UPDATE public.gantt_tasks SET plan='{"name":"Mejorar consultas","original":"Mejorar consulta y seguimiento del inventario","after":[],"cycle":"","condition":"","phase":"Información y controles","phaseOrder":5}'::jsonb WHERE id='59506303-3c6d-44e0-ab8b-edc6d317144c' AND plan='{}'::jsonb;
UPDATE public.gantt_tasks SET plan='{"name":"Validar disponibilidad","original":"Asegurar actualización y disponibilidad","after":["2d9a8823-13e6-466e-9958-0740900a59e9","59506303-3c6d-44e0-ab8b-edc6d317144c"],"cycle":"","condition":"","phase":"Información y controles","phaseOrder":5}'::jsonb WHERE id='fa06354f-ca48-4765-8708-e6ab20a6f673' AND plan='{}'::jsonb;
UPDATE public.gantt_tasks SET plan='{"name":"Activar controles","original":"Implementar controles y conteos cíclicos","after":["5e6b9dae-c3b0-4538-982d-816070785e1d"],"cycle":"Definir frecuencia por criticidad","condition":"","phase":"Información y controles","phaseOrder":5}'::jsonb WHERE id='5d1dd933-15f4-4835-8967-7de5ac0c9914' AND plan='{}'::jsonb;
UPDATE public.gantt_tasks SET plan='{"name":"Estabilizar operación","original":"Estabilizar la operación y corregir incidencias","after":["fa06354f-ca48-4765-8708-e6ab20a6f673","5d1dd933-15f4-4835-8967-7de5ac0c9914"],"cycle":"Revisión semanal","condition":"","phase":"Seguimiento y cierre","phaseOrder":6}'::jsonb WHERE id='b0b59c6d-cdea-44b8-a27b-ac39f07a5a51' AND plan='{}'::jsonb;
UPDATE public.gantt_tasks SET plan='{"name":"Medir resultados","original":"Medir exactitud y tiempos de actualización","after":["b0b59c6d-cdea-44b8-a27b-ac39f07a5a51"],"cycle":"Revisión semanal","condition":"","phase":"Seguimiento y cierre","phaseOrder":6}'::jsonb WHERE id='b77c889f-da04-4908-adf5-ab026ddd489a' AND plan='{}'::jsonb;
UPDATE public.gantt_tasks SET plan='{"name":"Entregar y mantener","original":"Cerrar proyecto y entregar mantenimiento","after":["b77c889f-da04-4908-adf5-ab026ddd489a"],"cycle":"","condition":"","phase":"Seguimiento y cierre","phaseOrder":6}'::jsonb WHERE id='6f31118c-c27c-4f7f-be38-1c2d882c93fb' AND plan='{}'::jsonb;
COMMIT;

-- Proyecto inicial de automatización; no duplica ni sobrescribe proyectos existentes.
SELECT public.pm_create_project('4c99ea7b-9b1b-44b1-b3a5-cf717d7af0e9','Automatización de procesos','Reducir tareas manuales, errores y tiempos de registro en Xtensor. Identificar y validar un proceso piloto antes de extender la automatización.','2026-09-29','22222222-2222-4222-8222-222222222221');
