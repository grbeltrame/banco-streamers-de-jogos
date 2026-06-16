-- Índices de apoio
-- TCC00335 — UFF — Prof. Marcos Bedo — 2026/1
-- Execute APÓS 02_dados.sql

SET search_path TO streaming;

-- Atualiza as estatísticas do banco antes de criar os índices
-- para garantir que o planner tenha informações corretas
ANALYZE;

-- =========================
-- Índice 1: comentario(id_video)
-- =========================
-- A tabela Comentario tem 1000 linhas e é acessada via Seq Scan nas
-- consultas 3, 4, 7 e 8 — as quatro consultas que envolvem doações.
-- Em todas elas o join é feito por co.id_video, buscando os comentários
-- de um vídeo específico dentro das 1000 linhas. Um índice nessa coluna
-- permite ao planner ir direto nos comentários do vídeo em questão,
-- em vez de varrer a tabela inteira a cada execução.
-- Overhead de inserção: moderado — cada INSERT em Comentario atualiza
-- este índice, mas comentários são inseridos com menos frequência do
-- que são lidos nas consultas analíticas.
CREATE INDEX idx_comentario_id_video
    ON Comentario(id_video);

-- =========================
-- Índice 2: doacao(id_comentario)
-- =========================
-- A tabela Doacao tem 500 linhas e é acessada via Seq Scan nas
-- consultas 3, 4, 7 e 8. O join com Comentario é feito por
-- d.id_comentario, e sem índice o planner constrói uma hash table
-- em memória a cada execução. Com o índice, o acesso é direto.
-- Overhead de inserção: baixo — doações são inseridas pontualmente
-- e a tabela tem apenas 500 linhas.
CREATE INDEX idx_doacao_id_comentario
    ON Doacao(id_comentario);

-- =========================
-- Índice 3: doacao(status)
-- =========================
-- Utilizado exclusivamente pela consulta 4, que filtra
-- WHERE status = 'lido'. O EXPLAIN ANALYZE mostrou
-- "Rows Removed by Filter: 300", ou seja, 60% das linhas
-- são descartadas após serem lidas. O índice evita essa
-- leitura desnecessária, indo direto nas 200 linhas com status 'lido'.
-- Overhead de inserção: baixo — o campo status tem apenas 3 valores
-- possíveis (recusado, recebido, lido), e o índice é pequeno.
CREATE INDEX idx_doacao_status
    ON Doacao(status);

-- =========================
-- Índice 4: inscricao(id_membro)
-- =========================
-- A tabela Inscricao tem 1000 linhas e é acessada via Seq Scan
-- nas consultas 2, 6 e 8. O join com Usuario é feito por
-- i.id_membro — buscando as inscrições de um membro específico
-- dentro das 1000 linhas. Um índice aqui permite localizar
-- diretamente as poucas inscrições de cada membro.
-- Overhead de inserção: moderado — inscrições são adicionadas
-- quando um usuário assina um canal, operação menos frequente
-- que as consultas analíticas.
CREATE INDEX idx_inscricao_id_membro
    ON Inscricao(id_membro);

-- =========================
-- Índice 5: nivelcanal(id_canal, nivel)
-- =========================
-- A tabela NivelCanal tem 605 linhas e é acessada via Seq Scan
-- nas consultas 2, 6 e 8. O join é sempre feito pelos dois campos
-- em conjunto: nc.id_canal = i.id_canal AND nc.nivel = i.nivel.
-- Um índice composto por ambas as colunas permite resolver esse
-- join com acesso direto, sem varrer os 605 registros.
-- Overhead de inserção: baixo — NivelCanal é uma tabela
-- relativamente estática; níveis de canal raramente mudam
-- após a criação do canal.
CREATE INDEX idx_nivelcanal_id_canal_nivel
    ON NivelCanal(id_canal, nivel);