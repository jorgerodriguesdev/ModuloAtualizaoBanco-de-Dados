Unit UnAtualizacao3;

interface
  Uses Classes, DbTables,SysUtils;

Type
  TAtualiza3 = Class
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
constructor TAtualiza3.criar( aowner : TComponent; ADataBase : TDataBase );
begin
  inherited Create;
  Aux := TQuery.Create(aowner);
  DataBase := ADataBase;
  Aux.DataBaseName := 'BaseDados';
end;

{*************** atualiza senha na base de dados ***************************** }
procedure TAtualiza3.AtualizaSenha( Senha : string );
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
function TAtualiza3.AtualizaBanco : boolean;
begin
  result := true;
  AdicionaSQLAbreTabela(Aux,'Select I_Ult_Alt from Cfg_Geral ');
  if Aux.FieldByName('I_Ult_Alt').AsInteger < CT_VersaoBanco Then
    result := AtualizaTabela(Aux.FieldByName('I_Ult_Alt').AsInteger);
end;


{**************************** atualiza a tabela *******************************}
function TAtualiza3.AtualizaTabela(VpaNumAtualizacao : Integer) : Boolean;
var
  VpfErro : String;
begin
  result := true;
  repeat
    Try

        if VpaNumAtualizacao < 395 Then
       begin
          VpfErro := '395';
//          ExecutaComandoSql(Aux,' delete MovComissoes;');
          ExecutaComandoSql(Aux,' drop index FK_Ref_68047_FK; ' +
                                ' alter table MovComissoes '  +
                                ' drop foreign Key FK_Ref_68047; ');

//          ExecutaComandoSql(Aux,' alter table MovComissoes '  +
                                //' delete I_LAN_APG, ' +
                                //' delete D_DAT_VEN, ' +
                                //' delete D_DAT_VAL, ' +
                                //' delete N_PER_PAG; ' );
          ExecutaComandoSql(Aux,' alter table MovComissoes '  +
                                ' add N_QTD_VEN integer null; ');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 395' );
        end;

       if VpaNumAtualizacao < 396 Then
       begin
          VpfErro := '396';
          ExecutaComandoSql(Aux,' alter table CFG_Fiscal '  +
                                ' delete I_COM_PRO, ' +
                                ' delete I_COM_SER; ' );
          ExecutaComandoSql(Aux,' alter table CFG_Financeiro '  +
                                ' modify C_COM_PAR integer null; ');
          ExecutaComandoSql(Aux,' alter table CFG_Financeiro '  +
                                ' add I_PAG_COM integer null, ' +
                                ' add I_COM_PRO integer null, ' +
                                ' add I_COM_SER integer null, ' +
                                ' add I_COM_PAD integer null; ');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 396' );
        end;

      if VpaNumAtualizacao < 397 Then
       begin
          VpfErro := '397';
          ExecutaComandoSql(Aux,' alter table CADCONDICOESPAGTO '  +
                                ' delete N_PER_CON; ' );
          ExecutaComandoSql(Aux,' alter table MOVCONDICAOPAGTO '  +
                                ' ADD N_PER_AJU numeric(8,3) null; ');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 397' );
        end;

       if VpaNumAtualizacao < 398 Then
       begin
          VpfErro := '398';

          ExecutaComandoSql(Aux,' alter table CADSERVICO '  +
                                ' ADD N_VLR_COM numeric(17,7) null; ');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 398' );
        end;


     if VpaNumAtualizacao < 399 Then                             // CadPercentualVendas
       begin
        VpfErro := '399';
        ExecutaComandoSql(Aux,' Create table CADMETACOMISSAO '+
                              ' ( ' +
                              '  I_EMP_FIL integer               not null, '+
                              '  I_COD_MET integer               not null, '+
                              '  C_NOM_MET char(60)                  null, '+
                              '  D_ULT_ALT date                      null, '+
                              '  I_COD_USU integer                   null, '+
                              '  D_DAT_CAD date                      null, '+
                              '  primary key (I_EMP_FIL, I_COD_MET) '+');'+
                              ' comment on table CADMETACOMISSAO is ''CADASTRO DE METAS COMISSAO''; '+
                              ' comment on column CADMETACOMISSAO.I_EMP_FIL is ''CODIGO DA FILIAL''; '+
                              ' comment on column CADMETACOMISSAO.I_COD_MET is ''CODIGO DA META''; '+
                              ' comment on column CADMETACOMISSAO.C_NOM_MET is ''DESCRICAO DA META''; '+
                              ' comment on column CADMETACOMISSAO.D_ULT_ALT is ''ULTIMA ALTERACAO''; '+
                              ' comment on column CADMETACOMISSAO.I_COD_USU is ''CODIGO DO USUARIO''; '+
                              ' comment on column CADMETACOMISSAO.D_DAT_CAD is ''DATA DE CADASTRO''; '+

                              ' Create table MOVMETACOMISSAO '+
                              ' ( ' +
                              '  I_EMP_FIL  integer               not null, '+
                              '  I_SEQ_MOV  integer               not null, '+
                              '  I_COD_MET  integer               not null, '+
                              '  N_TOT_MET  numeric(17,3)             null, '+
                              '  N_PER_MET  numeric(17,3)             null, '+
                              '  N_VLR_MET  numeric(17,3)             null, '+
                              '  I_QTD_MET  integer                   null, '+
                              '  N_VLR_QTD  numeric(17,3)             null, '+
                              '  I_COD_USU  integer                   null, '+
                              '  D_ULT_ALT  date                      null, '+
                              '  primary key (I_EMP_FIL,I_COD_MET, I_SEQ_MOV)' + ');' +
                              ' comment on table MOVMETACOMISSAO is ''MOVIMENTO META COMISSAO''; '+
                              ' comment on column MOVMETACOMISSAO.I_EMP_FIL is ''CODIGO DA FILIAL''; '+
                              ' comment on column MOVMETACOMISSAO.I_COD_MET is ''CODIGO DA META''; '+
                              ' comment on column MOVMETACOMISSAO.I_SEQ_MOV is ''SEQUENCIAL DO MOVIMENTO''; '+
                              ' comment on column MOVMETACOMISSAO.N_TOT_MET is ''VALOR TOTAL DA META''; '+
                              ' comment on column MOVMETACOMISSAO.N_PER_MET is ''PERCENTUAL DA META''; '+
                              ' comment on column MOVMETACOMISSAO.N_VLR_MET is ''VALOR UNITARIO DA META''; '+
                              ' comment on column MOVMETACOMISSAO.I_QTD_MET is ''QUANTIDADE DA META''; '+
                              ' comment on column MOVMETACOMISSAO.N_VLR_QTD is ''VALOR DA QUANTIDADE DA META''; '+
                              ' comment on column MOVMETACOMISSAO.I_COD_USU is ''CODIGO DO USUARIO''; '+
                              ' comment on column MOVMETACOMISSAO.D_ULT_ALT is ''ULTIMA ALTERACAO'';' );

        ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 399');
       end;


     if VpaNumAtualizacao < 400 Then
       begin
          VpfErro := '400';

          ExecutaComandoSql(Aux,' alter table CADVENDEDORES '  +
                                ' ADD I_COD_MET INTEGER null; '+
                                ' alter table MOVCOMISSOES '  +
                                ' ADD I_COD_MET INTEGER null; ');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 400' );
        end;


       if VpaNumAtualizacao < 401 Then
       begin
          VpfErro := '401';

          ExecutaComandoSql(Aux,' alter table MOVCOMISSOES '  +
                                ' ADD I_NRO_DOC integer null; ');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 401' );
        end;

       if VpaNumAtualizacao < 402 Then
       begin
          VpfErro := '402';

          ExecutaComandoSql(Aux,' alter table CADFILIAIS '  +
                                ' ADD I_COD_MET integer null; ');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 402' );
        end;

      if VpaNumAtualizacao < 403 Then
       begin
          VpfErro := '403';

          ExecutaComandoSql(Aux,' alter table CFG_FINANCEIRO '  +
                                ' ADD I_TIP_CAL integer null; ');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 403' );
        end;

      if VpaNumAtualizacao < 404 Then
       begin
          VpfErro := '404';

          ExecutaComandoSql(Aux,' alter table MOVMETACOMISSAO '  +
                                ' ADD N_MET_FIM numeric(17,7) null, ' +
                                ' ADD I_QTD_FIM integer null; ');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 404' );
        end;

       if VpaNumAtualizacao < 405 Then
       begin
          VpfErro := '405';

          ExecutaComandoSql(Aux,' alter table MOVCOMISSOES '  +
                                ' ADD N_CON_PER numeric(17,3) null; ');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 405' );
        end;

       if VpaNumAtualizacao < 406 Then
       begin
          VpfErro := '406';

          ExecutaComandoSql(Aux,' alter table MOVMETACOMISSAO '  +
                                ' ADD N_PER_QTD numeric(17,3) null; ');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 406' );
        end;

       if VpaNumAtualizacao < 407 Then
       begin
          VpfErro := '407';

          ExecutaComandoSql(Aux,' alter table MOVCOMISSOES '  +
                                ' ADD D_INI_FEC date null, ' +
                                ' ADD D_FIM_FEC date null; ');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 407' );
        end;

       if VpaNumAtualizacao < 408 Then
       begin
          VpfErro := '408';

          ExecutaComandoSql(Aux,' alter table MOVCOMISSOES '  +
                                ' ADD N_VLR_PAR numeric(17,3) null; ');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 408' );
        end;

      if VpaNumAtualizacao < 409 Then
       begin
          VpfErro := '409';

//          ExecutaComandoSql(Aux,' alter table MOVCOMISSOES '  +
//                                ' ADD D_DAT_VEN date null; ');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 409' );
        end;

      if VpaNumAtualizacao < 410 Then
       begin
          VpfErro := '410';

          ExecutaComandoSql(Aux,' alter table CFG_FINANCEIRO '  +
                                ' ADD I_TIP_MET integer null; ');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 410' );
        end;

     if VpaNumAtualizacao < 411 Then
       begin
          VpfErro := '411';

          ExecutaComandoSql(Aux,' alter table CADMETACOMISSAO '  +
                                ' ADD I_FOR_MET integer null, ' +
                                ' ADD I_ANA_MET integer null, ' +
                                ' ADD I_CAL_MET integer null, ' +
                                ' ADD I_PAG_MET integer null; ');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 411' );
        end;

      if VpaNumAtualizacao < 412 Then
       begin
          VpfErro := '412';

          ExecutaComandoSql(Aux,' alter table MOVCOMISSOES '  +
                                ' ADD N_VLR_MET numeric(17,3) null; ');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 412' );
        end;


      if VpaNumAtualizacao < 413 Then
       begin
          VpfErro := '413';

          ExecutaComandoSql(Aux,' alter table CADMETACOMISSAO ' +
                                ' ADD I_ORI_MET integer null, ' +
                                ' ADD I_VAL_MET integer null; ');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 413' );
        end;

       if VpaNumAtualizacao < 414 Then
       begin
          VpfErro := '414';

          ExecutaComandoSql(Aux,' alter table CFG_FINANCEIRO ' +
                                ' ADD N_DES_PAR numeric(17,3) null; ');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 414' );
        end;

      if VpaNumAtualizacao < 415 Then
       begin
          VpfErro := '415';

          ExecutaComandoSql(Aux,' alter table CADVENDEDORES ' +
                                ' ADD I_COD_ME2 integer null,' +
                                ' ADD I_COD_ME3 integer null; ');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 415' );
        end;

      if VpaNumAtualizacao < 416 Then
       begin
          VpfErro := '416';

          ExecutaComandoSql(Aux,' alter table MOVCOMISSOES ' +
                                ' ADD I_COD_ME2 integer null,' +
                                ' ADD I_COD_ME3 integer null; '+
                                ' alter table CFG_FINANCEIRO '+
                                ' ADD I_MET_ATU integer null;');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 416' );
        end;

      if VpaNumAtualizacao < 417 Then
       begin
          VpfErro := '417';

          ExecutaComandoSql(Aux,' alter table MOVCOMISSOES ' +
                                ' ADD N_VLR_ME2 numeric(17,3) null,' +
                                ' ADD N_VLR_ME3 numeric(17,3) null; ');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 417' );
        end;

      if VpaNumAtualizacao < 418 Then
       begin
        VpfErro := '418';
        ExecutaComandoSql(Aux,' Create table MOVFECHAMENTO '+
                              ' ( ' +
                              '  I_EMP_FIL  integer               not null, '+
                              '  I_SEQ_MOV  integer               not null, '+
                              '  I_COD_VEN  integer               not null, '+
                              '  I_COD_MET  integer                   null, '+
                              '  I_COD_ME2  integer                   null, '+
                              '  I_COD_ME3  integer                   null, '+
                              '  N_VLR_MET  numeric(17,3)             null, '+
                              '  N_VLR_ME2  numeric(17,3)             null, '+
                              '  N_VLR_ME3  numeric(17,3)             null, '+
                              '  N_PER_VEN  numeric(17,3)             null, '+
                              '  N_VLR_COM  numeric(17,3)             null, '+
                              '  N_VLR_PON  numeric(17,3)             null, '+
                              '  D_INI_FEC  date                      null, '+
                              '  D_FIM_FEC  date                      null, '+
                              '  I_COD_USU  integer                   null, '+
                              '  D_ULT_ALT  date                      null, '+
                              '  primary key (I_EMP_FIL,I_COD_VEN, I_SEQ_MOV)' + ');' +
                              ' comment on table MOVFECHAMENTO is ''FECHAMENTO DE METAS''; '+
                              ' comment on column MOVFECHAMENTO.I_EMP_FIL is ''CODIGO DA FILIAL''; '+
                              ' comment on column MOVFECHAMENTO.I_COD_MET is ''CODIGO DA META1''; '+
                              ' comment on column MOVFECHAMENTO.I_COD_ME2 is ''CODIGO DA META2''; '+
                              ' comment on column MOVFECHAMENTO.I_COD_ME3 is ''CODIGO DA META3''; '+
                              ' comment on column MOVFECHAMENTO.I_SEQ_MOV is ''SEQUENCIAL DO MOVIMENTO''; '+
                              ' comment on column MOVFECHAMENTO.I_COD_VEN is ''CODIGO DO VENDEDOR''; '+
                              ' comment on column MOVFECHAMENTO.N_VLR_MET is ''VALOR DA META1''; '+
                              ' comment on column MOVFECHAMENTO.N_VLR_ME2 is ''VALOR DA META2''; '+
                              ' comment on column MOVFECHAMENTO.N_VLR_ME3 is ''VALOR DA META3 ''; '+
                              ' comment on column MOVFECHAMENTO.N_PER_VEN is ''PERCENTUAL DE COMISSAO DO VENDEDOR''; '+
                              ' comment on column MOVFECHAMENTO.N_VLR_PON is ''QUANTIDADE DE PONTOS''; '+
                              ' comment on column MOVFECHAMENTO.N_VLR_COM is ''VALOR DA COMISSAO DO VENDEDOR''; '+
                              ' comment on column MOVFECHAMENTO.I_COD_USU is ''CODIGO DO USUARIO''; '+
                              ' comment on column MOVFECHAMENTO.D_ULT_ALT is ''ULTIMA ALTERACAO'';'+
                              ' comment on column MOVFECHAMENTO.D_INI_FEC is ''DATA DE INICIO DO FECHAMENTO'';'+
                              ' comment on column MOVFECHAMENTO.D_FIM_FEC is ''DATA DE FIM DO FECHAMENTO'';');

        ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 418');
       end;

      if VpaNumAtualizacao < 419 Then
       begin
          VpfErro := '419';

          ExecutaComandoSql(Aux,' alter table MOVCOMISSOES ' +
                                ' ADD C_FLA_FEC char(1) null; ');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 419' );
        end;

      if VpaNumAtualizacao < 420 Then
       begin
          VpfErro := '420';

          ExecutaComandoSql(Aux,' alter table MOVCOMISSOES ' +
                                ' ADD C_FLA_PAR char(1) null; ');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 420' );
        end;

      if VpaNumAtualizacao < 421 Then
       begin
          VpfErro := '421';

          ExecutaComandoSql(Aux,' alter table MOVFECHAMENTO ' +
                                ' ADD N_VLR_FAT numeric(17,3) null; ');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 421' );
        end;

      if VpaNumAtualizacao < 422 Then
       begin
          VpfErro := '422';

          ExecutaComandoSql(Aux,' alter table CADCONTASARECEBER ' +
                                ' ADD I_SEQ_MAT integer null; ');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 422' );
        end;

     if VpaNumAtualizacao < 423 Then
       begin
        VpfErro := '423';
        ExecutaComandoSql(Aux,' Create table MOVVENDEDORES '+
                              ' ( ' +
                              '  I_EMP_FIL  integer               not null, '+
                              '  I_SEQ_MOV  integer               not null, '+
                              '  I_COD_VEN  integer                   null, '+
                              '  I_COD_MAT  integer                   null, '+
                              '  I_SEQ_NOT  integer                   null, '+
                              '  I_LAN_REC  integer                   null, '+
                              '  I_COD_USU  integer                   null, '+
                              '  D_ULT_ALT  date                      null, '+
                              '  primary key (I_EMP_FIL, I_SEQ_MOV)' + ');' +
                              ' comment on table MOVVENDEDORES is ''VENDEDORES DA NOTA OU CONTRATO''; '+
                              ' comment on column MOVVENDEDORES.I_EMP_FIL is ''CODIGO DA FILIAL''; '+
                              ' comment on column MOVVENDEDORES.I_COD_MAT is ''CODIGO DA MATRICULA''; '+
                              ' comment on column MOVVENDEDORES.I_SEQ_NOT is ''CODIGO DA NOTA FISCAL''; '+
                              ' comment on column MOVVENDEDORES.I_LAN_REC is ''CODIGO DA LANCAMENTO RECEBER''; '+
                              ' comment on column MOVVENDEDORES.I_SEQ_MOV is ''SEQUENCIAL DO MOVIMENTO''; '+
                              ' comment on column MOVVENDEDORES.I_COD_VEN is ''CODIGO DO VENDEDOR''; '+
                              ' comment on column MOVFECHAMENTO.I_COD_USU is ''CODIGO DO USUARIO''; '+
                              ' comment on column MOVFECHAMENTO.D_ULT_ALT is ''ULTIMA ALTERACAO'';');

        ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 423');
       end;

      if VpaNumAtualizacao < 424 Then
       begin
          VpfErro := '424';

          ExecutaComandoSql(Aux,' alter table MOVCOMISSOES ' +
                                ' ADD I_COD_MAT integer null, '+
                                ' ADD I_SEQ_NOT integer null; ');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 424' );
        end;

      if VpaNumAtualizacao < 425 Then
       begin
          VpfErro := '425';

          ExecutaComandoSql(Aux,' alter table MOVCOMISSOES ' +
                                ' ADD I_NRO_LOT integer null');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 425' );
        end;

      if VpaNumAtualizacao < 426 Then
       begin
          VpfErro := '426';

          ExecutaComandoSql(Aux,' alter table MOVFECHAMENTO ' +
                                ' ADD I_NRO_LOT integer null');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 426' );
        end;

      if VpaNumAtualizacao < 427 Then
       begin
          VpfErro := '427';

          ExecutaComandoSql(Aux,' alter table MOVFECHAMENTO ' +
                                ' ADD N_TOT_MET numeric(17,3) null,'+
                                ' ADD N_TOT_ME2 numeric(17,3) null,'+
                                ' ADD N_TOT_ME3 numeric(17,3) null;' );

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 427' );
        end;

      if VpaNumAtualizacao < 428 Then
       begin
          VpfErro := '428';

          ExecutaComandoSql(Aux,' alter table MOVFECHAMENTO ' +
                                ' ADD C_FLA_MOV char(1) null;');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 428' );
        end;

      if VpaNumAtualizacao < 429 Then
       begin
          VpfErro := '429';

          ExecutaComandoSql(Aux,' create unique index CADMETACOMISSAO_PK ' +
                                ' on CADMETACOMISSAO(I_EMP_FIL asc, I_COD_MET asc); '  +
                                ' create unique index MOVMETACOMISSAO_PK ' +
                                ' on MOVMETACOMISSAO(I_EMP_FIL asc, I_COD_MET asc, I_SEQ_MOV asc); '  +
                                ' create unique index MOVFECHAMENTO_PK ' +
                                ' on MOVFECHAMENTO(I_EMP_FIL asc, I_COD_VEN asc, I_SEQ_MOV asc); '  +
                                ' create unique index MOVVENDEDORES_PK ' +
                                ' on MOVVENDEDORES(I_EMP_FIL asc, I_SEQ_MOV asc); '  );

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 429' );
        end;

      if VpaNumAtualizacao < 430 Then
       begin
          VpfErro := '430';
          ExecutaComandoSql(Aux,' alter table MOVMETACOMISSAO ' +
                                ' add foreign key FK_MOVMETACOMISSAO_987 (I_EMP_FIL, I_COD_MET) ' +
                                ' references CADMETACOMISSAO(I_EMP_FIL, I_COD_MET) on update restrict on delete restrict; ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 430' );
        end;

      if VpaNumAtualizacao < 431 Then
       begin
          VpfErro := '431';
          ExecutaComandoSql(Aux,' alter table MOVVENDEDORES ' +
                                ' add foreign key FK_CR_9483 (I_EMP_FIL, I_LAN_REC) ' +
                                ' references CADCONTASARECEBER(I_EMP_FIL, I_LAN_REC) on update restrict on delete restrict; ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 431' );
        end;

      if VpaNumAtualizacao < 432 Then
       begin
          VpfErro := '432';
          ExecutaComandoSql(Aux,' alter table MOVVENDEDORES ' +
                                ' add foreign key FK_MOVVENDEDORES_346 (I_COD_VEN) ' +
                                ' references CADVENDEDORES(I_COD_VEN) on update restrict on delete restrict; ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 432' );
        end;

      if VpaNumAtualizacao < 433 Then
       begin
          VpfErro := '433';
          ExecutaComandoSql(Aux,' create index VEN_MOVVEN_FK on MOVVENDEDORES(I_COD_VEN asc); '  );
          ExecutaComandoSql(Aux,' create index CR_MOVVEN_FK on MOVVENDEDORES(I_EMP_FIL, I_LAN_REC asc); '  );
          ExecutaComandoSql(Aux,' create index CADMET_MOVMET_FK on MOVMETACOMISSAO(I_EMP_FIL, I_COD_MET asc); '  );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 433' );
        end;

      if VpaNumAtualizacao < 434 Then
       begin
          VpfErro := '434';
          ExecutaComandoSql(Aux,' alter table cfg_financeiro add C_OPE_COB char(3) null');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 434' );
        end;

      if VpaNumAtualizacao < 435 Then
      begin
          VpfErro := '435';
          ExecutaComandoSql(Aux,' create table CADITEMPEDIDO  ' +
                         ' ( ' +
                             '   I_COD_ITE  integer               not null,    ' +
                             '   L_DES_ITE  Long VarChar              null,    ' +
                             '   D_ULT_ALT  date                      null,    ' +
                             '   primary key (I_COD_ITE)                       ' +
                         ' );' +
                             ' comment on table CADITEMPEDIDO is ''CADITEMPEDIDO '';' +
                             ' comment on column CADITEMPEDIDO.I_COD_ITE is ''CODIGO DO ITEM '';' +
                             ' comment on column CADITEMPEDIDO.L_DES_ITE is ''NOME DO ITEM '';' +
                             ' comment on column CADITEMPEDIDO.D_ULT_ALT is ''DATA DA ULTIMA ALTERAÇAO '';');
          ExecutaComandoSql(Aux,' create unique index CADITEMPEDIDO_PK ' +
                                ' on CADITEMPEDIDO(I_COD_ITE asc); '  );

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 435' );
       end;

       if VpaNumAtualizacao < 436 Then
       begin
          VpfErro := '436';
          ExecutaComandoSql(Aux,' create table MOVITEMPEDIDO ' +
                         ' ( ' +
                             '   I_EMP_FIL  integer               not null, ' +
                             '   I_LAN_ORC  integer               not null, ' +
                             '   I_COD_ITE  integer               not null, ' +
                             '    D_ULT_ALT  date                     null, ' +
                             '    primary key (I_EMP_FIL, I_LAN_ORC, I_COD_ITE)  ' +
                         ' );' +
                             ' comment on table MOVITEMPEDIDO is ''MOVITEMPEDIDO '';' +
                             ' comment on column MOVITEMPEDIDO.I_EMP_FIL is ''CODIGO DA FILIAL '';' +
                             ' comment on column MOVITEMPEDIDO.I_LAN_ORC is ''NRO DO ORCAMENTO '';' +
                             ' comment on column MOVITEMPEDIDO.I_COD_ITE is ''CODIGO DO ITEM '';' +
                             ' comment on column MOVITEMPEDIDO.D_ULT_ALT is ''DATA ULTIMA ALTERACAO '';' +

                             ' alter table MOVITEMPEDIDO ' +
                             ' add  foreign key FK_MOVITEMP_REF_55_CADORCAM (I_EMP_FIL, I_LAN_ORC) ' +
                             ' references CADORCAMENTOS (I_EMP_FIL, I_LAN_ORC) on update restrict on delete restrict; ');
          ExecutaComandoSql(Aux,' create unique index MOVITEMPEDIDO_PK ' +
                                ' on MOVITEMPEDIDO(I_EMP_FIL asc, I_LAN_ORC asc, I_COD_ITE asc); '  );

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 436' );
       end;

       if VpaNumAtualizacao < 437 Then
       begin
          VpfErro := '437';
          ExecutaComandoSql(Aux,' alter table CFG_FINANCEIRO '+
                                ' ADD C_ALT_DAT char(1) null, '+
                                ' ADD C_MAI_VEN char(1) null;');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 437' );
        end;

       if VpaNumAtualizacao < 438 Then
       begin
          VpfErro := '438';
          ExecutaComandoSql(Aux,' alter table CFG_FINANCEIRO '+
                                ' ADD I_CAI_COP integer null, '+
                                ' ADD I_CAI_COR integer null;');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 438' );
        end;

       if VpaNumAtualizacao < 439 Then
       begin
          VpfErro := '439';
          ExecutaComandoSql(Aux,' alter table CadContas ' +
                                ' add C_MOS_FLU char(1) null;' +
                                ' Update CadContas ' +
                                ' set C_MOS_FLU = ''S'';' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 439' );
       end;

       if VpaNumAtualizacao < 440 Then
       begin
          VpfErro := '440';
          ExecutaComandoSql(Aux,' alter table CFG_GERAL ' +
                                ' add C_MOD_SIS char(1) null;' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 440' );
       end;

       if VpaNumAtualizacao < 441 Then
       begin
          VpfErro := '441';
          ExecutaComandoSql(Aux,' alter table CFG_produto ' +
                                ' delete C_CUP_AUT ;' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 441' );
       end;

       if VpaNumAtualizacao < 442 Then
       begin
          VpfErro := '442';
          ExecutaComandoSql(Aux,' alter table CFG_FINANCEIRO ' +
                                ' add I_IMP_AUT integer null;' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 442' );
       end;

       if VpaNumAtualizacao < 443 Then
       begin
          VpfErro := '443';
          ExecutaComandoSql(Aux,' alter table CFG_FINANCEIRO ' +
                                ' add I_MOD_AUT integer null,' +
                                ' add C_FON_NEG char(1) null,' +
                                ' add C_FON_ITA char(1) null,' +
                                ' add C_FON_SUB char(1) null,' +
                                ' add C_FON_EXP char(1) null;' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 443' );
       end;

       if VpaNumAtualizacao < 444 Then
       begin
          VpfErro := '444';
          ExecutaComandoSql(Aux,' alter table CFG_FINANCEIRO ' +
                                ' add I_NUM_AUT integer null;' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 444' );
       end;

       if VpaNumAtualizacao < 445 Then
       begin
          VpfErro := '445';
          ExecutaComandoSql(Aux,' alter table Cad_Caixa ' +
                                ' add FLA_CAD_PAG char(1) null, '+
                                ' add FLA_CAD_REC char(1) null, '+
                                ' add FLA_PAG_PAG char(1) null, '+
                                ' add FLA_REC_REC char(1) null;' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 445' );
       end;

       if VpaNumAtualizacao < 446 Then
       begin
          VpfErro := '446';
          ExecutaComandoSql(Aux,' alter table CFG_FINANCEIRO ' +
                                ' add I_FLA_COM integer null;' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 446' );
       end;

       if VpaNumAtualizacao < 447 Then
       begin
          VpfErro := '447';
          ExecutaComandoSql(Aux,' alter table CFG_FISCAL ' +
                                ' delete C_MOD_CAI ;' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 447' );
       end;

       if VpaNumAtualizacao < 448 Then
       begin
          VpfErro := '448';
          ExecutaComandoSql(Aux,' alter table CFG_GERAL ' +
                                ' add I_TIP_SIS integer null;' +
                                ' Update CFG_GERAL ' +
                                ' set I_TIP_SIS = 0 ;' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 448' );
       end;

       if VpaNumAtualizacao < 449 Then
       begin
          VpfErro := '449';
          ExecutaComandoSql(Aux,' alter table CFG_PRODUTO ' +
                                ' delete C_TIP_IND ;' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 449' );
       end;

       if VpaNumAtualizacao < 450 Then
       begin
          VpfErro := '450';
          ExecutaComandoSql(Aux,' alter table CFG_FINANCEIRO ' +
                                ' add I_FRM_BAN integer null;' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 450' );
       end;

       if VpaNumAtualizacao < 451 Then
       begin
          VpfErro := '451';
          ExecutaComandoSql(Aux,' alter table MOVCONDICAOPAGTO ' +
                                ' add C_DAT_INI char(1) null;' +
                                ' Update MOVCONDICAOPAGTO ' +
                                ' Set C_DAT_INI = ''N''; ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 451' );
       end;

       if VpaNumAtualizacao < 452 Then
       begin
          VpfErro := '452';
          ExecutaComandoSql(Aux,' alter table cfg_financeiro ' +
                                ' add C_CAI_COP char(1) null,' +
                                ' add C_CAI_COR char(1) null;' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 452' );
       end;

       if VpaNumAtualizacao < 453 Then
       begin
          VpfErro := '453';
          ExecutaComandoSql(Aux,' alter table cfg_Servicos ' +
                                ' add C_OBR_AVI char(1) null;' +
                                ' alter Table cadordemservico ' +
                                ' add I_DIA_ENT integer null ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 453' );
       end;

       if VpaNumAtualizacao < 454 Then
       begin
          VpfErro := '454';
          ExecutaComandoSql(Aux,' drop index fk_REF_31475_FK; ' +
                                ' drop index fk_REF_31485_FK; ' +
                                ' alter table ITE_CAIXA '  +
                                ' drop foreign key FK_PAGAR; ' +
                                ' alter table ITE_CAIXA ' +
                                ' drop foreign key FK_RECEBER; ');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 454' );
       end;

       if VpaNumAtualizacao < 455 Then
       begin
          VpfErro := '455';
          ExecutaComandoSql(Aux,' alter table ITE_CAIXA '  +
                                ' add foreign key  FK_PAGAR(FIL_ORI,LAN_PAGAR, NRO_PAGAR) ' +
                                ' references MOVCONTASAPAGAR(I_EMP_FIL, I_LAN_APG, I_NRO_PAR) on update restrict on delete restrict; ' +

                                ' alter table ITE_CAIXA '  +
                                ' add foreign key  FK_RECEBER(FIL_ORI,LAN_RECEBER, NRO_RECEBER) '  +
                                ' references MOVCONTASARECEBER(I_EMP_FIL, I_LAN_REC, I_NRO_PAR) on update restrict on delete restrict; ' +

                                ' create index fk_REF_31475_FK on ITE_CAIXA(FIL_ORI,LAN_RECEBER, NRO_RECEBER asc); '  +
                                ' create index fk_REF_31485_FK on ITE_CAIXA(FIL_ORI,LAN_PAGAR, NRO_PAGAR asc); '  );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 455' );
       end;

       if VpaNumAtualizacao < 456 Then
       begin
          VpfErro := '456';
          ExecutaComandoSql(Aux,' alter table ITE_Caixa ' +
                                ' add C_NRO_NOT char(15) null,'+
                                ' add D_DAT_NOT date null;');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 456' );
       end;

       if VpaNumAtualizacao < 457 Then
       begin
          VpfErro := '457';
          ExecutaComandoSql(Aux,' alter table CADEVENTOS ' +
                                ' modify C_NOM_EVE char(50) null ');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 457' );
       end;

       if VpaNumAtualizacao < 458 Then
       begin
          VpfErro := '458';
          ExecutaComandoSql(Aux,' create table CADLIGACOES ' +
                                ' ( ' +
                                '     I_EMP_FIL  integer               not null, ' +
                                '     I_SEQ_LIG  integer               not null, ' +
                                '     D_DAT_LIG  date                  not null, ' +
                                '     I_COD_USU  integer                   null, ' +
                                '     I_COD_CLI  integer                   null, ' +
                                '     C_NOM_CLI  char(50)                  null, ' +
                                '     C_TEX_LIG  long varchar              null, ' +
                                '     T_HOR_LIG  timestamp                 null, ' +
                                '     primary key (I_EMP_FIL, I_SEQ_LIG, D_DAT_LIG) ' +
                                '     ); ' +
                                '     comment on table CADLIGACOES is ''CADLIGACOES''; ' +
                                '     comment on column CADLIGACOES.I_EMP_FIL is ''CODIGO DA EMPRESA FILIAL''; ' +
                                '     comment on column CADLIGACOES.I_SEQ_LIG is ''CODIGO SEQUENCIAL DA LIGACAO''; ' +
                                '     comment on column CADLIGACOES.D_DAT_LIG is ''DATA DA LIGACAO''; ' +
                                '     comment on column CADLIGACOES.I_COD_USU is ''CODIGO DO USUARIO''; ' +
                                '     comment on column CADLIGACOES.I_COD_CLI is ''CODIGO DO CLIENTE''; ' +
                                '     comment on column CADLIGACOES.C_NOM_CLI is ''NOME DO CLIENTE''; ' +
                                '     comment on column CADLIGACOES.C_TEX_LIG is ''ASSUNTO DA LIGACAO''; ' +
                                '     comment on column CADLIGACOES.T_HOR_LIG is ''HORA DA LIGACAO'';');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 458' );
       end;

       if VpaNumAtualizacao < 459 Then
       begin
          VpfErro := '459';
          ExecutaComandoSql(Aux,'  create unique index CADLIGACOES_PK  on CADLIGACOES(I_EMP_FIL, I_SEQ_LIG, D_DAT_LIG asc); '  );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 459' );
       end;

       if VpaNumAtualizacao < 460 Then
       begin
          VpfErro := '460';
          ExecutaComandoSql(Aux,' Alter Table cfg_fiscal add I_TIP_TEF integer null ');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 460' );
       end;

       if VpaNumAtualizacao < 461 Then
       begin
          VpfErro := '461';
          ExecutaComandoSql(Aux,' Alter Table cadligacoes ' +
                                ' add C_RET_LIG char(1) null ');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 461' );
       end;

        if VpaNumAtualizacao < 462 Then
       begin
          VpfErro := '462';

          ExecutaComandoSql(Aux,' alter table CADMETACOMISSAO '  +
                                ' ADD I_CAL_FEC integer null; ');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 462' );
        end;

        if VpaNumAtualizacao < 463 Then
       begin
          VpfErro := '463';

          ExecutaComandoSql(Aux,' alter table CFG_GERAL '  +
                                ' ADD C_SEN_CAI char(15) null, ' +
                                ' ADD C_SEN_ADM char(15) null, ' +
                                ' ADD C_SEN_SER char(15) null, ' +
                                ' ADD C_SEN_FIN char(15) null; ' +
                                ' update cfg_geral ' +
                                ' set C_SEN_CAI = (select c_sen_cai from cfg_financeiro ),' +
                                ' C_SEN_ADM = C_SEN_LIB, ' +
                                ' C_SEN_SER = C_SEN_LIB, ' +
                                ' C_SEN_FIN = C_SEN_LIB ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 463' );
        end;

      if VpaNumAtualizacao < 464 Then
       begin
          VpfErro := '464';

          ExecutaComandoSql(Aux,' update CFG_GERAL '  +
                                ' set C_SEN_CAI = null; ');
          aviso('Caso você utilize o módulo caixa, favor atualizar a senha de linheração do caixa!');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 464' );
        end;

      if VpaNumAtualizacao < 465 Then
       begin
          VpfErro := '465';

          ExecutaComandoSql(Aux,' alter Table CadFiliais '  +
                                ' add N_PER_ISS numeric(8,3) null, ' +
                                ' add I_COD_BOL integer null ; ');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 465' );
        end;

      if VpaNumAtualizacao < 466 Then
       begin
          VpfErro := '466';
          ExecutaComandoSql(Aux,' alter Table CadFiliais '  +
                                ' add I_TEX_BOL integer null; ' );
          ExecutaComandoSql(Aux,' update CadFiliais '  +
                                ' set N_PER_ISS = (select n_per_isq from  cfg_fiscal), ' +
                                ' I_COD_BOL = (select i_bol_pad from  cfg_fiscal), ' +
                                ' I_TEX_BOL = (select i_dad_bol from  cfg_fiscal); ');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 466' );
        end;

      if VpaNumAtualizacao < 467 Then
       begin
          VpfErro := '467';
           ExecutaComandoSql(Aux,' alter Table CadNotaFiscais '  +
                                ' add N_PER_ISS numeric(8,3) null; ');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 467' );
        end;

      if VpaNumAtualizacao < 468 Then
       begin
          VpfErro := '468';
           ExecutaComandoSql(Aux,' create table TEMPORARIACPCR ' +
                                 '(                            ' +
                                 '     I_COD_CLI  integer           null            , ' +
                                 '     D_DAT_VEN  date              null            , ' +
                                 '     D_DAT_EMI  date              null            , ' +
                                 '     N_VLR_CCR  numeric(17,5)     null            , ' +
                                 '     I_NRO_NOT  integer           null            , ' +
                                 '     I_TIP_CAD  char(1)           null            , ' +
                                 '     N_VLR_CCP  numeric(17,5)     null            , ' +
                                 '     I_NRO_PAR  integer           null            , ' +
                                 '     D_DAT_PAG  timestamp         null ' +
                                 ' );  ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 468' );
        end;


      if VpaNumAtualizacao < 469 Then
      begin
              VpfErro := '469';
              ExecutaComandoSql(Aux,' Alter Table cadligacoes ' +
                                    ' add C_RET_REC char(1) null, '+
                                    ' add C_NOM_REC char(60) null,'+
                                    ' add C_FEZ_RET char(1) null, '+
                                    ' add C_FEZ_REC char(1) null');
              ExecutaComandoSql(Aux,' Alter Table cadligacoes ' +
                                    ' add C_NOM_SOL char(50) null, '+
                                    ' add C_FON_CLI char(20) null;');
              ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 469' );
       end;

      if VpaNumAtualizacao < 470 Then
       begin
          VpfErro := '470';
          ExecutaComandoSql(Aux,' create table TEMPORARIABANCO ' +
                                '(                            ' +
                                '     N_SAL_ATU  numeric(17,5) null                , ' +
                                '     N_LIM_CRE  numeric(17,5) null                , ' +
                                '     C_NRO_CON  char(15)      null                  ' +
                                ' );  ' );

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 470' );
        end;

       if VpaNumAtualizacao < 471 Then
       begin
          VpfErro := '471';
           ExecutaComandoSql(Aux,' alter table cfg_geral ' +
                                 ' add C_PAT_ATU  char(40)    null ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 471' );
        end;

      if VpaNumAtualizacao < 472 Then
       begin
          VpfErro := '472';
           ExecutaComandoSql(Aux,' alter table cad_caixa ' +
                                 ' add C_CAI_GER  char(1)    null ' );
           ExecutaComandoSql(Aux,' alter table MovBancos ' +
                                 ' add D_DAT_MOV  date    null ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 472' );
        end;

      if VpaNumAtualizacao < 473 Then
       begin
          VpfErro := '473';
           ExecutaComandoSql(Aux,' create table MOVSALDOBANCO ' +
                                 '(                            ' +
                                 '     I_SEQ_MOV integer null,  ' +
                                 '     SEQ_DIARIO  integer null                , ' +
                                 '     N_SAL_ATU  numeric(17,5)  null          , ' +
                                 '     C_NRO_CON  char(15)       null          ,'  +
                                 '     D_ULT_ALT date null                     , ' +
                                 ' primary key (I_SEQ_MOV,SEQ_DIARIO) );  ' +
                                 ' create unique index MOVSALDOBANCO_PK ' +
                                 ' on MOVSALDOBANCO(I_SEQ_MOV asc, SEQ_DIARIO asc ); '  );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 473' );
        end;

      if VpaNumAtualizacao < 474 Then
       begin
          VpfErro := '474';
           ExecutaComandoSql(Aux,' alter table cadusuarios ' +
                                 ' add L_TEX_NOT  Long VarChar    null ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 474' );
        end;

      if VpaNumAtualizacao < 476 Then
       begin
          VpfErro := '476';
           ExecutaComandoSql(Aux,' alter table cfg_financeiro ' +
                                 ' add I_FRM_BAN  INTEGER    null ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 476' );
        end;

     if VpaNumAtualizacao < 478 Then
      begin
        VpfErro := '478';
        aux.sql.clear;
        aux.sql.add(
        ' create table MOVEQUIPAMENTOOS ' +
        ' ( ' +
        '     I_EMP_FIL  integer               not null, ' +
        '     I_COD_ORS  integer               not null, ' +
        '     I_SEQ_MOV  integer               not null, ' +
        '     I_COD_EQU  integer                   null, ' +
        '     I_COD_MAR  integer                   null, ' +
        '     I_COD_MOD  integer                   null, ' +
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
        ' comment on column MOVEQUIPAMENTOOS.C_ACE_EQU is ''ACESSORIOS DO EQUIPAMENTO''; ' +
        ' comment on column MOVEQUIPAMENTOOS.C_GAR_EQU is ''POSSUI GARANTIA S/N''; ' +
        ' comment on column MOVEQUIPAMENTOOS.C_ORC_EQU is ''FAZER ORCAMENTO S/N''; ' +
        ' comment on column MOVEQUIPAMENTOOS.C_DEF_APR is ''DEFEITO APRESENTADO''; ' +
        ' comment on column MOVEQUIPAMENTOOS.C_NRO_NOT is ''NUMERO DA NOTA CASO GARANTIA''; ' );
      aux.ExecSQL;

      ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 478');
      end;

       if VpaNumAtualizacao < 479 Then
      begin
        VpfErro := '479';
        ExecutaComandoSql(Aux,

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

        ' create index Ref_65A_FK on MOVEQUIPAMENTOOS (I_COD_MOD asc); ' +
        ' create index Ref_61A_FK on MOVEQUIPAMENTOOS (I_COD_MAR asc); ' +
        ' create index Ref_132813A_FK on MOVEQUIPAMENTOOS (I_COD_EQU asc); ' +
        ' create unique index MOVEQUIPAMENTOOS_PK on MOVEQUIPAMENTOOS (I_EMP_FIL asc, I_COD_ORS asc, I_SEQ_MOV asc); ' );
        ExecutaComandoSql(Aux,'Update CFG_GERAL set I_Ult_Alt = 479');
      end;

        if VpaNumAtualizacao < 480 Then
      begin
        VpfErro := '480';
        ExecutaComandoSql(Aux,' ALTER TABLE MovEquipamentoOS  ' +
                              '  add D_ULT_ALT date null, ' +
                              '  add N_QTD_EQU numeric(17,3) null, ' +
                              '  add C_VOL_ENT char(10) null,' +
                              '  add C_NRO_SER char(20) null ' );
        ExecutaComandoSql(Aux,'Update Cfg_Geral set I_Ult_Alt = 480');
      end;
    except
        result := false;
        FAtualizaSistema.MostraErro(Aux.sql,'cfg_geral');
        Erro(VpfErro +  ' - OCORREU UM ERRO DURANTE A ATUALIZAÇÃO DO SISTEMA!');
        exit;
    end;
  until result;
end;

end.

