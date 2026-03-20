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
    moeda        VARCHAR(10)    PRIMARY KEY,
    nome         VARCHAR(50)    NOT NULL,
    fator_conver NUMERIC(18, 8) NOT NULL --Por se tratar de um dado financeiro, optou-se por usar NUMERIC para ter exatidao
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
    CONSTRAINT fk_empresapais_empresa FOREIGN KEY (nro_empresa) REFERENCES Empresa(nro),
    CONSTRAINT fk_empresapais_pais    FOREIGN KEY (ddi_pais)    REFERENCES Pais(ddi)
);

-- =========================
-- Plataforma e Usuário
-- =========================

CREATE TABLE Plataforma (
    nro           SERIAL       PRIMARY KEY,
    nome          VARCHAR(100) NOT NULL UNIQUE,
    qtd_users     BIGINT       DEFAULT 0,
    empresa_fund  INT          NOT NULL,
    empresa_respo INT          NOT NULL,
    data_fund     DATE         NOT NULL,
    CONSTRAINT fk_plat_fund  FOREIGN KEY (empresa_fund)  REFERENCES Empresa(nro),
    CONSTRAINT fk_plat_respo FOREIGN KEY (empresa_respo) REFERENCES Empresa(nro)
);

CREATE TABLE Usuario (
    nick            VARCHAR(50)  PRIMARY KEY,
    email           VARCHAR(150) NOT NULL UNIQUE,
    data_nasc       DATE         NOT NULL,
    telefone        VARCHAR(20)  NOT NULL,
    end_postal      VARCHAR(200) NOT NULL,
    pais_residencia INT          NOT NULL,
    CONSTRAINT fk_usuario_pais FOREIGN KEY (pais_residencia) REFERENCES Pais(ddi)
);

CREATE TABLE PlataformaUsuario (
    nro_plataforma INT         NOT NULL,
    nick_usuario   VARCHAR(50) NOT NULL,
    nro_usuario    VARCHAR(50) NOT NULL,
    PRIMARY KEY (nro_plataforma, nick_usuario),
    CONSTRAINT fk_platuser_plat    FOREIGN KEY (nro_plataforma) REFERENCES Plataforma(nro),
    CONSTRAINT fk_platuser_usuario FOREIGN KEY (nick_usuario)   REFERENCES Usuario(nick)
);

CREATE TABLE StreamerPais (
    nick_streamer  VARCHAR(50) NOT NULL,
    ddi_pais       INT         NOT NULL,
    nro_passaporte VARCHAR(30) NOT NULL,
    PRIMARY KEY (nick_streamer, ddi_pais),
    CONSTRAINT fk_streamerpais_usuario FOREIGN KEY (nick_streamer) REFERENCES Usuario(nick),
    CONSTRAINT fk_streamerpais_pais    FOREIGN KEY (ddi_pais)      REFERENCES Pais(ddi)
);

-- =========================
-- Canal, Patrocinio e Níveis
-- =========================

CREATE TABLE Canal (
    nome              VARCHAR(100) NOT NULL,
    nro_plataforma    INT          NOT NULL,
    tipo              VARCHAR(10)  NOT NULL CHECK (tipo IN ('privado', 'publico', 'misto')),
    data_inicio       DATE         NOT NULL,
    descricao         TEXT,
    qtd_videos        INT          DEFAULT 0,
    qtd_visualizacoes BIGINT       DEFAULT 0,
    nick_streamer     VARCHAR(50)  NOT NULL,
    PRIMARY KEY (nome, nro_plataforma),
    CONSTRAINT fk_canal_plataforma FOREIGN KEY (nro_plataforma) REFERENCES Plataforma(nro),
    CONSTRAINT fk_canal_streamer   FOREIGN KEY (nick_streamer)  REFERENCES Usuario(nick)
);

CREATE TABLE Patrocinio (
    nro_empresa    INT            NOT NULL,
    nome_canal     VARCHAR(100)   NOT NULL,
    nro_plataforma INT            NOT NULL,
    valor          NUMERIC(15, 2) NOT NULL,
    PRIMARY KEY (nro_empresa, nome_canal, nro_plataforma),
    CONSTRAINT fk_patroc_empresa FOREIGN KEY (nro_empresa)                REFERENCES Empresa(nro),
    CONSTRAINT fk_patroc_canal   FOREIGN KEY (nome_canal, nro_plataforma) REFERENCES Canal(nome, nro_plataforma)
);

CREATE TABLE NivelCanal (
    nome_canal     VARCHAR(100)   NOT NULL,
    nro_plataforma INT            NOT NULL,
    nivel          SMALLINT       NOT NULL CHECK (nivel BETWEEN 1 AND 5),
    valor          NUMERIC(10, 2) NOT NULL,
    gif            VARCHAR(300)   NOT NULL,
    PRIMARY KEY (nome_canal, nro_plataforma, nivel),
    CONSTRAINT fk_nivelcanal_canal FOREIGN KEY (nome_canal, nro_plataforma) REFERENCES Canal(nome, nro_plataforma)
);

CREATE TABLE Inscricao (
    nome_canal     VARCHAR(100) NOT NULL,
    nro_plataforma INT          NOT NULL,
    nick_membro    VARCHAR(50)  NOT NULL,
    nivel          SMALLINT     NOT NULL,
    PRIMARY KEY (nome_canal, nro_plataforma, nick_membro),
    CONSTRAINT fk_inscricao_nivelcanal FOREIGN KEY (nome_canal, nro_plataforma, nivel)
        REFERENCES NivelCanal(nome_canal, nro_plataforma, nivel),
    CONSTRAINT fk_inscricao_usuario FOREIGN KEY (nick_membro) REFERENCES Usuario(nick)
);

-- =========================
-- Video e Participa
-- =========================

CREATE TABLE Video (
    id_video       SERIAL         PRIMARY KEY, -- chave artificial pra simplificar propagação da chave
    nome_canal     VARCHAR(100)   NOT NULL,
    nro_plataforma INT            NOT NULL,
    titulo         VARCHAR(300)   NOT NULL,
    dataH          TIMESTAMP      NOT NULL,
    tema           VARCHAR(100),
    duracao        INTERVAL       NOT NULL,
    visu_simul     INT            DEFAULT 0,
    visu_total     BIGINT         DEFAULT 0,
    CONSTRAINT uq_video UNIQUE (nome_canal, nro_plataforma, titulo, dataH),
    CONSTRAINT fk_video_canal FOREIGN KEY (nome_canal, nro_plataforma)
        REFERENCES Canal(nome, nro_plataforma)
);

CREATE TABLE Participa (
    id_video      INT         NOT NULL,
    nick_streamer VARCHAR(50) NOT NULL,
    PRIMARY KEY (id_video, nick_streamer),
    CONSTRAINT fk_participa_video    FOREIGN KEY (id_video)      REFERENCES Video(id_video),
    CONSTRAINT fk_participa_streamer FOREIGN KEY (nick_streamer) REFERENCES Usuario(nick)
);

-- =========================
-- Comentario e Doações
-- =========================

CREATE TABLE Comentario (
    id_video     INT         NOT NULL,
    nick_usuario VARCHAR(50) NOT NULL,
    seq          INT         NOT NULL,
    texto        TEXT        NOT NULL,
    dataH        TIMESTAMP   NOT NULL,
    coment_on    BOOLEAN     NOT NULL DEFAULT TRUE,
    PRIMARY KEY (id_video, nick_usuario, seq),
    CONSTRAINT fk_coment_video   FOREIGN KEY (id_video)     REFERENCES Video(id_video),
    CONSTRAINT fk_coment_usuario FOREIGN KEY (nick_usuario) REFERENCES Usuario(nick)
);

CREATE TABLE Doacao (
    id_video       INT            NOT NULL,
    nick_usuario   VARCHAR(50)    NOT NULL,
    seq_comentario INT            NOT NULL,
    seq_pg         INT            NOT NULL,
    valor          NUMERIC(15, 2) NOT NULL,
    status         VARCHAR(10)    NOT NULL
                       CHECK (status IN ('recusado', 'recebido', 'lido')),
    PRIMARY KEY (id_video, nick_usuario, seq_comentario, seq_pg),
    CONSTRAINT fk_doacao_comentario FOREIGN KEY (id_video, nick_usuario, seq_comentario)
        REFERENCES Comentario(id_video, nick_usuario, seq)
);

CREATE TABLE Bitcoin (
    id_video       INT          NOT NULL,
    nick_usuario   VARCHAR(50)  NOT NULL,
    seq_comentario INT          NOT NULL,
    seq_doacao     INT          NOT NULL,
    TxID           VARCHAR(100) NOT NULL UNIQUE,
    PRIMARY KEY (id_video, nick_usuario, seq_comentario, seq_doacao),
    CONSTRAINT fk_btc_doacao FOREIGN KEY (id_video, nick_usuario, seq_comentario, seq_doacao)
        REFERENCES Doacao(id_video, nick_usuario, seq_comentario, seq_pg)
);

CREATE TABLE PayPal (
    id_video       INT          NOT NULL,
    nick_usuario   VARCHAR(50)  NOT NULL,
    seq_comentario INT          NOT NULL,
    seq_doacao     INT          NOT NULL,
    IdPayPal       VARCHAR(100) NOT NULL UNIQUE,
    PRIMARY KEY (id_video, nick_usuario, seq_comentario, seq_doacao),
    CONSTRAINT fk_paypal_doacao FOREIGN KEY (id_video, nick_usuario, seq_comentario, seq_doacao)
        REFERENCES Doacao(id_video, nick_usuario, seq_comentario, seq_pg)
);

CREATE TABLE CartaoCredito (
    id_video       INT          NOT NULL,
    nick_usuario   VARCHAR(50)  NOT NULL,
    seq_comentario INT          NOT NULL,
    seq_doacao     INT          NOT NULL,
    nro            VARCHAR(20)  NOT NULL,
    bandeira       VARCHAR(30)  NOT NULL,
    dataH          TIMESTAMP    NOT NULL,
    PRIMARY KEY (id_video, nick_usuario, seq_comentario, seq_doacao),
    CONSTRAINT fk_cartao_doacao FOREIGN KEY (id_video, nick_usuario, seq_comentario, seq_doacao)
        REFERENCES Doacao(id_video, nick_usuario, seq_comentario, seq_pg)
);

CREATE TABLE MecanismoPlat (
    id_video        INT         NOT NULL,
    nick_usuario    VARCHAR(50) NOT NULL,
    seq_comentario  INT         NOT NULL,
    seq_doacao      INT         NOT NULL,
    seq_plataforma  INT         NOT NULL,
    PRIMARY KEY (id_video, nick_usuario, seq_comentario, seq_doacao),
    CONSTRAINT fk_mecplat_doacao FOREIGN KEY (id_video, nick_usuario, seq_comentario, seq_doacao)
        REFERENCES Doacao(id_video, nick_usuario, seq_comentario, seq_pg)
);