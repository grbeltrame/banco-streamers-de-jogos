-- População do banco de dados de streaming de jogos
-- TCC00335 — UFF — Prof. Marcos Bedo — 2026/1
-- Execute APÓS 01_schema.sql

SET search_path TO streaming;

-- =========================
-- Empresa
-- =========================

INSERT INTO Empresa (nome, nome_fantasia) VALUES
('Google LLC',                'Google'),
('Amazon.com Inc.',           'Amazon'),
('Meta Platforms Inc.',       'Meta'),
('Microsoft Corporation',     'Microsoft'),
('Sony Group Corporation',    'Sony'),
('Twitch Interactive Inc.',   'Twitch'),
('YouTube LLC',               'YouTube'),
('Discord Inc.',              'Discord'),
('Riot Games Inc.',           'Riot Games'),
('Electronic Arts Inc.',      'EA'),
('Activision Blizzard Inc.',  'Blizzard'),
('Ubisoft Entertainment SA',  'Ubisoft'),
('Epic Games Inc.',           'Epic Games'),
('Nintendo Co. Ltd.',         'Nintendo'),
('Razer Inc.',                'Razer'),
('Logitech International SA', 'Logitech'),
('SteelSeries ApS',           'SteelSeries'),
('Corsair Gaming Inc.',       'Corsair'),
('Valve Corporation',         'Valve'),
('Nuuvem Ltda.',              'Nuuvem'),
('Rockstar Games',            'RockStar');

-- =========================
-- Conversao
-- =========================

INSERT INTO Conversao (moeda, nome, fator_conver) VALUES
('USD', 'Dólar Americano',   1.00000000),
('BRL', 'Real Brasileiro',   0.19000000),
('EUR', 'Euro',              1.08000000),
('GBP', 'Libra Esterlina',   1.27000000),
('JPY', 'Iene Japonês',      0.00670000),
('KRW', 'Won Sul-coreano',   0.00075000),
('CAD', 'Dólar Canadense',   0.73000000),
('AUD', 'Dólar Australiano', 0.65000000),
('MXN', 'Peso Mexicano',     0.05800000),
('SEK', 'Coroa Sueca',       0.09500000);

-- =========================
-- Pais
-- =========================
-- Optou-se por nao colocar o Canada incialmente por possuir o mesmo DDI, mas DDI é chave primaria

INSERT INTO Pais (ddi, nome, moeda) VALUES
(1,   'Estados Unidos', 'USD'),
(55,  'Brasil',         'BRL'),
(44,  'Reino Unido',    'GBP'),
(49,  'Alemanha',       'EUR'),
(33,  'França',         'EUR'),
(81,  'Japão',          'JPY'),
(82,  'Coreia do Sul',  'KRW'),
(61,  'Austrália',      'AUD'),
(52,  'México',         'MXN'),
(46,  'Suécia',         'SEK'),
(34,  'Espanha',        'EUR'),
(39,  'Itália',         'EUR'),
(7,   'Rússia',         'EUR'),
(86,  'China',          'USD'),
(351, 'Portugal',       'EUR');

-- =========================
-- EmpresaPais
-- =========================

INSERT INTO EmpresaPais (nro_empresa, ddi_pais, id_nacional) VALUES
(1,  1,   'US-GOOGLE-001'),
(2,  1,   'US-AMAZON-001'),
(3,  1,   'US-META-001'),
(4,  1,   'US-MSFT-001'),
(5,  81,  'JP-SONY-001'),
(6,  1,   'US-TWITCH-001'),
(7,  1,   'US-YOUTUBE-001'),
(8,  1,   'US-DISCORD-001'),
(9,  1,   'US-RIOT-001'),
(10, 1,   'US-EA-001'),
(11, 1,   'US-ACTBLIZ-001'),
(12, 33,  'FR-UBISOFT-001'),
(13, 1,   'US-EPIC-001'),
(14, 81,  'JP-NINTENDO-001'),
(15, 1,   'US-RAZER-001'),
(16, 46,  'SE-LOGITECH-001'),
(17, 46,  'SE-STEELSERIES-001'),
(18, 1,   'US-CORSAIR-001'),
(19, 1,   'US-VALVE-001'),
(20, 55,  'BR-NUUVEM-001'),
(21, 1,   'US-ROCKSTAR-001');

-- =========================
-- Plataforma
-- =========================

INSERT INTO Plataforma (nome, qtd_users, empresa_fund, empresa_respo, data_fund) VALUES
('Twitch',         140000000, 6,  2,  '2011-06-06'),
('YouTube Gaming',  50000000, 7,  1,  '2015-08-26'),
('Facebook Gaming', 38000000, 3,  3,  '2018-06-01'),
('Kick',            10000000, 19, 19, '2022-12-01'),
('TikTok Live',     30000000, 3,  3,  '2019-01-01');

-- =========================
-- Usuario
-- =========================

-- 30 streamers brasileiros e internacionais famosos
INSERT INTO Usuario (nick, email, data_nasc, telefone, end_postal, pais_residencia) VALUES
('gaules',        'gaules@email.com',        '1983-03-16', '+5551999990001', 'Porto Alegre, RS',      55),
('alanzoka',      'alanzoka@email.com',       '1996-05-20', '+5511999990002', 'São Paulo, SP',         55),
('cellbit',       'cellbit@email.com',        '1996-09-08', '+5541999990003', 'Curitiba, PR',          55),
('felps',         'felps@email.com',          '1996-12-07', '+5511999990004', 'São Paulo, SP',         55),
('loud_coringa',  'loud_coringa@email.com',   '2000-01-15', '+5511999990005', 'São Paulo, SP',         55),
('brtt',          'brtt@email.com',           '1995-03-22', '+5511999990006', 'São Paulo, SP',         55),
('baiano_gamer',  'baiano_gamer@email.com',   '1994-07-10', '+5571999990007', 'Salvador, BA',          55),
('jukes',         'jukes@email.com',          '1996-02-14', '+5511999990008', 'São Paulo, SP',         55),
('nobru',         'nobru@email.com',          '1999-11-03', '+5511999990009', 'São Paulo, SP',         55),
('coreano',       'coreano@email.com',        '1997-08-25', '+5521999990010', 'Rio de Janeiro, RJ',    55),
('shroud',        'shroud@email.com',         '1994-06-02', '+1604999990011', 'Vancouver, BC',          1),
('ninja',         'ninja@email.com',          '1991-06-05', '+1920999990012', 'Chicago, IL',            1),
('pokimane',      'pokimane@email.com',       '1996-05-14', '+1604999990013', 'Vancouver, BC',          1),
('tfue',          'tfue@email.com',           '1998-01-02', '+1772999990014', 'Florida, FL',            1),
('valkyrae',      'valkyrae@email.com',       '1999-01-08', '+1702999990015', 'Las Vegas, NV',          1),
('hasanabi',      'hasanabi@email.com',       '1991-07-23', '+1212999990016', 'New York, NY',           1),
('asmongold',     'asmongold@email.com',      '1990-04-20', '+1512999990017', 'Austin, TX',             1),
('moistcr1tikal', 'moistcr1tikal@email.com',  '1994-08-02', '+1813999990018', 'Tampa, FL',              1),
('sodapoppin',    'sodapoppin@email.com',     '1994-02-15', '+1512999990019', 'Austin, TX',             1),
('summit1g',      'summit1g@email.com',       '1987-04-23', '+1619999990020', 'San Diego, CA',          1),
('timthetatman',  'timthetatman@email.com',   '1990-04-08', '+1716999990021', 'Buffalo, NY',            1),
('lirik',         'lirik@email.com',          '1988-12-31', '+1858999990022', 'San Diego, CA',          1),
('xqc',           'xqc@email.com',            '1995-11-12', '+1418999990023', 'Quebec, QC',             1),
('jankos',        'jankos@email.com',         '1997-03-07', '+4930999990024', 'Berlin',                49),
('caps',          'caps@email.com',           '1999-11-02', '+4530999990025', 'Copenhagen',            49),
('rekkles',       'rekkles@email.com',        '1996-09-22', '+4630999990026', 'Gothenburg',            46),
('faker',         'faker@email.com',          '1996-05-07', '+8210999990027', 'Seoul',                 82),
('uzi',           'uzi@email.com',            '1999-03-03', '+8610999990028', 'Shanghai',              86),
('s1mple',        's1mple@email.com',         '1999-10-02', '+7044999990029', 'Kiev',                   7),
('niko',          'niko@email.com',           '1997-02-16', '+3811999990030', 'Sarajevo',              49);

-- 70 streamers gerados
INSERT INTO Usuario (nick, email, data_nasc, telefone, end_postal, pais_residencia)
SELECT
    'streamer_' || i,
    'streamer_' || i || '@email.com',
    ('1990-01-01'::DATE + (i * 53 || ' days')::INTERVAL)::DATE,
    '+' || (10000000000 + i * 13)::TEXT,
    'Rua Streamer ' || i,
    CASE (i % 5)
        WHEN 0 THEN 1
        WHEN 1 THEN 55
        WHEN 2 THEN 49
        WHEN 3 THEN 82
        ELSE        46
    END
FROM generate_series(1, 70) AS i;

-- 900 usuarios comuns
INSERT INTO Usuario (nick, email, data_nasc, telefone, end_postal, pais_residencia)
SELECT
    'user_' || i,
    'user_' || i || '@email.com',
    ('1985-01-01'::DATE + (i * 47 || ' days')::INTERVAL)::DATE,
    '+' || (20000000000 + i * 7)::TEXT,
    'Rua Usuario ' || i,
    CASE (i % 10)
        WHEN 0 THEN 1
        WHEN 1 THEN 55
        WHEN 2 THEN 44
        WHEN 3 THEN 49
        WHEN 4 THEN 33
        WHEN 5 THEN 81
        WHEN 6 THEN 82
        WHEN 7 THEN 61
        WHEN 8 THEN 52
        ELSE        46
    END
FROM generate_series(1, 900) AS i;

-- =========================
-- StreamerPais
-- =========================

-- streamers famosos
INSERT INTO StreamerPais (nick_streamer, ddi_pais, nro_passaporte) VALUES
('gaules',        55, 'BR-PASS-0001'),
('alanzoka',      55, 'BR-PASS-0002'),
('cellbit',       55, 'BR-PASS-0003'),
('felps',         55, 'BR-PASS-0004'),
('loud_coringa',  55, 'BR-PASS-0005'),
('brtt',          55, 'BR-PASS-0006'),
('baiano_gamer',  55, 'BR-PASS-0007'),
('jukes',         55, 'BR-PASS-0008'),
('nobru',         55, 'BR-PASS-0009'),
('coreano',       55, 'BR-PASS-0010'),
('shroud',         1, 'US-PASS-0001'),
('ninja',          1, 'US-PASS-0002'),
('pokimane',       1, 'US-PASS-0003'),
('tfue',           1, 'US-PASS-0004'),
('valkyrae',       1, 'US-PASS-0005'),
('hasanabi',       1, 'US-PASS-0006'),
('asmongold',      1, 'US-PASS-0007'),
('moistcr1tikal',  1, 'US-PASS-0008'),
('sodapoppin',     1, 'US-PASS-0009'),
('summit1g',       1, 'US-PASS-0010'),
('timthetatman',   1, 'US-PASS-0011'),
('lirik',          1, 'US-PASS-0012'),
('xqc',            1, 'US-PASS-0013'),
('jankos',        49, 'DE-PASS-0001'),
('caps',          49, 'DE-PASS-0002'),
('rekkles',       46, 'SE-PASS-0001'),
('faker',         82, 'KR-PASS-0001'),
('uzi',           86, 'CN-PASS-0001'),
('s1mple',         7, 'RU-PASS-0001'),
('niko',          49, 'DE-PASS-0003');

-- streamers gerados
INSERT INTO StreamerPais (nick_streamer, ddi_pais, nro_passaporte)
SELECT
    'streamer_' || i,
    CASE (i % 5)
        WHEN 0 THEN 1
        WHEN 1 THEN 55
        WHEN 2 THEN 49
        WHEN 3 THEN 82
        ELSE        46
    END,
    'PASS-GEN-' || LPAD(i::TEXT, 4, '0')
FROM generate_series(1, 70) AS i;

-- =========================
-- PlataformaUsuario
-- =========================

INSERT INTO PlataformaUsuario (nro_plataforma, nick_usuario, nro_usuario) VALUES
-- Brasileiros: Twitch (1) + YouTube (2)
(1, 'gaules',        'twitch_gaules'),
(2, 'gaules',        'yt_gaules'),
(4, 'gaules',       'kick_gaules'),
(1, 'alanzoka',      'twitch_alanzoka'),
(2, 'alanzoka',      'yt_alanzoka'),
(1, 'cellbit',       'twitch_cellbit'),
(2, 'cellbit',       'yt_cellbit'),
(1, 'felps',         'twitch_felps'),
(2, 'felps',         'yt_felps'),
(1, 'loud_coringa',  'twitch_coringa'),
(2, 'loud_coringa',  'yt_coringa'),
(1, 'brtt',          'twitch_brtt'),
(2, 'brtt',          'yt_brtt'),
(1, 'baiano_gamer',  'twitch_baiano'),
(2, 'baiano_gamer',  'yt_baiano'),
(4, 'baiano_gamer',  'kick_baiano'),
(1, 'jukes',         'twitch_jukes'),
(2, 'jukes',         'yt_jukes'),
(1, 'nobru',         'twitch_nobru'),
(2, 'nobru',         'yt_nobru'),
(1, 'coreano',       'twitch_coreano'),
(2, 'coreano',       'yt_coreano'),
(1, 'xqc',           'twitch_xqc'),
(4, 'xqc',           'kick_xqc'),
(1, 'tfue',          'twitch_tfue'),
(4, 'tfue',          'kick_tfue'),
(1, 'shroud',        'twitch_shroud'),
(2, 'shroud',        'yt_shroud'),
(1, 'ninja',         'twitch_ninja'),
(2, 'ninja',         'yt_ninja'),
(1, 'pokimane',      'twitch_pokimane'),
(2, 'pokimane',      'yt_pokimane'),
(1, 'hasanabi',      'twitch_hasanabi'),
(4, 'hasanabi',      'kick_hasanabi'),
(1, 'asmongold',     'twitch_asmongold'),
(2, 'asmongold',     'yt_asmongold'),
(1, 'moistcr1tikal', 'twitch_moist'),
(2, 'moistcr1tikal', 'yt_moist'),
(1, 'sodapoppin',    'twitch_soda'),
(4, 'sodapoppin',    'kick_soda'),
(1, 'summit1g',      'twitch_summit'),
(4, 'summit1g',      'kick_summit'),
(1, 'timthetatman',  'twitch_tatman'),
(2, 'timthetatman',  'yt_tatman'),
(1, 'lirik',         'twitch_lirik'),
(2, 'valkyrae',      'yt_valkyrae'),
(1, 'valkyrae',      'twitch_valkyrae'),
(1, 'jankos',        'twitch_jankos'),
(2, 'jankos',        'yt_jankos'),
(1, 'caps',          'twitch_caps'),
(2, 'caps',          'yt_caps'),
(1, 'rekkles',       'twitch_rekkles'),
(2, 'rekkles',       'yt_rekkles'),
(1, 'faker',         'twitch_faker'),
(2, 'faker',         'yt_faker'),
(1, 'uzi',           'twitch_uzi'),
(2, 'uzi',           'yt_uzi'),
(1, 's1mple',        'twitch_s1mple'),
(2, 's1mple',        'yt_s1mple'),
(1, 'niko',          'twitch_niko'),
(2, 'niko',          'yt_niko');

-- streamers gerados — cada um em 1 plataforma
INSERT INTO PlataformaUsuario (nro_plataforma, nick_usuario, nro_usuario)
SELECT
    (i % 5) + 1,
    'streamer_' || i,
    'uid_str_' || i
FROM generate_series(1, 70) AS i;

-- usuarios comuns — cada um em 1 plataforma
INSERT INTO PlataformaUsuario (nro_plataforma, nick_usuario, nro_usuario)
SELECT
    (i % 5) + 1,
    'user_' || i,
    'uid_user_' || i
FROM generate_series(1, 900) AS i;

-- =========================
-- Canal
-- =========================

INSERT INTO Canal (nome, nro_plataforma, tipo, data_inicio, descricao, nick_streamer) VALUES
-- Brasileiros
('gaules',         1, 'publico', '2015-07-10', 'CS e FPS competitivo',          'gaules'),
('gaules',         2, 'publico', '2016-01-01', 'Highlights e torneios',         'gaules'),
('gaules',         4, 'publico', '2023-05-01', 'Canal do Gaules na Kick',       'gaules'),
('alanzoka',       1, 'publico', '2018-09-01', 'RPGs e narrativa',              'alanzoka'),
('alanzoka',       2, 'publico', '2019-03-01', 'VODs e highlights',             'alanzoka'),
('cellbit',        1, 'publico', '2019-03-22', 'Terror e horror games',         'cellbit'),
('cellbit',        2, 'publico', '2021-02-10', 'Conteúdo extra do Cellbit',     'cellbit'),
('felps',          1, 'publico', '2017-08-08', 'Variety gaming',                'felps'),
('felps',          2, 'publico', '2020-11-01', 'Melhores momentos',             'felps'),
('loud_coringa',   1, 'publico', '2020-01-10', 'Canal oficial LOUD Coringa',    'loud_coringa'),
('loud_coringa',   2, 'publico', '2021-06-01', 'Highlights da LOUD',            'loud_coringa'),
('brtt',           1, 'publico', '2018-04-01', 'League of Legends',             'brtt'),
('brtt',           2, 'publico', '2019-08-01', 'Clips e highlights',            'brtt'),
('baiano_gamer',   1, 'publico', '2021-04-01', 'Clash Royale e mobile',         'baiano_gamer'),
('baiano_gamer',   2, 'publico', '2022-01-01', 'VODs do Baiano',                'baiano_gamer'),
('baiano_gamer',   4, 'publico', '2023-06-01', 'BaianoTV na Kick',              'baiano_gamer'),
('jukes',          1, 'publico', '2019-01-01', 'League of Legends',             'jukes'),
('nobru',          1, 'publico', '2020-03-01', 'Free Fire e mobile',            'nobru'),
('coreano',        1, 'publico', '2018-11-01', 'Variety e jogos',               'coreano'),
-- Internacionais
('xqc',            1, 'publico', '2016-03-01', 'Variety e reacts',              'xqc'),
('xqc',            4, 'publico', '2023-02-01', 'Canal do xQc na Kick',          'xqc'),
('shroud',         1, 'publico', '2014-02-20', 'FPS profissional',              'shroud'),
('shroud',         2, 'publico', '2018-01-01', 'Highlights do Shroud',          'shroud'),
('ninja',          1, 'publico', '2011-11-01', 'Fortnite e highlights',         'ninja'),
('ninja',          2, 'publico', '2018-03-01', 'Canal do Ninja no YouTube',     'ninja'),
('pokimane',       1, 'publico', '2017-05-15', 'Variety e reacts',              'pokimane'),
('pokimane',       2, 'misto',   '2018-06-01', 'VODs e highlights',             'pokimane'),
('tfue',           1, 'publico', '2018-04-05', 'Fortnite competitivo',          'tfue'),
('tfue',           4, 'publico', '2023-03-01', 'Canal do Tfue na Kick',         'tfue'),
('valkyrae',       1, 'publico', '2019-01-20', 'Variety e Among Us',            'valkyrae'),
('valkyrae',       2, 'publico', '2020-05-01', 'Highlights da Valkyrae',        'valkyrae'),
('hasanabi',       1, 'publico', '2018-05-12', 'Política e jogos',              'hasanabi'),
('hasanabi',       4, 'publico', '2023-04-01', 'Canal do Hasan na Kick',        'hasanabi'),
('asmongold',      1, 'publico', '2014-09-09', 'World of Warcraft e MMOs',      'asmongold'),
('asmongold',      2, 'publico', '2019-01-01', 'Highlights do Asmongold',       'asmongold'),
('moistcr1tikal',  1, 'publico', '2019-07-07', 'Reacts e comentários',          'moistcr1tikal'),
('moistcr1tikal',  2, 'publico', '2020-01-01', 'Canal principal do Moist',      'moistcr1tikal'),
('sodapoppin',     1, 'publico', '2012-03-15', 'Variety stream',                'sodapoppin'),
('summit1g',       1, 'publico', '2012-06-01', 'FPS e variety',                 'summit1g'),
('summit1g',       4, 'publico', '2023-03-01', 'Canal do Summit na Kick',       'summit1g'),
('timthetatman',   1, 'publico', '2012-09-01', 'Gameplay com amigos',           'timthetatman'),
('timthetatman',   2, 'publico', '2019-06-01', 'Highlights do Tatman',          'timthetatman'),
('lirik',          1, 'publico', '2013-01-01', 'FPS e variety',                 'lirik'),
('jankos',         1, 'publico', '2016-11-15', 'League of Legends pro',         'jankos'),
('caps',           1, 'publico', '2018-03-01', 'League of Legends pro',         'caps'),
('rekkles',        1, 'publico', '2016-05-01', 'League of Legends pro',         'rekkles'),
('faker',          1, 'publico', '2015-09-01', 'League of Legends pro',         'faker'),
('faker',          2, 'publico', '2018-01-01', 'Canal do Faker no YouTube',     'faker'),
('uzi',            1, 'publico', '2016-01-01', 'League of Legends pro',         'uzi'),
('s1mple',         1, 'publico', '2016-08-01', 'CS profissional',               's1mple'),
('niko',           1, 'publico', '2017-04-01', 'CS profissional',               'niko');

-- canais dos streamers gerados
INSERT INTO Canal (nome, nro_plataforma, tipo, data_inicio, descricao, nick_streamer)
SELECT
    'streamer_' || i,
    (i % 5) + 1,
    'publico',
    ('2018-01-01'::DATE + (i * 30 || ' days')::INTERVAL)::DATE,
    'Canal do streamer ' || i,
    'streamer_' || i
FROM generate_series(1, 70) AS i;

-- =========================
-- Patrocinio
-- =========================

INSERT INTO Patrocinio (nro_empresa, nome_canal, nro_plataforma, valor) VALUES
-- Periféricos patrocinando canais famosos
(15, 'gaules',        1, 45000.00),  -- Razer patrocina Gaules
(16, 'gaules',        2, 20000.00),  -- Logitech patrocina Gaules no YouTube
(15, 'shroud',        1, 60000.00),  -- Razer patrocina Shroud
(16, 'ninja',         1, 80000.00),  -- Logitech patrocina Ninja
(15, 'tfue',          1, 35000.00),  -- Razer patrocina Tfue
(16, 'summit1g',      1, 30000.00),  -- Logitech patrocina Summit
(17, 'jankos',        1, 25000.00),  -- SteelSeries patrocina Jankos
(18, 'valkyrae',      2, 40000.00),  -- Corsair patrocina Valkyrae
(17, 'faker',         1, 55000.00),  -- SteelSeries patrocina Faker
(15, 'xqc',           1, 70000.00),  -- Razer patrocina xQc
(16, 'asmongold',     1, 20000.00),  -- Logitech patrocina Asmongold
(18, 'cellbit',       1, 33000.00),  -- Corsair patrocina Cellbit
(13, 'alanzoka',      1, 18000.00),  -- Ubisoft patrocina Alanzoka
(14, 'loud_coringa',  1, 55000.00),  -- Epic Games patrocina Coringa
(14, 'ninja',         2, 65000.00),  -- Epic Games patrocina Ninja no YouTube
(10, 'felps',         1, 15000.00),  -- EA patrocina Felps
(9,  'brtt',          1, 22000.00),  -- Riot patrocina brTT
(9,  'caps',          1, 28000.00),  -- Riot patrocina Caps
(9,  'rekkles',       1, 25000.00),  -- Riot patrocina Rekkles
(4,  'hasanabi',      1, 12000.00);  -- Microsoft patrocina Hasanabi

-- =========================
-- NivelCanal
-- =========================

INSERT INTO NivelCanal (nome_canal, nro_plataforma, nivel, valor, gif)
SELECT
    c.nome,
    c.nro_plataforma,
    n.nivel,
    CASE n.nivel
        WHEN 1 THEN  4.99
        WHEN 2 THEN  9.99
        WHEN 3 THEN 19.99
        WHEN 4 THEN 49.99
        WHEN 5 THEN 99.99
    END,
    'https://cdn.streaming.io/gifs/' || c.nome || '_nivel' || n.nivel || '.gif'
FROM Canal c
CROSS JOIN (SELECT generate_series(1, 5) AS nivel) n;

-- =========================
-- Inscricao
-- =========================

INSERT INTO Inscricao (nome_canal, nro_plataforma, nick_membro, nivel)
SELECT DISTINCT
    c.nome,
    c.nro_plataforma,
    'user_' || i,
    ((ABS(HASHTEXT('user_' || i || c.nome)) % 5) + 1)::SMALLINT
FROM Canal c
CROSS JOIN generate_series(1, 900) AS i
WHERE (ABS(HASHTEXT('user_' || i || c.nome)) % 10) = 0
LIMIT 1000;

-- =========================
-- Video
-- =========================

INSERT INTO Video (nome_canal, nro_plataforma, titulo, dataH, tema, duracao, visu_simul, visu_total)
SELECT
    c.nome,
    c.nro_plataforma,
    CASE (i % 10)
        WHEN 0 THEN 'Ranked ao vivo #' || i || ' — ' || c.nome
        WHEN 1 THEN 'Torneio especial #' || i || ' — ' || c.nome
        WHEN 2 THEN 'Gameplay com inscritos #' || i || ' — ' || c.nome
        WHEN 3 THEN 'Reagindo a clips #' || i || ' — ' || c.nome
        WHEN 4 THEN 'Live de madrugada #' || i || ' — ' || c.nome
        WHEN 5 THEN 'Especial de fim de semana #' || i || ' — ' || c.nome
        WHEN 6 THEN 'Desafio com a comunidade #' || i || ' — ' || c.nome
        WHEN 7 THEN 'Review do patch #' || i || ' — ' || c.nome
        WHEN 8 THEN 'Highlights da semana #' || i || ' — ' || c.nome
        ELSE        'Surpresa ao vivo #' || i || ' — ' || c.nome
    END,
    (c.data_inicio + (i * 7 || ' days')::INTERVAL + (i % 24 || ' hours')::INTERVAL),
    CASE (i % 6)
        WHEN 0 THEN 'FPS'
        WHEN 1 THEN 'RPG'
        WHEN 2 THEN 'MOBA'
        WHEN 3 THEN 'Battle Royale'
        WHEN 4 THEN 'Variety'
        ELSE        'IRL'
    END,
    ((30 + (i % 150)) || ' minutes')::INTERVAL,
    (1000  + (i * 137) % 50000),
    (10000 + (i * 997) % 5000000)
FROM Canal c
CROSS JOIN generate_series(1, 10) AS i;

-- =========================
-- Participa
-- =========================

INSERT INTO Participa (id_video, nick_streamer)
SELECT DISTINCT
    v.id_video,
    s.nick_streamer
FROM Video v
JOIN StreamerPais s ON s.nick_streamer <> (
    SELECT nick_streamer FROM Canal
    WHERE nome = v.nome_canal AND nro_plataforma = v.nro_plataforma
)
WHERE v.id_video % 7 = 0
LIMIT 200;

-- =========================
-- Comentario
-- =========================

INSERT INTO Comentario (id_video, nick_usuario, seq, texto, dataH, coment_on)
SELECT
    v.id_video,
    u.nick,
    ROW_NUMBER() OVER (PARTITION BY v.id_video ORDER BY u.nick) AS seq,
    CASE (v.id_video % 8)
        WHEN 0 THEN 'Que stream incrível, mano!'
        WHEN 1 THEN 'GG, foi muito bom!'
        WHEN 2 THEN 'Hahaha não acredito nessa jogada'
        WHEN 3 THEN 'Já inscrevi no canal!'
        WHEN 4 THEN 'Manda mais conteúdo!'
        WHEN 5 THEN 'Esse cara é muito bom mesmo'
        WHEN 6 THEN 'Primeira vez assistindo, adorei!'
        ELSE        'Clipa isso aí!'
    END,
    v.dataH + (ROW_NUMBER() OVER (PARTITION BY v.id_video ORDER BY u.nick) || ' minutes')::INTERVAL,
    (v.id_video % 3 <> 0)
FROM Video v
CROSS JOIN (SELECT nick FROM Usuario WHERE nick LIKE 'user_%' LIMIT 10) u
LIMIT 1000;

-- =========================
-- Doacao
-- =========================

INSERT INTO Doacao (id_video, nick_usuario, seq_comentario, seq_pg, valor, status)
SELECT
    c.id_video,
    c.nick_usuario,
    c.seq,
    1,
    ROUND((5.00 + (ABS(HASHTEXT(c.nick_usuario || c.id_video::TEXT)) % 200))::NUMERIC, 2),
    CASE (ABS(HASHTEXT(c.nick_usuario)) % 3)
        WHEN 0 THEN 'recebido'
        WHEN 1 THEN 'lido'
        ELSE        'recusado'
    END
FROM Comentario c
WHERE c.id_video % 2 = 0
LIMIT 500;

-- =========================
-- Bitcoin
-- =========================

INSERT INTO Bitcoin (id_video, nick_usuario, seq_comentario, seq_doacao, TxID)
SELECT
    id_video, nick_usuario, seq_comentario, seq_pg,
    'btctxid_' || id_video || '_' || seq_comentario || '_' || ABS(HASHTEXT(nick_usuario || seq_pg::TEXT))
FROM Doacao
WHERE (ABS(HASHTEXT(nick_usuario || id_video::TEXT)) % 4) = 0
LIMIT 125;

-- =========================
-- PayPal
-- =========================

INSERT INTO PayPal (id_video, nick_usuario, seq_comentario, seq_doacao, IdPayPal)
SELECT
    id_video, nick_usuario, seq_comentario, seq_pg,
    'PAYPAL-' || UPPER(SUBSTRING(MD5(nick_usuario || id_video::TEXT), 1, 16))
FROM Doacao
WHERE (ABS(HASHTEXT(nick_usuario || id_video::TEXT)) % 4) = 1
LIMIT 125;

-- =========================
-- CartaoCredito
-- =========================

INSERT INTO CartaoCredito (id_video, nick_usuario, seq_comentario, seq_doacao, nro, bandeira, dataH)
SELECT
    id_video, nick_usuario, seq_comentario, seq_pg,
    '4' || LPAD((ABS(HASHTEXT(nick_usuario)) % 1000000000000000)::TEXT, 15, '0'),
    CASE (ABS(HASHTEXT(nick_usuario)) % 4)
        WHEN 0 THEN 'Visa'
        WHEN 1 THEN 'Mastercard'
        WHEN 2 THEN 'Amex'
        ELSE        'Elo'
    END,
    NOW() - ((ABS(HASHTEXT(nick_usuario)) % 365) || ' days')::INTERVAL
FROM Doacao
WHERE (ABS(HASHTEXT(nick_usuario || id_video::TEXT)) % 4) = 2
LIMIT 125;

-- =========================
-- MecanismoPlat
-- =========================

INSERT INTO MecanismoPlat (id_video, nick_usuario, seq_comentario, seq_doacao, seq_plataforma)
SELECT
    id_video, nick_usuario, seq_comentario, seq_pg,
    ROW_NUMBER() OVER (ORDER BY id_video, nick_usuario)
FROM Doacao
WHERE (ABS(HASHTEXT(nick_usuario || id_video::TEXT)) % 4) = 3
LIMIT 125;