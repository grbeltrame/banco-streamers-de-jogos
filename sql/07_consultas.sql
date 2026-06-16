-- Rascunho de consultas para teste
-- NÃO incluir na entrega final
SET search_path TO streaming;

-- Consulta 1: Canais patrocinados por empresa
SELECT
    e.nome          AS empresa,
    c.nome          AS canal,
    c.nro_plataforma,
    p.valor
FROM Patrocinio p
JOIN Empresa e ON e.nro = p.nro_empresa
JOIN Canal   c ON c.id_canal = p.id_canal
ORDER BY e.nome, p.valor DESC;

-- Consulta 2: Quantidade de canais que cada usuário é membro e soma mensal
SELECT
    u.nick,
    COUNT(i.id_canal)   AS qtd_canais,
    SUM(nc.valor)       AS total_mensal
FROM Inscricao i
JOIN Usuario    u  ON u.id_usuario = i.id_membro
JOIN NivelCanal nc ON nc.id_canal  = i.id_canal
                   AND nc.nivel    = i.nivel
GROUP BY u.id_usuario, u.nick
ORDER BY total_mensal DESC;

-- Consulta 3: Canais que receberam doações e soma dos valores (excluindo recusadas)
SELECT
    c.nome          AS canal,
    c.nro_plataforma,
    SUM(d.valor)    AS total_doacoes
FROM Doacao d
JOIN Comentario co ON co.id_comentario = d.id_comentario
JOIN Video      v  ON v.id_video       = co.id_video
JOIN Canal      c  ON c.id_canal       = v.id_canal
WHERE d.status IN ('recebido', 'lido')
GROUP BY c.id_canal, c.nome, c.nro_plataforma
ORDER BY total_doacoes DESC;

-- Consulta 4: Soma das doações de comentários lidos, por vídeo
SELECT
    v.id_video,
    v.titulo,
    SUM(d.valor)    AS total_lido
FROM Doacao d
JOIN Comentario co ON co.id_comentario = d.id_comentario
JOIN Video      v  ON v.id_video       = co.id_video
WHERE d.status = 'lido'
GROUP BY v.id_video, v.titulo
ORDER BY total_lido DESC;

-- Consulta 5: Top-k canais por valor de patrocínio
SELECT
    c.nome          AS canal,
    c.nro_plataforma,
    SUM(p.valor)    AS total_patrocinio
FROM Patrocinio p
JOIN Canal c ON c.id_canal = p.id_canal
GROUP BY c.id_canal, c.nome, c.nro_plataforma
ORDER BY total_patrocinio DESC
LIMIT 10;

-- Consulta 6: Top-k canais por aportes de membros
SELECT
    c.nome          AS canal,
    c.nro_plataforma,
    SUM(nc.valor)   AS total_membros
FROM Inscricao i
JOIN Canal      c  ON c.id_canal  = i.id_canal
JOIN NivelCanal nc ON nc.id_canal = i.id_canal
                   AND nc.nivel   = i.nivel
GROUP BY c.id_canal, c.nome, c.nro_plataforma
ORDER BY total_membros DESC
LIMIT 10;

-- Consulta 7: Top-k canais por soma de doações (excluindo recusadas)
SELECT
    c.nome          AS canal,
    c.nro_plataforma,
    SUM(d.valor)    AS total_doacoes
FROM Doacao d
JOIN Comentario co ON co.id_comentario = d.id_comentario
JOIN Video      v  ON v.id_video       = co.id_video
JOIN Canal      c  ON c.id_canal       = v.id_canal
WHERE d.status IN ('recebido', 'lido')
GROUP BY c.id_canal, c.nome, c.nro_plataforma
ORDER BY total_doacoes DESC
LIMIT 10;

-- Consulta 8: Top-k canais por faturamento total (patrocínio + membros + doações)
SELECT
    c.nome              AS canal,
    c.nro_plataforma,
    COALESCE(pat.total, 0) +
    COALESCE(mem.total, 0) +
    COALESCE(don.total, 0) AS faturamento_total
FROM Canal c
LEFT JOIN (
    SELECT id_canal, SUM(valor) AS total
    FROM Patrocinio
    GROUP BY id_canal
) pat ON pat.id_canal = c.id_canal
LEFT JOIN (
    SELECT i.id_canal, SUM(nc.valor) AS total
    FROM Inscricao i
    JOIN NivelCanal nc ON nc.id_canal = i.id_canal
                      AND nc.nivel    = i.nivel
    GROUP BY i.id_canal
) mem ON mem.id_canal = c.id_canal
LEFT JOIN (
    SELECT v.id_canal, SUM(d.valor) AS total
    FROM Doacao d
    JOIN Comentario co ON co.id_comentario = d.id_comentario
    JOIN Video      v  ON v.id_video       = co.id_video
    WHERE d.status IN ('recebido', 'lido')
    GROUP BY v.id_canal
) don ON don.id_canal = c.id_canal
WHERE COALESCE(pat.total, 0) +
      COALESCE(mem.total, 0) +
      COALESCE(don.total, 0) > 0
ORDER BY faturamento_total DESC
LIMIT 10;