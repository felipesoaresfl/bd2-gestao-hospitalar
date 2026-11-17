-- =====================================================================
-- Sistema de Gestão de Emergências e Atendimento Hospitalar
-- Disciplina: Banco de Dados II - Prof. André Olímpio
-- Engenharia da Computação - Univap
-- SGBD: MySQL 8 (MySQL Workbench) - Engine InnoDB
-- Total de tabelas: 37
-- =====================================================================
-- 1. CADASTRO E IDENTIFICAÇÃO DO PACIENTE
-- =====================================================================

-- Convênios (planos de saúde) aceitos pelo hospital. Usado somente pelo paciente.
create table convenio (
    id_convenio int not null auto_increment,
    nome varchar(100) not null,
    registro_ans char(6) unique,
    telefone varchar(11),
    status char(1) not null default 'A',
    primary key (id_convenio),
    constraint ck_convenio_status check (status in ('A', 'I'))
) engine = InnoDB;

-- Cadastro dos pacientes identificados.
create table paciente (
    id_paciente int not null auto_increment,
    nome varchar(120) not null,
    cpf char(11) not null unique,
    data_nasc date not null,
    sexo char(1) not null,
    nome_mae varchar(120),
    cartao_sus char(15) unique,
    tipo_sanguineo varchar(3),
    id_convenio int,
    numero_carteirinha varchar(20),
    data_cadastro datetime not null default current_timestamp,
    status char(1) not null default 'A',
    primary key (id_paciente),
    constraint ck_paciente_sexo check (sexo in ('M', 'F', 'O')),
    constraint ck_paciente_tipo_sanguineo check (tipo_sanguineo in ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    constraint ck_paciente_status check (status in ('A', 'I', 'O')),
    constraint fk_paciente_convenio foreign key (id_convenio) references convenio (id_convenio)
        on delete no action on update no action
) engine = InnoDB;

-- Pacientes que chegam sem identificação (ex.: inconscientes). Depois de identificados, são vinculados ao cadastro definitivo.
create table cadastro_provisorio (
    id_cadastro_provisorio int not null auto_increment,
    identificacao varchar(120) not null,
    sexo_aparente char(1),
    idade_aparente smallint,
    caracteristicas varchar(255),
    local_encontrado varchar(150),
    data_hora_cadastro datetime not null default current_timestamp,
    id_paciente int,
    data_identificacao datetime,
    primary key (id_cadastro_provisorio),
    constraint ck_cadastro_provisorio_sexo_aparente check (sexo_aparente in ('M', 'F', 'I')),
    constraint ck_cadastro_provisorio_idade_aparente check (idade_aparente between 0 and 130),
    constraint fk_cadastro_provisorio_paciente foreign key (id_paciente) references paciente (id_paciente)
        on delete no action on update no action
) engine = InnoDB;


-- =====================================================================
-- 2. HISTÓRICO CLÍNICO
-- =====================================================================

-- Histórico clínico do paciente (um por paciente).
create table historico_clinico (
    id_historico int not null auto_increment,
    id_paciente int not null unique,
    observacoes text,
    data_criacao datetime not null default current_timestamp,
    primary key (id_historico),
    constraint fk_historico_clinico_paciente foreign key (id_paciente) references paciente (id_paciente)
        on delete no action on update no action
) engine = InnoDB;

-- Doenças registradas no histórico do paciente.
create table doenca (
    id_doenca int not null auto_increment,
    id_historico int not null,
    nome varchar(120) not null,
    cid varchar(10),
    data_diagnostico date,
    cronica char(1) not null default 'N',
    observacao varchar(255),
    primary key (id_doenca),
    constraint ck_doenca_cronica check (cronica in ('S', 'N')),
    constraint fk_doenca_historico foreign key (id_historico) references historico_clinico (id_historico)
        on delete no action on update no action
) engine = InnoDB;

-- Cirurgias já realizadas pelo paciente.
create table cirurgia (
    id_cirurgia int not null auto_increment,
    id_historico int not null,
    descricao varchar(150) not null,
    data_cirurgia date,
    hospital varchar(120),
    observacao varchar(255),
    primary key (id_cirurgia),
    constraint fk_cirurgia_historico foreign key (id_historico) references historico_clinico (id_historico)
        on delete no action on update no action
) engine = InnoDB;

-- Alergias do paciente.
create table alergia (
    id_alergia int not null auto_increment,
    id_historico int not null,
    agente varchar(120) not null,
    tipo char(1) not null,
    gravidade char(1) not null,
    reacao varchar(255),
    primary key (id_alergia),
    constraint ck_alergia_tipo check (tipo in ('M', 'A', 'O')),
    constraint ck_alergia_gravidade check (gravidade in ('L', 'M', 'G')),
    constraint fk_alergia_historico foreign key (id_historico) references historico_clinico (id_historico)
        on delete no action on update no action
) engine = InnoDB;

-- Contraindicações do paciente (medicamentos ou procedimentos que não podem ser usados).
create table contraindicacao (
    id_contraindicacao int not null auto_increment,
    id_historico int not null,
    descricao varchar(255) not null,
    motivo varchar(255),
    primary key (id_contraindicacao),
    constraint fk_contraindicacao_historico foreign key (id_historico) references historico_clinico (id_historico)
        on delete no action on update no action
) engine = InnoDB;


-- =====================================================================
-- 3. FUNCIONÁRIOS E PERMISSÕES
-- =====================================================================

-- Setores do hospital (ex.: Pronto-Socorro, Enfermagem, Farmácia).
create table setor (
    id_setor int not null auto_increment,
    nome varchar(80) not null unique,
    descricao varchar(255),
    primary key (id_setor)
) engine = InnoDB;

-- Cargos dos funcionários. Cada cargo pertence a um setor.
create table cargo (
    id_cargo int not null auto_increment,
    id_setor int not null,
    nome varchar(80) not null,
    descricao varchar(255),
    primary key (id_cargo),
    constraint fk_cargo_setor foreign key (id_setor) references setor (id_setor)
        on delete no action on update no action
) engine = InnoDB;

-- Funcionários do hospital (médicos, enfermeiros, recepcionistas etc.).
create table funcionario (
    id_funcionario int not null auto_increment,
    id_cargo int not null,
    nome varchar(120) not null,
    cpf char(11) not null unique,
    data_nasc date not null,
    sexo char(1) not null,
    registro_profissional varchar(20),
    data_admissao date not null,
    email varchar(120) unique,
    login varchar(50) not null unique,
    senha varchar(255) not null,
    status char(1) not null default 'A',
    primary key (id_funcionario),
    constraint ck_funcionario_sexo check (sexo in ('M', 'F', 'O')),
    constraint ck_funcionario_status check (status in ('A', 'I', 'F')),
    constraint fk_funcionario_cargo foreign key (id_cargo) references cargo (id_cargo)
        on delete no action on update no action
) engine = InnoDB;

-- Marcações de entrada e saída dos funcionários.
create table registro_ponto (
    id_registro_ponto int not null auto_increment,
    id_funcionario int not null,
    data_hora datetime not null default current_timestamp,
    tipo char(1) not null,
    primary key (id_registro_ponto),
    constraint ck_registro_ponto_tipo check (tipo in ('E', 'S')),
    constraint fk_registro_ponto_funcionario foreign key (id_funcionario) references funcionario (id_funcionario)
        on delete no action on update no action
) engine = InnoDB;

-- Permissões de acesso às funções do sistema.
create table permissao (
    id_permissao int not null auto_increment,
    nome varchar(60) not null unique,
    descricao varchar(255),
    primary key (id_permissao)
) engine = InnoDB;

-- Permissões padrão de cada cargo (relação N:N entre cargo e permissão).
create table cargo_permissao (
    id_cargo int not null,
    id_permissao int not null,
    primary key (id_cargo, id_permissao),
    constraint fk_cargo_permissao_cargo foreign key (id_cargo) references cargo (id_cargo)
        on delete no action on update no action,
    constraint fk_cargo_permissao_permissao foreign key (id_permissao) references permissao (id_permissao)
        on delete no action on update no action
) engine = InnoDB;

-- Permissões extras dadas a um funcionário, além das do cargo (relação N:N entre funcionário e permissão).
create table funcionario_permissao (
    id_funcionario int not null,
    id_permissao int not null,
    data_concessao datetime not null default current_timestamp,
    primary key (id_funcionario, id_permissao),
    constraint fk_funcionario_permissao_funcionario foreign key (id_funcionario) references funcionario (id_funcionario)
        on delete no action on update no action,
    constraint fk_funcionario_permissao_permissao foreign key (id_permissao) references permissao (id_permissao)
        on delete no action on update no action
) engine = InnoDB;


-- =====================================================================
-- 4. CONTATO E ENDEREÇO (PACIENTE E FUNCIONÁRIO)
-- =====================================================================

-- Telefones e e-mails do paciente ou do funcionário. Cada contato pertence a apenas um dos dois.
create table contato (
    id_contato int not null auto_increment,
    id_paciente int,
    id_funcionario int,
    tipo char(1) not null,
    valor varchar(120) not null,
    nome_contato varchar(120),
    principal char(1) not null default 'N',
    primary key (id_contato),
    constraint ck_contato_tipo check (tipo in ('C', 'F', 'E')),
    constraint ck_contato_principal check (principal in ('S', 'N')),
    constraint ck_contato_dono check ((id_paciente is not null and id_funcionario is null) or (id_paciente is null and id_funcionario is not null)),
    constraint fk_contato_paciente foreign key (id_paciente) references paciente (id_paciente)
        on delete no action on update no action,
    constraint fk_contato_funcionario foreign key (id_funcionario) references funcionario (id_funcionario)
        on delete no action on update no action
) engine = InnoDB;

-- Endereços do paciente ou do funcionário. Cada endereço pertence a apenas um dos dois.
create table endereco (
    id_endereco int not null auto_increment,
    id_paciente int,
    id_funcionario int,
    cep char(8) not null,
    logradouro varchar(150) not null,
    numero varchar(10) not null,
    complemento varchar(60),
    bairro varchar(80) not null,
    cidade varchar(80) not null,
    uf char(2) not null,
    primary key (id_endereco),
    constraint ck_endereco_dono check ((id_paciente is not null and id_funcionario is null) or (id_paciente is null and id_funcionario is not null)),
    constraint fk_endereco_paciente foreign key (id_paciente) references paciente (id_paciente)
        on delete no action on update no action,
    constraint fk_endereco_funcionario foreign key (id_funcionario) references funcionario (id_funcionario)
        on delete no action on update no action
) engine = InnoDB;


-- =====================================================================
-- 5. ESTRUTURA FÍSICA
-- =====================================================================

-- Locais físicos do hospital (consultórios, salas, enfermarias, UTI).
create table local (
    id_local int not null auto_increment,
    nome varchar(80) not null,
    tipo char(1) not null,
    andar varchar(10),
    primary key (id_local),
    constraint ck_local_tipo check (tipo in ('R', 'T', 'C', 'E', 'X', 'I', 'U'))
) engine = InnoDB;

-- Equipamentos de cada local (monitores, desfibriladores, respiradores etc.).
create table equipamento (
    id_equipamento int not null auto_increment,
    id_local int not null,
    nome varchar(100) not null,
    numero_patrimonio varchar(20) not null unique,
    status char(1) not null default 'D',
    primary key (id_equipamento),
    constraint ck_equipamento_status check (status in ('D', 'U', 'M', 'I')),
    constraint fk_equipamento_local foreign key (id_local) references local (id_local)
        on delete no action on update no action
) engine = InnoDB;

-- Leitos de internação e observação.
create table leito (
    id_leito int not null auto_increment,
    id_local int not null,
    numero varchar(10) not null,
    tipo char(1) not null,
    status char(1) not null default 'L',
    primary key (id_leito),
    constraint uq_leito_local_numero unique (id_local, numero),
    constraint ck_leito_tipo check (tipo in ('E', 'U', 'O', 'I')),
    constraint ck_leito_status check (status in ('L', 'O', 'H', 'M')),
    constraint fk_leito_local foreign key (id_local) references local (id_local)
        on delete no action on update no action
) engine = InnoDB;


-- =====================================================================
-- 6. ATENDIMENTO
-- =====================================================================

-- Etapas possíveis de um atendimento.
create table status_atendimento (
    id_status int not null auto_increment,
    descricao varchar(40) not null unique,
    primary key (id_status)
) engine = InnoDB;

-- Níveis de classificação de risco usados na triagem (Protocolo de Manchester).
create table classificacao_risco (
    id_classificacao int not null auto_increment,
    cor varchar(20) not null unique,
    descricao varchar(60) not null,
    tempo_max_espera smallint not null,
    prioridade tinyint not null,
    primary key (id_classificacao),
    constraint ck_classificacao_risco_tempo_max_espera check (tempo_max_espera between 0 and 480),
    constraint ck_classificacao_risco_prioridade check (prioridade between 1 and 5),
    constraint uq_classificacao_risco_prioridade unique (prioridade)
) engine = InnoDB;

-- Registro central de cada entrada de paciente na emergência.
create table atendimento (
    id_atendimento int not null auto_increment,
    id_paciente int,
    id_cadastro_provisorio int unique,
    id_funcionario int not null,
    id_status int not null,
    id_local int,
    data_hora_entrada datetime not null default current_timestamp,
    tipo_entrada char(1) not null,
    queixa_principal varchar(255) not null,
    primary key (id_atendimento),
    constraint ck_atendimento_tipo_entrada check (tipo_entrada in ('E', 'A', 'B', 'T')),
    constraint ck_atendimento_identificacao check (id_paciente is not null or id_cadastro_provisorio is not null),
    constraint fk_atendimento_paciente foreign key (id_paciente) references paciente (id_paciente)
        on delete no action on update no action,
    constraint fk_atendimento_cadastro_provisorio foreign key (id_cadastro_provisorio) references cadastro_provisorio (id_cadastro_provisorio)
        on delete no action on update no action,
    constraint fk_atendimento_funcionario foreign key (id_funcionario) references funcionario (id_funcionario)
        on delete no action on update no action,
    constraint fk_atendimento_status foreign key (id_status) references status_atendimento (id_status)
        on delete no action on update no action,
    constraint fk_atendimento_local foreign key (id_local) references local (id_local)
        on delete no action on update no action
) engine = InnoDB;

-- Triagem de enfermagem do atendimento (uma por atendimento).
create table triagem (
    id_triagem int not null auto_increment,
    id_atendimento int not null unique,
    id_funcionario int not null,
    id_classificacao int not null,
    data_hora datetime not null default current_timestamp,
    descricao_sintomas varchar(255) not null,
    observacao varchar(255),
    primary key (id_triagem),
    constraint fk_triagem_atendimento foreign key (id_atendimento) references atendimento (id_atendimento)
        on delete no action on update no action,
    constraint fk_triagem_funcionario foreign key (id_funcionario) references funcionario (id_funcionario)
        on delete no action on update no action,
    constraint fk_triagem_classificacao foreign key (id_classificacao) references classificacao_risco (id_classificacao)
        on delete no action on update no action
) engine = InnoDB;

-- Aferições de sinais vitais feitas durante o atendimento.
create table sinais_vitais (
    id_sinais_vitais int not null auto_increment,
    id_atendimento int not null,
    id_funcionario int not null,
    data_hora datetime not null default current_timestamp,
    pressao_sistolica smallint,
    pressao_diastolica smallint,
    frequencia_cardiaca smallint,
    frequencia_respiratoria tinyint,
    temperatura decimal(4,1),
    saturacao_o2 tinyint,
    glicemia smallint,
    escala_dor tinyint,
    primary key (id_sinais_vitais),
    constraint ck_sinais_vitais_pressao_sistolica check (pressao_sistolica between 40 and 300),
    constraint ck_sinais_vitais_pressao_diastolica check (pressao_diastolica between 20 and 200),
    constraint ck_sinais_vitais_frequencia_cardiaca check (frequencia_cardiaca between 20 and 250),
    constraint ck_sinais_vitais_frequencia_respiratoria check (frequencia_respiratoria between 5 and 80),
    constraint ck_sinais_vitais_temperatura check (temperatura between 30 and 45),
    constraint ck_sinais_vitais_saturacao_o2 check (saturacao_o2 between 50 and 100),
    constraint ck_sinais_vitais_glicemia check (glicemia between 20 and 800),
    constraint ck_sinais_vitais_escala_dor check (escala_dor between 0 and 10),
    constraint fk_sinais_vitais_atendimento foreign key (id_atendimento) references atendimento (id_atendimento)
        on delete no action on update no action,
    constraint fk_sinais_vitais_funcionario foreign key (id_funcionario) references funcionario (id_funcionario)
        on delete no action on update no action
) engine = InnoDB;


-- =====================================================================
-- 7. SOLICITAÇÕES, EXAMES E ESTOQUE
-- =====================================================================

-- Catálogo de procedimentos que podem ser solicitados (ex.: sutura, curativo).
create table procedimento (
    id_procedimento int not null auto_increment,
    codigo varchar(10) unique,
    nome varchar(150) not null,
    descricao varchar(255),
    valor decimal(10,2),
    primary key (id_procedimento),
    constraint ck_procedimento_valor check (valor >= 0)
) engine = InnoDB;

-- Categorias de exame (ex.: Laboratorial, Imagem, Cardiológico).
create table tipo_exame (
    id_tipo_exame int not null auto_increment,
    nome varchar(60) not null unique,
    primary key (id_tipo_exame)
) engine = InnoDB;

-- Catálogo de exames que podem ser solicitados (ex.: Hemograma, Raio-X de tórax).
create table exame (
    id_exame int not null auto_increment,
    id_tipo_exame int not null,
    nome varchar(120) not null unique,
    preparo varchar(255),
    prazo_resultado smallint,
    primary key (id_exame),
    constraint ck_exame_prazo_resultado check (prazo_resultado between 0 and 720),
    constraint fk_exame_tipo_exame foreign key (id_tipo_exame) references tipo_exame (id_tipo_exame)
        on delete no action on update no action
) engine = InnoDB;

-- Catálogo de medicamentos e materiais usados nos atendimentos.
create table insumo (
    id_insumo int not null auto_increment,
    nome varchar(120) not null,
    tipo char(1) not null,
    unidade_medida varchar(20) not null,
    estoque_minimo int not null default 0,
    primary key (id_insumo),
    constraint ck_insumo_tipo check (tipo in ('M', 'T')),
    constraint ck_insumo_estoque_minimo check (estoque_minimo >= 0)
) engine = InnoDB;

-- Locais de armazenamento de insumos (ex.: Farmácia central, Almoxarifado). O saldo de cada insumo é calculado pelas movimentações.
create table estoque (
    id_estoque int not null auto_increment,
    nome varchar(80) not null unique,
    descricao varchar(255),
    primary key (id_estoque)
) engine = InnoDB;

-- Pedidos feitos pelo médico durante o atendimento. Cada solicitação pede um único item: um procedimento, um exame ou um insumo.
create table solicitacao (
    id_solicitacao int not null auto_increment,
    id_atendimento int not null,
    id_funcionario int not null,
    tipo char(1) not null,
    id_procedimento int,
    id_exame int,
    id_insumo int,
    quantidade smallint not null default 1,
    prioridade char(1) not null default 'N',
    status char(1) not null default 'P',
    data_hora datetime not null default current_timestamp,
    observacao varchar(255),
    primary key (id_solicitacao),
    constraint ck_solicitacao_tipo check (tipo in ('P', 'E', 'I')),
    constraint ck_solicitacao_quantidade check (quantidade >= 1),
    constraint ck_solicitacao_prioridade check (prioridade in ('N', 'U')),
    constraint ck_solicitacao_status check (status in ('P', 'E', 'R', 'C')),
    constraint ck_solicitacao_item check ((tipo = 'P' and id_procedimento is not null and id_exame is null and id_insumo is null) or (tipo = 'E' and id_exame is not null and id_procedimento is null and id_insumo is null) or (tipo = 'I' and id_insumo is not null and id_procedimento is null and id_exame is null)),
    constraint fk_solicitacao_atendimento foreign key (id_atendimento) references atendimento (id_atendimento)
        on delete no action on update no action,
    constraint fk_solicitacao_funcionario foreign key (id_funcionario) references funcionario (id_funcionario)
        on delete no action on update no action,
    constraint fk_solicitacao_procedimento foreign key (id_procedimento) references procedimento (id_procedimento)
        on delete no action on update no action,
    constraint fk_solicitacao_exame foreign key (id_exame) references exame (id_exame)
        on delete no action on update no action,
    constraint fk_solicitacao_insumo foreign key (id_insumo) references insumo (id_insumo)
        on delete no action on update no action
) engine = InnoDB;

-- Resultado (laudo) dos exames solicitados. Fica ligado à solicitação, pois a tabela EXAME é o catálogo de exames.
create table resultado_exame (
    id_resultado int not null auto_increment,
    id_solicitacao int not null unique,
    id_funcionario int not null,
    data_hora_coleta datetime,
    data_hora_resultado datetime not null default current_timestamp,
    resultado text not null,
    arquivo_laudo varchar(255),
    situacao char(1) not null,
    primary key (id_resultado),
    constraint ck_resultado_exame_situacao check (situacao in ('N', 'A', 'C')),
    constraint fk_resultado_exame_solicitacao foreign key (id_solicitacao) references solicitacao (id_solicitacao)
        on delete no action on update no action,
    constraint fk_resultado_exame_funcionario foreign key (id_funcionario) references funcionario (id_funcionario)
        on delete no action on update no action
) engine = InnoDB;

-- Entradas e saídas de insumos em cada estoque.
create table movimentacao_estoque (
    id_movimentacao int not null auto_increment,
    id_insumo int not null,
    id_estoque int not null,
    id_funcionario int not null,
    id_solicitacao int,
    tipo char(1) not null,
    quantidade int not null,
    lote varchar(30),
    data_validade date,
    data_hora datetime not null default current_timestamp,
    primary key (id_movimentacao),
    constraint ck_movimentacao_estoque_tipo check (tipo in ('E', 'S', 'A')),
    constraint ck_movimentacao_estoque_quantidade check (quantidade >= 1),
    constraint fk_movimentacao_estoque_insumo foreign key (id_insumo) references insumo (id_insumo)
        on delete no action on update no action,
    constraint fk_movimentacao_estoque_estoque foreign key (id_estoque) references estoque (id_estoque)
        on delete no action on update no action,
    constraint fk_movimentacao_estoque_funcionario foreign key (id_funcionario) references funcionario (id_funcionario)
        on delete no action on update no action,
    constraint fk_movimentacao_estoque_solicitacao foreign key (id_solicitacao) references solicitacao (id_solicitacao)
        on delete no action on update no action
) engine = InnoDB;


-- =====================================================================
-- 8. INTERNAÇÃO E ALTA
-- =====================================================================

-- Internação do paciente a partir do atendimento (no máximo uma por atendimento).
create table internacao (
    id_internacao int not null auto_increment,
    id_atendimento int not null unique,
    id_funcionario int not null,
    data_hora_entrada datetime not null default current_timestamp,
    data_hora_saida datetime,
    motivo varchar(255) not null,
    tipo char(1) not null,
    status char(1) not null default 'A',
    primary key (id_internacao),
    constraint ck_internacao_tipo check (tipo in ('C', 'R', 'U')),
    constraint ck_internacao_status check (status in ('A', 'E')),
    constraint ck_internacao_datas check (data_hora_saida is null or data_hora_saida >= data_hora_entrada),
    constraint fk_internacao_atendimento foreign key (id_atendimento) references atendimento (id_atendimento)
        on delete no action on update no action,
    constraint fk_internacao_funcionario foreign key (id_funcionario) references funcionario (id_funcionario)
        on delete no action on update no action
) engine = InnoDB;

-- Histórico de leitos ocupados em cada internação.
create table ocupacao (
    id_ocupacao int not null auto_increment,
    id_internacao int not null,
    id_leito int not null,
    data_hora_entrada datetime not null default current_timestamp,
    data_hora_saida datetime,
    primary key (id_ocupacao),
    constraint ck_ocupacao_datas check (data_hora_saida is null or data_hora_saida >= data_hora_entrada),
    constraint fk_ocupacao_internacao foreign key (id_internacao) references internacao (id_internacao)
        on delete no action on update no action,
    constraint fk_ocupacao_leito foreign key (id_leito) references leito (id_leito)
        on delete no action on update no action
) engine = InnoDB;

-- Transferências do paciente internado para outro setor ou outro hospital.
create table transferencia (
    id_transferencia int not null auto_increment,
    id_internacao int not null,
    id_funcionario int not null,
    tipo char(1) not null,
    destino varchar(150) not null,
    motivo varchar(255) not null,
    data_hora datetime not null default current_timestamp,
    primary key (id_transferencia),
    constraint ck_transferencia_tipo check (tipo in ('I', 'E')),
    constraint fk_transferencia_internacao foreign key (id_internacao) references internacao (id_internacao)
        on delete no action on update no action,
    constraint fk_transferencia_funcionario foreign key (id_funcionario) references funcionario (id_funcionario)
        on delete no action on update no action
) engine = InnoDB;

-- Encerramento do atendimento (uma alta por atendimento).
create table alta (
    id_alta int not null auto_increment,
    id_atendimento int not null unique,
    id_funcionario int not null,
    data_hora datetime not null default current_timestamp,
    tipo char(1) not null,
    cid_final varchar(10),
    orientacoes text,
    primary key (id_alta),
    constraint ck_alta_tipo check (tipo in ('M', 'P', 'T', 'O', 'E')),
    constraint fk_alta_atendimento foreign key (id_atendimento) references atendimento (id_atendimento)
        on delete no action on update no action,
    constraint fk_alta_funcionario foreign key (id_funcionario) references funcionario (id_funcionario)
        on delete no action on update no action
) engine = InnoDB;


-- Conferência: lista as tabelas criadas
show tables;
