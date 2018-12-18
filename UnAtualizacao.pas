Unit UnAtualizacao;

interface
  Uses Classes, DbTables,SysUtils;

Type
  TAtualiza = Class
    Private
      Aux : TQuery;
      DataBase : TDataBase;
      procedure AtualizaSenha( Senha : string );
      procedure AlteraVersoesSistemas;
    public
      function AtualizaTabela(VpaNumAtualizacao : Integer) : Boolean;
      function AtualizaBanco : Boolean;
      constructor criar( aowner : TComponent; ADataBase : TDataBase );
end;

Const
  CT_SenhaAtual = '9774';

implementation

Uses FunSql, ConstMsg, FunNumeros, Registry, Constantes, FunString, funvalida, AAtualizaSistema;

{*************************** cria a classe ************************************}
constructor TAtualiza.criar( aowner : TComponent; ADataBase : TDataBase );
begin
  inherited Create;
  Aux := TQuery.Create(aowner);
  DataBase := ADataBase;
  Aux.DataBaseName := 'BaseDados';
end;

{*************** atualiza senha na base de dados ***************************** }
procedure TAtualiza.AtualizaSenha( Senha : string );
var
  ini : TRegIniFile;
  senhaInicial : string;
begin
  try
    if not DataBase.InTransaction then
      DataBase.StartTransaction;

    // atualiza regedit
    Ini := TRegIniFile.Create('Software\Systec\Sistema');
    senhaInicial := Ini.ReadString('SENHAS','BANCODADOS', '');  // guarda senha do banco
    Ini.WriteString('SENHAS','BANCODADOS', Criptografa(senha));  // carrega senha do banco


   // atualiza base de dados
    LimpaSQLTabela(aux);
    AdicionaSQLTabela(Aux, 'grant connect, to DBA identified by ''' + senha + '''');
    Aux.ExecSQL;

    if DataBase.InTransaction then
      DataBase.commit;
    ini.free;
   except
    if DataBase.InTransaction then
      DataBase.Rollback;
    Ini.WriteString('SENHAS','BANCODADOS', senhaInicial);
    ini.free;
  end;
end;

{*********************** atualiza o banco de dados ****************************}
function TAtualiza.AtualizaBanco : Boolean;
begin
  result := true;
  AdicionaSQLAbreTabela(Aux,'Select I_Ult_Alt from Cfg_Geral ');
  if Aux.FieldByName('I_Ult_Alt').AsInteger < CT_VersaoBanco Then
    result := AtualizaTabela(Aux.FieldByName('I_Ult_Alt').AsInteger);
  AlteraVersoesSistemas;
end;

{**************************** atualiza a tabela *******************************}
function TAtualiza.AtualizaTabela(VpaNumAtualizacao : Integer)  : Boolean;
var
  VpfErro : String;
begin
  result := true;
  repeat
    Try
      if VpaNumAtualizacao < 105 Then
      begin
        VpfErro := '105';
        ExecutaComandoSql(Aux,'alter table cadformularios'
                            +'  add C_MOD_TRX CHAR(1) NULL ');
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 105');
        ExecutaComandoSql(Aux,'comment on column cadformularios.C_MOD_TRX is ''MODULO DE TRANSFERECIA''');
      end;

      if VpaNumAtualizacao < 106 Then
      begin
        VpfErro := '106';
        ExecutaComandoSql(Aux,'alter table cadusuarios'
                            +'    add C_MOD_REL char(1) null ');
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 106');
        ExecutaComandoSql(Aux,'comment on column cadusuarios.c_mod_rel is ''PERMITE CONSULTAR O MODULO DE RELATORIOS''');
      end;

      if VpaNumAtualizacao < 107 Then
      begin
        VpfErro := '107';
        ExecutaComandoSql(Aux,'alter table cadformularios'
                            +'    add C_MOD_REL char(1) null ');
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 107');
        ExecutaComandoSql(Aux,'comment on column cadformularios.c_mod_rel is ''cadastros de relatorios''');
      end;

      if VpaNumAtualizacao < 108 Then
      begin
        VpfErro := '108';
        ExecutaComandoSql(Aux,'alter table cfg_geral'
                            +'    add C_MOD_REL char(10) null ');
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 108');
        ExecutaComandoSql(Aux,'comment on column CFG_GERAL.C_MOD_REL is ''VERSAO DO MODULO DE RALATORIO''');
      end;

      if VpaNumAtualizacao < 109 Then
      begin
        VpfErro := '109';
        ExecutaComandoSql(Aux,' alter table cfg_geral'
                            +'    ADD I_DIA_VAL integer NULL, '
                            +'    ADD I_TIP_BAS integer NULL; '
                            +' update cfg_geral set i_tip_bas = 1');
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 109');
        ExecutaComandoSql(Aux,'comment on column cfg_geral.I_DIA_VAL is ''DIAS DE VALIDADE DA BASE DEMO''');
        ExecutaComandoSql(Aux,'comment on column cfg_geral.I_TIP_BAS is ''TIPO DA BASE DEMO OU OFICIAL 0 OFICIAL 1 DEMO''');
      end;

      if VpaNumAtualizacao < 110 Then
      begin
        VpfErro := '110';
        ExecutaComandoSql(Aux,'alter table cfg_financeiro'
                            +'  add I_FRM_CAR INTEGER NULL ');
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 110');
        ExecutaComandoSql(Aux,'comment on column cfg_financeiro.I_FRM_CAR is ''FORMA DE PAGAMENTO EM CARTEIRA''');
      end;

      if VpaNumAtualizacao < 111 Then
      begin
        VpfErro := '111';
        ExecutaComandoSql(Aux,' create table MOVFORMAS'
                            +'  ( I_EMP_FIL INTEGER NOT NULL, '
                            +'   I_SEQ_MOV INTEGER NOT NULL, '
                            +'   I_NRO_LOT INTEGER NULL, '
                            +'   I_LAN_REC INTEGER NULL, '
                            +'   I_LAN_APG INTEGER NULL, '
                            +'   I_COD_FRM INTEGER NULL, '
                            +'   C_NRO_CHE CHAR(20) NULL, '
                            +'   N_VLR_MOV NUMERIC(17,3) NULL, '
                            +'   C_NRO_CON CHAR(13) NULL, '
                            +'   C_NRO_BOL CHAR(20) NULL, '
                            +'   C_NOM_CHE CHAR(50) NULL, '
                            +'  PRIMARY KEY(I_EMP_FIL, I_SEQ_MOV)) ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 111');
        ExecutaComandoSql(Aux,'comment on column movformas.I_EMP_FIL is ''CODIGO DA FILIAL''');
        ExecutaComandoSql(Aux,'comment on column movformas.I_SEQ_MOV is ''SEQUENCIAL DO MOVIMENTO''');
        ExecutaComandoSql(Aux,'comment on column movformas.I_NRO_LOT is ''NUMERO DO LOTE''');
        ExecutaComandoSql(Aux,'comment on column movformas.I_LAN_REC is ''LANCAMENTO DO CONTAS A RECEBER''');
        ExecutaComandoSql(Aux,'comment on column movformas.I_LAN_APG is ''LANCAMENTO DO CONTAS A PAGAR''');
        ExecutaComandoSql(Aux,'comment on column movformas.I_COD_FRM is ''CODIGO DA FORMA DE PAGAMENTO''');
        ExecutaComandoSql(Aux,'comment on column movformas.C_NRO_CHE is ''NUMERO DO CHEQUE''');
        ExecutaComandoSql(Aux,'comment on column movformas.N_VLR_MOV is ''VALOR DO MOVIMENTO''');
        ExecutaComandoSql(Aux,'comment on column movformas.C_NRO_CON is ''NUMERO DA CONTA''');
        ExecutaComandoSql(Aux,'comment on column movformas.C_NRO_BOL is ''NUMERO DO BOLETO''');
        ExecutaComandoSql(Aux,'comment on column movformas.C_NOM_CHE is ''NOMINAL DO CHEQUE''');
      end;

      if VpaNumAtualizacao < 112 Then
      begin
        VpfErro := '112';
        ExecutaComandoSql(Aux,'create unique index MOVFORMAS_pk on'
                            +'  MOVFORMAS(I_EMP_FIL, I_SEQ_MOV ASC)  ');
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 112');
      end;

      if VpaNumAtualizacao < 113 Then
      begin
        VpfErro := '113';
        ExecutaComandoSql(Aux,'create table CADHISTORICOCLIENTE'
                            +'  ( I_COD_HIS INTEGER NOT NULL, '
                            +'    C_DES_HIS char(40) NULL, '
                            +'    D_ULT_ALT DATE NULL, '
                            +'    PRIMARY KEY(I_COD_HIS) ) ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 113');
        ExecutaComandoSql(Aux,'comment on table CADHISTORICOCLIENTE is ''TABELA DO HISTORICO DO CLIENTE''');
        ExecutaComandoSql(Aux,'comment on column CADHISTORICOCLIENTE.I_COD_HIS is ''CODIGO HISTORICO CLIENTE''');
        ExecutaComandoSql(Aux,'comment on column CADHISTORICOCLIENTE.C_DES_HIS is ''DESCRICAO DO HISTORICO DO CLIENTE''');
      end;

      if VpaNumAtualizacao < 114 Then
      begin
        VpfErro := '114';
        ExecutaComandoSql(Aux,'create table MOVHISTORICOCLIENTE'
                            +'  ( I_SEQ_HIS INTEGER NOT NULL, '
                            +'    I_COD_HIS INTEGER NULL, '
                            +'    I_COD_CLI INTEGER NULL, '
                            +'    I_COD_USU INTEGER NULL, '
                            +'    D_DAT_HIS  DATE  NULL, '
                            +'    L_HIS_CLI LONG VARCHAR NULL, '
                            +'    D_DAT_AGE  DATE NULL, '
                            +'    L_HIS_AGE LONG VARCHAR NULL, '
                            +'    D_ULT_ALT DATE NULL, '
                            +'    PRIMARY KEY(I_SEQ_HIS) ) ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 114');
        ExecutaComandoSql(Aux,'comment on table MOVHISTORICOCLIENTE is ''TABELA DO HISTORICO DO CLIENTE''');
        ExecutaComandoSql(Aux,'comment on column MOVHISTORICOCLIENTE.I_SEQ_HIS is ''SEQUENCIAL DO MOV HISTORICO''');
        ExecutaComandoSql(Aux,'comment on column MOVHISTORICOCLIENTE.I_COD_HIS is ''CODIGO HISTORICO''');
        ExecutaComandoSql(Aux,'comment on column MOVHISTORICOCLIENTE.I_COD_CLI is ''CODIGO DO CLIENTE''');
        ExecutaComandoSql(Aux,'comment on column MOVHISTORICOCLIENTE.D_DAT_HIS is ''DATA DO HISTORICO''');
        ExecutaComandoSql(Aux,'comment on column MOVHISTORICOCLIENTE.L_HIS_CLI is ''HISTORICO DO CLIENTE''');
        ExecutaComandoSql(Aux,'comment on column MOVHISTORICOCLIENTE.D_DAT_AGE is ''DATA DA AGENDA DO CLIENTE''');
        ExecutaComandoSql(Aux,'comment on column MOVHISTORICOCLIENTE.L_HIS_AGE is ''HISTORICO DA AGENDA''');
      end;

      if VpaNumAtualizacao < 115 Then
      begin
        VpfErro := '115';
        ExecutaComandoSql(Aux,' alter table MOVHISTORICOCLIENTE '
                            +'  add foreign key CADHISTORICOCLIENTE_FK(I_COD_HIS)  '
                            +'  references CADHISTORICOCLIENTE(I_COD_HIS)  '
                            +'  on update restrict on delete restrict ');
        ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 115');
      end;

      if VpaNumAtualizacao < 116 Then
      begin
        VpfErro := '116';
        ExecutaComandoSql(Aux,' alter table MOVHISTORICOCLIENTE '
                            +'  add foreign key CADCLIENTE_FK101(I_COD_CLI)  '
                            +'  references CADCLIENTES(I_COD_CLI)  '
                            +'  on update restrict on delete restrict ');
        ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 116');
      end;

      if VpaNumAtualizacao < 117 Then
      begin
        VpfErro := '117';
        ExecutaComandoSql(Aux,'alter table cfg_geral'
                            +'    add L_ATU_IGN long varchar null; '
                            +'  update cfg_geral '
                            +'    set L_ATU_IGN = null; ');
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 117');
        ExecutaComandoSql(Aux,'comment on column cfg_geral.L_ATU_IGN is ''ATUALIZACOES IGNORADAS''');
      end;

      if VpaNumAtualizacao < 118 Then
      begin
        VpfErro := '118';
        ExecutaComandoSql(Aux,' alter table movhistoricocliente '
                            +'  add H_HOR_AGE TIME NULL ');
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 118');
        ExecutaComandoSql(Aux,'comment on column movhistoricocliente.H_HOR_AGE is ''HORA AGENDADA''');
      end;

      if VpaNumAtualizacao < 119 Then
      begin
        VpfErro := '119';
        ExecutaComandoSql(Aux,' alter table movhistoricocliente '
                            +'  add C_SIT_AGE char(1) NULL ');
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 119');
        ExecutaComandoSql(Aux,'comment on column movhistoricocliente.H_HOR_AGE is ''HORA AGENDADA''');
      end;

      if VpaNumAtualizacao < 120 Then
      begin
        VpfErro := '120';
        ExecutaComandoSql(Aux,' alter table movhistoricocliente '
                            +'  add H_HOR_HIS TIME NULL  ');
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 120');
        ExecutaComandoSql(Aux,'comment on column movhistoricocliente.H_HOR_HIS is ''HORA HISTORICO''');
      end;

      if VpaNumAtualizacao < 121 Then
      begin
        VpfErro := '121';
        ExecutaComandoSql(Aux,' alter table movcontasareceber '
                            +'  add N_VLR_CHE numeric(17,3) NULL, '
                            +'  add C_CON_CHE char(15) NULL      ');
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 121');
        ExecutaComandoSql(Aux,'comment on column movcontasareceber.N_VLR_CHE is ''VALOR DO CHEQUE''');
        ExecutaComandoSql(Aux,'comment on column movcontasareceber.C_CON_CHE is ''CONTA DO CHEQUE''');
      end;

      if VpaNumAtualizacao < 122 Then
      begin
        VpfErro := '122';
        ExecutaComandoSql(Aux,'create table CADCODIGO'
                            +'   ( I_EMP_FIL INTEGER NULL, '
                            +'     I_LAN_REC INTEGER NULL, '
                            +'     I_LAN_APG INTEGER NULL, '
                            +'     I_LAN_EST INTEGER NULL, '
                            +'     I_LAN_BAC INTEGER NULL, '
                            +'     I_LAN_CON INTEGER NULL ) ');
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 122');
      end;

      if VpaNumAtualizacao < 123 Then
      begin
        VpfErro := '123';
        ExecutaComandoSql(Aux,'alter table cfg_modulo'
                            +' add FLA_MALACLIENTE CHAR(1) NULL, '
                            +' add FLA_AGENDACLIENTE CHAR(1) NULL, '
                            +' add FLA_PEDIDO CHAR(1) NULL, '
                            +' add FLA_ORDEMSERVICO CHAR(1) NULL ' );
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 123');
      end;

      if VpaNumAtualizacao < 124 Then
      begin
        VpfErro := '124';
        ExecutaComandoSql(Aux,'alter table cadorcamentos'
                            +' add I_NRO_PED integer NULL, '
                            +' add I_NRO_ORC integer NULL, '
                            +' add C_TIP_CAD char(1) NULL, '
                            +' add I_PRA_ENT integer NULL ');
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 124');
      end;

      if VpaNumAtualizacao < 125 Then
      begin
        VpfErro := '125';
        ExecutaComandoSql(Aux,
                             ' update cadorcamentos ' +
                             ' set i_nro_orc = i_lan_orc , ' +
                             ' i_nro_ped = i_lan_orc ' );
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 125');
      end;

      if VpaNumAtualizacao < 126 Then
      begin
        VpfErro := '126';
        ExecutaComandoSql(Aux,
                               '  create index FK_CADORCAMENTOS_5586 on '
                              +'  CadOrcamentos( I_NRO_PED ASC ); '
                              +'  create index FK_CADORCAMENTOS_5590 on '
                              +'  CadOrcamentos( I_NRO_ORC ASC ); ');
           ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 126');
      end;

      if VpaNumAtualizacao < 127 Then
      begin
        VpfErro := '127';
        ExecutaComandoSql(Aux,
                             ' update cadorcamentos ' +
                             ' set C_TIP_CAD = ''O'' ' );
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 127');
      end;


      if VpaNumAtualizacao < 128 Then
      begin
        VpfErro := '128';
        ExecutaComandoSql(Aux,

        //   Table: CADMARCAS
        ' create table CADMARCAS ' +
        ' ( ' +
        '     I_COD_MAR  integer               not null, ' +
        '     C_NOM_MAR  char(50)              not null, ' +
        '     D_ULT_ALT  date                      null, ' +
        '     primary key (I_COD_MAR) ' +
        ' ); ' +

        ' comment on table CADMARCAS is ''CADMARCAS''; ' +
        ' comment on column CADMARCAS.I_COD_MAR is ''CODIGO DA MARCA''; ' +
        ' comment on column CADMARCAS.C_NOM_MAR is ''NOME DA MARCA''; ' +
        ' comment on column CADMARCAS.D_ULT_ALT is ''DATA DA ULTIMA ALTERACAO''; ' +

        //   Table: CADCOR
        ' create table CADCOR ' +
        ' ( ' +
        '     I_COD_COR  integer               not null, ' +
        '     C_NOM_COR  char(30)              not null, ' +
        '     D_ULT_ALT  date                      null, ' +
        '     primary key (I_COD_COR) ' +
        ' ); ' +

        ' comment on table CADCOR is ''CADCOR''; ' +
        ' comment on column CADCOR.I_COD_COR is ''CODIGO DA COR''; ' +
        ' comment on column CADCOR.C_NOM_COR is ''NOME DA COR''; ' +
        ' comment on column CADCOR.D_ULT_ALT is ''DATA DA ULTIMA ALTERACAO''; ' +


        //   Table: CADMODELO
        ' create table CADMODELO ' +
        ' ( ' +
        '     I_COD_MOD  integer               not null, ' +
        '     C_NOM_MOD  char(50)                  null, ' +
        '     D_ULT_ALT  date                      null, ' +
        '     primary key (I_COD_MOD) ' +
        ' ); ' +

        ' comment on table CADMODELO is ''MODELOS''; ' +
        ' comment on column CADMODELO.I_COD_MOD is ''CODIGO DO MODELO''; ' +
        ' comment on column CADMODELO.C_NOM_MOD is ''NOME DO MODELO''; ' +
        ' comment on column CADMODELO.D_ULT_ALT is ''DATA DA ULTIMA ALTERACAO''; ' +

        //   Table: CADTIPO
        ' create table CADTIPO ' +
        ' ( ' +
        '     I_COD_TIP  integer               not null, ' +
        '     C_NOM_TIP  char(30)              not null, ' +
        '     D_ULT_ALT  date                      null, ' +
        '     primary key (I_COD_TIP) ' +
        ' ); ' +

        ' comment on table CADTIPO is ''TIPOS DE EQUIPAMENTO OS''; ' +
        ' comment on column CADTIPO.I_COD_TIP is ''CODIGO DO TIPO''; ' +
        ' comment on column CADTIPO.C_NOM_TIP is ''NOME DO TIPO''; ' +
        ' comment on column CADTIPO.D_ULT_ALT is ''DATA DA ULTIMA ALTERACAO''; ' );
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 128');
      end;

      if VpaNumAtualizacao < 129 Then
      begin
        VpfErro := '129';
        aux.sql.clear;
        aux.sql.add(
//        ExecutaComandoSql(Aux,

        //   Table: CADORDEMSERVICO
        ' create table CADORDEMSERVICO ' +
        ' ( ' +
        '     I_EMP_FIL  integer               not null, ' +
        '     I_COD_ORS  integer               not null, ' +
        '     I_COD_SIT  integer                   null, ' +
        '     I_COD_CLI  integer                   null, ' +
        '     I_SEQ_PRO  integer                   null, ' +
        '     D_DAT_CAD  date                      null, ' +
        '     D_DAT_AGE  date                      null, ' +
        '     H_HOR_AGE  time                      null, ' +
        '     C_CLI_PRO  varchar(60)               null, ' +
        '     C_OBS_EQU  varchar(250)              null, ' +
        '     N_TEM_GAS  numeric(17,3)             null, ' +
        '     N_VLR_HOR  numeric(17,3)             null, ' +
        '     I_COD_FRM  integer                   null, ' +
        '     I_COD_PAG  integer                   null, ' +
        '     D_DAT_FEC  date                      null, ' +
        '     C_CLI_REC  char(40)                  null, ' +
        '     D_DAT_EMP  date                      null, ' +
        '     D_DAT_DEV  date                      null, ' +
        '     primary key (I_EMP_FIL, I_COD_ORS) ' +
        ' ); ' +

        ' comment on table CADORDEMSERVICO is ''ORDEM DE SERVICO''; ' +
        ' comment on column CADORDEMSERVICO.I_EMP_FIL is ''EMPRESA FILIAL''; ' +
        ' comment on column CADORDEMSERVICO.I_COD_ORS is ''CODIGO DA ORDEM DE SERVICO''; ' +
        ' comment on column CADORDEMSERVICO.I_COD_SIT is ''CODIGO DA SITUACAO''; ' +
        ' comment on column CADORDEMSERVICO.I_COD_CLI is ''CODIGO DO CLIENTE''; ' +
        ' comment on column CADORDEMSERVICO.I_SEQ_PRO is ''CODIGO DO PRODUTO, PARA EMPRESTIMO''; ' +
        ' comment on column CADORDEMSERVICO.D_DAT_CAD is ''DATA DE CADASTRO''; ' +
        ' comment on column CADORDEMSERVICO.D_DAT_AGE is ''DATA DE AGENDA PARA VISITA''; ' +
        ' comment on column CADORDEMSERVICO.H_HOR_AGE is ''HORA DE AGENDA PARA VISITA''; ' +
        ' comment on column CADORDEMSERVICO.C_CLI_PRO is ''ENDERECO DO CLIENTE PROXIMA A..''; ' +
        ' comment on column CADORDEMSERVICO.C_OBS_EQU is ''OBSERVACAO GERAL DO CAD''; ' +
        ' comment on column CADORDEMSERVICO.N_TEM_GAS is ''TEMPO GASTO PARA O OS''; ' +
        ' comment on column CADORDEMSERVICO.N_VLR_HOR is ''VALOR HORA''; ' +
        ' comment on column CADORDEMSERVICO.I_COD_FRM is ''CODIGO DA FORMA DE PAGAMENTO''; ' +
        ' comment on column CADORDEMSERVICO.I_COD_PAG is ''CODIGO DA CONDICAO DE PAGAMENTO''; ' +
        ' comment on column CADORDEMSERVICO.D_DAT_FEC is ''DATA DE FECHAMENTO DA OS, ENTREGA''; ' +
        ' comment on column CADORDEMSERVICO.C_CLI_REC is ''PESSOA QUE RECEBEU O EQUIPAMENTO''; ' +
        ' comment on column CADORDEMSERVICO.D_DAT_EMP is ''DATA DO EMPRESTIMO''; ' +
        ' comment on column CADORDEMSERVICO.D_DAT_DEV is ''DATA DA DEVOLUCAO''; ' );
      aux.ExecSQL;
      ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 129');
      end;

      if VpaNumAtualizacao < 130 Then
      begin
        VpfErro := '130';
        ExecutaComandoSql(Aux,

        //   Table: MOVORDEMSERVICO
        ' create table MOVORDEMSERVICO ' +
        ' ( ' +
        '     I_EMP_FIL  integer                  not null, ' +
        '     I_COD_ORS  integer                  not null, ' +
        '     I_SEQ_MOV  integer                  not null, ' +
        '     I_SEQ_PRO  integer                      null, ' +
        '     I_COD_EMP  integer                      null, ' +
        '     I_COD_SER  integer                      null, ' +
        '     I_COD_USU  integer                      null, ' +
        '     N_QTD_MOV  numeric(17,3)                null, ' +
        '     N_VLR_UNI  numeric(17,3)                null, ' +
        '     N_VLR_TOT  numeric(17,3)                null, ' +
        '     C_COD_UNI  char(2)                      null, ' +
        '     L_OBS_MOV  long varchar null, ' +
        '     primary key (I_EMP_FIL, I_COD_ORS, I_SEQ_MOV ) ' +
        ' ); ' +

       ' comment on table MOVORDEMSERVICO is ''ORDEM SERVICO''; ' +
        ' comment on column MOVORDEMSERVICO.I_EMP_FIL is ''EMPRESA FILIAL''; ' +
        ' comment on column MOVORDEMSERVICO.I_COD_ORS is ''CODIGO DA ORDEM DE SERVICO''; ' +
        ' comment on column MOVORDEMSERVICO.I_SEQ_PRO is ''CODIGO DO PRODUTO''; ' +
        ' comment on column MOVORDEMSERVICO.I_COD_EMP is ''COdigo do Empresa''; ' +
        ' comment on column MOVORDEMSERVICO.I_COD_SER is ''CODIGO DO SERVICO''; ' +
        ' comment on column MOVORDEMSERVICO.I_COD_USU is ''CODIGO DO USUARIO''; ' +
        ' comment on column MOVORDEMSERVICO.N_QTD_MOV is ''QUNTIDADE DE SERVICO OU PRODUTO''; ' +
        ' comment on column MOVORDEMSERVICO.N_VLR_UNI is ''VALOR UNITARIO DO SERVICO OU PRODUTO''; ' +
        ' comment on column MOVORDEMSERVICO.N_VLR_TOT is ''VALOR TOTAL DO SERVICO OU PRODUTO''; ' +
        ' comment on column MOVORDEMSERVICO.C_COD_UNI is ''UNIDADE DO SERVICO''; ' +
        ' comment on column MOVORDEMSERVICO.L_OBS_MOV is ''OBSERVACAO''; ' +

        //   Table: MOVTERCEIROOS
        ' create table MOVTERCEIROOS ' +
        ' ( ' +
        '     I_EMP_FIL  integer                  not null, ' +
        '     I_COD_ORS  integer                  not null, ' +
        '     I_SEQ_MOV  integer                  not null, ' +
        '     I_COD_CLI  integer                      null, ' +
        '     D_DAT_COM  date                         null, ' +
        '     I_NOT_COM  integer                      null, ' +
        '     I_NOT_REM  integer                      null, ' +
        '     I_NOT_FOR  integer                      null, ' +
        '     D_DAT_REM  date                         null, ' +
        '     D_DAT_RET  date                         null, ' +
        '     N_VLR_SER  numeric(17,3) null, ' +
        '     primary key (I_EMP_FIL, I_COD_ORS, I_SEQ_MOV ) ' +
        ' ); ' +

        ' comment on table MOVTERCEIROOS is ''TERCEIROS DA OS''; ' +
        ' comment on column MOVTERCEIROOS.I_EMP_FIL is ''EMPRESA FILIAL''; ' +
        ' comment on column MOVTERCEIROOS.I_COD_ORS is ''CODIGO DA ORDEM DE SERVICO''; ' +
        ' comment on column MOVTERCEIROOS.I_COD_CLI is ''CODIGO DO CLIENTE''; ' +
        ' comment on column MOVTERCEIROOS.D_DAT_COM is ''DATA DE COMPRA, CASO GARANTIA''; ' +
        ' comment on column MOVTERCEIROOS.I_NOT_COM is ''NRO DA NOTA DE COMPRA CASO GARANTIA''; ' +
        ' comment on column MOVTERCEIROOS.I_NOT_REM is ''NOTA DE REMESSA PARA CONSERTO''; ' +
        ' comment on column MOVTERCEIROOS.I_NOT_FOR is ''NOTA DE DEVOLUCAO DO FORNECEDOR''; ' +
        ' comment on column MOVTERCEIROOS.D_DAT_REM is ''DATA DA REMESSA PARA CONSERTO''; ' +
        ' comment on column MOVTERCEIROOS.D_DAT_RET is ''DATA DE RETORNO''; ' +
        ' comment on column MOVTERCEIROOS.N_VLR_SER is ''VALOR DO SERVICO''; ' +

        //   Table: CADEQUIPAMENTOS
        ' create table CADEQUIPAMENTOS ' +
        ' ( ' +
        '     I_COD_EQU  integer               not null, ' +
        '     C_NOM_EQU  char(50)              not null, ' +
        '     D_ULT_ALT  date                      null, ' +
        '     primary key (I_COD_EQU) ' +
        ' ); ' +

        ' comment on table CADEQUIPAMENTOS is ''EQUIPAMENTOS''; ' +
        ' comment on column CADEQUIPAMENTOS.I_COD_EQU is ''CODIGO DA EQUIPAMENTO''; ' +
        ' comment on column CADEQUIPAMENTOS.C_NOM_EQU is ''NOME DO EQUIPAMENTO''; ' +
        ' comment on column CADEQUIPAMENTOS.D_ULT_ALT is ''DATA DA ULTIMA ALTERACAO''; ' );

      ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 130');
      end;

      if VpaNumAtualizacao < 131 Then
      begin
        VpfErro := '131';
        ExecutaComandoSql(Aux,
        ' alter table CADORDEMSERVICO ' +
        '     add foreign key FK_CADORDEM_REF_13281_CADSITUA (I_COD_SIT) ' +
        '        references CADSITUACOES (I_COD_SIT) on update restrict on delete restrict; ' +

        ' alter table CADORDEMSERVICO ' +
        '     add foreign key FK_CADORDEM_REF_13282_CADCLIEN (I_COD_CLI) ' +
        '        references CADCLIENTES (I_COD_CLI) on update restrict on delete restrict; ' +

        ' alter table CADORDEMSERVICO ' +
        '     add foreign key FK_CADORDEM_REF_13283_CADPRODU (I_SEQ_PRO) ' +
        '        references CADPRODUTOS (I_SEQ_PRO) on update restrict on delete restrict; ' +

        ' alter table MOVORDEMSERVICO ' +
        '     add foreign key FK_MOVORDEM_REF_77_CADORDEM (I_EMP_FIL, I_COD_ORS) ' +
        '        references CADORDEMSERVICO (I_EMP_FIL, I_COD_ORS) on update restrict on delete restrict; ' +

        ' alter table MOVORDEMSERVICO ' +
        '     add foreign key FK_MOVORDEM_REF_13284_CADPRODU (I_SEQ_PRO) ' +
        '        references CADPRODUTOS (I_SEQ_PRO) on update restrict on delete restrict; ' +

        ' alter table MOVORDEMSERVICO ' +
        '     add foreign key FK_MOVORDEM_REF_13284_CADSERVI (I_COD_EMP, I_COD_SER) ' +
        '        references CADSERVICO (I_COD_EMP, I_COD_SER) on update restrict on delete restrict; ' +

        ' alter table MOVTERCEIROOS ' +
        '     add foreign key FK_MOVTERCE_REF_84_CADORDEM (I_EMP_FIL, I_COD_ORS) ' +
        '        references CADORDEMSERVICO (I_EMP_FIL, I_COD_ORS) on update restrict on delete restrict; ' );
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 131');
      end;

      if VpaNumAtualizacao < 132 Then
      begin
        VpfErro := '132';
        ExecutaComandoSql(Aux,

         ' create unique index CADMARCAS_PK on CADMARCAS (I_COD_MAR asc); ' +
         ' create unique index CADCOR_PK on CADCOR (I_COD_COR asc); ' +
         ' create unique index CADMODELO_PK on CADMODELO (I_COD_MOD asc); ' +
         ' create unique index CADTIPO_PK on CADTIPO (I_COD_TIP asc); ' +
         ' create unique index CADORDEMSERVICO_PK on CADORDEMSERVICO (I_EMP_FIL asc, I_COD_ORS asc); ' +
         ' create unique index MOVORDEMSERVICO_PK on MOVORDEMSERVICO (I_EMP_FIL asc, I_COD_ORS asc, I_SEQ_MOV asc); ' +
         ' create unique index MOVTERCEIROOS_PK on MOVTERCEIROOS (I_EMP_FIL asc, I_COD_ORS asc, I_SEQ_MOV asc); ' +
         ' create index Ref_132816_FK on CADORDEMSERVICO (I_COD_SIT asc); ' +
         ' create index Ref_132820_FK on CADORDEMSERVICO (I_COD_CLI asc); ' +
         ' create index Ref_132835_FK on CADORDEMSERVICO (I_SEQ_PRO asc); ' +
         ' create index Ref_77_FK on MOVORDEMSERVICO (I_EMP_FIL asc, I_COD_ORS asc); ' +
         ' create index Ref_132840_FK on MOVORDEMSERVICO (I_SEQ_PRO asc); ' +
         ' create index Ref_132844_FK on MOVORDEMSERVICO (I_COD_EMP asc, I_COD_SER asc); ' +
         ' create index Ref_84_FK on MOVTERCEIROOS (I_EMP_FIL asc, I_COD_ORS asc); ' +
         ' create unique index CADEQUIPAMENTOS_PK on CADEQUIPAMENTOS (I_COD_EQU asc); ' );
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 132');
      end;

      if VpaNumAtualizacao < 133 Then
      begin
        VpfErro := '133';
        ExecutaComandoSql(Aux,' alter table cfg_geral'
                             +' add  c_mos_dec as char(1) null ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 133');
      end;

      if VpaNumAtualizacao < 134 Then
      begin
        VpfErro := '134';
        ExecutaComandoSql(Aux,' alter table MovOrcamentos'
                             +' add N_DES_PRO numeric(17,3) null ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 134');
      end;


      if VpaNumAtualizacao < 135 Then
      begin
        VpfErro := '135';
        ExecutaComandoSql(Aux,' ALTER TABLE MOVORCAMENTOS  '
                             +'  MODIFY n_vlr_pro NUMERIC(18,5); '
                             +' ALTER TABLE MOVNOTASFISCAIS  '
                             +'  MODIFY n_vlr_pro NUMERIC(18,5); ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 135');
      end;

      if VpaNumAtualizacao < 136 Then
      begin
        VpfErro := '136';
        ExecutaComandoSql(Aux,' alter table CadOrcamentos'
                             +' add N_VLR_PER numeric(17,3) null, '
                             +' add C_DES_ACR CHAR(1) null, '
                             +' add C_VLR_PER CHAR(1) null; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 136');
      end;

     if VpaNumAtualizacao < 137 Then
      begin
        VpfErro := '137';
        ExecutaComandoSql(Aux,' alter table CadOrdemServico'
                             +' add C_COD_PRO char(20) null ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 137');
      end;

     if VpaNumAtualizacao < 138 Then
      begin
        VpfErro := '138';
        ExecutaComandoSql(Aux,' alter table MovOrdemServico '
                             +' add C_COD_PRO char(20) null ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 138');
      end;

      if VpaNumAtualizacao < 139 Then
      begin
        VpfErro := '139';
        ExecutaComandoSql(Aux,' ALTER TABLE cadOrdemServico  '
                             +'  add D_ULT_ALT date null; '
                             +' ALTER TABLE MovOrdemServico  '
                             +'  add D_ULT_ALT date null; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 139');
      end;

      if VpaNumAtualizacao < 140 Then
      begin
        VpfErro := '140';
        ExecutaComandoSql(Aux,' ALTER TABLE MovOrdemServico '
                             +'  drop L_OBS_MOV ; '
                             +' ALTER TABLE CadOrdemServico  '
                             +' add L_OBS_MOV long varchar null; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 140');
      end;

      if VpaNumAtualizacao < 141 Then
      begin
        VpfErro := '141';
        ExecutaComandoSql(Aux,' ALTER TABLE CadContasaReceber '
                             +'  add I_COD_VEN integer null ; ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 141');
      end;

      if VpaNumAtualizacao < 142 Then
      begin
        VpfErro := '142';
        ExecutaComandoSql(Aux,' ALTER TABLE CadOrdemServico '
                             +'  add C_SIT_ORS char(1) null ; ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 142');
        ExecutaComandoSql(Aux,'comment on column CadOrdemServico.C_SIT_ORS is ''SITUACAO DA ORDEM DE SERVICO''');
      end;

      if VpaNumAtualizacao < 143 Then
      begin
        VpfErro := '143';
        ExecutaComandoSql(Aux,' ALTER TABLE CadOrdemServico '
                             +'  add N_TOT_PRO numeric(17,3) null, '
                             +'  add N_TOT_SER numeric(17,3) null, '
                             +'  add N_TOT_TER numeric(17,3) null; ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 143');
        ExecutaComandoSql(Aux,'comment on column CadOrdemServico.N_TOT_PRO is ''TOTAL DOS PRODUTOS''');
        ExecutaComandoSql(Aux,'comment on column CadOrdemServico.N_TOT_SER is ''TOTAL DOS SERVICO''');
      end;

      if VpaNumAtualizacao < 144 Then
      begin
        VpfErro := '144';
        ExecutaComandoSql(Aux,' alter table CadOrdemServico'
                             +' add N_VLR_PER numeric(17,3) null, '
                             +' add C_DES_ACR CHAR(1) null, '
                             +' add C_VLR_PER CHAR(1) null, '
                             +' add N_TOT_ORS numeric(17,3) null; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 144');
        ExecutaComandoSql(Aux,'comment on column CadOrdemServico.N_VLR_PER is ''DESCONTO''');
        ExecutaComandoSql(Aux,'comment on column CadOrdemServico.C_DES_ACR is ''DESCONTO OU ACRESCIMO''');
        ExecutaComandoSql(Aux,'comment on column CadOrdemServico.C_VLR_PER is ''VALOR OU PERCENTUAL''');
        ExecutaComandoSql(Aux,'comment on column CadOrdemServico.N_TOT_ORS is ''VALOR TOTAL DA ORDEM DE SERVICO''');
      end;

      if VpaNumAtualizacao < 145 Then
      begin
        VpfErro := '145';
        ExecutaComandoSql(Aux,' alter table CadOrdemServico'
                             +' add N_TOT_HOR numeric(17,3) null, '
                             +' add L_OBS_TER LONG VARCHAR null; '
                             +' alter table MovTerceiroOS '
                             +' add N_VLR_COB numeric(17,3) null; ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 145');
        ExecutaComandoSql(Aux,'comment on column CadOrdemServico.N_TOT_HOR is ''TOTAL DE HORAS TRABALHADA''');
        ExecutaComandoSql(Aux,'comment on column MovTerceiroOS.N_VLR_COB is ''VALOR DA COBRANCA''');
        ExecutaComandoSql(Aux,'comment on column CadOrdemServico.L_OBS_TER is ''OBSERVACAO DO TERCEIRO''');
      end;

      if VpaNumAtualizacao < 146 Then
      begin
        VpfErro := '146';
        ExecutaComandoSql(Aux,'create table CFG_SERVICOS '
                             +'  ( C_USA_TER char(1) NULL, '
                             +'    I_QTD_ORS integer null ); ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 146');
        ExecutaComandoSql(Aux,'comment on column CFG_SERVICOS.C_USA_TER is ''USAR TERCEIRO NA OS''');
        ExecutaComandoSql(Aux,'comment on column CFG_SERVICOS.I_QTD_ORS is ''QUANTIDADE DE ITEMS, EQUI, TIPO, MODELO ETC''');
      end;

      if VpaNumAtualizacao < 147 Then
      begin
        VpfErro := '147';
        aux.sql.clear;
        aux.sql.add(
//        ExecutaComandoSql(Aux,

        //   Table: CADORDEMSERVICO
        ' create table MOVEQUIPAMENTOOS ' +
        ' ( ' +
        '     I_EMP_FIL  integer               not null, ' +
        '     I_COD_ORS  integer               not null, ' +
        '     I_SEQ_MOV  integer               not null, ' +
        '     I_COD_EQU  integer                   null, ' +
        '     I_COD_MAR  integer                   null, ' +
        '     I_COD_MOD  integer                   null, ' +
        '     I_COD_COR  integer                   null, ' +
        '     I_COD_TIP  integer                   null, ' +
        '     C_ACE_EQU  varchar(100)              null, ' +
        '     C_GAR_EQU  char(1)                   null, ' +
        '     C_ORC_EQU  char(1)                   null, ' +
        '     C_NRO_NOT  char(40)                  null, ' +
        '     C_DEF_APR  varchar(250)              null, ' +
        '     primary key (I_EMP_FIL, I_COD_ORS, I_SEQ_MOV) ' +
        ' ); ' +

        ' comment on table MOVEQUIPAMENTOOS is ''EQUIPAMENTOS DA ORDEM DE SERVICO''; ' +
        ' comment on column MOVEQUIPAMENTOOS.I_EMP_FIL is ''EMPRESA FILIAL''; ' +
        ' comment on column MOVEQUIPAMENTOOS.I_COD_ORS is ''CODIGO DA ORDEM DE SERVICO''; ' +
        ' comment on column MOVEQUIPAMENTOOS.I_COD_EQU is ''CODIGO DA EQUIPAMENTO''; ' +
        ' comment on column MOVEQUIPAMENTOOS.I_COD_MAR is ''CODIGO DA MARCA''; ' +
        ' comment on column MOVEQUIPAMENTOOS.I_COD_MOD is ''CODIGO DO MODELO''; ' +
        ' comment on column MOVEQUIPAMENTOOS.I_COD_COR is ''CODIGO DA COR''; ' +
        ' comment on column MOVEQUIPAMENTOOS.I_COD_TIP is ''CODIGO DO TIPO''; ' +
        ' comment on column MOVEQUIPAMENTOOS.C_ACE_EQU is ''ACESSORIOS DO EQUIPAMENTO''; ' +
        ' comment on column MOVEQUIPAMENTOOS.C_GAR_EQU is ''POSSUI GARANTIA S/N''; ' +
        ' comment on column MOVEQUIPAMENTOOS.C_ORC_EQU is ''FAZER ORCAMENTO S/N''; ' +
        ' comment on column MOVEQUIPAMENTOOS.C_DEF_APR is ''DEFEITO APRESENTADO''; ' +
        ' comment on column MOVEQUIPAMENTOOS.C_NRO_NOT is ''NUMERO DA NOTA CASO GARANTIA''; ' );
      aux.ExecSQL;

      ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 147');
      end;

      if VpaNumAtualizacao < 148 Then
      begin
        VpfErro := '148';
        ExecutaComandoSql(Aux,

        ' alter table MOVEQUIPAMENTOOS ' +
        '     add foreign key FK_CADORDEM_REF_73A_CADTIPO (I_COD_TIP) ' +
        '        references CADTIPO (I_COD_TIP) on update restrict on delete restrict; ' +

        ' alter table MOVEQUIPAMENTOOS ' +
        '     add foreign key FK_CADORDEM_REF_69A_CADCOR (I_COD_COR) ' +
         '        references CADCOR (I_COD_COR) on update restrict on delete restrict; ' +

        ' alter table MOVEQUIPAMENTOOS ' +
        '     add foreign key FK_CADORDEM_REF_65A_CADMODEL (I_COD_MOD) ' +
        '        references CADMODELO (I_COD_MOD) on update restrict on delete restrict; ' +

        ' alter table MOVEQUIPAMENTOOS ' +
        '     add foreign key FK_CADORDEM_REF_61A_CADMARCA (I_COD_MAR) ' +
        '        references CADMARCAS (I_COD_MAR) on update restrict on delete restrict; ' +

        ' alter table MOVEQUIPAMENTOOS ' +
        '     add foreign key FK_CADORDEM_REF_13281A_CADEQUIP (I_COD_EQU) ' +
        '        references CADEQUIPAMENTOS (I_COD_EQU) on update restrict on delete restrict; ' +

        ' alter table MOVEQUIPAMENTOOS ' +
        '     add foreign key FK_MOVORDEM_REF_77A_CADORDEM (I_EMP_FIL, I_COD_ORS) ' +
        '        references CADORDEMSERVICO (I_EMP_FIL, I_COD_ORS) on update restrict on delete restrict; ' +

        ' create index Ref_73A_FK on MOVEQUIPAMENTOOS (I_COD_TIP asc); ' +
        ' create index Ref_69A_FK on MOVEQUIPAMENTOOS (I_COD_COR asc); ' +
        ' create index Ref_65A_FK on MOVEQUIPAMENTOOS (I_COD_MOD asc); ' +
        ' create index Ref_61A_FK on MOVEQUIPAMENTOOS (I_COD_MAR asc); ' +
        ' create index Ref_132813A_FK on MOVEQUIPAMENTOOS (I_COD_EQU asc); ' +
        ' create unique index MOVEQUIPAMENTOOS_PK on MOVEQUIPAMENTOOS (I_EMP_FIL asc, I_COD_ORS asc, I_SEQ_MOV asc); ' );
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 148');
      end;

      if VpaNumAtualizacao < 149 Then
      begin
        VpfErro := '149';
        ExecutaComandoSql(Aux,' ALTER TABLE MovEquipamentoOS  '
                             +'  add D_ULT_ALT date null; '
                             +' ALTER TABLE MovTerceiroOS  '
                             +'  add D_ULT_ALT date null; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 149');
      end;

      if VpaNumAtualizacao < 150 Then
      begin
        VpfErro := '150';
        ExecutaComandoSql(Aux,' ALTER TABLE MovEquipamentoOS  '
                             +'  add N_QTD_EQU numeric(17,3) null; ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 150');
      end;


      if VpaNumAtualizacao < 151 Then
      begin
        VpfErro := '151';
        aux.sql.clear;
        aux.sql.add(

        ' create table MOVESTOUROOS ' +
        ' ( ' +
        '     I_EMP_FIL  integer               not null, ' +
        '     I_SEQ_MOV  integer               not null, ' +
        '     I_COD_EQU  integer                   null, ' +
        '     I_COD_MAR  integer                   null, ' +
        '     I_COD_MOD  integer                   null, ' +
        '     I_COD_COR  integer                   null, ' +
        '     I_COD_TIP  integer                   null, ' +
        '     I_SEQ_PRO  integer                   null, ' +
        '     I_COD_EMP  integer                   null, ' +
        '     I_COD_SER  integer                   null, ' +
        '     N_QTD_MOV  numeric(17,3)             null, ' +
        '     D_ULT_ALT  date                      null, ' +
        '     primary key (I_EMP_FIL, I_SEQ_MOV) ' +
        ' ); ' +

        ' comment on table MOVESTOUROOS is ''ESTOURO DA ORDEM DE SERVICO''; ' +
        ' comment on column MOVESTOUROOS.I_EMP_FIL is ''EMPRESA FILIAL''; ' +
        ' comment on column MOVESTOUROOS.I_COD_EQU is ''CODIGO DA EQUIPAMENTO''; ' +
        ' comment on column MOVESTOUROOS.I_COD_MAR is ''CODIGO DA MARCA''; ' +
        ' comment on column MOVESTOUROOS.I_COD_MOD is ''CODIGO DO MODELO''; ' +
        ' comment on column MOVESTOUROOS.I_COD_COR is ''CODIGO DA COR''; ' +
        ' comment on column MOVESTOUROOS.I_COD_TIP is ''CODIGO DO TIPO''; ' +
        ' comment on column MOVESTOUROOS.I_SEQ_PRO is ''CODIGO DO PRODUTO''; ' +
        ' comment on column MOVESTOUROOS.I_COD_EMP is ''COdigo do Empresa''; ' +
        ' comment on column MOVESTOUROOS.I_COD_SER is ''CODIGO DO SERVICO''; ' +
        ' comment on column MOVESTOUROOS.N_QTD_MOV is ''QUANTIDADE DE SERVICO OU PRODUTO''; ' +
        ' comment on column MOVESTOUROOS.D_ULT_ALT is ''DATA DA ULTIMA ALTERACAO''; ' +

        ' alter table MOVESTOUROOS ' +
        '     add foreign key FK_MOVEST_REF_13281_CADPRODU (I_SEQ_PRO) ' +
        '        references CADPRODUTOS (I_SEQ_PRO) on update restrict on delete restrict; ' +

        ' alter table MOVESTOUROOS ' +
        '     add foreign key FK_MOVEST_REF_13281_CADSERVI (I_COD_EMP, I_COD_SER) ' +
        '        references CADSERVICO (I_COD_EMP, I_COD_SER) on update restrict on delete restrict; ' +

        ' alter table MOVESTOUROOS ' +
        '     add foreign key FK_MOVEST_REF_731_CADTIPO (I_COD_TIP) ' +
        '        references CADTIPO (I_COD_TIP) on update restrict on delete restrict; ' +

        ' alter table MOVESTOUROOS ' +
        '     add foreign key FK_MOVEST_REF_691_CADCOR (I_COD_COR) ' +
         '        references CADCOR (I_COD_COR) on update restrict on delete restrict; ' +

        ' alter table MOVESTOUROOS ' +
        '     add foreign key FK_MOVEST_REF_651_CADMODEL (I_COD_MOD) ' +
        '        references CADMODELO (I_COD_MOD) on update restrict on delete restrict; ' +

        ' alter table MOVESTOUROOS ' +
        '     add foreign key FK_MOVEST_REF_611_CADMARCA (I_COD_MAR) ' +
        '        references CADMARCAS (I_COD_MAR) on update restrict on delete restrict; ' +

        ' alter table MOVESTOUROOS ' +
        '     add foreign key FK_MOVEST_REF_13282_CADEQUIP (I_COD_EQU) ' +
        '        references CADEQUIPAMENTOS (I_COD_EQU) on update restrict on delete restrict; ' +

        ' create index Ref_7311_FK on MOVESTOUROOS (I_COD_TIP asc); ' +
        ' create index Ref_6111_FK on MOVESTOUROOS (I_COD_COR asc); ' +
        ' create index Ref_6522_FK on MOVESTOUROOS (I_COD_MOD asc); ' +
        ' create index Ref_6567_FK on MOVESTOUROOS (I_COD_MAR asc); ' +
        ' create index Ref_1321T_FK on MOVESTOUROOS (I_COD_EQU asc); ' +
        ' create unique index MOVEESTOUROOS_PK on MOVESTOUROOS (I_EMP_FIL asc, I_SEQ_MOV asc); ' );

      aux.ExecSQL;

      ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 151');
    end;


     if VpaNumAtualizacao < 152 Then
     begin
        VpfErro := '152';
        ExecutaComandoSql(Aux,' ALTER TABLE MovEstouroOS  '
                             +'  add C_COD_PRO char(20) null, '
                             +'  add C_COD_UNI char(2) null; ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 152');
     end;

     if VpaNumAtualizacao < 153 Then
     begin
        VpfErro := '153';
        ExecutaComandoSql(Aux,' alter table CadOrdemServico'
                             +' add I_COD_USU integer null  ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 153');
        ExecutaComandoSql(Aux,' comment on column CadOrdemServico.I_COD_USU is ''CODIGO USUARIO''; ' );
      end;

     if VpaNumAtualizacao < 154 Then
     begin
        VpfErro := '154';
        ExecutaComandoSql(Aux,' alter table CadOrdemServico'
                             +' add C_OBS_ABE Varchar(200) null  ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 154');
        ExecutaComandoSql(Aux,' comment on column CadOrdemServico.c_obs_abe is ''OBSERVACAO DA ABERTURA''; ' );
     end;

     if VpaNumAtualizacao < 155 Then
     begin
        VpfErro := '155';
        ExecutaComandoSql(Aux,' alter table CFG_SERVICOS '
                             +' add L_TEX_ORS Long Varchar null,  '
                             +' add I_TIP_REL integer null ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 155');
        ExecutaComandoSql(Aux,' comment on column CadOrdemServico.c_obs_abe is ''OBSERVACAO DA ABERTURA''; ' );
     end;

     if VpaNumAtualizacao < 156 Then
     begin
        VpfErro := '156';
        ExecutaComandoSql(Aux,' alter table CFG_PRODUTO '
                             +' add C_PRO_NUM CHAR(1) null; '
                             +' update CFG_PRODUTO set c_pro_num = ''F''');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 156');
        ExecutaComandoSql(Aux,' comment on column CFG_PRODUTO.C_PRO_NUM is ''NAO PERMITE USAR CARACTER NO CODIGO DO PRODUTO''; ' );
     end;

     if VpaNumAtualizacao < 157 Then
     begin
        VpfErro := '157';
        ExecutaComandoSql(Aux,'create table CADTIPOENTREGA'
                            +'  ( I_COD_ENT INTEGER NOT NULL, '
                            +'    C_DES_ENT char(40) NULL, '
                            +'  PRIMARY KEY(I_COD_ENT))');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 157');
        ExecutaComandoSql(Aux,'comment on table CADTIPOENTREGA is ''TIPOS DE ENTREGA''');
        ExecutaComandoSql(Aux,'comment on column CADTIPOENTREGA.I_COD_ENT is ''CODIGO DA ENTREGA''');
        ExecutaComandoSql(Aux,'comment on column CADTIPOENTREGA.C_DES_ENT is ''DESCRICAO DA ENTREGA''');
      end;

      if VpaNumAtualizacao < 158 Then
      begin
        VpfErro := '158';
        ExecutaComandoSql(Aux,'create unique index CADTIPOENTREGA_pk on'
                            +'  CADTIPOENTREGA(I_COD_ENT ASC) ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 158');
      end;

     if VpaNumAtualizacao < 159 Then
     begin
        VpfErro := '159';
        ExecutaComandoSql(Aux,' alter table CadOrdemServico '
                             +' add I_COD_ENT integer null; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 159');
        ExecutaComandoSql(Aux,' comment on column CadOrdemServico.I_COD_ENT is ''TIPO DE ENTREGA''; ' );
     end;

     if VpaNumAtualizacao < 160 Then
     begin
        VpfErro := '160';
        ExecutaComandoSql(Aux,' alter table CadOrdemServico ' +
                              ' add foreign key FK_CADTIPO_REF_699_CADENTREGA(I_COD_ENT) ' +
                              ' references CADTIPOENTREGA(I_COD_ENT) on update restrict on delete restrict; ' );

        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 159');
     end;

     if VpaNumAtualizacao < 161 Then
     begin
        VpfErro := '161';
        ExecutaComandoSql(Aux,' create unique index CADOrdemServico_FK_CADTIPO_857 on'
                            +'  CADORDEMSERVICO(I_COD_ENT ASC) ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 161');
     end;

     if VpaNumAtualizacao < 162 Then
     begin
        VpfErro := '162';
        ExecutaComandoSql(Aux,' alter table  movterceiroos '
                             +' add C_DES_PRO char(100) null; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 162');
        ExecutaComandoSql(Aux,' comment on column  movterceiroos.C_DES_PRO is ''DESCRICAO DO PRODUTO ENVIADO AO TERCEIRO''; ' );
     end;

     if VpaNumAtualizacao < 163 Then
     begin
        VpfErro := '163';
        ExecutaComandoSql(Aux,' alter table  CADICMSECF '
                             +' add C_TIP_CAD char(1) null; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 163');
        ExecutaComandoSql(Aux,' comment on column CADICMSECF.C_TIP_CAD is ''TIPO DE CADASTRO SERVICO OU PRODUTO S/P''; ' );
     end;

     if VpaNumAtualizacao < 164 Then
     begin
        VpfErro := '164';
        ExecutaComandoSql(Aux,' alter table movserviconota '
                             +' add N_ALI_SER numeric(8,3) null, '
                             +' add I_NUM_ITE integer null; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 164');
        ExecutaComandoSql(Aux,' comment on column  movserviconota.n_ali_ser is ''ALICOTA DO SERVICO''; ' );
        ExecutaComandoSql(Aux,' comment on column  movserviconota.i_num_ite is ''NUMERO DO ITEM''; ' );
     end;

      if VpaNumAtualizacao < 165 Then
      begin
        VpfErro := '165';
        ExecutaComandoSql(Aux,' alter table CADCODIGO '
                            +' add I_COD_PRO INTEGER NULL ');
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 165');
      end;

      if VpaNumAtualizacao < 166 Then
      begin
        VpfErro := '166';
        ExecutaComandoSql(Aux,' alter table cfg_fiscal '
                            +' add C_CST_NOT char(2) NULL ');
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 166');
      end;

     if VpaNumAtualizacao < 167 Then
      begin
        VpfErro := '167';
        ExecutaComandoSql(Aux,' alter table cfg_fiscal '
                            +' add C_GER_NRO char(1) NULL ');
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 167');
      end;

      if VpaNumAtualizacao < 168 Then
      begin
        VpfErro := '168';
        ExecutaComandoSql(Aux,' alter table cfg_servicos '
                            +' add I_REL_PED integer NULL ');
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 168');
      end;

      if VpaNumAtualizacao < 169 Then
      begin
        VpfErro := '169';
        ExecutaComandoSql(Aux,' alter table  movnatureza '
                            +' add C_MOS_FAT char(1) NULL; '
                            +' Update  movnatureza set c_mos_fat = ''S'' ');
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 169');
      end;

      if VpaNumAtualizacao < 170 Then
      begin
        VpfErro := '170';
        ExecutaComandoSql(Aux,' alter table CFG_PRODUTO '
                            +' add C_ADI_FIL char(1) NULL; '
                            +' Update CFG_PRODUTO set C_ADI_FIL = ''T'' ');
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 170');
      end;

      if VpaNumAtualizacao < 171 Then
      begin
        VpfErro := '171';
        ExecutaComandoSql(Aux,' alter table CFG_SERVICOS '
                             +' add C_INA_CLI char(1) NULL, '
                             +' add C_MOS_DES char(1) NULL, '
                             +' add N_PER_DES numeric(8,3) null; '
                             +' Update CFG_SERVICOS set C_INA_CLI = ''F'' ');
        ExecutaComandoSql(Aux,' Update CFG_GERAL set I_Ult_Alt = 171');
        ExecutaComandoSql(Aux,' comment on column  CFG_SERVICOS.c_ina_cli is ''CALCULA A INADINPLENCIA DO CLIENTE NO CADASTRO DE UM NOVO PEDIDO''; ' );
        ExecutaComandoSql(Aux,' comment on column  CFG_SERVICOS.c_mos_des is ''MOSTRA DESCONTO REFERENTE A ULTIMA COMPRA''; ' );
        ExecutaComandoSql(Aux,' comment on column  CFG_SERVICOS.n_per_des is ''PERCENTUAL DE DESCONTO REFERENTE A ULTIMA COMPRA''; ' );
      end;

      if VpaNumAtualizacao < 172 Then
      begin
        VpfErro := '172';
        ExecutaComandoSql(Aux,' alter table CADSERVICO '
                            + ' add N_PER_COM numeric(17,3) NULL ');
        ExecutaComandoSql(Aux,' Update CFG_GERAL set I_Ult_Alt = 172');
        ExecutaComandoSql(Aux,' comment on column CADSERVICO.N_PER_COM is ''PERCENTUAL DE COMISSAO''; ' );
      end;

      if VpaNumAtualizacao < 173 Then
      begin
        VpfErro := '173';
        ExecutaComandoSql(Aux,' create table MOVCLIENTEVENDEDOR '
                            +'  ( I_COD_VEN INTEGER NOT NULL, '
                            +'    I_COD_CLI  INTEGER NOT NULL, '
                            +'  PRIMARY KEY(I_COD_VEN,I_COD_CLI)) ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 173');
        ExecutaComandoSql(Aux,'comment on table MOVCLIENTEVENDEDOR is ''CLIENTES POR VENDEDOR''');
        ExecutaComandoSql(Aux,'comment on column MOVCLIENTEVENDEDOR.I_COD_VEN is ''CODIGO DO VENDEDOR''');
        ExecutaComandoSql(Aux,'comment on column MOVCLIENTEVENDEDOR.I_COD_CLI is ''CODIGO DO CLIENTE''');
      end;

      if VpaNumAtualizacao < 174 Then
      begin
        VpfErro := '174';
        ExecutaComandoSql(Aux,' alter table cfg_financeiro '
                            + ' add C_OPE_HOM CHAR(3) NULL ');
        ExecutaComandoSql(Aux,' Update CFG_GERAL set I_Ult_Alt = 174');
        ExecutaComandoSql(Aux,' comment on column cfg_financeiro.C_OPE_HOM is ''OPERACAO BANCARIA HOME BANKING ''; ' );
      end;

      if VpaNumAtualizacao < 175 Then
      begin
        VpfErro := '175';
        ExecutaComandoSql(Aux,' alter table cadclientes '
                            + ' add N_DES_VEN numeric(8,3) NULL ');
        ExecutaComandoSql(Aux,' Update CFG_GERAL set I_Ult_Alt = 175');
        ExecutaComandoSql(Aux,' comment on column cadclientes.N_DES_VEN is ''DESCONTO NA VENDA''; ' );
      end;

      if VpaNumAtualizacao < 176 Then
      begin
        VpfErro := '176';
        ExecutaComandoSql(Aux,' alter table CFG_SERVICOS '
                            + ' add C_CAB_ORC char(1) NULL, ' +
                              ' add I_ALT_CAB integer NULL, ' +
                              ' add I_ALT_ROD integer NULL ');
        ExecutaComandoSql(Aux,' Update CFG_GERAL set I_Ult_Alt = 176');
        ExecutaComandoSql(Aux,' comment on column CFG_SERVICOS.C_CAB_ORC is ''MOSTRXA CABECALHO DA IMPRESSAO DE ORCAMENTO''; ' );
        ExecutaComandoSql(Aux,' comment on column CFG_SERVICOS.I_ALT_CAB is ''ALTURA DO CABECALHO DA IMPRESSAO DE ORCAMENTO''; ' );
        ExecutaComandoSql(Aux,' comment on column CFG_SERVICOS.I_ALT_ROD is ''ALTURA DO RODAPE DA IMPRESSAO DE ORCAMENTO''; ' );
      end;

      if VpaNumAtualizacao < 177 Then
      begin
        VpfErro := '177';
        ExecutaComandoSql(Aux,'alter table movnatureza'
                            +'    add C_DES_NOT char(40) null ');
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 177');
        ExecutaComandoSql(Aux,' UPDATE MOVNATUREZA NAT ' +
                              ' SET C_DES_NOT =  (SELECT MAX(C_NOM_NAT) ' +
                              ' FROM CADNATUREZA NAT1 WHERE NAT.C_COD_NAT = NAT1.C_COD_NAT) ');
        ExecutaComandoSql(Aux,'comment on column movnatureza.c_des_not is ''CAMPO DE DESCRICAO DA NOTA''');
      end;


      if VpaNumAtualizacao < 178 Then
      begin
        VpfErro := '178';
        ExecutaComandoSql(Aux,' alter table CFG_SERVICOS '
                            + ' add L_TEX_ORC LONG VARCHAR NULL, ' +
                              ' add C_DES_PED char(1) NULL, ' +
                              ' add C_DES_ORC char(1) NULL ' );
        ExecutaComandoSql(Aux,' Update CFG_GERAL set I_Ult_Alt = 178');
        ExecutaComandoSql(Aux,' comment on column CFG_SERVICOS.L_TEX_ORC is ''TEXTO A SER IMPRESSO NA IMPRESSAO DE ORCAMENTO''; ' );
        ExecutaComandoSql(Aux,' comment on column CFG_SERVICOS.C_DES_PED is ''MOSTRAR DESCONTO PARA ITENS DE PEDIDO''; ' );
        ExecutaComandoSql(Aux,' comment on column CFG_SERVICOS.C_DES_ORC is ''MOSTRAR DESCONTO PARA ITENS DE ORCAMENTO''; ' );
      end;

     if VpaNumAtualizacao < 179 Then
     begin
        VpfErro := '179';
        ExecutaComandoSql(Aux,' alter table CFG_PRODUTO '
                             +' add C_MAS_SER CHAR(1) null; '
                             +' update CFG_PRODUTO set C_MAS_SER = ''T''');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 179');
        ExecutaComandoSql(Aux,' comment on column CFG_PRODUTO.C_MAS_SER is ''UTILIZAR A MASCARA DE EMPRESA FILIAL PARA GERAR O CODIGO''; ' );
     end;

     if VpaNumAtualizacao < 180 Then
     begin
        VpfErro := '180';
        ExecutaComandoSql(Aux,' alter table CADCLIENTES '
                             +' add C_END_COB CHAR(50) null; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 180');
        ExecutaComandoSql(Aux,' comment on column CADCLIENTES.C_END_COB is ''ENDERECO PARA COBRANCA''; ' );
     end;

     if VpaNumAtualizacao < 181 Then
     begin
        VpfErro := '181';
        ExecutaComandoSql(Aux,' alter table CADNOTAFISCAIS '
                             +' add C_NRO_PED CHAR(20) null');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 181');
        ExecutaComandoSql(Aux,' comment on column CADNOTAFISCAIS.c_nro_ped is ''NRO DO PEDIDO''; ' );
     end;

     if VpaNumAtualizacao < 182 Then
      begin
        VpfErro := '182';
        ExecutaComandoSql(Aux,' alter table CFG_SERVICOS '
                            + ' add L_TEX_PED LONG VARCHAR NULL ' );
        ExecutaComandoSql(Aux,' Update CFG_GERAL set I_Ult_Alt = 182');
        ExecutaComandoSql(Aux,' comment on column CFG_SERVICOS.L_TEX_PED is ''TEXTO A SER IMPRESSO NA IMPRESSAO NO PEDIDO''; ' );
      end;

     if VpaNumAtualizacao < 183 Then
     begin
        VpfErro := '183';
        ExecutaComandoSql(Aux,' alter table CADNOTAFISCAIS '
                             +' add C_NRO_ORC CHAR(20) null');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 183');
        ExecutaComandoSql(Aux,' comment on column CADNOTAFISCAIS.c_nro_orc is ''NRO DO ORCAMENTO''; ' );
     end;

     if VpaNumAtualizacao < 184 Then
      begin
        VpfErro := '184';
        ExecutaComandoSql(Aux,'alter table CADORCAMENTOS'
                             +'  ADD I_QTD_IMP integer NULL ');
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 184');
        ExecutaComandoSql(Aux,'comment on column CADORCAMENTOS.I_QTD_IMP is ''QUANTIDADE DE IMPRESSOES''');
      end;

      if VpaNumAtualizacao < 185 Then
      begin
        VpfErro := '185';
        ExecutaComandoSql(Aux,' alter table MOVCLIENTEVENDEDOR '
                            + ' ADD D_ULT_ALT date null ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 185');
        ExecutaComandoSql(Aux,'comment on column MOVCLIENTEVENDEDOR.D_ULT_ALT is ''DATA DA ULTIMA ALTERACAO''');
      end;

     if VpaNumAtualizacao < 186 Then
     begin
        VpfErro := '186';
        ExecutaComandoSql(Aux,' alter table CFG_SERVICOS '
                             +' add C_VEN_PED char(1) null, ' 
                             +' add C_VEN_ORC char(1) null; '
                             +' alter table CFG_FISCAL '
                             +' add C_TRA_VEN char(1) null; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 186');
        ExecutaComandoSql(Aux,' comment on column CFG_SERVICOS.C_VEN_PED is ''TRANCAR OU NAO A ALTERACAO DO VENDEDOR DO PEDIDO''; ' );
        ExecutaComandoSql(Aux,' comment on column CFG_SERVICOS.C_VEN_ORC is ''TRANCAR OU NAO A ALTERACAO DO VENDEDOR DO PEDIDO''; ' );
        ExecutaComandoSql(Aux,' comment on column CFG_FISCAL.C_TRA_VEN is ''TRANCAR OU NAO A ALTERACAO DO VENDEDOR DO CUPOM E NOTA FISCAL''; ' );
     end;

     if VpaNumAtualizacao < 187 Then
     begin
        VpfErro := '187';
        ExecutaComandoSql(Aux,' alter table CadNotaFiscais '
                             +' add I_COD_USU integer null; '
                             +' alter table CadOrcamentos '
                             +' add I_COD_USU integer null; '
                             +' alter table CadClientes '
                             +' add I_COD_USU integer null; ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 187');
        ExecutaComandoSql(Aux,' comment on column CadNotaFiscais.I_COD_USU is ''USUARIO QUE CADASTROU''; ' );
        ExecutaComandoSql(Aux,' comment on column CadOrcamentos.I_COD_USU is ''USUARIO QUE CADASTROU''; ' );
        ExecutaComandoSql(Aux,' comment on column CadClientes.I_COD_USU is ''USUARIO QUE CADASTROU''; ' );
     end;

     if VpaNumAtualizacao < 188 Then
     begin
        VpfErro := '188';
        ExecutaComandoSql(Aux,' alter table CFG_SERVICOS '
                             +' add I_PAG_PED integer null ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 188');
        ExecutaComandoSql(Aux,' comment on column CFG_SERVICOS.I_PAG_PED is ''TAMANHO DA PAGINA DA IMPRESSORA MATRICIAL DOS PEDIDOS''; ' );
     end;

     if VpaNumAtualizacao < 189 Then
     begin
        VpfErro := '189';
        ExecutaComandoSql(Aux,' alter table CFG_SERVICOS '
                             +' add I_PAG_ORC integer null, '
                             +' add I_IMP_ORC integer null;'
                             +' update cfg_servicos set i_imp_orc = 1' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 189');
        ExecutaComandoSql(Aux,' comment on column CFG_SERVICOS.I_PAG_ORC is ''TAMANHO DA PAGINA DA IMPRESSORA MATRICIAL DOS ORCAMENTOS''; ' );
        ExecutaComandoSql(Aux,' comment on column CFG_SERVICOS.I_IMP_ORC is ''TIPO DA IMPRESSORA DE ORCAMENTOS''; ' );
     end;

     if VpaNumAtualizacao < 190 Then
     begin
        VpfErro := '190';
        ExecutaComandoSql(Aux,'  create table MOVCOMPOSICAOPRODUTO ' +
                              ' ( '+
                              '   I_PRO_COM  integer               not null, ' +
                              '   I_SEQ_PRO  integer               not null, ' +
                              '   C_COD_UNI  char(2)                   null, ' +
                              '   N_QTD_PRO  numeric(17,3)             null, ' +
                              '   I_COD_EMP  integer                   null, ' +
                              '   D_ULT_ALT  date                      null, ' +
                              '   primary key (I_PRO_COM, I_SEQ_PRO)         ' +
                              ' ); ' +

                              ' comment on table MOVCOMPOSICAOPRODUTO is ''COMPOSICAO DO PRODUTO''; ' +
                              ' comment on column MOVCOMPOSICAOPRODUTO.I_PRO_COM is ''CODIGO DO PRODUTO DE COMPOSICAO''; ' +
                              ' comment on column MOVCOMPOSICAOPRODUTO.I_SEQ_PRO is ''CODIGO DO PRODUTO''; ' +
                              ' comment on column MOVCOMPOSICAOPRODUTO.C_COD_UNI is ''CODIGO DA UNIDADE''; ' +
                              ' comment on column MOVCOMPOSICAOPRODUTO.N_QTD_PRO is ''QUANTIDADE DE PRODUTOS''; ' +
                              ' comment on column MOVCOMPOSICAOPRODUTO.I_COD_EMP is ''CODIGO DA EMPRESA''; ' +
                              ' comment on column MOVCOMPOSICAOPRODUTO.D_ULT_ALT is ''DATA DA ULTIMA ALTERACAO''; ' +

                              ' alter table MOVCOMPOSICAOPRODUTO ' +
                              '     add foreign key FK_MOVCOMPO_REF_14026_CADUNIDA (C_COD_UNI) ' +
                              '       references CADUNIDADE (C_COD_UNI) on update restrict on delete restrict; ' +

                              ' alter table MOVCOMPOSICAOPRODUTO ' +
                              '     add foreign key FK_MOVCOMPO_REF_14179_CADPRODU (I_SEQ_PRO) ' +
                              '        references CADPRODUTOS (I_SEQ_PRO) on update restrict on delete restrict; ' +

                              ' alter table MOVCOMPOSICAOPRODUTO ' +
                              '     add foreign key FK_MOVCOMPO_REF_14256_CADPRODU (I_PRO_COM) ' +
                              '       references CADPRODUTOS (I_SEQ_PRO) on update restrict on delete restrict; ' +

                              ' create unique index MOVCOMPOSICAOPRODUTO_PK on MOVCOMPOSICAOPRODUTO (I_PRO_COM asc, I_SEQ_PRO asc); ' +
                              ' create index Ref_140261_FK on MOVCOMPOSICAOPRODUTO (C_COD_UNI asc); ' +
                              ' create index Ref_141796_FK on MOVCOMPOSICAOPRODUTO (I_SEQ_PRO asc); ' +
                              ' create index Ref_142569_FK on MOVCOMPOSICAOPRODUTO (I_PRO_COM asc); ');
       ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 190' );
     end;

     if VpaNumAtualizacao < 191 Then
     begin
        VpfErro := '191';
        ExecutaComandoSql(Aux,' alter table cadprodutos '
                             +' add C_PRO_COM char(1) null; '
                             +' update CADPRODUTOS set C_PRO_COM = ''N''' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 191');
        ExecutaComandoSql(Aux,' comment on column cadprodutos.c_pro_com is ''SE O PRODUTO E COMPOSTO''; ' );
     end;

     if VpaNumAtualizacao < 192 Then
     begin
        VpfErro := '192';
        ExecutaComandoSql(Aux,' alter table cfg_fiscal '
                             +' add C_NOT_SUB char(1) null ');
        ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 192');
        ExecutaComandoSql(Aux,' comment on column CFG_FISCAL.C_NOT_SUB is ''PERMITIR EXCLUIR NOTAS COM NUMEROS SUBSEQUENTES''; ' );
     end;

     if VpaNumAtualizacao < 193 Then
     begin
        VpfErro := '193';
        ExecutaComandoSql(Aux,' alter table cfg_fiscal '
                             +' add C_TOT_NOT char(1) null ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 193');
        ExecutaComandoSql(Aux,' comment on column CFG_FISCAL.C_TOT_NOT is ''PERMITIR ALTERAR O TOTAL DA NOTA''; ' );
     end;

     if VpaNumAtualizacao < 194 Then
     begin
        VpfErro := '194';
        ExecutaComandoSql(Aux, ' create table MOVCAIXAESTOQUE(  ' +
                               ' I_EMP_FIL  integer               not null, ' +
                               ' I_NRO_CAI  integer               not null, ' +
                               ' I_SEQ_PRO  integer               null    , ' +
                               ' I_SEQ_NOT  integer               null    , ' +
                               ' C_COD_PRO  Char(20)              null    , ' +
                               ' I_PES_CAI  numeric(17,4)         null    , ' +
                               ' D_DAT_ENT  date                  null    , ' +
                               ' D_DAT_SAI  date                  null    , ' +
                               ' N_VLR_SAI  numeric(17,4)         null    , ' +
                               ' C_OBS_CAI  varchar(100)          null    , ' +
                               ' C_SIT_CAI  char(1)               null    , ' +
                               ' C_NRO_REC  char(20)              null    , ' +
                               ' C_COD_BAR  char(25)              null    , ' +
                               ' primary key (I_EMP_FIL, I_NRO_CAI) ); ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 194');
    end;

     if VpaNumAtualizacao < 195 Then
     begin
        VpfErro := '195';
        ExecutaComandoSql(Aux, ' comment on table MOVCAIXAESTOQUE is ''MOVIMENTO DE CAIXA PARA ESTOQUES''; ' +
                               ' comment on column MOVCAIXAESTOQUE.I_EMP_FIL is ''CODIGO DA EMPRESA FILIAL''; ' +
                               ' comment on column MOVCAIXAESTOQUE.I_NRO_CAI is ''NUMERO DA CAIXA''; ' +
                               ' comment on column MOVCAIXAESTOQUE.I_SEQ_PRO is ''CODIGO DO PRODUTO''; ' +
                               ' comment on column MOVCAIXAESTOQUE.I_SEQ_NOT is ''NUMERO SEQUENCIAL DA NOTA''; ' +
                               ' comment on column MOVCAIXAESTOQUE.I_PES_CAI is ''PESO DA CAIXA''; ' +
                               ' comment on column MOVCAIXAESTOQUE.D_DAT_ENT is ''DATA DE ENTREGA''; ' +
                               ' comment on column MOVCAIXAESTOQUE.D_DAT_SAI is ''DATA DE SAIDA''; ' +
                               ' comment on column MOVCAIXAESTOQUE.N_VLR_SAI is ''VALOR DA SAIDA''; ' +
                               ' comment on column MOVCAIXAESTOQUE.C_OBS_CAI is ''OBSERVACAO''; ' +
                               ' comment on column MOVCAIXAESTOQUE.C_SIT_CAI is ''SITUACAO DA CAIXA''; ' +
                               ' comment on column MOVCAIXAESTOQUE.C_NRO_REC is ''NUMERO DO RECIBO''; ' +
                               ' comment on column MOVCAIXAESTOQUE.C_COD_BAR is ''CODIGO DA BARRAS''; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 195');
    end;

     if VpaNumAtualizacao < 196 Then
     begin
        VpfErro := '196';
        ExecutaComandoSql(Aux, ' create unique index MOVCAIXAESTOQUE_PK on MOVCAIXAESTOQUE (I_EMP_FIL asc, I_NRO_CAI asc); ' +
                               ' create index Ref_144353_FK on MOVCAIXAESTOQUE (I_SEQ_PRO asc); ' +
                               ' create index Ref_145121_FK on MOVCAIXAESTOQUE (I_EMP_FIL asc, I_SEQ_NOT asc); ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 196');
    end;

     if VpaNumAtualizacao < 197 Then
     begin
        VpfErro := '197';
        ExecutaComandoSql(Aux,' alter table cfg_fiscal '
                             +' add C_DUP_PRO char(1) null ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 197');
        ExecutaComandoSql(Aux,' comment on column CFG_FISCAL.C_DUP_PRO is ''PERMITIR DUPLICAR PRODUTO NA NOTA FISCAL''; ' );
    end;

     if VpaNumAtualizacao < 198 Then
     begin
        VpfErro := '198';
        ExecutaComandoSql(Aux,' alter table cfg_fiscal '
                             +' add C_TRU_TOT char(1) null ');
        ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 198');
        ExecutaComandoSql(Aux,' comment on column CFG_FISCAL.C_TRU_TOT is ''TRUNCA O VALOR DOS DECIMAIS NO TOTAL DA NOTA''; ' );
    end;

   if VpaNumAtualizacao < 199 Then
   begin
        VpfErro := '199';
        ExecutaComandoSql(Aux,' alter table cfg_geral ' +
                              ' add C_ALT_CAP char(1) null, ' +
                              ' add C_ALT_CAR char(1) null, ' +
                              ' add C_ALT_NFS char(1) null, ' +
                              ' add C_ALT_PED char(1) null, ' +
                              ' add C_ALT_ORC char(1) null, ' +
                              ' add C_ALT_EST char(1) null, ' +
                              ' add C_ALT_COS char(1) null, ' +
                              ' add C_ALT_BAN char(1) null, ' +
                              ' add C_ALT_ORS char(1) null, ' +
                              ' add C_ALT_NFE char(1) null, ' +
                              ' add C_ALT_PRE char(1) null, ' +
                              ' add C_ALT_PLA char(1) null, ' +
                              ' add C_ALT_NAT char(1) null, ' +
                              ' add C_ALT_PRO char(1) null '  );
        ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 199');
        ExecutaComandoSql(Aux,' comment on column CFG_GERAL.C_ALT_CAP is ''NAO/SIM PERMITIR A ALTERACAO DO CONTAS A PAGAR''; ' );
        ExecutaComandoSql(Aux,' comment on column CFG_GERAL.C_ALT_CAR is ''NAO/SIM PERMITIR A ALTERACAO DO CONTAS A RECEBER''; ' );
        ExecutaComandoSql(Aux,' comment on column CFG_GERAL.C_ALT_NFS is ''NAO/SIM PERMITIR A ALTERACAO DA NOTA FISCAL SAIDA''; ' );
        ExecutaComandoSql(Aux,' comment on column CFG_GERAL.C_ALT_PED is ''NAO/SIM PERMITIR A ALTERACAO DO PEDIDO''; ' );
        ExecutaComandoSql(Aux,' comment on column CFG_GERAL.C_ALT_ORC is ''NAO/SIM PERMITIR A ALTERACAO DO ORCAMENTO''; ' );
        ExecutaComandoSql(Aux,' comment on column CFG_GERAL.C_ALT_EST is ''NAO/SIM PERMITIR A ALTERACAO DO ESTOQUE''; ' );
        ExecutaComandoSql(Aux,' comment on column CFG_GERAL.C_ALT_COS is ''NAO/SIM PERMITIR A ALTERACAO DA COMISSOES''; ' );
        ExecutaComandoSql(Aux,' comment on column CFG_GERAL.C_ALT_BAN is ''NAO/SIM PERMITIR A ALTERACAO DOS BANCOS ''; ' );
        ExecutaComandoSql(Aux,' comment on column CFG_GERAL.C_ALT_ORS is ''NAO/SIM PERMITIR A ALTERACAO DOS ORCAMENTOS''; ' );
        ExecutaComandoSql(Aux,' comment on column CFG_GERAL.C_ALT_NFE is ''NAO/SIM PERMITIR A ALTERACAO DO NOTA FISCAL DE ENTRADA''; ' );
        ExecutaComandoSql(Aux,' comment on column CFG_GERAL.C_ALT_PRE is ''NAO/SIM PERMITIR A ALTERACAO DO PRECO DO PRECO''; ' );
        ExecutaComandoSql(Aux,' comment on column CFG_GERAL.C_ALT_PLA is ''NAO/SIM PERMITIR A ALTERACAO DO PLANO DE CONTAS''; ' );
        ExecutaComandoSql(Aux,' comment on column CFG_GERAL.C_ALT_NAT is ''NAO/SIM PERMITIR A ALTERACAO DAS NATUREZAS''; ' );
        ExecutaComandoSql(Aux,' comment on column CFG_GERAL.C_ALT_PRO is ''NAO/SIM PERMITIR A ALTERACAO DOS PRODUTOS''; ' );
    end;

     if VpaNumAtualizacao < 200 Then
     begin
        VpfErro := '200';
        ExecutaComandoSql(Aux,' create table MOVTABELAPRECOCLIENTE( '
                             +' I_EMP_FIL integer  not  null, '
                             +' I_SEQ_MOV integer  not  null, '
                             +' I_COD_TAB integer       null, '
                             +' I_COD_EMP integer       null, '
                             +' I_COD_CLI integer       null, '
                             +' I_TAB_SER integer       null, '
                             +' primary key (I_EMP_FIL, I_SEQ_MOV) ); ' );

        ExecutaComandoSql(Aux,' alter table MOVTABELAPRECOCLIENTE ' +
                              ' add foreign key FK_MOVTABELA_REF_155_CLIENTES(I_COD_CLI) ' +
                              ' references CADCLIENTES(I_COD_CLI) on update restrict on delete restrict; ' );

        ExecutaComandoSql(Aux,' alter table MOVTABELAPRECOCLIENTE ' +
                              ' add foreign key FK_MOVTABELA_REF_160_PRE_PRO(I_COD_EMP, I_COD_TAB) ' +
                              ' references CADTABELAPRECO(I_COD_EMP, I_COD_TAB) on update restrict on delete restrict; ' );

        ExecutaComandoSql(Aux,' alter table MOVTABELAPRECOCLIENTE ' +
                              ' add foreign key FK_MOVTABELA_REF_170_PRE_PRO(I_COD_EMP, I_TAB_SER) ' +
                              ' references CADTABELAPRECO(I_COD_EMP, I_COD_TAB) on update restrict on delete restrict; ' );

        ExecutaComandoSql(Aux,' create index MOVTABELAPRECO_PK on MOVTABELAPRECOCLIENTE(I_EMP_FIL, I_SEQ_MOV asc); ' );
        ExecutaComandoSql(Aux,' create index MOVTABELAPRECO_FK_123 on MOVTABELAPRECOCLIENTE(I_COD_CLI asc); ' );
        ExecutaComandoSql(Aux,' create index MOVTABELAPRECO_FK_124 on MOVTABELAPRECOCLIENTE(I_COD_EMP,I_COD_TAB asc); ' );
        ExecutaComandoSql(Aux,' create index MOVTABELAPRECO_FK_125 on MOVTABELAPRECOCLIENTE(I_COD_EMP,I_TAB_SER asc); ' );

        ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 200');
    end;


    if VpaNumAtualizacao < 201 Then
    begin
      VpfErro := '201';
      ExecutaComandoSql(Aux,' ALTER TABLE MOVTABELAPRECOCLIENTE  '
                           +'  add D_ULT_ALT date null; ');
      ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 201');
    end;

   if VpaNumAtualizacao < 202 Then
   begin
        VpfErro := '202';
        ExecutaComandoSql(Aux,' alter table cfg_geral ' +
                              ' add C_EXP_FIL char(1) null ' );
      ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 202');
    end;

   if VpaNumAtualizacao < 203 Then
   begin
        VpfErro := '203';
        ExecutaComandoSql(Aux,' alter table cfg_fiscal ' +
                              ' add C_DEV_CUP char(100) null; ' +
                              ' update cfg_fiscal set c_dev_cup = ''Nota fiscal de devolução referente ao Cupom Fiscal nº''' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 203');
    end;

   if VpaNumAtualizacao < 204 Then
   begin
        VpfErro := '204';
        ExecutaComandoSql(Aux,' alter table cadfiliais ' +
                              ' add C_PER_CAD char(1) null; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 204');
    end;

   if VpaNumAtualizacao < 205 Then
   begin
        VpfErro := '205';
        ExecutaComandoSql(Aux,' alter table cfg_servicos ' +
                              ' add C_TRA_INA char(1) null; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 205');
    end;

  if VpaNumAtualizacao < 206 Then
   begin
        VpfErro := '206';
        ExecutaComandoSql(Aux,' alter table cadNotaFiscais ' +
                              ' add C_INF_NOT Varchar(100) null; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 206');
    end;

   if VpaNumAtualizacao < 207 Then
   begin
        VpfErro := '207';
        ExecutaComandoSql(Aux,' alter table MOVCAIXAESTOQUE ' +
                              ' add I_COD_USU integer null; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 207');
    end;

   if VpaNumAtualizacao < 208 Then
   begin
        VpfErro := '208';
        ExecutaComandoSql(Aux,' alter table CFG_FISCAL ' +
                              ' add C_MOD_CAI char(1) null; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 208');
    end;

   if VpaNumAtualizacao < 209 Then
   begin
        VpfErro := '209';
        ExecutaComandoSql(Aux,' alter table cadinventario ' +
                              ' add D_ULT_ALT date null,  '+
                              ' add C_NOM_IVE char(40) null; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 209');
    end;

   if VpaNumAtualizacao < 210 then
   begin
        VpfErro := '210';
        ExecutaComandoSql(Aux,' alter table Movinventario ' +
                              ' add D_ULT_ALT date null,  '+
                              ' add C_COD_UNI char(2) null; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 210');
    end;

   if VpaNumAtualizacao < 211 then
   begin
        VpfErro := '211';
        ExecutaComandoSql(Aux,' alter table CadProdutos ' +
                              ' add I_TIP_TRI integer null; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 211');
        ExecutaComandoSql(Aux,' comment on column CadProdutos.I_TIP_TRI is ''0 - Sujeito ICMS, 1 - Substituicao Tributaria,  2 - Isento,  3 -  Não Incidencia''; ' );
    end;

   if VpaNumAtualizacao < 212 then
   begin
        VpfErro := '212';
        ExecutaComandoSql(Aux,' delete  CADICMSECF ');
        ExecutaComandoSql(Aux,' alter table CadIcmsECF ' +
                              ' add C_REG_IMP char(20) not null, ' +
                              ' add I_TIP_IMP integer not null; ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 212');
    end;

   if VpaNumAtualizacao < 213 then
   begin
        VpfErro := '213';
        ExecutaComandoSql(Aux,' drop index CADICMSECF_PK; ');
        ExecutaComandoSql(Aux,' alter TABLE  CADICMSECF  drop primary key ');
        ExecutaComandoSql(Aux,' alter table CADICMSECF add primary key (c_cod_icm, c_reg_imp, i_tip_imp); ' );
        ExecutaComandoSql(Aux,' create index CADICMSECF_PK on CADICMSECF(c_cod_icm, c_reg_imp, i_tip_imp asc); ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 213');
        aviso('A T E N Ç Ã O - Caso você utilize equipamento de cupom fiscal, antes de usar o sistema vá ao modulo configurções de sistema no menu impressões / configurações da impressora fiscal e utilize o botão atualiza tabela ICMS ');
    end;

   if VpaNumAtualizacao < 214 then
   begin
        VpfErro := '214';
        ExecutaComandoSql(Aux,' alter table Movinventario ' +
                              ' add C_COD_PRO char(20) null ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 214');
    end;

   if VpaNumAtualizacao < 215 then
   begin
        VpfErro := '215';
        ExecutaComandoSql(Aux,' alter table CadProdutos ' +
                              ' add N_QTD_COM numeric(8,3) null ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 215');
        ExecutaComandoSql(Aux,' comment on column CadProdutos.N_QTD_COM is ''Quantidade que ser referencia a composicao do produto''; ' );
    end;

   if VpaNumAtualizacao < 216 then
   begin
        VpfErro := '216';
        ExecutaComandoSql(Aux,' alter table CadProdutos ' +
                              ' add D_DAT_VAL date null, ' +
                              ' add I_QTD_CAI integer null ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 216');
    end;

   if VpaNumAtualizacao < 217 then
   begin
        VpfErro := '217';
        ExecutaComandoSql(Aux,' alter table MovQdadeProduto ' +
                              ' add N_EST_MAX numeric(8,3) null ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 217');
    end;

   if VpaNumAtualizacao < 218 then
   begin
        VpfErro := '218';
        ExecutaComandoSql(Aux,' alter table cfg_produto ' +
                              ' add C_CLA_PAD char(20) null ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 218');
    end;

   if VpaNumAtualizacao < 219 then
   begin
        VpfErro := '219';
        ExecutaComandoSql(Aux,' alter table CadClientes ' +
                              ' add C_IMP_BOL char(1) null,  ' +
                              ' add N_DES_BOL numeric(8,3) null ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 219');
    end;

   if VpaNumAtualizacao < 220 then
   begin
        VpfErro := '220';
        ExecutaComandoSql(Aux,' alter table CFG_PRODUTO ' +
                              ' add C_CFG_VEN char(20) null ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 220');
    end;

   if VpaNumAtualizacao < 221 then
   begin
        VpfErro := '221';
        ExecutaComandoSql(Aux,' alter table cadordemservico ' +
                              ' add D_DAT_PRE date null, ' +
                              ' add C_NOM_USU char(40) null ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 221');
    end;

   if VpaNumAtualizacao < 222 then
   begin
        VpfErro := '222';
        ExecutaComandoSql(Aux,' alter table cadnotafiscais ' +
                              ' add C_PRA_PAG Varchar(40) null, ' +
                              ' add C_END_COB Varchar(40) null ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 222');
    end;

   if VpaNumAtualizacao < 223 then
   begin
        VpfErro := '223';
        ExecutaComandoSql(Aux,' alter table grupo_Exportacao ' +
                              ' add C_NAO_RES char(1) null ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 223');
    end;

   if VpaNumAtualizacao < 224 then
   begin
        VpfErro := '224';
        ExecutaComandoSql(Aux,' alter table CadProdutos ' +
                              ' add N_VLR_MAX numeric(17,3) null ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 224');
    end;

   if VpaNumAtualizacao < 225 then
   begin
        VpfErro := '225';
        ExecutaComandoSql(Aux,' alter table CadProdutos ' +
                              ' delete D_DAT_VAL; ' +
                              ' alter table CadProdutos ' +
                              ' add I_DAT_VAL integer null; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 225');
    end;

   if VpaNumAtualizacao < 226 then
   begin
        VpfErro := '226';
        ExecutaComandoSql(Aux,' alter table CadClientes ' +
                              ' add I_COD_FRM integer null, ' +
                              ' add I_COD_PAG integer null ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 226');
    end;

   if VpaNumAtualizacao < 227 then
   begin
        VpfErro := '227';
        ExecutaComandoSql(Aux,' alter table MovNotasFiscais ' +
                              ' modify c_cod_cst char(3) null ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 227');
    end;

   if VpaNumAtualizacao < 228 then
   begin
        VpfErro := '228';
        ExecutaComandoSql(Aux,' alter table MovCaixaEstoque ' +
                              ' add C_TIP_CAI char(1) null,  ' +
                              ' add I_SEQ_CAI integer null ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 228');
    end;

   if VpaNumAtualizacao < 229 then
   begin
        VpfErro := '229';
        ExecutaComandoSql(Aux,' alter table MovQdadeProduto ' +
                              ' add N_CUS_COM numeric(17,3) null; ' +
                              ' alter table CFG_Produto ' +
                              ' add C_TIP_CUS char(6) null ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 229');
        ExecutaComandoSql(Aux,' comment on column MovQdadeProduto.N_CUS_COM is ''Custo de compra''; ' );
        ExecutaComandoSql(Aux,' comment on column CFG_Produto.C_TIP_CUS is ''MARCA OS TIPO DE ITENS DE CUSTO''; ' );
    end;

   if VpaNumAtualizacao < 230 then
   begin
        VpfErro := '230';
        ExecutaComandoSql(Aux,' alter table cadItensCusto ' +
                              ' add C_ADI_CAD char(1) null, '+
                              ' add N_VLR_PAD numeric(17,3) null, ' +
                              ' add N_PER_PAD numeric(8,3) null ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 230');
        ExecutaComandoSql(Aux,' comment on column cadItensCusto.C_ADI_CAD is ''ADICIONA O ITEM DE CUSTO AUTOMATICAMENTE AO CADASTRAR O PRODUTO''; ' );
        ExecutaComandoSql(Aux,' comment on column cadItensCusto.N_VLR_PAD is ''VALOR PADRAO''; ' );
        ExecutaComandoSql(Aux,' comment on column cadItensCusto.N_PER_PAD is ''PERCENTUAL PADRAO''; ' );
    end;

   if VpaNumAtualizacao < 231 then
   begin
        VpfErro := '231';
        ExecutaComandoSql(Aux,' alter table cadItensCusto ' +
                              ' add D_ULT_ALT date null ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 231');
    end;

   if VpaNumAtualizacao < 232 then
   begin
        VpfErro := '232';
        ExecutaComandoSql(Aux,' alter table cfg_produto ' +
                              ' add C_TIP_IND char(1) null; '+
                              ' alter table cadoperacaoestoque ' +
                              ' add I_OPE_BAI integer null ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 232');
        ExecutaComandoSql(Aux,' comment on column cfg_produto.C_TIP_IND is ''SE O ESTOQUE SERA DO TIPO INDUSTRIALIZADO''; ' );
        ExecutaComandoSql(Aux,' comment on column cadoperacaoestoque.I_OPE_BAI is ''OPERACAO DE BAIXA CASO PRODUTO INDUSTRIALIZADO''; ' );
    end;

   if VpaNumAtualizacao < 233 then
   begin
        VpfErro := '233';
        ExecutaComandoSql(Aux,' alter table MovComposicaoproduto ' +
                              ' add C_UNI_PAI char(2) null ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 233');
    end;

   if VpaNumAtualizacao < 234 then
   begin
        VpfErro := '234';
        ExecutaComandoSql(Aux,' alter table cfg_geral ' +
                              ' add C_ALT_COR char(1) null;  ' +
                              ' alter table cadfiliais ' +
                              ' add C_COR_FIL char(10) null ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 234');
    end;

   if VpaNumAtualizacao < 235 then
   begin
        VpfErro := '235';
        ExecutaComandoSql(Aux,' alter table cadfiliais ' +
                              ' add L_TEX_CAB Long varchar null  ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 235');
    end;

   if VpaNumAtualizacao < 236 then
   begin
        VpfErro := '236';
        ExecutaComandoSql(Aux,' alter table movequipamentoOS ' +
                              ' add C_VOL_ENT char(10) null; ' +
                              ' alter table  cadordemservico ' +
                              ' add T_HOR_PRE time null');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 236');
        ExecutaComandoSql(Aux,' comment on column movequipamentoOS.C_VOL_ENT is ''VOLTAGEM PADRAO DE ENTRADA''; ' );
        ExecutaComandoSql(Aux,' comment on column cadordemservico.T_HOR_PRE is ''HORA PREVISTA''; ' );
    end;

   if VpaNumAtualizacao < 237 then
   begin
        VpfErro := '237';
        ExecutaComandoSql(Aux,' alter table cadcontasapagar ' +
                              ' add I_CON_ORC integer null; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 237');
        ExecutaComandoSql(Aux,' comment on column cadcontasapagar.I_CON_ORC is ''IDENTIFICA ORCAMENTO DE CONTAS A PAGAR 0 - CP / 1 ORC''; ' );
    end;

   if VpaNumAtualizacao < 238 then
   begin
        VpfErro := '238';
        ExecutaComandoSql(Aux,' alter table CFG_MODULO ' +
                              ' add FLA_INVENTARIO CHAR(1) null, '+
                              ' add FLA_INTERNET CHAR(1) NULL, ' +
                              ' add FLA_PREVISAO CHAR(1) NULL ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 238');
        ExecutaComandoSql(Aux,' comment on column cadcontasapagar.I_CON_ORC is ''IDENTIFICA ORCAMENTO DE CONTAS A PAGAR''; ' );
    end;

      if VpaNumAtualizacao < 239 Then
      begin
        VpfErro := '239';
        ExecutaComandoSql(Aux,'create table MOVREDUCOESICMS '
                            +'  ( I_COD_RED INTEGER NOT NULL, '
                            +'    C_EST_RED char(2) not Null, '
                            +'    C_DES_RED char(40) NULL, '
                            +'    N_PER_RED numeric(17,6) NULL, '
                            +'    PRIMARY KEY(I_COD_RED, C_EST_RED) ) ');
        ExecutaComandoSql(Aux,' create index MOVREDUCOESICMS_PK on MOVREDUCOESICMS(I_COD_RED, C_EST_RED asc); ' );
        ExecutaComandoSql(Aux,' alter table CADPRODUTOS ' +
                              ' add I_COD_RED INTEGER null ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 239');
        ExecutaComandoSql(Aux,'comment on table MOVREDUCOESICMS is ''TABELA DREDUCAO DE ICMS''');
        ExecutaComandoSql(Aux,'comment on column MOVREDUCOESICMS.I_COD_RED is ''CODIGO HISTORICO CLIENTE''');
        ExecutaComandoSql(Aux,'comment on column MOVREDUCOESICMS.C_DES_RED is ''DESCRICAO DO HISTORICO DO CLIENTE''');
        ExecutaComandoSql(Aux,'comment on column MOVREDUCOESICMS.N_PER_RED is ''PERCENTUAL DA REDUCAO''');
        ExecutaComandoSql(Aux,'comment on column MOVREDUCOESICMS.C_EST_RED is ''ESTADO DA REDUCAO''');
      end;

   if VpaNumAtualizacao < 240 then
   begin
        VpfErro := '240';
        ExecutaComandoSql(Aux,' alter table MOVREDUCOESICMS ' +
                              ' add D_ULT_ALT date null ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 240');
    end;

   if VpaNumAtualizacao < 241 then
   begin
        VpfErro := '241';
        ExecutaComandoSql(Aux,' alter table cfg_servicos ' +
                              ' add C_HIS_PED CHAR(1) null ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 241');
        ExecutaComandoSql(Aux,'comment on column cfg_servicos.C_HIS_PED is ''MOSTRAR HISTORICO AUTOMATICO NO PEDIDO''');
    end;

      if VpaNumAtualizacao < 242 Then
      begin
        VpfErro := '242';
        ExecutaComandoSql(Aux,'create table CADCONTATOS '
                            +'  ( D_ULT_ALT date NULL, '
                            +'    I_COD_CLI integer not Null, '
                            +'    I_COD_CON integer not NULL, '
                            +'    C_DEP_CON char(20)NULL, '
                            +'    C_EMA_CON char(40)Null, '
                            +'    C_FAX_CON char(15)NULL, '
                            +'    C_FON_CON char(15)NULL, '
                            +'    C_NOM_CON char(30)NULL, '
                            +'    PRIMARY KEY(I_COD_CLI, I_COD_CON) ) ');
        ExecutaComandoSql(Aux,' create index CADCONTATOS_PK on CADCONTATOS(I_COD_CLI, I_COD_CON asc); ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 242');
        ExecutaComandoSql(Aux,'comment on table CADCONTATOS is ''TABELA DE CONTATOS DE CLIENTES''');
        ExecutaComandoSql(Aux,'comment on column CADCONTATOS.D_DAT_ALT is ''DATA DA ULTIMA ALTERACAO''');
        ExecutaComandoSql(Aux,'comment on column CADCONTATOS.I_COD_CLI is ''CODIGO DO CLIENTE''');
        ExecutaComandoSql(Aux,'comment on column CADCONTATOS.I_COD_CON is ''CODIGO DO CONTATO''');
        ExecutaComandoSql(Aux,'comment on column CADCONTATOS.C_DEP_CON is ''DEPARTAMENTO DO CONTATO''');
        ExecutaComandoSql(Aux,'comment on column CADCONTATOS.C_EMA_CON is ''E-MAIL DO CONTATO''');
        ExecutaComandoSql(Aux,'comment on column CADCONTATOS.C_FAX_CON is ''FAX''');
        ExecutaComandoSql(Aux,'comment on column CADCONTATOS.C_FON_CON is ''TELEFONE''');
        ExecutaComandoSql(Aux,'comment on column CADCONTATOS.C_NOM_CON is ''NOME DO CONTATO''');
      end;

     if VpaNumAtualizacao < 243 Then
     begin
        VpfErro := '243';
        ExecutaComandoSql(Aux, ' alter table MOVCAIXAESTOQUE  ' +
                               ' add I_NRO_NOT integer null, ' +
                               ' add C_SER_NOT char(2) null ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 243');
        ExecutaComandoSql(Aux,'comment on column MOVCAIXAESTOQUE.I_NRO_NOT is ''NUMERO DA NOTA FISCAL''');
        ExecutaComandoSql(Aux,'comment on column MOVCAIXAESTOQUE.C_SER_NOT is ''SERIE DA NOTA''');
    end;

     if VpaNumAtualizacao < 244 Then
     begin
        VpfErro := '244';
        ExecutaComandoSql(Aux, ' alter table  movcomposicaoproduto  ' +
                               ' modify N_QTD_PRO numeric(17,8) null ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 244');
    end;

    if VpaNumAtualizacao < 245 Then
     begin
        VpfErro := '245';
        ExecutaComandoSql(Aux, ' create table CADCICLOPRODUTO  ' +
                               ' (  ' +
                               ' I_EMP_FIL  integer               not null,  ' +
                               ' I_SEQ_CIC  integer               not null,  ' +
                               ' I_SEQ_PRO  integer               not null,  ' +
                               ' C_COD_UNI  char(2)               null    ,  ' +
                               ' N_CIC_PRO  numeric(17,8)         null    ,  ' +
                               ' N_PES_CIC  numeric(17,8)         null    ,  ' +
                               ' N_QTD_CIC  numeric(17,8)         null    ,  ' +
                               ' D_ULT_ALT  date                  null    ,  ' +
                               ' C_UNI_TEM  char(1)               null    ,  ' +
                               ' primary key (I_EMP_FIL, I_SEQ_CIC, I_SEQ_PRO)  ' +
                               ' );  ' +

                               ' comment on table CADCICLOPRODUTO is ''CADASTRO DE CLICLOS DE PRODUTO''; ' +
                               ' comment on column CADCICLOPRODUTO.I_EMP_FIL is ''CODIGO EMPRESA FILIAL''; ' +
                               ' comment on column CADCICLOPRODUTO.I_SEQ_CIC is ''SEQUENCIAL DE CICLO''; ' +
                               ' comment on column CADCICLOPRODUTO.I_SEQ_PRO is ''CODIGO DO PRODUTO''; ' +
                               ' comment on column CADCICLOPRODUTO.C_COD_UNI is ''CODIGO DA UNIDADE''; ' +
                               ' comment on column CADCICLOPRODUTO.N_CIC_PRO is ''CICLO DO PRODUTO POR TEMPO''; ' +
                               ' comment on column CADCICLOPRODUTO.N_PES_CIC is ''PESO DO PRODUTO''; ' +
                               ' comment on column CADCICLOPRODUTO.N_QTD_CIC is ''QUANTIDADE DE PRODUTO POR CICLO''; ' +
                               ' comment on column CADCICLOPRODUTO.D_ULT_ALT is ''DATA DA ULTIMA ALTERACAO''; ' +
                               ' comment on column CADCICLOPRODUTO.C_UNI_TEM is ''UNIDADE DE TEMPO''; ' +

                               ' create table CADMAQUINAS ' +
                               ' ( ' +
                               ' I_COD_MAQ  integer               not null, ' +
                               ' C_NOM_MAQ  char(40)              null    , ' +
                               ' N_PER_CIC  numeric(17,8)         null    , ' +
                               ' D_ULT_ALT  date                  null    , ' +
                               ' primary key (I_COD_MAQ) ' +
                               ' ); ' +

                               ' comment on table CADMAQUINAS is ''CADASTRO DE MAQUINAS''; ' +
                               ' Comment on column CADMAQUINAS.I_COD_MAQ is ''CODIGO DA MAQUINA''; ' +
                               ' comment on column CADMAQUINAS.C_NOM_MAQ is ''NOME DA MAQUINA''; ' +
                               ' comment on column CADMAQUINAS.N_PER_CIC is ''PERCENTUAL DE DESCONTO OU ACRESCIMO NO CLICO DE PRODUCAO''; ' +
                               ' comment on column CADMAQUINAS.D_ULT_ALT is ''DATA DA ULTIMA ALTERACAO''; ' +

                               ' create table CADORDEMPRODUCAO ' +
                               ' ( ' +
                               ' I_EMP_FIL  integer               not null, ' +
                               ' I_NRO_ORP  integer               not null, ' +
                               ' I_SEQ_PRO  integer               null    , ' +
                               ' I_COD_MAQ  integer               null    , ' +
                               ' I_COD_SIT  integer               null    , ' +
                               ' I_LAN_ORC  integer               null    , ' +
                               ' D_DAT_EMI  date                  null    , ' +
                               ' D_DAT_ENT  date                  null    , ' +
                               ' D_DAT_PRO  date                  null    , ' +
                               ' N_QTD_PRO  numeric(17,8)         null    , ' +
                               ' N_QTD_SAC  numeric(17,8)         null    , ' +
                               ' N_PES_CIC  numeric(17,8)         null    , ' +
                               ' N_CIC_PRO  numeric(17,8)         null    , ' +
                               ' N_TOT_HOR  numeric(17,8)         null    , ' +
                               ' I_NRO_PED  integer               null    , ' +
                               ' L_OBS_ORP  long varchar          null    , ' +
                               ' D_ULT_ALT  date                  null    , ' +
                               ' primary key (I_EMP_FIL, I_NRO_ORP) ' +
                               ' );                              ' +

                               ' comment on table CADORDEMPRODUCAO is ''CADASTRO DE ORDEM DE PRODUCAO''; ' +
                               ' comment on column CADORDEMPRODUCAO.I_EMP_FIL is ''CODIGO DA FILIAL''; ' +
                               ' comment on column CADORDEMPRODUCAO.I_NRO_ORP is ''CODIGO DA ORDEM DE PRODUCAO''; ' +
                               ' comment on column CADORDEMPRODUCAO.I_SEQ_PRO is ''CODIGO DO PRODUTO''; ' +
                               ' comment on column CADORDEMPRODUCAO.I_COD_MAQ is ''CODIGO DA MAQUINA''; ' +
                               ' comment on column CADORDEMPRODUCAO.I_COD_SIT is ''CODIGO DA SITUACAO''; ' +
                               ' comment on column CADORDEMPRODUCAO.I_LAN_ORC is ''NUMERO DE LANCAMENTO SEQUENCIAL''; ' +
                               ' comment on column CADORDEMPRODUCAO.D_DAT_EMI is ''DATA DE EMISSAO''; ' +
                               ' comment on column CADORDEMPRODUCAO.D_DAT_ENT is ''DATA DE ENTREGA''; ' +
                               ' comment on column CADORDEMPRODUCAO.D_DAT_PRO is ''DATA PARA PRODUZIR''; ' +
                               ' comment on column CADORDEMPRODUCAO.N_QTD_PRO is ''QUANTIDADE A PRODUZIR''; ' +
                               ' comment on column CADORDEMPRODUCAO.N_QTD_SAC is ''QUANTIDADE DE SACO''; ' +
                               ' comment on column CADORDEMPRODUCAO.N_PES_CIC is ''PECO DO CICLO''; ' +
                               ' comment on column CADORDEMPRODUCAO.N_CIC_PRO is ''CICLO DE PRODUCAO''; ' +
                               ' comment on column CADORDEMPRODUCAO.N_TOT_HOR is ''TOTAL DE HORAS DA PRODUCAO''; ' +
                               ' comment on column CADORDEMPRODUCAO.I_NRO_PED is ''NUMERO DO PEDIDO''; ' +
                               ' comment on column CADORDEMPRODUCAO.L_OBS_ORP is ''L_OBS_ORP''; ' +
                               ' comment on column CADORDEMPRODUCAO.D_ULT_ALT is ''DATA DA ULTIMA ALTERACAO''; ' +

                               ' alter table CADCICLOPRODUTO ' +
                               '     add foreign key FK_CADCICLO_REF_15174_CADPRODU (I_SEQ_PRO) ' +
                               '        references CADPRODUTOS (I_SEQ_PRO) on update restrict on delete restrict; ' +

                               ' alter table CADCICLOPRODUTO ' +
                               '     add foreign key FK_CADCICLO_REF_15176_CADUNIDA (C_COD_UNI) ' +
                               '        references CADUNIDADE (C_COD_UNI) on update restrict on delete restrict; ' +

                               ' alter table CADORDEMPRODUCAO ' +
                               '     add foreign key FK_CADORDEM_REF_15174_CADPRODU (I_SEQ_PRO) ' +
                               '        references CADPRODUTOS (I_SEQ_PRO) on update restrict on delete restrict; ' +

                               ' alter table CADORDEMPRODUCAO ' +
                               '     add foreign key FK_CADORDEM_REF_15177_CADMAQUI (I_COD_MAQ) ' +
                               '        references CADMAQUINAS (I_COD_MAQ) on update restrict on delete restrict; ' +

                               ' alter table CADORDEMPRODUCAO ' +
                               '     add foreign key FK_CADORDEM_REF_15178_CADSITUA (I_COD_SIT) ' +
                               '        references CADSITUACOES (I_COD_SIT) on update restrict on delete restrict; ' +

                               ' alter table CADORDEMPRODUCAO ' +
                               '     add foreign key FK_CADORDEM_REF_15179_CADORCAM (I_EMP_FIL, I_LAN_ORC) ' +
                               '        references CADORCAMENTOS (I_EMP_FIL, I_LAN_ORC) on update restrict on delete restrict; ' );
       ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 245');
    end;

     if VpaNumAtualizacao < 246 Then
     begin
        VpfErro := '246';
        ExecutaComandoSql(Aux, ' create unique index CADCICLOPRODUTO_PK on CADCICLOPRODUTO (I_EMP_FIL asc, I_SEQ_CIC asc, I_SEQ_PRO asc); ' +
                               ' create index Ref_151744_FK on CADCICLOPRODUTO (I_SEQ_PRO asc); ' +
                               ' create index Ref_151762_FK on CADCICLOPRODUTO (C_COD_UNI asc); ' +
                               ' create unique index CADMAQUINAS_PK on CADMAQUINAS (I_COD_MAQ asc); ' +
                               ' create unique index CADORDEMPRODUCAO_PK on CADORDEMPRODUCAO (I_EMP_FIL asc, I_NRO_ORP asc); ' +
                               ' create index Ref_151748_FK on CADORDEMPRODUCAO (I_SEQ_PRO asc); ' +
                               ' create index Ref_151771_FK on CADORDEMPRODUCAO (I_COD_MAQ asc); ' +
                               ' create index Ref_151785_FK on CADORDEMPRODUCAO (I_COD_SIT asc); ' +
                               ' create index Ref_151791_FK on CADORDEMPRODUCAO (I_EMP_FIL asc, I_LAN_ORC asc); ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 246');
    end;

    if VpaNumAtualizacao < 247 Then
     begin
        VpfErro := '247';
        ExecutaComandoSql(Aux,' alter table  cadprofissoes ' +
                              ' add C_TIP_CAD char(1) null ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 247');
    end;

    if VpaNumAtualizacao < 248 Then
     begin
        VpfErro := '248';
        ExecutaComandoSql(Aux,' alter table cadOrdemProducao ' +
                              ' add C_COD_PRO char(20) null ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 248');
    end;

    if VpaNumAtualizacao < 249 Then
     begin
        VpfErro := '249';
        ExecutaComandoSql(Aux,' alter table cfg_fiscal ' +
                              ' add C_SER_AUT char(1) null ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 249');
    end;

    if VpaNumAtualizacao < 250 Then
     begin
        VpfErro := '250';
        ExecutaComandoSql(Aux,' alter table cadnotafiscais ' +
                              ' modify N_PES_BRU numeric(17,3) null ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 250');
    end;

     if VpaNumAtualizacao < 251 Then
     begin
        VpfErro := '251';
        ExecutaComandoSql(Aux,' alter table CadOrdemServico ' +
                              ' add I_COD_ATE integer null; ' +
                              ' alter table MOVEQUIPAMENTOOS ' +
                              ' add C_NRO_SER char(20) null; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 251');
        ExecutaComandoSql(Aux,'comment on column CadOrdemServico.I_COD_ATE is ''CODIGO DO ATENTENDE''');
        ExecutaComandoSql(Aux,'comment on column MOVEQUIPAMENTOOS.C_NRO_SER is ''NUMERO DE SERIE DO EQUIPAMENTO''');
    end;

     if VpaNumAtualizacao < 252 Then
     begin
        VpfErro := '252';
        ExecutaComandoSql(Aux,' alter table CadContatos ' +
                              ' add D_ULT_ALT date null ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 252');
    end;

     if VpaNumAtualizacao < 253 Then
     begin
        VpfErro := '253';
        ExecutaComandoSql(Aux,' alter table CFG_MODULO ' +
                              ' add FLA_PCP char(1) null ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 253');
    end;

     if VpaNumAtualizacao < 254 Then
     begin
        VpfErro := '254';
        ExecutaComandoSql(Aux,' alter table CadOrdemServico ' +
                              ' add C_NON_AVI char(30) null, ' +
                              ' add D_DAT_AVI date null; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 254');
        ExecutaComandoSql(Aux,'comment on column CadOrdemServico.C_NON_AVI is ''NOME DO USUARIO QUE FOI AVISADO DO TERMINO DO SERVIÇO''');
        ExecutaComandoSql(Aux,'comment on column CadOrdemServico.D_DAT_AVI is ''DATA DE AVISO DE TERMINO''');
    end;

   if VpaNumAtualizacao < 255 Then
   begin
        VpfErro := '255';
        ExecutaComandoSql(Aux,' alter table MOVCAIXAESTOQUE ' +
                              ' add D_DAT_PRO date null; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 255');
    end;

   if VpaNumAtualizacao < 256 Then
   begin
        VpfErro := '256';
        ExecutaComandoSql(Aux,' alter table MOVCAIXAESTOQUE ' +
                              ' modify C_COD_BAR Varchar(70) null; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 256');
    end;


  if VpaNumAtualizacao < 257 Then
   begin
        VpfErro := '257';
        ExecutaComandoSql(Aux,' drop index MOVCAIXAESTOQUE_PK ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 257');
    end;

   if VpaNumAtualizacao < 258 Then
   begin
        VpfErro := '258';
        ExecutaComandoSql(Aux,' alter TABLE MOVCAIXAESTOQUE drop primary key ');
        ExecutaComandoSql(Aux,' alter TABLE MOVCAIXAESTOQUE modify i_seq_pro integer not null ');
        ExecutaComandoSql(Aux,' alter table MOVCAIXAESTOQUE add primary key (i_emp_fil,i_nro_cai,i_seq_pro) ' );
        ExecutaComandoSql(Aux,' create index MOVCAIXAESTOQUE_PK on MOVCAIXAESTOQUE(i_emp_fil,i_nro_cai,i_seq_pro asc) ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 258');
    end;

   if VpaNumAtualizacao < 259 Then
   begin
        VpfErro := '259';
        ExecutaComandoSql(Aux,'alter table movnotasfiscais ' +
                              ' add I_QTD_CAI integer null;   ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 259');
    end;

   if VpaNumAtualizacao < 260 Then
   begin
        VpfErro := '260';
        ExecutaComandoSql(Aux,' create index EmissaoCP_10 on CADNOTAFISCAIS (D_DAT_EMI asc); ' );
        ExecutaComandoSql(Aux,' create index EmissaoCP_10 on CADCONTASARECEBER(D_DAT_EMI asc); ' );
        ExecutaComandoSql(Aux,' create index EmissaoCP_10 on CADCONTASAPAGAR(D_DAT_EMI asc); ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 260');
    end;

   if VpaNumAtualizacao < 261 Then
   begin
        VpfErro := '261';
        ExecutaComandoSql(Aux,' alter table CadOrdemProducao ' +
                              ' add C_TIP_ORP CHAR(1) null,   ' +
                              ' add D_DAT_FEC date null, ' +
                              ' add D_DAT_INI date null, ' +
                              ' add D_DAT_FIM date null, '+
                              ' add N_QTD_TER numeric(17,4) null ');
        ExecutaComandoSql(Aux,'comment on column CadOrdemProducao.C_TIP_ORP is ''TIPO DE ORDEM PRODUCAO''');
        ExecutaComandoSql(Aux,'comment on column CadOrdemProducao.D_DAT_FEC is ''DATA DE FECHAMENTO''');
        ExecutaComandoSql(Aux,'comment on column CadOrdemProducao.D_DAT_INI is ''DATA DE INICIO DE PRODUCAO''');
        ExecutaComandoSql(Aux,'comment on column CadOrdemProducao.D_DAT_FIM is ''DATA DE FIM DFE PRODUCAO''');
        ExecutaComandoSql(Aux,'comment on column CadOrdemProducao.N_QTD_TER is ''QUANTIDADE JA TERMINADA NA PRODUCAO''');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 261');
    end;

  
    except
        FAtualizaSistema.MostraErro(Aux.sql,'cfg_geral');
        Erro(VpfErro +  ' - OCORREU UM ERRO DURANTE A ATUALIZAÇAO DO SISTEMA inSIG.');
        result := false;
        exit;
    end;
  until result;
end;

{********************* altera as versoes do sistema ***************************}
procedure TAtualiza.AlteraVersoesSistemas;
begin
  ExecutaComandoSql(Aux,'Update Cfg_Geral ' +
                        'set C_Mod_Fat = '''+ VersaoFaturamento + ''',' +
                        ' C_Mod_Pon = '''+ VersaoPontoLoja + ''','+
                        ' C_Mod_Est = ''' + VersaoEstoque + ''',' +
                        ' C_Mod_Cai = '''+ VersaoCaixa +''',' +
                        ' C_Mod_Fin = ''' + VersaoFinanceiro+''','+
                        ' C_CON_USU = ''' + VersaoConfiguracaoAmbiente+''','+
                        ' C_Mod_TRX = ''' + VersaoTrasnferencia+''',' +
                        ' C_Mod_REL = ''' + VersaoRelatorios+''',' +
                        ' C_CON_SIS = ''' + VersaoConfiguracaoSistema+'''');
end;

end.
