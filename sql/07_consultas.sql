-- Stored Procedures (PL/pgSQL) — Banco de Dados de Streaming de Jogos
-- TCC00335 — UFF — Prof. Marcos Bedo — 2026/1
-- Execute APÓS 06_functions.sql
--
-- =========================================================================
-- Camadas de reuso: views → functions → procedures
-- =========================================================================
-- O enunciado permite responder as 8 consultas com functions OU
-- procedures. Implementamos as duas (06_functions.sql e este arquivo)
-- propositalmente em camadas, em vez de duas implementações paralelas e
-- redundantes da mesma lógica:
--
--   1) As views/MV de 04_views.sql concentram os JOINs e GROUP BYs;
--   2) As functions de 06_functions.sql filtram/ordenam/paginam sobre
--      essas views e já devolvem o resultado tabular pronto via
--      RETURNS TABLE;
--   3) As procedures abaixo NÃO repetem esse SELECT — elas apenas abrem
--      um REFCURSOR sobre "SELECT * FROM fn_xxx(...)", reaproveitando a
--      function. Isso significa que qualquer correção ou ajuste de
--      regra de negócio (ex.: o filtro de doações com status
--      'recusado') é escrito uma única vez (na function) e vale para
--      quem chama a function diretamente e para quem prefere o estilo
--      CALL + FETCH de uma procedure.
--
-- Como consequência, a validação de p_k > 0 (consultas 5 a 8) também
-- deixou de ser duplicada aqui: ela já existe dentro de fn_top_xxx
-- (06_functions.sql) e dispara normalmente quando a procedure chama a
-- function, então a procedure não precisa repetir o mesmo RAISE
-- EXCEPTION.
--
-- Padrão de chamada (inalterado):
--   BEGIN;
--   CALL sp_nome('meu_cursor', <params>);
--   FETCH ALL FROM meu_cursor;
--   COMMIT;

SET search_path TO streaming;

-- =========================================================================
-- Procedure 1 — Canais patrocinados e valores de patrocínio, por empresa
-- =========================================================================
-- Encapsula: fn_canais_patrocinados (06_functions.sql), que por sua vez
-- usa vw_canais_patrocinados (04_views.sql).
-- Parâmetro opcional p_nro_empresa: NULL → todas as empresas;
--                                   valor → somente aquela empresa.
-- =========================================================================
CREATE OR REPLACE PROCEDURE sp_canais_patrocinados(
    INOUT p_cursor      REFCURSOR DEFAULT 'cur_canais_patrocinados',
    IN    p_nro_empresa INT       DEFAULT NULL
)
LANGUAGE plpgsql
SET search_path = streaming, pg_temp
AS $$
BEGIN
    OPEN p_cursor FOR
        SELECT * FROM fn_canais_patrocinados(p_nro_empresa);
END;
$$;

-- Exemplos de chamada:
-- BEGIN;
-- CALL sp_canais_patrocinados();              -- todas as empresas
-- FETCH ALL FROM cur_canais_patrocinados;
-- COMMIT;
--
-- BEGIN;
-- CALL sp_canais_patrocinados('cur', 3);      -- só a empresa nro = 3
-- FETCH ALL FROM cur;
-- COMMIT;


-- =========================================================================
-- Procedure 2 — Quantidade de canais por usuário-membro e gasto mensal
-- =========================================================================
-- Encapsula: fn_gastos_mensais_membros (06_functions.sql), que usa
-- vw_gastos_mensais_membros (04_views.sql) + join com Usuario.
-- Parâmetro opcional p_id_usuario: NULL → todos os membros;
--                                  valor → somente aquele usuário.
-- =========================================================================
CREATE OR REPLACE PROCEDURE sp_gastos_mensais_membros(
    INOUT p_cursor     REFCURSOR DEFAULT 'cur_gastos_mensais',
    IN    p_id_usuario INT       DEFAULT NULL
)
LANGUAGE plpgsql
SET search_path = streaming, pg_temp
AS $$
BEGIN
    OPEN p_cursor FOR
        SELECT * FROM fn_gastos_mensais_membros(p_id_usuario);
END;
$$;

-- Exemplos de chamada:
-- BEGIN;
-- CALL sp_gastos_mensais_membros();           -- todos os membros
-- FETCH ALL FROM cur_gastos_mensais;
-- COMMIT;
--
-- BEGIN;
-- CALL sp_gastos_mensais_membros('cur', 42);  -- só o usuário id = 42
-- FETCH ALL FROM cur;
-- COMMIT;


-- =========================================================================
-- Procedure 3 — Canais que receberam doações e soma dos valores recebidos
-- =========================================================================
-- Encapsula: fn_doacoes_por_canal (06_functions.sql), que usa
-- vw_doacoes_por_canal (04_views.sql) — já exclui doações com status
-- 'recusado' (ver README).
-- Parâmetro opcional p_id_canal: NULL → todos os canais;
--                                valor → somente aquele canal.
-- =========================================================================
CREATE OR REPLACE PROCEDURE sp_doacoes_por_canal(
    INOUT p_cursor   REFCURSOR DEFAULT 'cur_doacoes_canal',
    IN    p_id_canal INT       DEFAULT NULL
)
LANGUAGE plpgsql
SET search_path = streaming, pg_temp
AS $$
BEGIN
    OPEN p_cursor FOR
        SELECT * FROM fn_doacoes_por_canal(p_id_canal);
END;
$$;

-- Exemplos de chamada:
-- BEGIN;
-- CALL sp_doacoes_por_canal();                -- todos os canais
-- FETCH ALL FROM cur_doacoes_canal;
-- COMMIT;
--
-- BEGIN;
-- CALL sp_doacoes_por_canal('cur', 10);       -- só o canal id = 10
-- FETCH ALL FROM cur;
-- COMMIT;


-- =========================================================================
-- Procedure 4 — Soma das doações de comentários lidos, por vídeo
-- =========================================================================
-- Encapsula: fn_doacoes_lidas_por_video (06_functions.sql), que usa
-- vw_doacoes_lidas_por_video (04_views.sql) — filtra status = 'lido'.
-- Parâmetro opcional p_id_video: NULL → todos os vídeos;
--                                valor → somente aquele vídeo.
-- =========================================================================
CREATE OR REPLACE PROCEDURE sp_doacoes_lidas_por_video(
    INOUT p_cursor   REFCURSOR DEFAULT 'cur_doacoes_video',
    IN    p_id_video INT       DEFAULT NULL
)
LANGUAGE plpgsql
SET search_path = streaming, pg_temp
AS $$
BEGIN
    OPEN p_cursor FOR
        SELECT * FROM fn_doacoes_lidas_por_video(p_id_video);
END;
$$;

-- Exemplos de chamada:
-- BEGIN;
-- CALL sp_doacoes_lidas_por_video();           -- todos os vídeos
-- FETCH ALL FROM cur_doacoes_video;
-- COMMIT;
--
-- BEGIN;
-- CALL sp_doacoes_lidas_por_video('cur', 100); -- só o vídeo id = 100
-- FETCH ALL FROM cur;
-- COMMIT;


-- =========================================================================
-- Procedure 5 — Top-k canais por valor de patrocínio
-- =========================================================================
-- Encapsula: fn_top_canais_patrocinio (06_functions.sql). A validação de
-- p_k > 0 já é feita dentro da function — se p_k for inválido, o erro é
-- levantado lá e propagado normalmente para quem chamou a procedure.
-- Parâmetro obrigatório p_k: inteiro positivo (tamanho do ranking).
-- =========================================================================
CREATE OR REPLACE PROCEDURE sp_top_canais_patrocinio(
    INOUT p_cursor REFCURSOR DEFAULT 'cur_top_patrocinio',
    IN    p_k      INT
)
LANGUAGE plpgsql
SET search_path = streaming, pg_temp
AS $$
BEGIN
    OPEN p_cursor FOR
        SELECT * FROM fn_top_canais_patrocinio(p_k);
END;
$$;

-- Exemplo de chamada:
-- BEGIN;
-- CALL sp_top_canais_patrocinio('cur', 10);    -- top-10
-- FETCH ALL FROM cur;
-- COMMIT;


-- =========================================================================
-- Procedure 6 — Top-k canais por aportes de membros
-- =========================================================================
-- Encapsula: fn_top_canais_membros (06_functions.sql), que repete o join
-- agregado Inscricao + NivelCanal + Canal + Plataforma (sem view
-- equivalente, pois vw_gastos_mensais_membros agrega por usuário, não
-- por canal).
-- Parâmetro obrigatório p_k: inteiro positivo (tamanho do ranking).
-- =========================================================================
CREATE OR REPLACE PROCEDURE sp_top_canais_membros(
    INOUT p_cursor REFCURSOR DEFAULT 'cur_top_membros',
    IN    p_k      INT
)
LANGUAGE plpgsql
SET search_path = streaming, pg_temp
AS $$
BEGIN
    OPEN p_cursor FOR
        SELECT * FROM fn_top_canais_membros(p_k);
END;
$$;

-- Exemplo de chamada:
-- BEGIN;
-- CALL sp_top_canais_membros('cur', 10);       -- top-10
-- FETCH ALL FROM cur;
-- COMMIT;


-- =========================================================================
-- Procedure 7 — Top-k canais por doações (todos os vídeos)
-- =========================================================================
-- Encapsula: fn_top_canais_doacoes (06_functions.sql), que usa
-- vw_doacoes_por_canal (04_views.sql), já agregada por canal.
-- Parâmetro obrigatório p_k: inteiro positivo (tamanho do ranking).
-- =========================================================================
CREATE OR REPLACE PROCEDURE sp_top_canais_doacoes(
    INOUT p_cursor REFCURSOR DEFAULT 'cur_top_doacoes',
    IN    p_k      INT
)
LANGUAGE plpgsql
SET search_path = streaming, pg_temp
AS $$
BEGIN
    OPEN p_cursor FOR
        SELECT * FROM fn_top_canais_doacoes(p_k);
END;
$$;

-- Exemplo de chamada:
-- BEGIN;
-- CALL sp_top_canais_doacoes('cur', 10);       -- top-10
-- FETCH ALL FROM cur;
-- COMMIT;


-- =========================================================================
-- Procedure 8 — Top-k canais por faturamento total (3 fontes de receita)
-- =========================================================================
-- Encapsula: fn_top_canais_faturamento (06_functions.sql), que usa
-- mv_receita_total_canal (view MATERIALIZADA de 04_views.sql).
-- Parâmetro obrigatório p_k: inteiro positivo (tamanho do ranking).
--
-- ATENÇÃO: os triggers de 05_triggers.sql disparam REFRESH da view
-- materializada automaticamente após inserções em Patrocinio, Inscricao
-- e Doacao, mantendo os dados sempre atualizados.
-- =========================================================================
CREATE OR REPLACE PROCEDURE sp_top_canais_faturamento(
    INOUT p_cursor REFCURSOR DEFAULT 'cur_top_faturamento',
    IN    p_k      INT
)
LANGUAGE plpgsql
SET search_path = streaming, pg_temp
AS $$
BEGIN
    OPEN p_cursor FOR
        SELECT * FROM fn_top_canais_faturamento(p_k);
END;
$$;

-- Exemplo de chamada:
-- BEGIN;
-- CALL sp_top_canais_faturamento('cur', 10);   -- top-10
-- FETCH ALL FROM cur;
-- COMMIT;