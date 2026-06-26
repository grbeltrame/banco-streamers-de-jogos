-- Chamadas de teste das consultas/funções
-- Banco de Dados de Streaming de Jogos
-- TCC00335 — UFF — Prof. Marcos Bedo — 2026/1

SET search_path TO streaming;

-- =========================================================================
-- TESTES VIA FUNCTIONS (SELECT * FROM fn_xxx)
-- =========================================================================

-- Consulta 1: todos os patrocínios
SELECT * FROM fn_canais_patrocinados();

-- Consulta 1: filtrado por empresa (Razer = nro 15)
SELECT * FROM fn_canais_patrocinados(15);

-- Consulta 2: todos os membros
SELECT * FROM fn_gastos_mensais_membros() LIMIT 10;

-- Consulta 2: filtrado por usuário (id = 1)
SELECT * FROM fn_gastos_mensais_membros(1);

-- Consulta 3: todos os canais com doações
SELECT * FROM fn_doacoes_por_canal() LIMIT 10;

-- Consulta 3: filtrado por canal (id = 22)
SELECT * FROM fn_doacoes_por_canal(22);

-- Consulta 4: todos os vídeos com doações lidas
SELECT * FROM fn_doacoes_lidas_por_video() LIMIT 10;

-- Consulta 4: filtrado por vídeo (id = 22)
SELECT * FROM fn_doacoes_lidas_por_video(22);

-- Consulta 5: top 10 canais por patrocínio
SELECT * FROM fn_top_canais_patrocinio(10);

-- Consulta 6: top 10 canais por membros
SELECT * FROM fn_top_canais_membros(10);

-- Consulta 7: top 10 canais por doações
SELECT * FROM fn_top_canais_doacoes(10);

-- Consulta 8: top 10 canais por faturamento total
SELECT * FROM fn_top_canais_faturamento(10);


-- =========================================================================
-- TESTES VIA PROCEDURES (CALL + FETCH)
-- =========================================================================

-- Procedure 1: todos os patrocínios
BEGIN;
CALL sp_canais_patrocinados();
FETCH ALL FROM cur_canais_patrocinados;
COMMIT;

-- Procedure 1: filtrado por empresa (Razer = nro 15)
BEGIN;
CALL sp_canais_patrocinados('cur', 15);
FETCH ALL FROM cur;
COMMIT;

-- Procedure 2: todos os membros
BEGIN;
CALL sp_gastos_mensais_membros();
FETCH 10 FROM cur_gastos_mensais;
COMMIT;

-- Procedure 3: todos os canais com doações
BEGIN;
CALL sp_doacoes_por_canal();
FETCH 10 FROM cur_doacoes_canal;
COMMIT;

-- Procedure 4: todos os vídeos com doações lidas
BEGIN;
CALL sp_doacoes_lidas_por_video();
FETCH 10 FROM cur_doacoes_video;
COMMIT;

-- Procedure 5: top 10 por patrocínio
BEGIN;
CALL sp_top_canais_patrocinio(10);
FETCH ALL FROM cur_top_patrocinio;
COMMIT;

-- Procedure 6: top 10 por membros
BEGIN;
CALL sp_top_canais_membros(10);
FETCH ALL FROM cur_top_membros;
COMMIT;

-- Procedure 7: top 10 por doações
BEGIN;
CALL sp_top_canais_doacoes(10);
FETCH ALL FROM cur_top_doacoes;
COMMIT;

-- Procedure 8: top 10 por faturamento total
BEGIN;
CALL sp_top_canais_faturamento(10);
FETCH ALL FROM cur_top_faturamento;
COMMIT;