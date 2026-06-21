-- Functions (stored routines parametrizadas) em PL/pgSQL
-- TCC00335 — UFF — Prof. Marcos Bedo — 2026/1
-- Execute APÓS 04_views.sql

SET search_path TO streaming;

-- =========================================================================
-- Decisão de design: functions sobre procedures, e functions sobre views
-- =========================================================================
-- O PostgreSQL distingue FUNCTION de PROCEDURE: uma PROCEDURE (CREATE
-- PROCEDURE / CALL) não devolve um conjunto de linhas diretamente — só
-- devolve valores via parâmetros OUT ou via um cursor (REFCURSOR), que o
-- chamador precisaria abrir e percorrer manualmente com FETCH. Como todas
-- as 8 consultas pedem uma listagem de linhas (canais, vídeos, usuários
-- etc.), o grupo optou por implementar todas como FUNCTION com RETURNS
-- TABLE, que pode ser chamada diretamente com SELECT * FROM fn_xxx(...) e
-- já devolve o resultado tabular pronto. O enunciado permite essa escolha
-- explicitamente ("functions ou stored procedures"); aqui "stored
-- procedure" é usado no sentido genérico de rotina parametrizada
-- armazenada no banco, não no sentido estrito da palavra-chave PROCEDURE.
--
-- A maioria das functions abaixo reaproveita as views virtuais e a view
-- materializada de 04_views.sql em vez de reescrever os mesmos joins.
-- Isso mantém a lógica de negócio (como o filtro de doações com status
-- 'recusado') definida em um único lugar, e ainda se beneficia dos
-- índices já criados em 03_indices.sql para as colunas de junção que
-- essas views utilizam por trás dos panos. As exceções são as funções 5
-- e 6 (rankings de patrocínio e de membros), que precisam agregar por
-- canal e não correspondem a nenhuma view já existente — então repetem,
-- de forma agregada, os joins originais de 07_consultas.sql.
--
-- Padrão de filtro opcional (consultas 1 a 4): o parâmetro recebe DEFAULT
-- NULL, e a cláusula WHERE usa "p_parametro IS NULL OR coluna =
-- p_parametro". Quando o parâmetro não é informado, a condição
-- "IS NULL" é verdadeira para todas as linhas e a function devolve o
-- resultado completo; quando é informado, filtra exatamente o registro
-- pedido. Esse padrão evita duplicar a lógica em uma versão "com filtro"
-- e outra "sem filtro" da mesma consulta.
-- =========================================================================


-- =========================================================================
-- Função 1 — Canais patrocinados e valores de patrocínio, por empresa
-- =========================================================================
-- Responde à consulta 1 do professor. Constrói-se sobre vw_canais_patrocinados
-- (04_views.sql), que já reúne Patrocinio, Empresa, Canal e Plataforma.
-- p_nro_empresa = NULL devolve os patrocínios de todas as empresas;
-- informado, devolve apenas os patrocínios daquela empresa.
CREATE OR REPLACE FUNCTION fn_canais_patrocinados(p_nro_empresa INT DEFAULT NULL)
RETURNS TABLE (
    nro_empresa      INT,
    empresa          VARCHAR,
    nome_fantasia    VARCHAR,
    id_canal         INT,
    canal            VARCHAR,
    plataforma       VARCHAR,
    id_streamer      INT,
    valor_patrocinio NUMERIC
)
LANGUAGE plpgsql
SET search_path = streaming, pg_temp
AS $$
BEGIN
    RETURN QUERY
    SELECT
        v.nro_empresa,
        v.empresa,
        v.nome_fantasia,
        v.id_canal,
        v.canal,
        v.plataforma,
        v.id_streamer,
        v.valor_patrocinio
    FROM vw_canais_patrocinados v
    WHERE p_nro_empresa IS NULL OR v.nro_empresa = p_nro_empresa
    ORDER BY v.empresa, v.valor_patrocinio DESC;
END;
$$;


-- =========================================================================
-- Função 2 — Quantidade de canais por usuário-membro e gasto mensal
-- =========================================================================
-- Responde à consulta 2. Constrói-se sobre vw_gastos_mensais_membros, que
-- agrupa Inscricao com NivelCanal por membro; aqui apenas junta-se
-- Usuario para expor o nick (a view guarda só o id_membro). p_id_usuario
-- = NULL devolve todos os membros; informado, devolve um único usuário.
CREATE OR REPLACE FUNCTION fn_gastos_mensais_membros(p_id_usuario INT DEFAULT NULL)
RETURNS TABLE (
    id_usuario          INT,
    nick                VARCHAR,
    qtd_canais_membro   BIGINT,
    valor_total_mensal  NUMERIC
)
LANGUAGE plpgsql
SET search_path = streaming, pg_temp
AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.id_usuario,
        u.nick,
        g.qtd_canais_membro,
        g.valor_total_mensal
    FROM vw_gastos_mensais_membros g
    JOIN Usuario u ON u.id_usuario = g.id_membro
    WHERE p_id_usuario IS NULL OR u.id_usuario = p_id_usuario
    ORDER BY g.valor_total_mensal DESC;
END;
$$;


-- =========================================================================
-- Função 3 — Canais que receberam doações e soma dos valores recebidos
-- =========================================================================
-- Responde à consulta 3. Constrói-se sobre vw_doacoes_por_canal, que já
-- percorre Doacao → Comentario → Video → Canal → Plataforma filtrando
-- status IN ('recebido', 'lido') — doações recusadas não contam como
-- valor recebido (decisão registrada no README). p_id_canal = NULL
-- devolve todos os canais; informado, devolve um único canal.
CREATE OR REPLACE FUNCTION fn_doacoes_por_canal(p_id_canal INT DEFAULT NULL)
RETURNS TABLE (
    id_canal                      INT,
    canal                         VARCHAR,
    plataforma                    VARCHAR,
    id_streamer                   INT,
    qtd_doacoes_recebidas         BIGINT,
    valor_total_doacoes_recebidas NUMERIC
)
LANGUAGE plpgsql
SET search_path = streaming, pg_temp
AS $$
BEGIN
    RETURN QUERY
    SELECT
        v.id_canal,
        v.canal,
        v.plataforma,
        v.id_streamer,
        v.qtd_doacoes_recebidas,
        v.valor_total_doacoes_recebidas
    FROM vw_doacoes_por_canal v
    WHERE p_id_canal IS NULL OR v.id_canal = p_id_canal
    ORDER BY v.valor_total_doacoes_recebidas DESC;
END;
$$;


-- =========================================================================
-- Função 4 — Soma das doações de comentários lidos, por vídeo
-- =========================================================================
-- Responde à consulta 4. Constrói-se sobre vw_doacoes_lidas_por_video, que
-- filtra especificamente status = 'lido' (subconjunto da view da função
-- 3, com granularidade de vídeo). p_id_video = NULL devolve todos os
-- vídeos; informado, devolve um único vídeo.
CREATE OR REPLACE FUNCTION fn_doacoes_lidas_por_video(p_id_video INT DEFAULT NULL)
RETURNS TABLE (
    id_video                  INT,
    titulo                    VARCHAR,
    id_canal                  INT,
    canal                     VARCHAR,
    plataforma                VARCHAR,
    qtd_doacoes_lidas         BIGINT,
    valor_total_doacoes_lidas NUMERIC
)
LANGUAGE plpgsql
SET search_path = streaming, pg_temp
AS $$
BEGIN
    RETURN QUERY
    SELECT
        v.id_video,
        v.titulo,
        v.id_canal,
        v.canal,
        v.plataforma,
        v.qtd_doacoes_lidas,
        v.valor_total_doacoes_lidas
    FROM vw_doacoes_lidas_por_video v
    WHERE p_id_video IS NULL OR v.id_video = p_id_video
    ORDER BY v.valor_total_doacoes_lidas DESC;
END;
$$;


-- =========================================================================
-- Função 5 — Top-k canais por valor de patrocínio
-- =========================================================================
-- Responde à consulta 5. vw_canais_patrocinados tem uma linha por
-- patrocínio (um canal pode ter mais de um patrocinador), então aqui
-- agrupa-se por canal e soma-se valor_patrocinio antes de aplicar o
-- LIMIT — diferente da função 1, que lista os patrocínios individuais.
CREATE OR REPLACE FUNCTION fn_top_canais_patrocinio(p_k INT)
RETURNS TABLE (
    id_canal         INT,
    canal            VARCHAR,
    plataforma       VARCHAR,
    total_patrocinio NUMERIC
)
LANGUAGE plpgsql
SET search_path = streaming, pg_temp
AS $$
BEGIN
    IF p_k IS NULL OR p_k <= 0 THEN
        RAISE EXCEPTION 'p_k deve ser um inteiro positivo (valor informado: %)', p_k;
    END IF;

    RETURN QUERY
    SELECT
        v.id_canal,
        v.canal,
        v.plataforma,
        SUM(v.valor_patrocinio) AS total_patrocinio
    FROM vw_canais_patrocinados v
    GROUP BY v.id_canal, v.canal, v.plataforma
    ORDER BY total_patrocinio DESC
    LIMIT p_k;
END;
$$;


-- =========================================================================
-- Função 6 — Top-k canais por aportes de membros
-- =========================================================================
-- Responde à consulta 6. Não existe view agregada por canal para aportes
-- de membros — vw_gastos_mensais_membros é agrupada por usuário, não por
-- canal — então esta função repete, de forma agregada, o join original
-- Inscricao + NivelCanal + Canal + Plataforma de 07_consultas.sql.
CREATE OR REPLACE FUNCTION fn_top_canais_membros(p_k INT)
RETURNS TABLE (
    id_canal      INT,
    canal         VARCHAR,
    plataforma    VARCHAR,
    total_membros NUMERIC
)
LANGUAGE plpgsql
SET search_path = streaming, pg_temp
AS $$
BEGIN
    IF p_k IS NULL OR p_k <= 0 THEN
        RAISE EXCEPTION 'p_k deve ser um inteiro positivo (valor informado: %)', p_k;
    END IF;

    RETURN QUERY
    SELECT
        c.id_canal,
        c.nome AS canal,
        p.nome AS plataforma,
        SUM(nc.valor) AS total_membros
    FROM Inscricao i
    JOIN NivelCanal nc ON nc.id_canal = i.id_canal AND nc.nivel = i.nivel
    JOIN Canal c        ON c.id_canal = i.id_canal
    JOIN Plataforma p   ON p.nro = c.nro_plataforma
    GROUP BY c.id_canal, c.nome, p.nome
    ORDER BY total_membros DESC
    LIMIT p_k;
END;
$$;


-- =========================================================================
-- Função 7 — Top-k canais por doações, considerando todos os vídeos
-- =========================================================================
-- Responde à consulta 7. vw_doacoes_por_canal já agrega por canal
-- considerando todos os vídeos do canal, então basta ordenar e aplicar
-- o LIMIT — sem necessidade de um novo GROUP BY aqui.
CREATE OR REPLACE FUNCTION fn_top_canais_doacoes(p_k INT)
RETURNS TABLE (
    id_canal      INT,
    canal         VARCHAR,
    plataforma    VARCHAR,
    total_doacoes NUMERIC
)
LANGUAGE plpgsql
SET search_path = streaming, pg_temp
AS $$
BEGIN
    IF p_k IS NULL OR p_k <= 0 THEN
        RAISE EXCEPTION 'p_k deve ser um inteiro positivo (valor informado: %)', p_k;
    END IF;

    RETURN QUERY
    SELECT
        v.id_canal,
        v.canal,
        v.plataforma,
        v.valor_total_doacoes_recebidas AS total_doacoes
    FROM vw_doacoes_por_canal v
    ORDER BY total_doacoes DESC
    LIMIT p_k;
END;
$$;


-- =========================================================================
-- Função 8 — Top-k canais por faturamento total (patrocínio + membros + doações)
-- =========================================================================
-- Responde à consulta 8, a mais pesada do banco. Constrói-se sobre a view
-- materializada mv_receita_total_canal (04_views.sql), que já soma as três
-- fontes de receita por canal — por isso a function só filtra, ordena e
-- aplica o LIMIT, sem refazer os joins pesados a cada chamada. Mantém-se
-- o filtro de faturamento > 0 do rascunho original (07_consultas.sql)
-- para não exibir canais sem nenhuma fonte de receita no ranking.
-- Observação: como é uma view MATERIALIZADA, os valores ficam
-- desatualizados até que se rode REFRESH MATERIALIZED VIEW
-- streaming.mv_receita_total_canal — atualização que deve ser disparada
-- pelos triggers de inserção em Patrocinio, Inscricao e Doacao (05_triggers.sql).
CREATE OR REPLACE FUNCTION fn_top_canais_faturamento(p_k INT)
RETURNS TABLE (
    id_canal         INT,
    canal            VARCHAR,
    plataforma       VARCHAR,
    total_patrocinio NUMERIC,
    total_membros    NUMERIC,
    total_doacoes    NUMERIC,
    total_receita    NUMERIC
)
LANGUAGE plpgsql
SET search_path = streaming, pg_temp
AS $$
BEGIN
    IF p_k IS NULL OR p_k <= 0 THEN
        RAISE EXCEPTION 'p_k deve ser um inteiro positivo (valor informado: %)', p_k;
    END IF;

    RETURN QUERY
    SELECT
        m.id_canal,
        m.canal,
        m.plataforma,
        m.total_patrocinio,
        m.total_membros,
        m.total_doacoes,
        m.total_receita
    FROM mv_receita_total_canal m
    WHERE m.total_receita > 0
    ORDER BY m.total_receita DESC
    LIMIT p_k;
END;
$$;


-- =========================================================================
-- Exemplos de chamada (não fazem parte da entrega — apenas referência)
-- =========================================================================
-- SELECT * FROM fn_canais_patrocinados();                -- todas as empresas
-- SELECT * FROM fn_canais_patrocinados(3);                -- só a empresa nro = 3
-- SELECT * FROM fn_gastos_mensais_membros();
-- SELECT * FROM fn_gastos_mensais_membros(42);
-- SELECT * FROM fn_doacoes_por_canal();
-- SELECT * FROM fn_doacoes_por_canal(10);
-- SELECT * FROM fn_doacoes_lidas_por_video();
-- SELECT * FROM fn_doacoes_lidas_por_video(100);
-- SELECT * FROM fn_top_canais_patrocinio(10);
-- SELECT * FROM fn_top_canais_membros(10);
-- SELECT * FROM fn_top_canais_doacoes(10);
-- SELECT * FROM fn_top_canais_faturamento(10);