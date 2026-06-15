-- views banco de dados de streaming de jogos
-- TCC00335 — UFF — Prof. Marcos Bedo — 2026/1

SET search_path TO streaming;

DROP MATERIALIZED VIEW IF EXISTS mv_receita_total_canal;
DROP VIEW IF EXISTS vw_doacoes_lidas_por_video;
DROP VIEW IF EXISTS vw_doacoes_por_canal;
DROP VIEW IF EXISTS vw_gastos_mensais_membros;
DROP VIEW IF EXISTS vw_canais_patrocinados;

CREATE VIEW vw_canais_patrocinados AS
SELECT
    e.nro AS nro_empresa,
    e.nome AS empresa,
    e.nome_fantasia,
    c.id_canal,
    c.nome AS canal,
    p.nome AS plataforma,
    c.nick_streamer,
    pa.valor AS valor_patrocinio
FROM Patrocinio pa
JOIN Empresa e
    ON e.nro = pa.nro_empresa
JOIN Canal c
    ON c.id_canal = pa.id_canal
JOIN Plataforma p
    ON p.nro = c.nro_plataforma;

CREATE VIEW vw_gastos_mensais_membros AS
SELECT
    i.nick_membro,
    COUNT(*) AS qtd_canais_membro,
    SUM(nc.valor) AS valor_total_mensal
FROM Inscricao i
JOIN NivelCanal nc
    ON nc.id_canal = i.id_canal
   AND nc.nivel = i.nivel
GROUP BY i.nick_membro;

CREATE VIEW vw_doacoes_por_canal AS
SELECT
    c.id_canal,
    c.nome AS canal,
    p.nome AS plataforma,
    c.nick_streamer,
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
    c.nick_streamer;

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
    c.nick_streamer,
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
