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
-- Correção: p_k (sem default) deve vir antes de p_cursor (com default)
CREATE OR REPLACE PROCEDURE sp_top_canais_patrocinio(
    IN    p_k      INT,
    INOUT p_cursor REFCURSOR DEFAULT 'cur_top_patrocinio'
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
-- CALL sp_top_canais_patrocinio(10);           -- top-10
-- FETCH ALL FROM cur_top_patrocinio;
-- COMMIT;
--
-- BEGIN;
-- CALL sp_top_canais_patrocinio(10, 'cur');    -- cursor nomeado
-- FETCH ALL FROM cur;
-- COMMIT;


-- =========================================================================
-- Procedure 6 — Top-k canais por aportes de membros
-- =========================================================================
-- Correção: p_k (sem default) deve vir antes de p_cursor (com default)
CREATE OR REPLACE PROCEDURE sp_top_canais_membros(
    IN    p_k      INT,
    INOUT p_cursor REFCURSOR DEFAULT 'cur_top_membros'
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
-- CALL sp_top_canais_membros(10);              -- top-10
-- FETCH ALL FROM cur_top_membros;
-- COMMIT;


-- =========================================================================
-- Procedure 7 — Top-k canais por doações (todos os vídeos)
-- =========================================================================
-- Correção: p_k (sem default) deve vir antes de p_cursor (com default)
CREATE OR REPLACE PROCEDURE sp_top_canais_doacoes(
    IN    p_k      INT,
    INOUT p_cursor REFCURSOR DEFAULT 'cur_top_doacoes'
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
-- CALL sp_top_canais_doacoes(10);              -- top-10
-- FETCH ALL FROM cur_top_doacoes;
-- COMMIT;


-- =========================================================================
-- Procedure 8 — Top-k canais por faturamento total (3 fontes de receita)
-- =========================================================================
-- Correção: p_k (sem default) deve vir antes de p_cursor (com default)
CREATE OR REPLACE PROCEDURE sp_top_canais_faturamento(
    IN    p_k      INT,
    INOUT p_cursor REFCURSOR DEFAULT 'cur_top_faturamento'
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
-- CALL sp_top_canais_faturamento(10);          -- top-10
-- FETCH ALL FROM cur_top_faturamento;
-- COMMIT;