Unit UnAtualizacao1;

interface
  Uses Classes, DbTables,SysUtils;

Type
  TAtualiza1 = Class
    Private
      Aux : TQuery;
      DataBase : TDataBase;
      procedure AtualizaSenha( Senha : string );
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
constructor TAtualiza1.criar( aowner : TComponent; ADataBase : TDataBase );
begin
  inherited Create;
  Aux := TQuery.Create(aowner);
  DataBase := ADataBase;
  Aux.DataBaseName := 'BaseDados';
end;

{*************** atualiza senha na base de dados ***************************** }
procedure TAtualiza1.AtualizaSenha( Senha : string );
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
function TAtualiza1.AtualizaBanco : boolean;
begin
  result := true;
  AdicionaSQLAbreTabela(Aux,'Select I_Ult_Alt from Cfg_Geral ');
  if Aux.FieldByName('I_Ult_Alt').AsInteger < CT_VersaoBanco Then
    result := AtualizaTabela(Aux.FieldByName('I_Ult_Alt').AsInteger);
end;

{**************************** atualiza a tabela *******************************}
function TAtualiza1.AtualizaTabela(VpaNumAtualizacao : Integer) : Boolean;
var
  VpfErro : String;
begin
  result := true;
  repeat
    Try
        if VpaNumAtualizacao < 262 Then
       begin
            VpfErro := '262';
            ExecutaComandoSql(Aux,

                '  create table CADREQUISICAOMATERIAL  ' +
                '  (                                        ' +
                '   I_EMP_FIL  integer               not null,  ' +
                '   I_COD_REQ  integer               not null,  ' +
                '   I_COD_USU  integer                   null,  ' +
                '   I_USU_REQ  integer                   null,  ' +
                '   L_OBS_REQ  long varchar              null,  ' +
                '   D_DAT_REQ  date                      null,  ' +
                '   D_ULT_ALT  date                      null,  ' +
                '   C_SIT_REQ  char(1)                   null,  ' +
                '   primary key (I_EMP_FIL, I_COD_REQ)          ' +
                ' );                                            ' +

                ' comment on table CADREQUISICAOMATERIAL is ''REQUISICAO DE MATERIAL'';  ' +
                ' comment on column CADREQUISICAOMATERIAL.I_EMP_FIL is  ''CODIGO EMPRESA FILIAL '';  ' +
                ' comment on column CADREQUISICAOMATERIAL.I_COD_REQ is  ''CODIGO DA REQUISICAO '';   ' +
                ' comment on column CADREQUISICAOMATERIAL.I_COD_USU is  ''CODIGO DO USUARIO QUE CEDE O MATERIAL '';  ' +
                ' comment on column CADREQUISICAOMATERIAL.I_USU_REQ is  ''CODIGO DO USUARIO QUE PEGA O MATERIAL '';  ' +
                ' comment on column CADREQUISICAOMATERIAL.L_OBS_REQ is  ''OBSERVACAO'';  ' +
                ' comment on column CADREQUISICAOMATERIAL.D_DAT_REQ is  ''DATA DA REQUISICAO '';  ' +
                ' comment on column CADREQUISICAOMATERIAL.D_ULT_ALT is  ''DATA DA ALTERACAO'';  ' +
                ' comment on column CADREQUISICAOMATERIAL.C_SIT_REQ is  ''SITUACAO DA REQUISICAO '';  ' );

      ExecutaComandoSql(Aux,
                ' create table MOVREQUISICAOMATERIAL  ' +
                ' (                                   ' +
                '   I_EMP_FIL  integer               not null,  ' +
                '   I_COD_REQ  integer               not null,  ' +
                '   I_SEQ_PRO  integer               not null,  ' +
                '   C_COD_UNI  char(2)                   null,  ' +
                '   N_QTD_PRO  numeric(17,3)             null,  ' +
                '   primary key (I_EMP_FIL, I_COD_REQ, I_SEQ_PRO)  ' +
                ' );                                               ' +

                ' comment on table MOVREQUISICAOMATERIAL is  ''MOVIMENTO DE REQUISICAO DE MATERIAL '';  ' +
                ' comment on column MOVREQUISICAOMATERIAL.I_EMP_FIL is  ''CODIGO EMPRESA FILIAL '';  ' +
                ' comment on column MOVREQUISICAOMATERIAL.I_COD_REQ is  ''CODIGO DA REQUISICAO '';  ' +
                ' comment on column MOVREQUISICAOMATERIAL.I_SEQ_PRO is  ''CODIGO DO PRODUTO'';  ' +
                ' comment on column MOVREQUISICAOMATERIAL.C_COD_UNI is  ''CODIGO DA UNIDADE '';  ' +
                ' comment on column MOVREQUISICAOMATERIAL.N_QTD_PRO is  ''QUANTIDADE DE PRODUTO'';  ' );

          ExecutaComandoSql(Aux,
                ' alter table MOVREQUISICAOMATERIAL  ' +
                '   add foreign key FK_MOVREQUI_REF_14803_CADREQUI (I_EMP_FIL, I_COD_REQ)  ' +
                '      references CADREQUISICAOMATERIAL (I_EMP_FIL, I_COD_REQ) on update restrict on delete restrict;  ' +

                ' alter table MOVREQUISICAOMATERIAL  ' +
                '   add foreign key FK_MOVREQUI_REF_14804_CADPRODU (I_SEQ_PRO)  ' +
                '      references CADPRODUTOS (I_SEQ_PRO) on update restrict on delete restrict;  ' +

                ' alter table MOVREQUISICAOMATERIAL  ' +
                '   add foreign key FK_MOVREQUI_REF_14804_CADUNIDA (C_COD_UNI)  ' +
                '      references CADUNIDADE (C_COD_UNI) on update restrict on delete restrict;  ' );
            ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 262');
        end;


       if VpaNumAtualizacao < 263 Then
       begin
            VpfErro := '263';
            ExecutaComandoSql(Aux,
              ' create unique index CADREQUISICAOMATERIAL_PK on CADREQUISICAOMATERIAL (I_EMP_FIL asc, I_COD_REQ asc); ' +
              ' create unique index MOVREQUISICAOMATERIAL_PK on MOVREQUISICAOMATERIAL (I_EMP_FIL asc, I_COD_REQ asc, I_SEQ_PRO asc); ' +
              ' create index Ref_148037_FK on MOVREQUISICAOMATERIAL (I_EMP_FIL asc, I_COD_REQ asc); ' +
              ' create index Ref_148044_FK on MOVREQUISICAOMATERIAL (I_SEQ_PRO asc); ' +
              ' create index Ref_148048_FK on MOVREQUISICAOMATERIAL (C_COD_UNI asc); ' );
            ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 263');
        end;


     if VpaNumAtualizacao < 264 Then
       begin
         VpfErro := '264';
         ExecutaComandoSql(Aux,' alter table cfg_fiscal' +
                               ' add I_VIA_ROM INTEGER NULL; ' +
                               ' alter table cadtransportadoras ' +
                               ' add C_PLA_VEI char(10) null; ' +
                               ' alter table movcaixaestoque '  +
                               ' add D_DAT_CAN date null ' );
         ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 264');
         ExecutaComandoSql(Aux,'comment on column cfg_fiscal.I_VIA_ROM is ''QUANTIDADE DE VIAS DO ROMANEIO''');
         ExecutaComandoSql(Aux,'comment on column cadtransportadoras.C_PLA_VEI is ''PLACA DO VEICULO''');
         ExecutaComandoSql(Aux,'comment on column movcaixaestoque.D_DAT_CAN is ''DATA DO CANCELAMENTO DA CAIXA''');
      end;


     if VpaNumAtualizacao < 265 Then
       begin
         VpfErro := '265';
         ExecutaComandoSql(Aux,' create table MOVORDEMPRODUCAO ' +
                              ' ( ' +
                              ' I_EMP_FIL  integer               not null, ' +
                              ' I_NRO_ORP  integer               not null, ' +
                              ' I_SEQ_PRO  integer               not null, ' +
                              ' C_COD_UNI  char(2)                   null, ' +
                              ' N_QTD_PRO  numeric(17,8)             null, ' +
                              ' D_ULT_ALT  date                      null, ' +
                              ' C_UNI_PAI  char(2)                   null, ' +
                              ' primary key (I_EMP_FIL, I_NRO_ORP, I_SEQ_PRO) ' +
                              ' ); ' +
                              ' comment on table MOVORDEMPRODUCAO is ''MOVORDEMPRODUCAO''; ' +
                              ' comment on column MOVORDEMPRODUCAO.I_EMP_FIL is ''CODIGO DA FILIAL''; ' +
                              ' comment on column MOVORDEMPRODUCAO.I_NRO_ORP is ''CODIGO DA ORDEM DE PRODUCAO''; ' +
                              ' comment on column MOVORDEMPRODUCAO.I_SEQ_PRO is ''CODIGO DO PRODUTO''; ' +
                              ' comment on column MOVORDEMPRODUCAO.C_COD_UNI is ''CODIGO DA UNIDADE''; ' +
                              ' comment on column MOVORDEMPRODUCAO.N_QTD_PRO is ''QUANTIDADE DE PRODUTOS''; ' +
                              ' comment on column MOVORDEMPRODUCAO.D_ULT_ALT is ''DATA DA ULTIMA ALTERACAO''; ' +
                              ' comment on column MOVORDEMPRODUCAO.C_UNI_PAI is ''C_UNI_PAI''; ' );

        ExecutaComandoSql(Aux,' create table CADTURNOS ' +
                              ' ( ' +
                              ' I_EMP_FIL  integer               not null, ' +
                              ' I_COD_TUR  integer               not null, ' +
                              ' C_DES_TUR  char(30)                  null, ' +
                              ' H_HOR_INI  time                      null, ' +
                              ' H_HOR_FIM  time                      null, ' +
                              ' N_QTD_HOR  numeric(10,3)             null, ' +
                              ' primary key (I_EMP_FIL, I_COD_TUR) ' +
                              ' ); ' +
                              ' comment on table CADTURNOS is ''CADASTRO DE TURNOS''; ' +
                              ' comment on column CADTURNOS.I_EMP_FIL is ''CODIGO EMPRESA FILIAL''; ' +
                              ' comment on column CADTURNOS.I_COD_TUR is ''CODIGO DO TURNO''; ' +
                              ' comment on column CADTURNOS.C_DES_TUR is ''DESCRICAO DO TURNO''; ' +
                              ' comment on column CADTURNOS.H_HOR_INI is ''HRA DE INICIO DO TURNO''; ' +
                              ' comment on column CADTURNOS.H_HOR_FIM is ''HORA DE FIM DO TRUNO''; ' +
                              ' comment on column CADTURNOS.N_QTD_HOR is ''QUANTIDADE DE HORAS EFETIVAS''; ' +

                              ' alter table MOVORDEMPRODUCAO ' +
                              '     add foreign key FK_MOVORDEM_REF_16248_CADORDEM (I_EMP_FIL, I_NRO_ORP) ' +
                              '        references CADORDEMPRODUCAO (I_EMP_FIL, I_NRO_ORP) on update restrict on delete restrict; ' +

                              ' alter table MOVORDEMPRODUCAO ' +
                              '     add foreign key FK_MOVORDEM_REF_16249_CADPRODU (I_SEQ_PRO) ' +
                              '        references CADPRODUTOS (I_SEQ_PRO) on update restrict on delete restrict; ' +

                              ' alter table CADTURNOS ' +
                              '     add foreign key FK_CADTURNO_REF_16250_CADFILIA (I_EMP_FIL) ' +
                              '        references CADFILIAIS (I_EMP_FIL) on update restrict on delete restrict; ' );

            ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 265');
        end;

     if VpaNumAtualizacao < 266 Then
       begin
         VpfErro := '266';
         ExecutaComandoSql(Aux,' create unique index MOVORDEMPRODUCAO_PK on MOVORDEMPRODUCAO (I_EMP_FIL asc, I_NRO_ORP asc, I_SEQ_PRO asc); ' +
                               ' create index Ref_162488_FK on MOVORDEMPRODUCAO (I_EMP_FIL asc, I_NRO_ORP asc); ' +
                               ' create index Ref_162495_FK on MOVORDEMPRODUCAO (I_SEQ_PRO asc); ' +
                               ' create unique index CADTURNOS_PK on CADTURNOS (I_EMP_FIL asc, I_COD_TUR asc); ' +
                               ' create index Ref_162501_FK on CADTURNOS (I_EMP_FIL asc); ' );
            ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 266');
        end;

    if VpaNumAtualizacao < 267 Then
     begin
        VpfErro := '267';
        ExecutaComandoSql(Aux,' alter table cadOrdemProducao ' +
                              ' add N_PES_TOT numeric(17,8) null, ' +
                              ' add N_PEC_HOR numeric(17,8) null' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 267');
    end;

    if VpaNumAtualizacao < 268 Then
     begin
        VpfErro := '268';
        ExecutaComandoSql(Aux,' alter table cfg_fiscal ' +
                              ' add C_CAL_PES char(1) null; ' +
                              ' alter table cfg_produto ' +
                              ' add C_MOS_RES char(1) null; ' +
                              ' alter table cadprodutos  ' +
                              ' add N_LIQ_CAI numeric(17,8) null, ' +
                              ' add C_UNI_VEN char(2) null ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 268');
        ExecutaComandoSql(Aux,'comment on column cfg_fiscal.C_CAL_PES is ''PERMITE O CALCULO DO PESO LIQUIDO AO NATO AUTOMATICAMENTE''');
        ExecutaComandoSql(Aux,'comment on column cfg_produto.C_MOS_RES is ''MOSTRA RESERVADO''');
        ExecutaComandoSql(Aux,'comment on column cadprodutos.N_LIQ_CAI is ''PESO LIQUIDO DA CAIXA''');
        ExecutaComandoSql(Aux,'comment on column cadprodutos.C_UNI_VEN is ''UNIDADE DE VANDA PARA USO DE CAIXA''');
    end;

    if VpaNumAtualizacao < 269 Then
     begin
        VpfErro := '269';
        ExecutaComandoSql(Aux,' alter table movNotasfiscais ' +
                              ' add N_LIQ_CAI numeric(17,8) null, ' +
                              ' add C_UNI_VEN char(2) null ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 269');
        ExecutaComandoSql(Aux,'comment on column movNotasfiscais.N_LIQ_CAI is ''PESO LIQUIDO DA CAIXA''');
        ExecutaComandoSql(Aux,'comment on column movNotasfiscais.C_UNI_VEN is ''UNIDADE DE VANDA PARA USO DE CAIXA''');
    end;

    if VpaNumAtualizacao < 270 Then
     begin
        VpfErro := '270';
        ExecutaComandoSql(Aux,' alter table cfg_geral ' +
                              ' add D_DAT_SIS date null ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 270');
    end;

     if VpaNumAtualizacao < 271 Then
     begin
        VpfErro := '271';
        ExecutaComandoSql(Aux,' alter table cadclientes ' +
                              ' modify C_PRA_CLI char(80) null; '  +
                              ' alter table movrequisicaomaterial ' +
                              ' add C_COD_PRO char(20) null ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 271');
    end;

     if VpaNumAtualizacao < 272 Then
     begin
        VpfErro := '272';
        ExecutaComandoSql(Aux,' alter table cadturnos ' +
                              ' add D_ULT_ALT DATE null; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 272');
    end;

     if VpaNumAtualizacao < 273 Then
     begin
        VpfErro := '273';
        ExecutaComandoSql(Aux,' alter table cfg_servicos ' +
                              ' add I_SIT_PAD integer null; ' +
                              ' alter table movordemproducao ' +
                              ' add C_COD_PRO char(20) null ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 273');
    end;

     if VpaNumAtualizacao < 274 Then
     begin
        VpfErro := '274';

          ExecutaComandoSql(Aux,
                ' create table CADSETORESESTOQUE  ' +
                ' (                                   ' +
                '   I_COD_SET  integer               not null,  ' +
                '   C_NOM_SET  char(30)                   null,  ' +
                '   D_ULT_ALT  date                       null,  ' +
                '   primary key (I_COD_SET)  ' +
                ' );                                               ' +

                ' comment on table CADSETORESESTOQUE is  ''SETORES DO MOVIMENTO DE ESTOQUE '';  ' +
                ' comment on column CADSETORESESTOQUE.I_COD_SET is  ''CODIGO DO SETOR DE ESTOQUE'';  ' +
                ' comment on column CADSETORESESTOQUE.C_NOM_SET is  ''NOME DO SETOR DE ESTOQUE'';  ' );

          ExecutaComandoSql(Aux, ' alter table  movestoqueprodutos ' +
                                 ' add I_COD_SET integer null ' );

          ExecutaComandoSql(Aux,
                ' alter table  movestoqueprodutos  ' +
                '   add foreign key FK_MOVSETOR_REF_1487 (I_COD_SET)  ' +
                '      references CADSETORESESTOQUE(I_COD_SET) on update restrict on delete restrict;  ' );

         ExecutaComandoSql(Aux,' create unique index CADSETORESESTOQUE_PK on CADSETORESESTOQUE (I_COD_SET asc); ' +
                               ' create index Ref_89733_FK on  movestoqueprodutos(I_COD_SET asc); ' );

            ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 274');
        end;

     if VpaNumAtualizacao < 275 Then
     begin
        VpfErro := '275';
        ExecutaComandoSql(Aux,' alter table cfg_geral' +
                              ' add C_SEN_LIB char(10) null; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 275');
    end;

     if VpaNumAtualizacao < 276 Then
     begin
        VpfErro := '276';
        ExecutaComandoSql(Aux,' alter table caditenscusto' +
                              ' add C_TIP_LUC char(1) null,' +
                              ' add I_DES_IMP integer null; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 276');
    end;

    if VpaNumAtualizacao < 277 Then
     begin
        VpfErro := '277';
        ExecutaComandoSql(Aux,' alter table cadcontatos' +
                              ' modify C_FON_CON char(20) null,' +
                              ' modify C_FAX_CON char(20) null; ' +
                              ' create index cadorcamentosCP_01 on cadorcamentos(D_DAT_ENT asc); ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 277');
    end;

    if VpaNumAtualizacao < 278 Then
     begin
        VpfErro := '278';
        ExecutaComandoSql(Aux,' alter table movQdadeProduto ' +
                              ' modify N_VLR_CUS numeric(17,7) null,' +
                              ' modify N_VLR_COM numeric(17,7) null, ' +
                              ' modify N_CUS_COM numeric(17,7) null; ' +
                              ' alter table CadItensCusto ' +
                              ' modify N_PER_PAD numeric(17,8) null,' +
                              ' modify N_VLR_PAD numeric(17,8) null; ' +
                              ' alter table MovItensCusto ' +
                              ' modify N_VLR_CUS numeric(17,8) null,' +
                              ' modify N_PER_CUS numeric(17,8) null; ');
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 278');
    end;

     if VpaNumAtualizacao < 279 Then
     begin
        VpfErro := '279';
        ExecutaComandoSql(Aux,' alter table CFG_GERAL ' +
                              ' Add I_DEC_CUS integer null;' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 279');
    end;

     if VpaNumAtualizacao < 280 Then
     begin
        VpfErro := '280';
        ExecutaComandoSql(Aux,' alter table  movitenscusto ' +
                              ' Add I_DES_IMP integer null;' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 280');
    end;

     if VpaNumAtualizacao < 281 Then
     begin
        VpfErro := '281';
        ExecutaComandoSql(Aux,' alter table cfg_servicos ' +
                              ' add I_OPE_PCP integer null; ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 281');
    end;

   if VpaNumAtualizacao < 282 Then
   begin
      VpfErro := '282';
      ExecutaComandoSql(Aux,' alter table cfg_fiscal ' +
                            ' add C_ITE_AUT char(1) null, ' +
                            ' add C_ORD_CAI char(1) null; ' +
                            ' alter table cfg_produto ' +
                            ' add C_VAL_CUS char(1) null');
      ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 282');
    end;

   if VpaNumAtualizacao < 283 Then
   begin
      VpfErro := '283';
      ExecutaComandoSql(Aux,' alter table MovQdadeProduto ' +
                            ' add N_VLR_MAR numeric(17,7) null; ' );
      ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 283');
    end;

   if VpaNumAtualizacao < 284 Then
   begin
      VpfErro := '284';
      ExecutaComandoSql(Aux,' alter table MovQdadeProduto ' +
                            ' add N_VLR_DES numeric(17,7) null; ' );
      ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 284');
    end;

   if VpaNumAtualizacao < 285 Then
   begin
      VpfErro := '285';
      ExecutaComandoSql(Aux,' alter table CadProdutos ' +
                            ' add C_UNI_COM char(2) null; ' );
      ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 285');
    end;

   if VpaNumAtualizacao < 286 Then
   begin
      VpfErro := '286';
      ExecutaComandoSql(Aux,' alter table MovQdadeProduto ' +
                            ' add N_VLR_PRO numeric(17,7) null; ' );
      ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 286');
    end;

   if VpaNumAtualizacao < 287 Then
   begin
      VpfErro := '287';
      ExecutaComandoSql(Aux,' alter table MovComposicaoProduto ' +
                            ' add N_QTD_COM numeric(17,7) null; ' );
      ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 287');
    end;

   if VpaNumAtualizacao < 288 Then
   begin
      VpfErro := '288';
      ExecutaComandoSql(Aux,' alter table CFG_FISCAL ' +
                            ' add C_MOS_TRO char(1) null; ' );
      ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 288');
    end;

   if VpaNumAtualizacao < 289 Then
   begin
      VpfErro := '289';
      ExecutaComandoSql(Aux,' drop index MOVITENSCUSTO_PK;' +
                            ' alter TABLE MovItensCusto  drop primary key;' +
                            ' alter table MovItensCusto add I_COD_TAB  integer null;' +
                            ' update MovItensCusto set i_cod_tab = (select min(i_cod_tab) from cadtabelapreco);' +
                            ' alter table MovItensCusto modify I_COD_TAB  integer not null;' +
                            ' alter table  MovItensCusto add primary key (i_cod_emp, i_cod_ite, i_seq_pro, i_cod_tab);' +
                            ' create index MovItensCusto_PK on MovItensCusto(i_cod_emp, i_cod_ite, i_seq_pro, i_cod_tab asc);' +
                            ' alter table movtabelapreco ' +
                            ' add N_VLR_CUS numeric(17,7) null, ' +
                            ' add N_VLR_PRO numeric(17,7) null, ' +
                            ' add N_VLR_DES numeric(17,7) null, ' +
                            ' add N_VLR_MAR numeric(17,7) null; ' +
                            ' alter table movqdadeproduto ' +
                            ' delete N_VLR_CUS , ' +
                            ' delete N_VLR_PRO , ' +
                            ' delete N_VLR_DES , ' +
                            ' delete N_VLR_MAR ' );
      ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 289');
    end;

   if VpaNumAtualizacao < 290 Then
   begin
      VpfErro := '290';
      ExecutaComandoSql(Aux,' alter table CFG_Produto ' +
                            ' add I_OPE_REQ integer null, '+
                            ' add I_IMP_REQ integer null; ' );
      ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 290');
    end;

   if VpaNumAtualizacao < 291 Then
   begin
      VpfErro := '291';
      ExecutaComandoSql(Aux,' alter table CFG_Produto ' +
                            ' add I_REQ_CAN integer null; ');
      ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 291');
    end;

   if VpaNumAtualizacao < 292 Then
   begin
      VpfErro := '292';
      ExecutaComandoSql(Aux,' alter table CadRequisicaoMaterial ' +
                            ' add I_NRO_ORS integer null,  ' +
                            ' add I_NRO_ORP integer null, ' +
                            ' add I_NRO_NOF integer null, ' +
                            ' add I_NRO_PED integer null; ');
      ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 292');
    end;

   if VpaNumAtualizacao < 293 Then
   begin
      VpfErro := '293';
      ExecutaComandoSql(Aux,' alter table Cfg_Produto ' +
                            ' add C_IMP_TAG char(1) null; ');
      ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 293');
    end;

   if VpaNumAtualizacao < 294 Then
   begin
      VpfErro := '294';
      ExecutaComandoSql(Aux,' alter table Cfg_Produto ' +
                            ' add I_SIT_REQ integer null; ');
      ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 294');
    end;

   if VpaNumAtualizacao < 295 Then
   begin
      VpfErro := '295';
      ExecutaComandoSql(Aux,' alter table Cfg_Produto ' +
                            ' add C_CUP_AUT char(1) null; ');
      ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 295');
    end;

   if VpaNumAtualizacao < 296 Then
   begin
      VpfErro := '296';
      ExecutaComandoSql(Aux,' alter table cadsituacoes ' +
                            ' add I_QTD_DIA integer null; ');
      ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 296');
    end;

   if VpaNumAtualizacao < 297 Then
   begin
      VpfErro := '297';
      ExecutaComandoSql(Aux,' alter table cad_plano_conta ' +
                            ' add C_TIP_CUS char(1) null, ' +
                            ' add C_TIP_DES char(1) null;' +
                            ' Update Cad_plano_conta set c_tip_cus = ''V''; ' +
                            ' Update Cad_plano_conta set c_tip_des = ''F''; ');
      ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 297');
    end;

  if VpaNumAtualizacao < 298 Then
   begin
      VpfErro := '298';
      ExecutaComandoSql(Aux,' alter table CADFORMASPAGAMENTO ' +
                            ' add I_COD_SIT integer null; ');
      ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 298');
    end;

   if VpaNumAtualizacao < 299 Then
   begin
      VpfErro := '299';
      ExecutaComandoSql(Aux,' alter table ITE_CAIXA ' +
                            ' add FIL_ORI integer null; ' );
      ExecutaComandoSql(Aux,' Update ITE_CAIXA set FIL_ORI = 11');
      ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 299');
    end;

    except
        result := false;
        FAtualizaSistema.MostraErro(Aux.sql,'cfg_geral');
        Erro(VpfErro +  ' - OCORREU UM ERRO DURANTE A ATUALIZAÇAO DO SISTEMA inSIG.');
        exit;
    end;
  until result;
end;

end.
