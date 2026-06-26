-- Triggers banco de dados de streaming de jogos
-- TCC00335 — UFF — Prof. Marcos Bedo — 2026/1
-- Execute APÓS 04_views.sql (Trigger 7 depende de mv_receita_total_canal)

SET search_path TO streaming;

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


-- =========================================================================
-- TRIGGER 1 — Plataforma.qtd_users (atributo derivado)
-- =========================================================================
-- A coluna Plataforma.qtd_users guarda a contagem de usuários cadastrados
-- naquela plataforma (PlataformaUsuario). Mantê-la sincronizada via
-- trigger evita um COUNT(*) a cada leitura — a tabela é consultada com
-- muito mais frequência do que usuários entram/saem de uma plataforma.
CREATE OR REPLACE FUNCTION fn_atualiza_qtd_users()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = streaming, pg_temp
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE Plataforma
           SET qtd_users = qtd_users + 1
         WHERE nro = NEW.nro_plataforma;
        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        UPDATE Plataforma
           SET qtd_users = qtd_users - 1
         WHERE nro = OLD.nro_plataforma;
        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$;

CREATE TRIGGER tg_atualiza_qtd_users
AFTER INSERT OR DELETE ON PlataformaUsuario
FOR EACH ROW
EXECUTE FUNCTION fn_atualiza_qtd_users();


-- =========================================================================
-- TRIGGER 2 — Canal.qtd_videos (atributo derivado)
-- =========================================================================
-- Mantém Canal.qtd_videos sincronizado a cada vídeo postado/removido no
-- canal, evitando um COUNT(*) em Video a cada consulta ao Canal.
CREATE OR REPLACE FUNCTION fn_atualiza_qtd_videos()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = streaming, pg_temp
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE Canal
           SET qtd_videos = qtd_videos + 1
         WHERE id_canal = NEW.id_canal;
        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        UPDATE Canal
           SET qtd_videos = qtd_videos - 1
         WHERE id_canal = OLD.id_canal;
        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$;

CREATE TRIGGER tg_atualiza_qtd_videos
AFTER INSERT OR DELETE ON Video
FOR EACH ROW
EXECUTE FUNCTION fn_atualiza_qtd_videos();


-- =========================================================================
-- TRIGGER 3 — Canal.qtd_visualizacoes (atributo derivado)
-- =========================================================================
-- Mantém Canal.qtd_visualizacoes = soma de Video.visu_total de todos os
-- vídeos do canal. Dispara em INSERT (vídeo novo já entra com
-- visu_total >= 0) e em UPDATE de visu_total (visualizações acumulando
-- ao longo do tempo).
CREATE OR REPLACE FUNCTION fn_atualiza_qtd_visualizacoes()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = streaming, pg_temp
AS $$
BEGIN
    UPDATE Canal
       SET qtd_visualizacoes = (
               SELECT COALESCE(SUM(visu_total), 0)
                 FROM Video
                WHERE id_canal = NEW.id_canal
           )
     WHERE id_canal = NEW.id_canal;

    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_atualiza_qtd_visualizacoes
AFTER INSERT OR UPDATE OF visu_total ON Video
FOR EACH ROW
EXECUTE FUNCTION fn_atualiza_qtd_visualizacoes();


-- =========================================================================
-- TRIGGER 4 — Inscrição (membro) vigente (sistema não armazena histórico)
-- =========================================================================
-- O enunciado define que "o sistema não armazena o histórico de membros,
-- ou seja, apenas os membros vigentes devem aparecer no sistema". A PK
-- (id_canal, id_membro) já impede duas linhas idênticas, mas não impede
-- o INSERT de falhar por violação de PK quando o membro troca de nível.
-- Este trigger remove a inscrição anterior antes do INSERT, tornando a
-- troca de nível transparente para quem está inserindo.
-- Nota: para Patrocinio, a própria PK (nro_empresa, id_canal) já garante
-- que a mesma empresa não patrocina o mesmo canal duas vezes — e o
-- enunciado não proíbe múltiplos patrocinadores simultâneos para um
-- mesmo canal, portanto nenhum trigger adicional é necessário lá.
CREATE OR REPLACE FUNCTION fn_substitui_inscricao()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = streaming, pg_temp
AS $$
BEGIN
    DELETE FROM Inscricao
     WHERE id_canal  = NEW.id_canal
       AND id_membro = NEW.id_membro;

    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_substitui_inscricao
BEFORE INSERT ON Inscricao
FOR EACH ROW
EXECUTE FUNCTION fn_substitui_inscricao();


-- =========================================================================
-- TRIGGER 5 — Consistência entre Doacao.metodo e a subtabela de pagamento
-- =========================================================================
-- O schema guarda o método de pagamento em Doacao.metodo (CHECK garante
-- apenas os 4 valores possíveis). O que nenhuma constraint declarativa
-- garante é a ligação entre Doacao e a subtabela específica: nada impede
-- que uma doação com metodo = 'bitcoin' seja inserida por engano em
-- PayPal. Este trigger atua nas 4 subtabelas e verifica, a cada INSERT,
-- se o metodo da Doacao referenciada corresponde à subtabela de destino.
CREATE OR REPLACE FUNCTION fn_valida_subtabela_doacao()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = streaming, pg_temp
AS $$
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

    SELECT metodo INTO v_metodo
      FROM Doacao
     WHERE id_comentario = NEW.id_comentario
       AND seq_pg        = NEW.seq_doacao;

    IF v_metodo IS NULL THEN
        RAISE EXCEPTION
            'Doação (id_comentario=%, seq_pg=%) não encontrada em Doacao',
            NEW.id_comentario, NEW.seq_doacao;
    END IF;

    IF v_metodo <> v_metodo_esperado THEN
        RAISE EXCEPTION
            'Doação (id_comentario=%, seq_pg=%) tem metodo=% em Doacao, mas está sendo inserida em %',
            NEW.id_comentario, NEW.seq_doacao, v_metodo, TG_TABLE_NAME;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_valida_bitcoin
AFTER INSERT ON Bitcoin
FOR EACH ROW
EXECUTE FUNCTION fn_valida_subtabela_doacao();

CREATE TRIGGER tg_valida_paypal
AFTER INSERT ON PayPal
FOR EACH ROW
EXECUTE FUNCTION fn_valida_subtabela_doacao();

CREATE TRIGGER tg_valida_cartao
AFTER INSERT ON CartaoCredito
FOR EACH ROW
EXECUTE FUNCTION fn_valida_subtabela_doacao();

CREATE TRIGGER tg_valida_mecplat
AFTER INSERT ON MecanismoPlat
FOR EACH ROW
EXECUTE FUNCTION fn_valida_subtabela_doacao();


-- =========================================================================
-- TRIGGER 6 — Refresh de mv_receita_total_canal
-- =========================================================================
-- mv_receita_total_canal soma patrocínio + membros + doações por canal e
-- é usada por fn_top_canais_faturamento (06_functions.sql). Por ser
-- MATERIALIZADA, seus valores não atualizam sozinhos a cada mudança nas
-- tabelas-fonte. Este trigger dispara REFRESH após qualquer alteração em
-- Patrocinio, Inscricao, Doacao e NivelCanal — incluindo NivelCanal
-- porque uma mudança no valor de um nível afeta diretamente o total de
-- membros agregado na view.
-- Observação: REFRESH sem CONCURRENTLY bloqueia leituras da view durante
-- a atualização; em uma base maior valeria criar um índice UNIQUE na view
-- e usar REFRESH ... CONCURRENTLY.
CREATE OR REPLACE FUNCTION fn_refresh_receita_total_canal()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = streaming, pg_temp
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW mv_receita_total_canal;
    RETURN NULL;
END;
$$;

CREATE TRIGGER tg_refresh_receita_patrocinio
AFTER INSERT OR UPDATE OR DELETE ON Patrocinio
FOR EACH STATEMENT
EXECUTE FUNCTION fn_refresh_receita_total_canal();

CREATE TRIGGER tg_refresh_receita_inscricao
AFTER INSERT OR UPDATE OR DELETE ON Inscricao
FOR EACH STATEMENT
EXECUTE FUNCTION fn_refresh_receita_total_canal();

CREATE TRIGGER tg_refresh_receita_doacao
AFTER INSERT OR UPDATE OR DELETE ON Doacao
FOR EACH STATEMENT
EXECUTE FUNCTION fn_refresh_receita_total_canal();

CREATE TRIGGER tg_refresh_receita_nivelcanal
AFTER INSERT OR UPDATE OR DELETE ON NivelCanal
FOR EACH STATEMENT
EXECUTE FUNCTION fn_refresh_receita_total_canal();


-- =========================================================================
-- Verificação: lista todos os triggers criados no schema streaming
-- =========================================================================
-- SELECT event_object_table AS tabela, trigger_name, action_timing, event_manipulation
--   FROM information_schema.triggers
--  WHERE trigger_schema = 'streaming'
--  ORDER BY tabela, trigger_name;