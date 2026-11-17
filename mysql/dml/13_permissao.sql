use gestao_emergencia_hospitalar;
set names utf8mb4;

insert into permissao (id_permissao, nome, descricao) values
(1, 'ABRIR_ATENDIMENTO', 'Registrar a entrada do paciente no pronto-socorro'),
(2, 'CADASTRAR_PACIENTE', 'Incluir e alterar o cadastro definitivo de pacientes'),
(3, 'CADASTRO_PROVISORIO', 'Criar cadastro provisório para paciente sem identificação e vincular ao cadastro definitivo'),
(4, 'REALIZAR_TRIAGEM', 'Registrar a triagem e a classificação de risco (Protocolo de Manchester)'),
(5, 'REGISTRAR_SINAIS_VITAIS', 'Registrar aferições de sinais vitais'),
(6, 'VER_HISTORICO_CLINICO', 'Consultar doenças, cirurgias, alergias e contraindicações do paciente'),
(7, 'EDITAR_HISTORICO_CLINICO', 'Incluir e alterar informações do histórico clínico'),
(8, 'SOLICITAR_EXAME', 'Solicitar exames laboratoriais, de imagem e cardiológicos'),
(9, 'SOLICITAR_PROCEDIMENTO', 'Solicitar procedimentos'),
(10, 'PRESCREVER_INSUMO', 'Prescrever medicamentos e materiais'),
(11, 'CANCELAR_SOLICITACAO', 'Cancelar solicitações pendentes'),
(12, 'LIBERAR_LAUDO', 'Registrar e liberar o resultado de exames'),
(13, 'INTERNAR_PACIENTE', 'Abrir internação a partir do atendimento'),
(14, 'TRANSFERIR_PACIENTE', 'Registrar transferências internas e externas'),
(15, 'DAR_ALTA', 'Encerrar o atendimento com registro de alta'),
(16, 'GERENCIAR_LEITOS', 'Alocar pacientes em leitos e alterar a situação dos leitos'),
(17, 'DISPENSAR_INSUMO', 'Dispensar medicamentos e materiais solicitados'),
(18, 'MOVIMENTAR_ESTOQUE', 'Registrar entradas, saídas e ajustes de estoque'),
(19, 'CONSULTAR_ESTOQUE', 'Consultar o saldo de insumos nos estoques'),
(20, 'GERENCIAR_EQUIPAMENTOS', 'Cadastrar equipamentos e alterar sua situação'),
(21, 'GERENCIAR_FUNCIONARIOS', 'Cadastrar funcionários, cargos e setores'),
(22, 'GERENCIAR_PERMISSOES', 'Conceder e revogar permissões de acesso'),
(23, 'EMITIR_RELATORIOS', 'Emitir relatórios gerenciais e indicadores'),
(24, 'VER_PAINEL_ATENDIMENTO', 'Visualizar o painel de pacientes em atendimento'),
(25, 'REGISTRAR_PONTO', 'Registrar marcações de entrada e saída');

select * from permissao;
