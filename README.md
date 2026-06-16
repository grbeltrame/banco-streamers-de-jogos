# Decisões de Projeto — Banco de Dados de Streaming de Jogos

Documentação das decisões de implementação tomadas pelo grupo ao longo da construção do banco de dados, com a justificativa de cada escolha. Este documento serve de base tanto para consulta interna do grupo quanto para o relatório final exigido pelo professor.

## Sobre o que veio do professor e o que foi decisão do grupo

O professor entregou o modelo ER e o modelo relacional já prontos, incluindo todas as tabelas, atributos e relacionamentos. O grupo optou por não alterar a estrutura conceitual do banco — apenas  traduzi-la em SQL e tomar decisões de implementação que o modelo relacional não especifica, como tipos de dado, índices artificiais, constraints e estratégia de população. Cada seção abaixo indica explicitamente se a decisão partiu do professor ou do grupo.

## Abordagem incremental e organização dos arquivos

O grupo decidiu construir o banco em etapas separadas, cada uma em um arquivo `.sql` próprio dentro da pasta `sql/`: `01_schema.sql` para a criação das tabelas, `02_dados.sql` para a população, e os arquivos `03_indices.sql`, `04_views.sql`, `05_triggers.sql` e `06_functions.sql` para as etapas seguintes, criados conforme o conteúdo correspondente for visto em aula. Essa separação evita um único arquivo gigante e facilita que os cinco integrantes do grupo trabalhem em paralelo sem conflitos constantes no Git.

## Ambiente de desenvolvimento

O grupo optou por usar Docker com PostgreSQL 16 em vez de pedir que cada integrante instalasse o PostgreSQL diretamente na própria máquina. Com cinco pessoas trabalhando no mesmo projeto, instalações individuais tendem a divergir em versão e configuração, gerando o clássico problema de "na minha máquina funciona". Com Docker, todos os integrantes sobem o mesmo container a partir da mesma definição em `docker-compose.yml`, eliminando essa fonte de inconsistência. Essa configuração foi sugestão do próprio professor no enunciado do trabalho.

## Identificadores artificiais (chaves substitutas)

O modelo relacional original do professor usa, em várias tabelas, chaves primárias compostas por múltiplas colunas que se propagam como chave estrangeira para outras tabelas. O professor sinalizou explicitamente essa possibilidade no caso da tabela `Video`, cuja chave natural seria `(nome_canal, nro_plataforma, titulo, dataH)`, e comentou em aula que chaves desse tipo — extensas ou baseadas em texto — tendem a aumentar o custo de armazenamento e comparação à medida que se propagam.

A partir desse comentário, o grupo formalizou uma regra própria: toda chave primária com três ou mais atributos, ou toda chave de tipo string que se propague como estrangeira para múltiplas tabelas, recebe um identificador artificial do tipo `SERIAL`. Chaves compostas de apenas dois atributos foram mantidas como estão, por não representarem o mesmo nível de overhead.

Aplicando essa regra, o grupo criou quatro identificadores artificiais:

`Video.id_video` substitui a chave natural de quatro atributos `(id_canal, titulo, dataH)`. Essa chave se propagava para `Participa`, `Comentario`, `Doacao` e as quatro tabelas de forma de pagamento (`Bitcoin`, `PayPal`, `CartaoCredito`, `MecanismoPlat`).

`Canal.id_canal` substitui a chave natural `(nome, nro_plataforma)`. Embora tenha apenas dois atributos, essa chave se propagava para quatro tabelas diferentes (`Patrocinio`, `NivelCanal`, `Inscricao`, `Video`), e a criação do identificador artificial reduziu sensivelmente o tamanho das chaves estrangeiras nessas quatro tabelas.

`Comentario.id_comentario` substitui a chave natural de três atributos `(id_video, id_usuario, seq)`, que se propagava para `Doacao` e, por consequência, para as quatro tabelas de forma de pagamento.

`Usuario.id_usuario` substitui `nick` (`VARCHAR(50)`) como chave primária. Embora `nick` seja um único atributo, ele é do tipo string e se propagava como chave estrangeira para seis tabelas (`PlataformaUsuario`, `StreamerPais`, `Canal`, `Inscricao`, `Participa`, `Comentario`) — a maior propagação de qualquer chave do banco. Comparação de inteiros é computacionalmente mais barata que comparação de strings, e os índices sobre colunas inteiras ocupam menos espaço em disco. O atributo `nick` foi mantido como `UNIQUE NOT NULL`, preservando a exigência do professor de que cada usuário tenha um nick único.

Um caso foi avaliado e mantido como chave natural: `Conversao.moeda` (`VARCHAR(10)`, valores como `BRL`, `USD`, `EUR`). Apesar de ser string, essa chave propaga para apenas uma tabela (`Pais`), e representa um código de domínio curto e estável — um padrão aceito mesmo em bancos profissionais. O grupo decidiu não criar um identificador artificial aqui, já que o ganho seria mínimo frente à simplicidade de manter o código da moeda como chave.

## Tipos de dados

O modelo relacional do professor especifica os atributos de cada tabela, mas não os tipos de dado SQL — essa foi uma decisão inteiramente do grupo na hora de traduzir o modelo para PostgreSQL.

Para todo atributo monetário (fator de conversão de moeda, valores de patrocínio, de doação e de mensalidade de nível), o grupo optou por `NUMERIC` em vez de `FLOAT`. A diferença é que `FLOAT` armazena uma aproximação binária do número, o que pode gerar pequenos erros de arredondamento ao longo de somas sucessivas — um problema sério quando se trata de dinheiro. `NUMERIC` armazena o valor exato, dígito por dígito, ao custo de um processamento levemente mais lento, o que é aceitável dado o volume de dados do projeto.

Para os demais atributos, seguiu-se a convenção: `VARCHAR(n)` para textos com tamanho limitado e previsível (nicks, nomes, e-mails); `TEXT` para textos sem limite definido (descrição de canal, texto de comentário); `DATE` para datas sem componente de hora (nascimento, fundação); `TIMESTAMP` para data e hora completas (postagem de vídeo, comentário, transação de cartão); `BIGINT` para contadores que podem crescer muito (visualizações totais, usuários da plataforma); `SMALLINT` para valores pequenos e limitados (nível de membro, de 1 a 5); `BOOLEAN` para os atributos binários (comentário online ou offline); e `INTERVAL`, tipo nativo do PostgreSQL, para representar a duração de um vídeo.

## Constraints de integridade

O grupo usou `CHECK` para campos cujo domínio de valores é fixo e enumerável, garantindo que o próprio banco rejeite valores inválidos sem depender de validação na aplicação. Isso foi aplicado ao tipo de canal (`privado`, `publico`, `misto`), ao nível de membro (`1` a `5`) e ao status da doação (`recusado`, `recebido`, `lido`) — todos definidos explicitamente pelo professor no enunciado.

Em paralelo aos identificadores artificiais, o grupo manteve constraints `UNIQUE` sobre as combinações de atributos que formavam a chave natural original, preservando a regra de negócio mesmo após a simplificação da chave primária. Por exemplo, mesmo com `id_video` como chave primária de `Video`, a combinação `(id_canal, titulo, dataH)` permanece `UNIQUE`, garantindo que um canal não publique dois vídeos com o mesmo título no mesmo instante. O mesmo padrão se repete em `Canal` (`nome, nro_plataforma`) e `Comentario` (`id_video, id_usuario, seq`).

## Verificação de normalização

O grupo verificou as três primeiras formas normais sobre o modelo entregue pelo professor antes de prosseguir com a implementação. Na Primeira Forma Normal, confirmou-se que nenhuma tabela possui atributos multivalorados ou grupos repetidos em uma mesma célula. Na Segunda Forma Normal, confirmou-se que todo atributo não-chave depende da chave inteira, e não apenas de parte dela, nas tabelas com chave composta. Na Terceira Forma Normal, confirmou-se a ausência de dependências transitivas — o exemplo mais claro no próprio modelo é a separação entre `Pais` e `Conversao`: o fator de conversão de uma moeda depende da moeda em si, não do país, e por isso vive em uma tabela própria, evitando que o mesmo fator se repita em todos os países que compartilham aquela moeda. O modelo entregue pelo professor já estava normalizado; o trabalho do grupo nessa etapa foi de verificação, não de correção.

## Estratégia de população dos dados

O professor exige entre 100 e 1000 tuplas por tabela, aceitando dados artificiais. O grupo optou por uma combinação de dados realistas e dados gerados proceduralmente: para usuários e canais notáveis, foram inseridos manualmente nomes reais de streamers (gaules, alanzoka, cellbit, xQc, shroud, ninja, faker, entre outros), incluindo associações de plataforma confirmadas por pesquisa quando relevante — por exemplo, o canal do xQc na Kick além da Twitch, e os canais de Gaules e Baiano_gamer também confirmados na Kick. Onde a informação não pôde ser confirmada com confiança, o grupo optou por não incluir o dado em vez de arriscar uma associação incorreta.

Para o volume restante necessário para atingir a faixa de 100 a 1000 tuplas, o grupo usou `generate_series` do PostgreSQL para gerar registros em lote (usuários comuns, streamers adicionais, vídeos, comentários), evitando escrever centenas de instruções `INSERT` manuais quase idênticas.

Um caso específico tratado durante a população foi o DDI do Canadá, que no mundo real é compartilhado com os Estados Unidos (+1). Como `ddi` é chave primária da tabela `Pais` e não pode se repetir, o grupo optou por deixar o Canadá de fora da população por ora, registrando a decisão em comentário no próprio arquivo SQL, em vez de inventar um DDI fictício para contornar o conflito.

Para o campo `gif` em `NivelCanal` — que o professor exige como um arquivo de imagem associado a cada nível de membro — o grupo optou por representar o valor como um caminho relativo fictício (por exemplo, `gifs/gaules_nivel1.gif`) em vez de uma URL `https://` completa, por ser mais honesto quanto à natureza fictícia do dado: o banco armazena apenas o texto do caminho, sem que ele aponte para um arquivo real.

## Status de vigência (sem histórico)

O professor especifica explicitamente que `Patrocinio` e `Inscricao` não devem manter histórico — apenas patrocínios e assinaturas vigentes devem aparecer no sistema. Essa regra já está refletida na própria estrutura das tabelas (cada combinação empresa-canal ou canal-membro aparece uma única vez, sem campo de data de início/fim), mas ainda não há um mecanismo automático (trigger) que remova ou substitua um registro quando um patrocínio ou uma assinatura deixam de ser vigentes — esse tratamento é um dos itens previstos para a etapa de triggers.

## Índices de apoio (`03_indices.sql`)

### Metodologia de escolha

Antes de definir qualquer índice, o grupo escreveu as 8 consultas exigidas pelo professor em SQL puro e executou `EXPLAIN ANALYZE` em cada uma delas com as estatísticas do banco atualizadas via `ANALYZE`. Essa análise revelou quais tabelas sofriam Seq Scan com mais frequência e quais filtros e joins eram responsáveis pelo maior volume de leituras desnecessárias.

A partir dos resultados, o grupo adotou três critérios para justificar a criação de um índice:

1. **Tamanho da tabela**: índices só fazem sentido em tabelas grandes o suficiente para que a varredura completa seja custosa. Para tabelas pequenas, o Seq Scan já é mais rápido do que o overhead de consultar o índice e depois buscar as linhas no disco.
2. **Frequência de acesso**: a coluna precisa ser usada em join ou filtro em múltiplas consultas, não apenas em uma situação isolada.
3. **Seletividade**: o índice precisa filtrar uma parte significativa das linhas — ou seja, a condição deve descartar a maioria das linhas da tabela. Se quase todas as linhas passam pelo filtro, o Seq Scan continua sendo mais eficiente.

O professor exige explicitamente que o overhead de inserção seja considerado. Para cada índice criado, o grupo avaliou se o custo de manter o índice atualizado a cada INSERT é justificado pelo ganho nas consultas de leitura.


### Índices criados

**Índice 1 — `idx_comentario_id_video` em `Comentario(id_video)`**

A tabela `Comentario` tem 1000 linhas e aparece em Seq Scan nas consultas 3, 4, 7 e 8 — todas as que envolvem doações. Em todas elas o join é feito por `co.id_video`, buscando os comentários de um vídeo específico. Sem índice, o banco varre as 1000 linhas para encontrar as poucas que pertencem ao vídeo buscado. O overhead de inserção é moderado: comentários são inseridos pontualmente e com menos frequência do que as consultas analíticas são executadas.

**Índice 2 — `idx_doacao_id_comentario` em `Doacao(id_comentario)`**

A tabela `Doacao` tem 500 linhas e aparece em Seq Scan nas mesmas 4 consultas (3, 4, 7 e 8). O join com `Comentario` é feito por `d.id_comentario`, e sem índice o planner constrói uma hash table em memória a cada execução para resolver esse join. O overhead de inserção é baixo: doações são inseridas em situações pontuais.

**Índice 3 — `idx_doacao_status` em `Doacao(status)`**

Utilizado pela consulta 4, que filtra `WHERE d.status = 'lido'`. O `EXPLAIN ANALYZE` mostrou `Rows Removed by Filter: 300`, ou seja, 60% das 500 linhas são lidas e depois descartadas a cada execução. O índice elimina essa leitura desnecessária. O overhead de inserção é baixo: o campo `status` tem apenas 3 valores possíveis e o índice resultante é pequeno.

**Índice 4 — `idx_inscricao_id_membro` em `Inscricao(id_membro)`**

A tabela `Inscricao` tem 1000 linhas e aparece em Seq Scan nas consultas 2, 6 e 8. O join com `Usuario` é feito por `i.id_membro`, buscando as inscrições de um membro específico — que são poucas comparado ao total de 1000 linhas. O overhead de inserção é moderado: inscrições são adicionadas quando um usuário assina um canal, operação menos frequente que as consultas analíticas.

**Índice 5 — `idx_nivelcanal_id_canal_nivel` em `NivelCanal(id_canal, nivel)`**

A tabela `NivelCanal` tem 605 linhas e aparece em Seq Scan nas consultas 2, 6 e 8. O join é sempre feito pelos dois campos em conjunto: `nc.id_canal = i.id_canal AND nc.nivel = i.nivel`. Um índice composto por ambas as colunas resolve esse join com acesso direto. O overhead de inserção é baixo: `NivelCanal` é uma tabela estática — os níveis de um canal raramente mudam após sua criação.

### Tabelas avaliadas e descartadas

**`Canal` (121 linhas)**: aparece em Seq Scan em todas as 8 consultas, mas tem apenas 121 linhas. O custo de varrer 121 linhas é desprezível — o Seq Scan é mais eficiente do que o overhead de acessar um índice para uma tabela tão pequena.

**`Patrocinio` (20 linhas)**: aparece em Seq Scan nas consultas 1, 5 e 8. Com apenas 20 linhas, qualquer Seq Scan é instantâneo. Um índice aqui geraria mais overhead de manutenção do que ganho de leitura.

**`Empresa` (21 linhas)**: mesma situação — tabela pequena demais para justificar índice.

**`Video` (1210 linhas) em `id_canal`**: o `EXPLAIN ANALYZE` mostrou que o planner já usa o índice da chave primária (`video_pkey`) para acessar vídeos, e o mecanismo de `Memoize` em `v.id_canal` reduz o custo das buscas repetidas. A justificativa para um índice adicional seria fraca dado que o planner já lida bem com esse acesso.

**`Usuario` (1000 linhas)**: não aparece como gargalo em nenhuma consulta — o join com `Inscricao` via `id_membro` é resolvido pelo índice 4 acima, e `Usuario` não é filtrada diretamente por nenhuma das 8 consultas.

**`NivelCanal` em `id_canal` isolado**: o join com `NivelCanal` sempre usa os dois campos `(id_canal, nivel)` em conjunto. Um índice só em `id_canal` seria menos eficiente do que o índice composto escolhido, que resolve o join inteiro diretamente.

## Views (`04_views.sql`)

### Decisão sobre filtro de status nas doações

Antes de descrever cada view, vale registrar uma decisão de implementação do grupo: doações com status `recusado` são excluídas de todas as views e consultas que somam valores de doação. O motivo é que uma doação recusada representa uma transação que não foi concluída — o dinheiro não entrou de fato no canal. Somar esses valores inflaria artificialmente o faturamento. O enunciado do professor não especifica esse filtro explicitamente, mas o grupo entendeu que "valores recebidos em doação" implica apenas as doações com status `recebido` ou `lido`.

### Sobre views virtuais e materializadas

O professor exige a construção de visões virtuais e materializadas. Uma view virtual é uma consulta armazenada — cada vez que é acessada, o banco executa a consulta de novo sobre os dados atuais. Uma view materializada armazena o resultado fisicamente em disco, como uma tabela, e precisa ser atualizada explicitamente com `REFRESH MATERIALIZED VIEW`. Views materializadas são mais rápidas para consulta, mas ficam desatualizadas se os dados mudarem — por isso são indicadas para consultas pesadas que não precisam de dados em tempo real.

### Views criadas

**View 1 — `vw_canais_patrocinados`**

Responde diretamente à consulta 1 do professor: quais canais são patrocinados, por qual empresa e qual o valor. Reúne `Patrocinio`, `Empresa`, `Canal` e `Plataforma` em uma view simples para evitar que esse join de 4 tabelas seja reescrito em cada consulta ou função que precise dessa informação. Foi criada como view virtual porque o conjunto de patrocínios pode mudar (o professor especifica que apenas patrocínios vigentes aparecem no sistema).

**View 2 — `vw_gastos_mensais_membros`**

Responde à consulta 2: de quantos canais cada usuário é membro e quanto desembolsa por mês. Agrupa `Inscricao` com `NivelCanal` por membro. Foi criada como view virtual porque inscrições podem ser adicionadas ou removidas, e os resultados precisam refletir o estado atual.

**View 3 — `vw_doacoes_por_canal`**

Responde às consultas 3 e 7: canais que receberam doações e a soma dos valores. Percorre a cadeia `Doacao → Comentario → Video → Canal → Plataforma` e filtra apenas doações com status `recebido` ou `lido`. Foi criada como view virtual porque novas doações são inseridas continuamente.

**View 4 — `vw_doacoes_lidas_por_video`**

Responde à consulta 4: soma das doações de comentários lidos, agrupada por vídeo. Filtra especificamente `status = 'lido'`, que é um subconjunto da view anterior com granularidade de vídeo em vez de canal. Foi criada como view virtual pelo mesmo motivo da view 3.

**View Materializada 5 — `mv_receita_total_canal`**

Responde à consulta 8: faturamento total de cada canal combinando as três fontes de receita (patrocínio + membros + doações). É a consulta mais pesada do banco — envolve subconsultas sobre `Patrocinio`, `Inscricao`, `NivelCanal`, `Doacao`, `Comentario` e `Video` ao mesmo tempo. Por ser custosa e não precisar de dados em tempo real (faturamento total é tipicamente consultado em relatórios periódicos), foi criada como view materializada. Para atualizar os dados após inserções, basta executar:

```sql
REFRESH MATERIALIZED VIEW streaming.mv_receita_total_canal;
```

Essa atualização deve ser incluída nos triggers de inserção de doações, inscrições e patrocínios na etapa de triggers, garantindo que a view permaneça consistente com os dados.