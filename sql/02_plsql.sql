-- PL/pgSQL — Views, Triggers, Functions e Procedures
-- Banco de Dados de Streaming de Jogos
-- TCC00335 — UFF — Prof. Marcos Bedo — 2026/1
-- Execute APÓS 01_schema.sql e 03_dados.sql

SET search_path TO streaming;

-- =========================================================================
-- VIEWS
-- =========================================================================

DROP MATERIALIZED VIEW IF EXISTS mv_receita_total_canal;
DROP VIEW IF EXISTS vw_doacoes_lidas_por_video;
DROP VIEW IF EXISTS vw_doacoes_por_canal;
DROP VIEW IF EXISTS vw_gastos_mensais_membros;
DROP VIEW IF EXISTS vw_canais_patrocinados;

-- View 1: Canais patrocinados
CREATE VIEW vw_canais_patrocinados AS
SELECT
    e.nro AS nro_empresa,
    e.nome AS empresa,
    e.nome_fantasia,
    c.id_canal,
    c.nome AS canal,
    p.nome AS plataforma,
    c.id_streamer,
    pa.valor AS valor_patrocinio
FROM Patrocinio pa
JOIN Empresa e
    ON e.nro = pa.nro_empresa
JOIN Canal c
    ON c.id_canal = pa.id_canal
JOIN Plataforma p
    ON p.nro = c.nro_plataforma;

-- View 2: Gastos mensais de membros
CREATE VIEW vw_gastos_mensais_membros AS
SELECT
    i.id_membro,
    COUNT(*) AS qtd_canais_membro,
    SUM(nc.valor) AS valor_total_mensal
FROM Inscricao i
JOIN NivelCanal nc
    ON nc.id_canal = i.id_canal
   AND nc.nivel = i.nivel
GROUP BY i.id_membro;

-- View 3: Doações por canal (excluindo recusadas)
CREATE VIEW vw_doacoes_por_canal AS
SELECT
    c.id_canal,
    c.nome AS canal,
    p.nome AS plataforma,
    c.id_streamer,
    COUNT(*) AS qtd_doacoes_recebidas,
    SUM(d.valor) AS valor_total_doacoes_recebidas
FROM Doacao d
JOIN Comentario cm
    ON cm.id_comentario = d.id_comentario
JOIN Video v
    ON v.id_video = cm.id_video
JOIN Canal c
    ON c.id_canal = v.id_canal
JOIN Plataforma p
    ON p.nro = c.nro_plataforma
WHERE d.status IN ('recebido', 'lido')
GROUP BY
    c.id_canal,
    c.nome,
    p.nome,
    c.id_streamer;

-- View 4: Doações lidas por vídeo
CREATE VIEW vw_doacoes_lidas_por_video AS
SELECT
    v.id_video,
    v.titulo,
    c.id_canal,
    c.nome AS canal,
    p.nome AS plataforma,
    COUNT(*) AS qtd_doacoes_lidas,
    SUM(d.valor) AS valor_total_doacoes_lidas
FROM Doacao d
JOIN Comentario cm
    ON cm.id_comentario = d.id_comentario
JOIN Video v
    ON v.id_video = cm.id_video
JOIN Canal c
    ON c.id_canal = v.id_canal
JOIN Plataforma p
    ON p.nro = c.nro_plataforma
WHERE d.status = 'lido'
GROUP BY
    v.id_video,
    v.titulo,
    c.id_canal,
    c.nome,
    p.nome;

-- View Materializada 5: Receita total por canal
CREATE MATERIALIZED VIEW mv_receita_total_canal AS
WITH patrocinio AS (
    SELECT
        id_canal,
        SUM(valor) AS total_patrocinio
    FROM Patrocinio
    GROUP BY id_canal
),
membros AS (
    SELECT
        i.id_canal,
        SUM(nc.valor) AS total_membros
    FROM Inscricao i
    JOIN NivelCanal nc
        ON nc.id_canal = i.id_canal
       AND nc.nivel = i.nivel
    GROUP BY i.id_canal
),
doacoes AS (
    SELECT
        v.id_canal,
        SUM(d.valor) AS total_doacoes
    FROM Doacao d
    JOIN Comentario cm
        ON cm.id_comentario = d.id_comentario
    JOIN Video v
        ON v.id_video = cm.id_video
    WHERE d.status IN ('recebido', 'lido')
    GROUP BY v.id_canal
)
SELECT
    c.id_canal,
    c.nome AS canal,
    p.nome AS plataforma,
    c.id_streamer,
    COALESCE(pa.total_patrocinio, 0::NUMERIC) AS total_patrocinio,
    COALESCE(mb.total_membros, 0::NUMERIC) AS total_membros,
    COALESCE(doa.total_doacoes, 0::NUMERIC) AS total_doacoes,
    COALESCE(pa.total_patrocinio, 0::NUMERIC)
    + COALESCE(mb.total_membros, 0::NUMERIC)
    + COALESCE(doa.total_doacoes, 0::NUMERIC) AS total_receita
FROM Canal c
JOIN Plataforma p
    ON p.nro = c.nro_plataforma
LEFT JOIN patrocinio pa
    ON pa.id_canal = c.id_canal
LEFT JOIN membros mb
    ON mb.id_canal = c.id_canal
LEFT JOIN doacoes doa
    ON doa.id_canal = c.id_canal;


-- =========================================================================
-- TRIGGERS
-- =========================================================================

DROP TRIGGER IF EXISTS tg_atualiza_qtd_users         ON PlataformaUsuario;
DROP TRIGGER IF EXISTS tg_atualiza_qtd_videos        ON Video;
DROP TRIGGER IF EXISTS tg_atualiza_qtd_visualizacoes ON Video;
DROP TRIGGER IF EXISTS tg_substitui_inscricao        ON Inscricao;
DROP TRIGGER IF EXISTS tg_valida_bitcoin             ON Bitcoin;
DROP TRIGGER IF EXISTS tg_valida_paypal              ON PayPal;
DROP TRIGGER IF EXISTS tg_valida_cartao              ON CartaoCredito;
DROP TRIGGER IF EXISTS tg_valida_mecplat             ON MecanismoPlat;
DROP TRIGGER IF EXISTS tg_refresh_receita_patrocinio ON Patrocinio;
DROP TRIGGER IF EXISTS tg_refresh_receita_inscricao  ON Inscricao;
DROP TRIGGER IF EXISTS tg_refresh_receita_doacao     ON Doacao;
DROP TRIGGER IF EXISTS tg_refresh_receita_nivelcanal ON NivelCanal;

DROP FUNCTION IF EXISTS fn_atualiza_qtd_users();
DROP FUNCTION IF EXISTS fn_atualiza_qtd_videos();
DROP FUNCTION IF EXISTS fn_atualiza_qtd_visualizacoes();
DROP FUNCTION IF EXISTS fn_substitui_inscricao();
DROP FUNCTION IF EXISTS fn_valida_subtabela_doacao();
DROP FUNCTION IF EXISTS fn_refresh_receita_total_canal();

-- Trigger 1: Plataforma.qtd_users
CREATE OR REPLACE FUNCTION fn_atualiza_qtd_users()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = streaming, pg_temp AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE Plataforma SET qtd_users = qtd_users + 1 WHERE nro = NEW.nro_plataforma;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE Plataforma SET qtd_users = qtd_users - 1 WHERE nro = OLD.nro_plataforma;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

CREATE TRIGGER tg_atualiza_qtd_users
AFTER INSERT OR DELETE ON PlataformaUsuario
FOR EACH ROW EXECUTE FUNCTION fn_atualiza_qtd_users();

-- Trigger 2: Canal.qtd_videos
CREATE OR REPLACE FUNCTION fn_atualiza_qtd_videos()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = streaming, pg_temp AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE Canal SET qtd_videos = qtd_videos + 1 WHERE id_canal = NEW.id_canal;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE Canal SET qtd_videos = qtd_videos - 1 WHERE id_canal = OLD.id_canal;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

CREATE TRIGGER tg_atualiza_qtd_videos
AFTER INSERT OR DELETE ON Video
FOR EACH ROW EXECUTE FUNCTION fn_atualiza_qtd_videos();

-- Trigger 3: Canal.qtd_visualizacoes
CREATE OR REPLACE FUNCTION fn_atualiza_qtd_visualizacoes()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = streaming, pg_temp AS $$
BEGIN
    UPDATE Canal
       SET qtd_visualizacoes = (
               SELECT COALESCE(SUM(visu_total), 0) FROM Video WHERE id_canal = NEW.id_canal
           )
     WHERE id_canal = NEW.id_canal;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_atualiza_qtd_visualizacoes
AFTER INSERT OR UPDATE OF visu_total ON Video
FOR EACH ROW EXECUTE FUNCTION fn_atualiza_qtd_visualizacoes();

-- Trigger 4: Inscricao vigente
CREATE OR REPLACE FUNCTION fn_substitui_inscricao()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = streaming, pg_temp AS $$
BEGIN
    DELETE FROM Inscricao WHERE id_canal = NEW.id_canal AND id_membro = NEW.id_membro;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_substitui_inscricao
BEFORE INSERT ON Inscricao
FOR EACH ROW EXECUTE FUNCTION fn_substitui_inscricao();

-- Trigger 5: Consistência entre Doacao.metodo e subtabela de pagamento
CREATE OR REPLACE FUNCTION fn_valida_subtabela_doacao()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = streaming, pg_temp AS $$
DECLARE
    v_metodo          VARCHAR(25);
    v_metodo_esperado VARCHAR(25);
BEGIN
    v_metodo_esperado := CASE TG_TABLE_NAME
        WHEN 'bitcoin'       THEN 'bitcoin'
        WHEN 'paypal'        THEN 'paypal'
        WHEN 'cartaocredito' THEN 'cartao_credito'
        WHEN 'mecanismoplat' THEN 'mecanismo_plataforma'
    END;
    SELECT metodo INTO v_metodo FROM Doacao
     WHERE id_comentario = NEW.id_comentario AND seq_pg = NEW.seq_doacao;
    IF v_metodo IS NULL THEN
        RAISE EXCEPTION 'Doação (id_comentario=%, seq_pg=%) não encontrada em Doacao',
            NEW.id_comentario, NEW.seq_doacao;
    END IF;
    IF v_metodo <> v_metodo_esperado THEN
        RAISE EXCEPTION 'Doação tem metodo=% mas está sendo inserida em %',
            v_metodo, TG_TABLE_NAME;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_valida_bitcoin  AFTER INSERT ON Bitcoin       FOR EACH ROW EXECUTE FUNCTION fn_valida_subtabela_doacao();
CREATE TRIGGER tg_valida_paypal   AFTER INSERT ON PayPal        FOR EACH ROW EXECUTE FUNCTION fn_valida_subtabela_doacao();
CREATE TRIGGER tg_valida_cartao   AFTER INSERT ON CartaoCredito FOR EACH ROW EXECUTE FUNCTION fn_valida_subtabela_doacao();
CREATE TRIGGER tg_valida_mecplat  AFTER INSERT ON MecanismoPlat FOR EACH ROW EXECUTE FUNCTION fn_valida_subtabela_doacao();

-- Trigger 6: Refresh de mv_receita_total_canal
CREATE OR REPLACE FUNCTION fn_refresh_receita_total_canal()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = streaming, pg_temp AS $$
BEGIN
    REFRESH MATERIALIZED VIEW mv_receita_total_canal;
    RETURN NULL;
END;
$$;

CREATE TRIGGER tg_refresh_receita_patrocinio AFTER INSERT OR UPDATE OR DELETE ON Patrocinio  FOR EACH STATEMENT EXECUTE FUNCTION fn_refresh_receita_total_canal();
CREATE TRIGGER tg_refresh_receita_inscricao  AFTER INSERT OR UPDATE OR DELETE ON Inscricao   FOR EACH STATEMENT EXECUTE FUNCTION fn_refresh_receita_total_canal();
CREATE TRIGGER tg_refresh_receita_doacao     AFTER INSERT OR UPDATE OR DELETE ON Doacao      FOR EACH STATEMENT EXECUTE FUNCTION fn_refresh_receita_total_canal();
CREATE TRIGGER tg_refresh_receita_nivelcanal AFTER INSERT OR UPDATE OR DELETE ON NivelCanal  FOR EACH STATEMENT EXECUTE FUNCTION fn_refresh_receita_total_canal();


-- =========================================================================
-- FUNCTIONS
-- =========================================================================

-- Função 1: Canais patrocinados por empresa
CREATE OR REPLACE FUNCTION fn_canais_patrocinados(p_nro_empresa INT DEFAULT NULL)
RETURNS TABLE (
    nro_empresa INT, empresa VARCHAR, nome_fantasia VARCHAR,
    id_canal INT, canal VARCHAR, plataforma VARCHAR,
    id_streamer INT, valor_patrocinio NUMERIC
)
LANGUAGE plpgsql SET search_path = streaming, pg_temp AS $$
BEGIN
    RETURN QUERY
    SELECT v.nro_empresa, v.empresa, v.nome_fantasia, v.id_canal, v.canal,
           v.plataforma, v.id_streamer, v.valor_patrocinio
    FROM vw_canais_patrocinados v
    WHERE p_nro_empresa IS NULL OR v.nro_empresa = p_nro_empresa
    ORDER BY v.empresa, v.valor_patrocinio DESC;
END;
$$;

-- Função 2: Gastos mensais de membros
CREATE OR REPLACE FUNCTION fn_gastos_mensais_membros(p_id_usuario INT DEFAULT NULL)
RETURNS TABLE (
    id_usuario INT, nick VARCHAR, qtd_canais_membro BIGINT, valor_total_mensal NUMERIC
)
LANGUAGE plpgsql SET search_path = streaming, pg_temp AS $$
BEGIN
    RETURN QUERY
    SELECT u.id_usuario, u.nick, g.qtd_canais_membro, g.valor_total_mensal
    FROM vw_gastos_mensais_membros g
    JOIN Usuario u ON u.id_usuario = g.id_membro
    WHERE p_id_usuario IS NULL OR u.id_usuario = p_id_usuario
    ORDER BY g.valor_total_mensal DESC;
END;
$$;

-- Função 3: Doações por canal
CREATE OR REPLACE FUNCTION fn_doacoes_por_canal(p_id_canal INT DEFAULT NULL)
RETURNS TABLE (
    id_canal INT, canal VARCHAR, plataforma VARCHAR, id_streamer INT,
    qtd_doacoes_recebidas BIGINT, valor_total_doacoes_recebidas NUMERIC
)
LANGUAGE plpgsql SET search_path = streaming, pg_temp AS $$
BEGIN
    RETURN QUERY
    SELECT v.id_canal, v.canal, v.plataforma, v.id_streamer,
           v.qtd_doacoes_recebidas, v.valor_total_doacoes_recebidas
    FROM vw_doacoes_por_canal v
    WHERE p_id_canal IS NULL OR v.id_canal = p_id_canal
    ORDER BY v.valor_total_doacoes_recebidas DESC;
END;
$$;

-- Função 4: Doações lidas por vídeo
CREATE OR REPLACE FUNCTION fn_doacoes_lidas_por_video(p_id_video INT DEFAULT NULL)
RETURNS TABLE (
    id_video INT, titulo VARCHAR, id_canal INT, canal VARCHAR, plataforma VARCHAR,
    qtd_doacoes_lidas BIGINT, valor_total_doacoes_lidas NUMERIC
)
LANGUAGE plpgsql SET search_path = streaming, pg_temp AS $$
BEGIN
    RETURN QUERY
    SELECT v.id_video, v.titulo, v.id_canal, v.canal, v.plataforma,
           v.qtd_doacoes_lidas, v.valor_total_doacoes_lidas
    FROM vw_doacoes_lidas_por_video v
    WHERE p_id_video IS NULL OR v.id_video = p_id_video
    ORDER BY v.valor_total_doacoes_lidas DESC;
END;
$$;

-- Função 5: Top-k canais por patrocínio
CREATE OR REPLACE FUNCTION fn_top_canais_patrocinio(p_k INT)
RETURNS TABLE (id_canal INT, canal VARCHAR, plataforma VARCHAR, total_patrocinio NUMERIC)
LANGUAGE plpgsql SET search_path = streaming, pg_temp AS $$
BEGIN
    IF p_k IS NULL OR p_k <= 0 THEN
        RAISE EXCEPTION 'p_k deve ser um inteiro positivo (valor informado: %)', p_k;
    END IF;
    RETURN QUERY
    SELECT v.id_canal, v.canal, v.plataforma, SUM(v.valor_patrocinio) AS total_patrocinio
    FROM vw_canais_patrocinados v
    GROUP BY v.id_canal, v.canal, v.plataforma
    ORDER BY total_patrocinio DESC
    LIMIT p_k;
END;
$$;

-- Função 6: Top-k canais por membros
CREATE OR REPLACE FUNCTION fn_top_canais_membros(p_k INT)
RETURNS TABLE (id_canal INT, canal VARCHAR, plataforma VARCHAR, total_membros NUMERIC)
LANGUAGE plpgsql SET search_path = streaming, pg_temp AS $$
BEGIN
    IF p_k IS NULL OR p_k <= 0 THEN
        RAISE EXCEPTION 'p_k deve ser um inteiro positivo (valor informado: %)', p_k;
    END IF;
    RETURN QUERY
    SELECT c.id_canal, c.nome AS canal, p.nome AS plataforma, SUM(nc.valor) AS total_membros
    FROM Inscricao i
    JOIN NivelCanal nc ON nc.id_canal = i.id_canal AND nc.nivel = i.nivel
    JOIN Canal c        ON c.id_canal = i.id_canal
    JOIN Plataforma p   ON p.nro = c.nro_plataforma
    GROUP BY c.id_canal, c.nome, p.nome
    ORDER BY total_membros DESC
    LIMIT p_k;
END;
$$;

-- Função 7: Top-k canais por doações
CREATE OR REPLACE FUNCTION fn_top_canais_doacoes(p_k INT)
RETURNS TABLE (id_canal INT, canal VARCHAR, plataforma VARCHAR, total_doacoes NUMERIC)
LANGUAGE plpgsql SET search_path = streaming, pg_temp AS $$
BEGIN
    IF p_k IS NULL OR p_k <= 0 THEN
        RAISE EXCEPTION 'p_k deve ser um inteiro positivo (valor informado: %)', p_k;
    END IF;
    RETURN QUERY
    SELECT v.id_canal, v.canal, v.plataforma, v.valor_total_doacoes_recebidas AS total_doacoes
    FROM vw_doacoes_por_canal v
    ORDER BY total_doacoes DESC
    LIMIT p_k;
END;
$$;

-- Função 8: Top-k canais por faturamento total
CREATE OR REPLACE FUNCTION fn_top_canais_faturamento(p_k INT)
RETURNS TABLE (
    id_canal INT, canal VARCHAR, plataforma VARCHAR,
    total_patrocinio NUMERIC, total_membros NUMERIC,
    total_doacoes NUMERIC, total_receita NUMERIC
)
LANGUAGE plpgsql SET search_path = streaming, pg_temp AS $$
BEGIN
    IF p_k IS NULL OR p_k <= 0 THEN
        RAISE EXCEPTION 'p_k deve ser um inteiro positivo (valor informado: %)', p_k;
    END IF;
    RETURN QUERY
    SELECT m.id_canal, m.canal, m.plataforma,
           m.total_patrocinio, m.total_membros, m.total_doacoes, m.total_receita
    FROM mv_receita_total_canal m
    WHERE m.total_receita > 0
    ORDER BY m.total_receita DESC
    LIMIT p_k;
END;
$$;


-- =========================================================================
-- PROCEDURES
-- =========================================================================

-- Procedure 1
CREATE OR REPLACE PROCEDURE sp_canais_patrocinados(
    INOUT p_cursor REFCURSOR DEFAULT 'cur_canais_patrocinados',
    IN p_nro_empresa INT DEFAULT NULL
)
LANGUAGE plpgsql SET search_path = streaming, pg_temp AS $$
BEGIN
    OPEN p_cursor FOR SELECT * FROM fn_canais_patrocinados(p_nro_empresa);
END;
$$;

-- Procedure 2
CREATE OR REPLACE PROCEDURE sp_gastos_mensais_membros(
    INOUT p_cursor REFCURSOR DEFAULT 'cur_gastos_mensais',
    IN p_id_usuario INT DEFAULT NULL
)
LANGUAGE plpgsql SET search_path = streaming, pg_temp AS $$
BEGIN
    OPEN p_cursor FOR SELECT * FROM fn_gastos_mensais_membros(p_id_usuario);
END;
$$;

-- Procedure 3
CREATE OR REPLACE PROCEDURE sp_doacoes_por_canal(
    INOUT p_cursor REFCURSOR DEFAULT 'cur_doacoes_canal',
    IN p_id_canal INT DEFAULT NULL
)
LANGUAGE plpgsql SET search_path = streaming, pg_temp AS $$
BEGIN
    OPEN p_cursor FOR SELECT * FROM fn_doacoes_por_canal(p_id_canal);
END;
$$;

-- Procedure 4
CREATE OR REPLACE PROCEDURE sp_doacoes_lidas_por_video(
    INOUT p_cursor REFCURSOR DEFAULT 'cur_doacoes_video',
    IN p_id_video INT DEFAULT NULL
)
LANGUAGE plpgsql SET search_path = streaming, pg_temp AS $$
BEGIN
    OPEN p_cursor FOR SELECT * FROM fn_doacoes_lidas_por_video(p_id_video);
END;
$$;

-- Procedure 5
CREATE OR REPLACE PROCEDURE sp_top_canais_patrocinio(
    IN p_k INT,
    INOUT p_cursor REFCURSOR DEFAULT 'cur_top_patrocinio'
)
LANGUAGE plpgsql SET search_path = streaming, pg_temp AS $$
BEGIN
    OPEN p_cursor FOR SELECT * FROM fn_top_canais_patrocinio(p_k);
END;
$$;

-- Procedure 6
CREATE OR REPLACE PROCEDURE sp_top_canais_membros(
    IN p_k INT,
    INOUT p_cursor REFCURSOR DEFAULT 'cur_top_membros'
)
LANGUAGE plpgsql SET search_path = streaming, pg_temp AS $$
BEGIN
    OPEN p_cursor FOR SELECT * FROM fn_top_canais_membros(p_k);
END;
$$;

-- Procedure 7
CREATE OR REPLACE PROCEDURE sp_top_canais_doacoes(
    IN p_k INT,
    INOUT p_cursor REFCURSOR DEFAULT 'cur_top_doacoes'
)
LANGUAGE plpgsql SET search_path = streaming, pg_temp AS $$
BEGIN
    OPEN p_cursor FOR SELECT * FROM fn_top_canais_doacoes(p_k);
END;
$$;

-- Procedure 8
CREATE OR REPLACE PROCEDURE sp_top_canais_faturamento(
    IN p_k INT,
    INOUT p_cursor REFCURSOR DEFAULT 'cur_top_faturamento'
)
LANGUAGE plpgsql SET search_path = streaming, pg_temp AS $$
BEGIN
    OPEN p_cursor FOR SELECT * FROM fn_top_canais_faturamento(p_k);
END;
$$;