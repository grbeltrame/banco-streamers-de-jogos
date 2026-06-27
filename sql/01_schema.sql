-- Schema do banco de dados de streaming de jogos
-- TCC00335 — UFF — Prof. Marcos Bedo — 2026/1

DROP SCHEMA IF EXISTS streaming CASCADE;
CREATE SCHEMA streaming;
SET search_path TO streaming;

-- =========================
-- Empresa, Conversao e Pais
-- =========================

CREATE TABLE Empresa (
    nro           SERIAL       PRIMARY KEY,
    nome          VARCHAR(100) NOT NULL,
    nome_fantasia VARCHAR(100)
);

CREATE TABLE Conversao (
    moeda        VARCHAR(10)    PRIMARY KEY, -- chave natural curta e estável; mantida por simplicidade (decisão do grupo)
    nome         VARCHAR(50)    NOT NULL,
    fator_conver NUMERIC(18, 8) NOT NULL CHECK (fator_conver > 0) -- NUMERIC para exatidão financeira; CHECK garante valor positivo
);

CREATE TABLE Pais (
    ddi   INT          PRIMARY KEY,
    nome  VARCHAR(100) NOT NULL,
    moeda VARCHAR(10)  NOT NULL,
    CONSTRAINT fk_pais_conversao FOREIGN KEY (moeda) REFERENCES Conversao(moeda)
);

CREATE TABLE EmpresaPais (
    nro_empresa INT         NOT NULL,
    ddi_pais    INT         NOT NULL,
    id_nacional VARCHAR(50) NOT NULL,
    PRIMARY KEY (nro_empresa, ddi_pais),
    CONSTRAINT uq_empresapais_id_nacional UNIQUE (ddi_pais, id_nacional),
    CONSTRAINT fk_empresapais_empresa FOREIGN KEY (nro_empresa) REFERENCES Empresa(nro),
    CONSTRAINT fk_empresapais_pais    FOREIGN KEY (ddi_pais)    REFERENCES Pais(ddi)
);

-- =========================
-- Plataforma e Usuário
-- =========================

CREATE TABLE Plataforma (
    nro           SERIAL       PRIMARY KEY,
    nome          VARCHAR(100) NOT NULL UNIQUE,
    qtd_users     BIGINT       NOT NULL DEFAULT 0 CHECK (qtd_users >= 0),
    empresa_fund  INT          NOT NULL,
    empresa_respo INT          NOT NULL,
    data_fund     DATE         NOT NULL,
    CONSTRAINT fk_plat_fund  FOREIGN KEY (empresa_fund)  REFERENCES Empresa(nro),
    CONSTRAINT fk_plat_respo FOREIGN KEY (empresa_respo) REFERENCES Empresa(nro)
);

-- Usuario: chave artificial id_usuario adicionada para evitar propagação de
-- uma chave do tipo VARCHAR para as 6 tabelas que dependem dela
-- (PlataformaUsuario, StreamerPais, Canal, Inscricao, Participa, Comentario).
-- "nick" permanece como UNIQUE NOT NULL pois é a identificação visível ao usuário.
CREATE TABLE Usuario (
    id_usuario      SERIAL       PRIMARY KEY,
    nick            VARCHAR(50)  NOT NULL UNIQUE,
    email           VARCHAR(150) NOT NULL UNIQUE,
    data_nasc       DATE         NOT NULL,
    telefone        VARCHAR(20)  NOT NULL,
    end_postal      VARCHAR(200) NOT NULL,
    pais_residencia INT          NOT NULL,
    CONSTRAINT fk_usuario_pais FOREIGN KEY (pais_residencia) REFERENCES Pais(ddi)
);

CREATE TABLE PlataformaUsuario (
    nro_plataforma INT         NOT NULL,
    id_usuario     INT         NOT NULL,
    nro_usuario    VARCHAR(50) NOT NULL,
    PRIMARY KEY (nro_plataforma, id_usuario),
    CONSTRAINT uq_platuser_nro_usuario UNIQUE (nro_plataforma, nro_usuario),
    CONSTRAINT fk_platuser_plat    FOREIGN KEY (nro_plataforma) REFERENCES Plataforma(nro),
    CONSTRAINT fk_platuser_usuario FOREIGN KEY (id_usuario)     REFERENCES Usuario(id_usuario)
);

CREATE TABLE StreamerPais (
    id_usuario     INT         NOT NULL,
    ddi_pais       INT         NOT NULL,
    nro_passaporte VARCHAR(30) NOT NULL,
    PRIMARY KEY (id_usuario, ddi_pais),
    CONSTRAINT uq_streamerpais_passaporte UNIQUE (ddi_pais, nro_passaporte),
    CONSTRAINT fk_streamerpais_usuario FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario),
    CONSTRAINT fk_streamerpais_pais    FOREIGN KEY (ddi_pais)   REFERENCES Pais(ddi)
);

-- =========================
-- Canal, Patrocinio e Níveis
-- =========================

CREATE TABLE Canal (
    id_canal          SERIAL       PRIMARY KEY, -- chave artificial para simplificar propagação
    nome              VARCHAR(100) NOT NULL,
    nro_plataforma    INT          NOT NULL,
    tipo              VARCHAR(10)  NOT NULL CHECK (tipo IN ('privado', 'publico', 'misto')),
    data_inicio       DATE         NOT NULL,
    descricao         TEXT         NOT NULL,
    qtd_videos        INT          NOT NULL DEFAULT 0 CHECK (qtd_videos >= 0),
    qtd_visualizacoes BIGINT       NOT NULL DEFAULT 0 CHECK (qtd_visualizacoes >= 0),
    id_streamer       INT          NOT NULL,
    ddi_streamer      INT          NOT NULL,
    CONSTRAINT uq_canal            UNIQUE (nome, nro_plataforma),
    CONSTRAINT fk_canal_plataforma FOREIGN KEY (nro_plataforma) REFERENCES Plataforma(nro),
    CONSTRAINT fk_canal_streamer   FOREIGN KEY (id_streamer, ddi_streamer)
        REFERENCES StreamerPais(id_usuario, ddi_pais)
);

CREATE TABLE Patrocinio (
    nro_empresa INT            NOT NULL,
    id_canal    INT            NOT NULL,
    valor       NUMERIC(15, 2) NOT NULL CHECK (valor > 0),
    PRIMARY KEY (nro_empresa, id_canal),
    CONSTRAINT fk_patroc_empresa FOREIGN KEY (nro_empresa) REFERENCES Empresa(nro),
    CONSTRAINT fk_patroc_canal   FOREIGN KEY (id_canal)    REFERENCES Canal(id_canal)
);

CREATE TABLE NivelCanal (
    id_canal   INT            NOT NULL,
    nivel      SMALLINT       NOT NULL CHECK (nivel BETWEEN 1 AND 5),
    nome_nivel VARCHAR(50)    NOT NULL,
    valor      NUMERIC(10, 2) NOT NULL CHECK (valor > 0),
    gif        VARCHAR(300)   NOT NULL,
    PRIMARY KEY (id_canal, nivel),
    CONSTRAINT fk_nivelcanal_canal FOREIGN KEY (id_canal) REFERENCES Canal(id_canal)
);

CREATE TABLE Inscricao (
    id_canal  INT      NOT NULL,
    id_membro INT      NOT NULL,
    nivel     SMALLINT NOT NULL,
    PRIMARY KEY (id_canal, id_membro),
    CONSTRAINT fk_inscricao_nivelcanal FOREIGN KEY (id_canal, nivel)
        REFERENCES NivelCanal(id_canal, nivel),
    CONSTRAINT fk_inscricao_usuario FOREIGN KEY (id_membro) REFERENCES Usuario(id_usuario)
);

-- =========================
-- Video e Participa
-- =========================

CREATE TABLE Video (
    id_video   SERIAL         PRIMARY KEY, -- chave artificial para simplificar propagação
    id_canal   INT            NOT NULL,
    titulo     VARCHAR(300)   NOT NULL,
    dataH      TIMESTAMP      NOT NULL,
    tema       VARCHAR(100),
    duracao    INTERVAL       NOT NULL,
    visu_simul INT            NOT NULL DEFAULT 0 CHECK (visu_simul >= 0),
    visu_total BIGINT         NOT NULL DEFAULT 0 CHECK (visu_total >= 0),
    CONSTRAINT uq_video       UNIQUE (id_canal, titulo, dataH),
    CONSTRAINT fk_video_canal FOREIGN KEY (id_canal) REFERENCES Canal(id_canal)
);

CREATE TABLE Participa (
    id_video      INT NOT NULL,
    id_streamer   INT NOT NULL,
    ddi_streamer  INT NOT NULL,
    PRIMARY KEY (id_video, id_streamer, ddi_streamer),
    CONSTRAINT fk_participa_video    FOREIGN KEY (id_video)    REFERENCES Video(id_video),
    CONSTRAINT fk_participa_streamer FOREIGN KEY (id_streamer, ddi_streamer)
        REFERENCES StreamerPais(id_usuario, ddi_pais)
);

-- =========================
-- Comentario e Doações
-- =========================

CREATE TABLE Comentario (
    id_comentario SERIAL    PRIMARY KEY, -- chave artificial para simplificar propagação
    id_video      INT       NOT NULL,
    id_usuario    INT       NOT NULL,
    seq           INT       NOT NULL CHECK (seq > 0),
    texto         TEXT      NOT NULL,
    dataH         TIMESTAMP NOT NULL,
    coment_on     BOOLEAN   NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_comentario     UNIQUE (id_video, seq),
    CONSTRAINT fk_coment_video   FOREIGN KEY (id_video)   REFERENCES Video(id_video),
    CONSTRAINT fk_coment_usuario FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario)
);

CREATE TABLE Doacao (
    id_comentario INT            NOT NULL,
    seq_pg        INT            NOT NULL CHECK (seq_pg > 0),
    metodo        VARCHAR(25)    NOT NULL
                      CHECK (metodo IN ('bitcoin', 'paypal', 'cartao_credito', 'mecanismo_plataforma')),
    valor         NUMERIC(15, 2) NOT NULL CHECK (valor > 0),
    status        VARCHAR(10)    NOT NULL
                      CHECK (status IN ('recusado', 'recebido', 'lido')),
    PRIMARY KEY (id_comentario, seq_pg),
    CONSTRAINT fk_doacao_comentario FOREIGN KEY (id_comentario)
        REFERENCES Comentario(id_comentario)
);

CREATE TABLE Bitcoin (
    id_comentario INT          NOT NULL,
    seq_doacao    INT          NOT NULL CHECK (seq_doacao > 0),
    TxID          VARCHAR(100) NOT NULL UNIQUE,
    PRIMARY KEY (id_comentario, seq_doacao),
    CONSTRAINT fk_btc_doacao FOREIGN KEY (id_comentario, seq_doacao)
        REFERENCES Doacao(id_comentario, seq_pg)
);

CREATE TABLE PayPal (
    id_comentario INT          NOT NULL,
    seq_doacao    INT          NOT NULL CHECK (seq_doacao > 0),
    IdPayPal      VARCHAR(100) NOT NULL UNIQUE,
    PRIMARY KEY (id_comentario, seq_doacao),
    CONSTRAINT fk_paypal_doacao FOREIGN KEY (id_comentario, seq_doacao)
        REFERENCES Doacao(id_comentario, seq_pg)
);

CREATE TABLE CartaoCredito (
    id_comentario INT          NOT NULL,
    seq_doacao    INT          NOT NULL CHECK (seq_doacao > 0),
    nro           VARCHAR(20)  NOT NULL,
    bandeira      VARCHAR(30)  NOT NULL,
    dataH         TIMESTAMP    NOT NULL,
    PRIMARY KEY (id_comentario, seq_doacao),
    CONSTRAINT fk_cartao_doacao FOREIGN KEY (id_comentario, seq_doacao)
        REFERENCES Doacao(id_comentario, seq_pg)
);

CREATE TABLE MecanismoPlat (
    id_comentario  INT NOT NULL,
    seq_doacao     INT NOT NULL CHECK (seq_doacao > 0),
    seq_plataforma INT NOT NULL CHECK (seq_plataforma > 0),
    PRIMARY KEY (id_comentario, seq_doacao),
    CONSTRAINT fk_mecplat_doacao FOREIGN KEY (id_comentario, seq_doacao)
        REFERENCES Doacao(id_comentario, seq_pg)
);