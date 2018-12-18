Unit UnAtualizacao2;

interface
  Uses Classes, DbTables,SysUtils;

Type
  TAtualiza2 = Class
    Private
      Aux : TQuery;
      DataBase : TDataBase;
      procedure AtualizaSenha( Senha : string );
    public
      function AtualizaTabela(VpaNumAtualizacao : Integer) : Boolean;
      function AtualizaBanco : Boolean;
      procedure AtualizaPlanoConta;
      constructor criar( aowner : TComponent; ADataBase : TDataBase );
end;

Const
  CT_SenhaAtual = '9774';

implementation

Uses FunSql, ConstMsg, FunNumeros, Registry, Constantes, FunString, funvalida, AAtualizaSistema;

{*************************** cria a classe ************************************}
constructor TAtualiza2.criar( aowner : TComponent; ADataBase : TDataBase );
begin
  inherited Create;
  Aux := TQuery.Create(aowner);
  DataBase := ADataBase;
  Aux.DataBaseName := 'BaseDados';
end;

{*************** atualiza senha na base de dados ***************************** }
procedure TAtualiza2.AtualizaSenha( Senha : string );
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
function TAtualiza2.AtualizaBanco : boolean;
begin
  result := true;
  AdicionaSQLAbreTabela(Aux,'Select I_Ult_Alt from Cfg_Geral ');
  if Aux.FieldByName('I_Ult_Alt').AsInteger < CT_VersaoBanco Then
    result := AtualizaTabela(Aux.FieldByName('I_Ult_Alt').AsInteger);
end;

procedure TAtualiza2.AtualizaPlanoConta;
 var
   v : TStringList;
   laco , conta: integer;
   Aux1 : TQuery;
   Mascara,Codigo : string;
begin
  Aux1 := TQuery.Create(nil);
  Aux1.DataBaseName := 'BaseDados';

  V := TStringList.create;
  AdicionaSQLAbreTabela(aux1, 'Select c_mas_pla from cadempresas where i_cod_emp = 1');
  Mascara := aux1.fieldByname('c_mas_pla').AsString;
  aux1.close;

  AdicionaSQLAbreTabela(aux1, 'Select * from Cad_plano_conta where i_cod_emp = 1');

{  while not aux1.eof do
  begin
    v.Clear;
    codigo := '';
    conta := DesmontaCodigo(v, aux1.fieldByname('c_cla_pla').AsString, mascara);
    for laco := 0 to v.Count - 1 do
       if v.Strings[laco] <> '' then
       begin
         if codigo <> '' then
            codigo := codigo + '.';
         codigo := codigo + v.Strings[laco];
         ExecutaComandoSql(Aux,' update Cad_Plano_conta ' +
                               ' set C_NIL_00' + inttostr(laco+1)+ ' = ''' +
                               codigo + '''' +
                               ' where c_cla_pla = ''' + aux1.fieldByname('c_cla_pla').AsString + '''' +
                               ' and i_cod_emp = 1 ');
       end;
    aux1.Next;
  end;  }
  ExecutaComandoSql(Aux,' update Cad_Plano_conta ' +
                        ' set I_COD_RED = c_cla_pla ');

  aux1.close;
  aux1.free;
  v.free;
end;

{**************************** atualiza a tabela *******************************}
function TAtualiza2.AtualizaTabela(VpaNumAtualizacao : Integer) : Boolean;
var
  VpfErro : String;
begin
  result := true;
  repeat
    Try

       if VpaNumAtualizacao < 300 Then
       begin
          VpfErro := '300';
          ExecutaComandoSql(Aux,' alter table  movnotasfiscaisfor ' +
                                ' modify N_QTD_PRO numeric(17,6) null; ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 300');
        end;

       if VpaNumAtualizacao < 301 Then
       begin
          VpfErro := '301';
          ExecutaComandoSql(Aux,' insert into cadprodutos(i_seq_pro, i_cod_emp) values (0,1); ' +
                                ' insert into movqdadeproduto(i_seq_pro, i_emp_fil) select 0, i_emp_fil from cadfiliais; ' +
                                ' insert into movtabelapreco(i_seq_pro, i_cod_emp, i_cod_tab) ' +
                                ' select 0,i_cod_emp,I_cod_tab from cadtabelapreco; ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 301' );
        end;

       if VpaNumAtualizacao < 302 Then
       begin
          VpfErro := '302';
          ExecutaComandoSql(Aux,' insert into cadnatureza(c_cod_nat, c_nom_nat, c_ent_sai, d_ult_alt) ' +
                                '  values(''ECF'', ''Natureza para ECF'', ''S'',now(*)); ' +
                                '  insert into movnatureza(c_cod_nat, i_seq_mov,c_nom_mov, c_ger_fin, c_ent_sai, c_bai_est, c_cal_icm, ' +
                                '                                                c_ger_com, c_imp_aut, c_ins_ser, c_nat_loc, c_ins_pro, c_mos_not, c_mos_fat, ' +
                                '                                                d_ult_alt, c_des_not) ' +
                                '  values(''ECF'',1,''ECF'',''S'',''S'',''S'',''S'',''S'',''N'',''S'',''S'',''S'',''N'',''S'',now(*),''ECF''); ' +
                                '  update cadnotafiscais ' +
                                '  set c_cod_nat = ''ECF'', ' +
                                '  i_ite_nat = 1 ' +
                                '  where c_cod_nat is null and c_fla_ecf = ''S''; ' +
                                '  update cadnotafiscais ' +
                                '  set c_ser_not = ''2'' ' +
                                '  where c_fla_ecf = ''S'' and c_ser_not is null; ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 302' );
        end;

       if VpaNumAtualizacao < 303 Then
       begin
          VpfErro := '303';
          ExecutaComandoSql(Aux,' alter table cad_plano_conta delete c_tip_cus ');
          ExecutaComandoSql(Aux,' alter table cad_plano_conta delete c_tip_des ');
          ExecutaComandoSql(Aux,' alter table cad_plano_conta add I_TIP_DES integer null');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 303' );
        end;

       if VpaNumAtualizacao < 304 Then
       begin
          VpfErro := '304';
          ExecutaComandoSql(Aux,' alter table MOVREQUISICAOMATERIAL add D_ULT_ALT date null ');
          ExecutaComandoSql(Aux,' update MOVREQUISICAOMATERIAL set D_ULT_ALT = ' + SQLTextoDataAAAAMMMDD(date));
          ExecutaComandoSql(Aux,' alter table CADICMSECF add D_ULT_ALT date null ');
          ExecutaComandoSql(Aux,' update CADICMSECF set D_ULT_ALT = ' + SQLTextoDataAAAAMMMDD(date));
          ExecutaComandoSql(Aux,' alter table MOVITENSCUSTO add D_ULT_ALT date null ');
          ExecutaComandoSql(Aux,' update MOVITENSCUSTO set D_ULT_ALT = ' + SQLTextoDataAAAAMMMDD(date));
          ExecutaComandoSql(Aux,' alter table MOVSUMARIZAESTOQUE add D_ULT_ALT date null ');
          ExecutaComandoSql(Aux,' update MOVSUMARIZAESTOQUE set D_ULT_ALT = ' + SQLTextoDataAAAAMMMDD(date));
          ExecutaComandoSql(Aux,' alter table MOVFORMAS add D_ULT_ALT date null ');
          ExecutaComandoSql(Aux,' update MOVFORMAS set D_ULT_ALT = ' + SQLTextoDataAAAAMMMDD(date));
          ExecutaComandoSql(Aux,' alter table CADTIPOENTREGA add D_ULT_ALT date null ');
          ExecutaComandoSql(Aux,' update CADTIPOENTREGA set D_ULT_ALT = ' + SQLTextoDataAAAAMMMDD(date));
          ExecutaComandoSql(Aux,' alter table MOVCAIXAESTOQUE add D_ULT_ALT date null ');
          ExecutaComandoSql(Aux,' update MOVCAIXAESTOQUE set D_ULT_ALT = ' + SQLTextoDataAAAAMMMDD(date));
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 304' );
        end;

       if VpaNumAtualizacao < 305 Then
       begin
          VpfErro := '305';
          ExecutaComandoSql(Aux,
            ' create table PERFIL_RECEBIDO  ' +
            ' (                                   ' +
            '   EMP_FIL  integer               not null,  ' +
            '   COD_PERFIL  integer               not null,  ' +
            '   DAT_IMPORTACAO  date                   null,  ' +
            '   primary key (EMP_FIL, COD_PERFIL)  ' +
            ' );                                               ' +

            ' comment on table PERFIL_RECEBIDO is  ''PERFIL RECEBIDOS'';  ' +
            ' comment on column PERFIL_RECEBIDO.EMP_FIL is  ''CODIGO EMPRESA FILIAL '';  ' +
            ' comment on column PERFIL_RECEBIDO.COD_PERFIL is  ''CODIGO DPERFIL '';  ' +
            ' comment on column PERFIL_RECEBIDO.DAT_IMPORTACAO is  ''DATA DA ULTIMA IMPORTACAO'';  ' +
            ' create unique index PERFIL_RECEBIDO_PK on PERFIL_RECEBIDO(EMP_FIL asc, COD_PERFIL asc); ' );
           ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 305' );
        end;

       if VpaNumAtualizacao < 306 Then
       begin
          VpfErro := '306';
          ExecutaComandoSql(Aux,' alter table cfg_fiscal add C_MOS_INA char(1) null ');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 306' );
        end;


       if VpaNumAtualizacao < 307 Then
       begin
          VpfErro := '307';
          ExecutaComandoSql(Aux,' drop index REF_9027_FK;' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 307' );
        end;

       if VpaNumAtualizacao < 308 Then
       begin
          VpfErro := '308';
          ExecutaComandoSql(Aux,' create index CP_NOME on CADCLIENTES (C_NOM_CLI asc); ' +
                                ' create index CP_SERIE on  CadNotaFIscais(I_EMP_FIL, C_SER_NOT, C_FLA_ECF asc); ' +
                                ' alter table cfg_financeiro add C_SEN_TRA char(1) null ');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 308' );
        end;

     if VpaNumAtualizacao < 309 Then
       begin
          VpfErro := '309';
            ExecutaComandoSql(Aux,

                '  create table MOVGRUPOUSUARIO  ' +
                '  (                                        ' +
                '   I_EMP_FIL  integer               not null,  ' +
                '   I_COD_USU  integer               not null,  ' +
                '   I_FIL_NEG  integer               not null,  ' +
                '   primary key (I_EMP_FIL, I_COD_USU, I_FIL_NEG)          ' +
                ' );                                            ' +

                ' comment on table MOVGRUPOUSUARIO is ''PERMITE OU NAO O ACESSO A FILIAL'';  ' +
                ' comment on column MOVGRUPOUSUARIO.I_EMP_FIL is  ''CODIGO EMPRESA FILIAL '';  ' +
                ' comment on column MOVGRUPOUSUARIO.I_COD_USU is  ''CODIGO DO USUARIO '';   ' +
                ' comment on column MOVGRUPOUSUARIO.I_FIL_NEG is  ''CODIGO DO FILIAL QUE NAO PODE SER ACESSADO '';  ' +
                ' create unique index MOVGRUPOUSUARIO_PK on MOVGRUPOUSUARIO (I_EMP_FIL asc, I_COD_USU asc, i_fil_neg ASC); ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 309' );
        end;

       if VpaNumAtualizacao < 310 Then
       begin
          VpfErro := '310';
          ExecutaComandoSql(Aux,' alter table tabela_exportacao ' +
                                ' add C_PER_UPD char(1) null; ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 310' );
        end;

       if VpaNumAtualizacao < 311 Then
       begin
          VpfErro := '311';
          ExecutaComandoSql(Aux,' delete movformas ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 311' );
        end;

       if VpaNumAtualizacao < 312 Then
       begin
          VpfErro := '312';
          ExecutaComandoSql(Aux,' create table MOVFORMA ' +
                                ' ( ' +
                                ' I_EMP_FIL  integer               not null, ' +
                                ' I_NRO_LOT  integer               not null, ' +
                                ' I_LAN_REC  integer               not null, ' +
                                ' I_NRO_PAR  integer               not null, ' +
                                ' I_COD_FRM  integer                   null, ' +
                                ' N_VLR_MOV  numeric(17,3)             null, ' +
                                ' C_NRO_CON  char(13)                  null, ' +
                                ' C_NRO_DOC  char(20)                  null, ' +
                                ' C_NOM_CHE  char(50)                  null, ' +
                                ' D_ULT_ALT  date                      null, ' +
                                ' D_CHE_VEN  date                      null, ' +
                                ' I_COD_BAN  integer                   null, ' +
                                ' primary key (I_EMP_FIL, I_NRO_LOT, I_LAN_REC, I_NRO_PAR) ' +
                                ' ); ' +

                                ' comment on table MOVFORMA is ''MOVFORMA'';  ' +
                                ' comment on column MOVFORMA.I_EMP_FIL is ''CODIGO DA FILIAL''; ' +
                                ' comment on column MOVFORMA.I_NRO_LOT is ''SEQUENCIAL DO MOVIMENTO''; ' +
                                ' comment on column MOVFORMA.I_LAN_REC is ''NUMERO DO LANCAMENTO''; ' +
                                ' comment on column MOVFORMA.I_NRO_PAR is ''NUMERO DA PARCELA''; ' +
                                ' comment on column MOVFORMA.I_COD_FRM is ''CODIGO DA FORMA DE PAGAMENTO''; ' +
                                ' comment on column MOVFORMA.N_VLR_MOV is ''VALOR DO MOVIMENTO''; ' +
                                ' comment on column MOVFORMA.C_NRO_CON is ''NUMERO DA CONTA''; ' +
                                ' comment on column MOVFORMA.C_NRO_DOC is ''NUMERO DO DOCUMENTO''; ' +
                                ' comment on column MOVFORMA.C_NOM_CHE is ''NOMINAL DO CHEQUE''; ' +
                                ' comment on column MOVFORMA.D_ULT_ALT is ''DATA DE ALTERACAO''; ' +
                                ' comment on column MOVFORMA.D_CHE_VEN is ''VENCIMENTO DO CHEQUE''; ' +
                                ' comment on column MOVFORMA.I_COD_BAN is ''CODIGO DO BANCO''; ' +


                                ' alter table MOVFORMA ' +
                                    ' add foreign key FK_MOVFORMA_REF_17882_MOVCONTA (I_EMP_FIL, I_LAN_REC, I_NRO_PAR) ' +
                                       ' references MOVCONTASARECEBER (I_EMP_FIL, I_LAN_REC, I_NRO_PAR) on update restrict on delete restrict; ' +

                                ' alter table MOVFORMA ' +
                                    ' add foreign key FK_MOVFORMA_REF_17883_CADBANCO (I_COD_BAN) ' +
                                       ' references CADBANCOS (I_COD_BAN) on update restrict on delete restrict; ' +

                                ' alter table MOVFORMA ' +
                                    ' add foreign key FK_MOVFORMA_REF_17883_CADFORMA (I_COD_FRM) ' +
                                       ' references CADFORMASPAGAMENTO (I_COD_FRM) on update restrict on delete restrict;  ' );

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 312' );
        end;

       if VpaNumAtualizacao < 313 Then
       begin
          VpfErro := '313';
          ExecutaComandoSql(Aux,' create unique index MOVFORMA on MOVFORMA (I_EMP_FIL asc, I_NRO_LOT asc, I_NRO_PAR asc, I_LAN_REC asc); ' +
                                ' create unique index MOVFORMA_PK on MOVFORMA (I_EMP_FIL asc, I_NRO_LOT asc, I_LAN_REC asc, I_NRO_PAR asc); ' +
                                ' create index Ref_178825_FK on MOVFORMA (I_EMP_FIL asc, I_LAN_REC asc, I_NRO_PAR asc); ' +
                                ' create index Ref_178832_FK on MOVFORMA (I_COD_BAN asc); ' +
                                ' create index Ref_178835_FK on MOVFORMA (I_COD_FRM asc); ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 313' );
        end;

       if VpaNumAtualizacao < 314 Then
       begin
          VpfErro := '314';
          ExecutaComandoSql(Aux,' insert into movforma( i_emp_fil, i_nro_lot, i_cod_frm, ' +
                                ' n_vlr_mov, c_nro_con,c_nro_doc, c_nom_che, ' +
                                ' d_ult_alt, i_lan_rec, i_nro_par, d_che_ven, i_cod_ban) ' +
                                ' select i_emp_fil, i_lan_rec, i_cod_frm, isnull(n_vlr_che,n_vlr_par), ' +
                                ' isnull(c_con_che,c_nro_con),isnull(c_nro_che, c_nro_doc), null, ' +
                                ' d_ult_alt, i_lan_rec, i_nro_par, d_che_ven, i_cod_ban '  +
                                ' from movcontasareceber ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 314' );
        end;

       if VpaNumAtualizacao < 315 Then
       begin
          VpfErro := '315';
          ExecutaComandoSql(Aux,' alter table movcontasareceber ' +
                                ' drop foreign key FK_BANCOS; ' +
                                ' alter table movcontasareceber ' +
                                ' drop foreign key FK_CADCONTAS; ' +
                                ' alter table movcontasareceber ' +
                                ' drop foreign key FK_MOVBANCOS; ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 315' );
        end;

       if VpaNumAtualizacao < 316 Then
       begin
          VpfErro := '316';
          ExecutaComandoSql(Aux,' drop index FK_CADCONTAS_FK; ' +
                                ' drop index FK_MOVBANCOS_FK; ' +
                                ' drop index FK_REF_12154_FK; ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 316' );
        end;

       if VpaNumAtualizacao < 317 Then
       begin
          VpfErro := '317';
          ExecutaComandoSql(Aux,' alter table movcontasareceber ' +
                                ' delete c_nro_con, ' +
                                ' delete c_nro_doc, ' +
                                ' delete d_che_ven, ' +
                                ' delete i_cod_ban, ' +
                                ' delete c_con_che, ' +
                                ' delete n_vlr_che, ' +
                                ' delete c_nro_che; ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 317' );
        end;

       if VpaNumAtualizacao < 318 Then
       begin
          VpfErro := '318';
          ExecutaComandoSql(Aux,' create index CP1_MOVFORMA on MOVFORMA(D_CHE_VEN asc); ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 318' );
       end;

       if VpaNumAtualizacao < 319 Then
       begin
          VpfErro := '319';
          ExecutaComandoSql(Aux,' create table MOVCHEQUEDEVOLVIDO ' +
                                ' ( ' +
                                ' I_EMP_FIL  integer               not null, ' +
                                ' I_NRO_LAN  integer               not null, ' +
                                ' I_COD_CLI  integer                   null, ' +
                                ' I_LAN_REC  integer                   null, ' +
                                ' I_NRO_PAR  integer                   null, ' +
                                ' N_VLR_MOV  numeric(17,3)             null, ' +
                                ' C_NRO_CON  char(13)                  null, ' +
                                ' C_NRO_DOC  char(20)                  null, ' +
                                ' D_ULT_ALT  date                      null, ' +
                                ' D_CHE_VEN  date                      null, ' +
                                ' I_COD_BAN  integer                   null, ' +
                                ' C_SIT_CHE  CHAR(1)                   null, ' +
                                ' primary key (I_EMP_FIL, I_NRO_LAN ) ' +
                                ' ); ' +

                                ' comment on table MOVCHEQUEDEVOLVIDO is ''MOVIMENTO DE CHEQUES DEVOLVIDO'';  ' +
                                ' comment on column MOVCHEQUEDEVOLVIDO.I_EMP_FIL is ''CODIGO DA FILIAL''; ' +
                                ' comment on column MOVCHEQUEDEVOLVIDO.I_NRO_LAN is ''SEQUENCIAL DO MOVIMENTO''; ' +
                                ' comment on column MOVCHEQUEDEVOLVIDO.I_COD_CLI is ''SEQUENCIAL DO MOVIMENTO''; ' +
                                ' comment on column MOVCHEQUEDEVOLVIDO.I_LAN_REC is ''NUMERO DO LANCAMENTO''; ' +
                                ' comment on column MOVCHEQUEDEVOLVIDO.I_NRO_PAR is ''NUMERO DA PARCELA''; ' +
                                ' comment on column MOVCHEQUEDEVOLVIDO.N_VLR_MOV is ''VALOR DO MOVIMENTO''; ' +
                                ' comment on column MOVCHEQUEDEVOLVIDO.C_NRO_CON is ''NUMERO DA CONTA''; ' +
                                ' comment on column MOVCHEQUEDEVOLVIDO.C_NRO_DOC is ''NUMERO DO DOCUMENTO''; ' +
                                ' comment on column MOVCHEQUEDEVOLVIDO.D_ULT_ALT is ''DATA DE ALTERACAO''; ' +
                                ' comment on column MOVCHEQUEDEVOLVIDO.D_CHE_VEN is ''VENCIMENTO DO CHEQUE''; ' +
                                ' comment on column MOVCHEQUEDEVOLVIDO.I_COD_BAN is ''CODIGO DO BANCO''; ' +
                                ' comment on column MOVCHEQUEDEVOLVIDO.C_SIT_CHE is ''SITUACAO DO CHEQUE''; ' +
                                ' alter table MOVCHEQUEDEVOLVIDO ' +
                                    ' add foreign key FK_MOVCHEQUE_REF_23984 (I_COD_CLI) ' +
                                       ' references CADCLIENTES(I_COD_CLI) on update restrict on delete restrict; ' +

                                ' alter table MOVCHEQUEDEVOLVIDO ' +
                                    ' add foreign key FK_MOVCHEQUE_343_CADBANCO (I_COD_BAN) ' +
                                       ' references CADBANCOS (I_COD_BAN) on update restrict on delete restrict; '  +
                                ' create unique index MOVCHEQUE_PK on MOVCHEQUEDEVOLVIDO (I_EMP_FIL asc, I_NRO_LAN asc ); ' );

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 319' );
       end;

       if VpaNumAtualizacao < 320 Then
       begin
          VpfErro := '320';
          ExecutaComandoSql(Aux,' alter table movforma ' +
                                ' add C_SIT_FRM char(1) null, ' +
                                ' add I_LAN_BAC integer null; ' +
                                ' update movForma set c_sit_frm = ''C'' ;');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 320' );
       end;

       if VpaNumAtualizacao < 321 Then
       begin
          VpfErro := '321';
          ExecutaComandoSql(Aux,' alter table CRP_PARCIAL ' +
                                ' drop foreign key FK_REF_36344; ' +
                                ' alter table MOV_DIARIO ' +
                                ' drop foreign key FK_REF_36359; ' +
                                ' alter table MOV_DIARIO ' +
                                ' drop foreign key FK_REF_31497; ' +
                                ' alter table MOV_ALTERACAO ' +
                                ' drop foreign key FK_REF_40679; ');
          ExecutaComandoSql(Aux,' update  cadusuarios ' +
                                ' set i_cod_usu = cast( i_emp_fil ||''0'' || i_cod_usu as integer) ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 321' );
       end;

       if VpaNumAtualizacao < 322 Then
       begin
          VpfErro := '322';
          ExecutaComandoSql(Aux,' drop index FK_REF_295_FK; ' +
                                ' drop index MOVGRUPOFORM_PK; ' +
                                ' alter TABLE MOVGRUPOFORM  drop primary key; ' +
                                ' alter table MOVGRUPOFORM ' +
                                ' drop foreign key FK_REF_295; ' +
                                ' update  movgrupoform ' +
                                ' set i_cod_gru = cast( i_emp_fil ||''0'' || i_cod_gru as integer); ' +
                                ' alter table  movgrupoform ' +
                                ' delete i_emp_fil; ' +
                                ' alter table MovGrupoForm add primary key (i_cod_gru, c_cod_fom); ' +
                                ' create index MovGrupoForm_PK on MovGrupoForm (i_cod_gru, c_cod_fom); ' +
                                ' alter table CADUSUARIOS ' +
                                ' drop foreign key FK_REF_275; ' +
                                ' alter table CADGRUPOS ' +
                                ' drop foreign key FK_REF_328; ' +
                                ' drop index CADGRUPOS_PK; ' +
                                ' drop index FK_REF_328_FK; ' +
                                ' alter TABLE CADGRUPOS  drop primary key; ' +
                                ' update  cadgrupos ' +
                                ' set i_cod_gru = cast( i_emp_fil ||''0'' || i_cod_gru as integer); ' +
                                ' update  cadusuarios ' +
                                ' set i_cod_gru = cast( i_emp_fil ||''0'' || i_cod_gru as integer); ' +
                                ' alter table Cadgrupos add primary key (i_cod_gru); ' +
                                ' create index CADGRUPOS_PK on CadGrupos (i_cod_gru); ' +
                                ' alter table cadusuarios ' +
                                ' add foreign key FK_CADUSUGRU_REF_1234 (I_COD_GRU) ' +
                                ' references CADGRUPOS(I_COD_GRU) on update restrict on delete restrict; ' +
                                ' alter table movgrupoform ' +
                                ' add foreign key FK_CADGRUFOR_REF_12334 (I_COD_GRU) ' +
                                ' references CADGRUPOS(I_COD_GRU) on update restrict on delete restrict; ' +
                                ' drop index CADUSUARIOS_PK; ' +
                                ' alter TABLE CADUSUARIOS  drop primary key; ' +
                                ' alter table CadUsuarios add primary key (i_cod_usu); ' +
                                ' create index CADUSUARIOS_PK on CadUsuarios(i_cod_usu); ' +
                                ' alter table cadusuarios ' +
                                ' add foreign key FK_CADFILIAL_REF_12345 (I_EMP_FIL) ' +
                                ' references CADFILIAIS(I_EMP_FIL) on update restrict on delete restrict; ' +
                                ' alter table cadgrupos ' +
                                ' add foreign key FK_CADFILIAL_REF_1234 (I_EMP_FIL) ' +
                                ' references CADFILIAIS(I_EMP_FIL) on update restrict on delete restrict; ' +
                                ' create index FK_CADFILIAL_234 on CadUsuarios(i_emp_fil); ' +
                                ' create index FK_CADFILIAL_2578 on CadGrupos(i_emp_fil); ' +
                                ' delete MOVGRUPOUSUARIO; commit; ' +
                                ' drop index MOVGRUPOUSUARIO_PK; ' +
                                ' alter table  MOVGRUPOUSUARIO drop primary key; ' +
                                ' alter table  MOVGRUPOUSUARIO add primary key (i_cod_usu, i_fil_neg); ' +
                                ' create index  MOVGRUPOUSUARIO_PK on  MOVGRUPOUSUARIO(i_cod_usu, i_fil_neg); ' +
                                ' alter table  MOVGRUPOUSUARIO add D_ULT_ALT date null; ' +
                                ' alter table  MOVGRUPOUSUARIO delete I_EMP_FIL; ' +
                                ' alter table MOVGRUPOUSUARIO ' +
                                ' add foreign key FK_CADUSUARIOPER_REF_496  (I_COD_USU) ' +
                                ' references CADUSUARIOS(I_COD_USU) on update restrict on delete restrict; ' +
                                ' create index FK_MOVGRUPOUSUARIO_1244 on  MOVGRUPOUSUARIO(i_cod_usu); ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 322' );
       end;

       if VpaNumAtualizacao < 323 Then
       begin
          VpfErro := '323';
          ExecutaComandoSql(Aux,' update cadclientes set i_cod_usu  = cast(110  || i_cod_usu as integer) where i_cod_usu is not null; ' +
                                ' update cadcontasapagar ' +
                                ' set i_cod_usu = cast(i_emp_fil || ''0''  || i_cod_usu as integer) ' +
                                ' where i_cod_usu is not null; ' +
                                ' update cadcontasareceber ' +
                                ' set i_cod_usu = cast(i_emp_fil || ''0''  || i_cod_usu as integer) ' +
                                ' where i_cod_usu is not null; ' +
                                ' update cadnotafiscais ' +
                                ' set i_cod_usu = cast(i_emp_fil || ''0'' || i_cod_usu as integer) ' +
                                ' where i_cod_usu is not null; ' +
                                ' update cadorcamentos ' +
                                ' set i_cod_usu = cast(i_emp_fil || ''0''  || i_cod_usu as integer) ' +
                                ' where i_cod_usu is not null; ' +
                                ' update cadOrdemServico ' +
                                ' set i_cod_usu = cast(i_emp_fil || ''0''  || i_cod_usu as integer) ' +
                                ' where i_cod_usu is not null; ' +
                                ' update cadOrdemServico ' +
                                ' set i_cod_ate = cast(i_emp_fil || ''0''  || i_cod_ate as integer) ' +
                                ' where i_cod_ate is not null; ' +
                                ' update cadRequisicaoMaterial ' +
                                ' set i_cod_usu = cast(i_emp_fil || ''0''  || i_cod_usu as integer) ' +
                                ' where i_cod_usu is not null; ' +
                                ' update cadRequisicaoMaterial ' +
                                ' set i_usu_req = cast(i_emp_fil || ''0''  || i_usu_req as integer) ' +
                                ' where i_usu_req is not null; ' +
                                ' update MovCaixaEstoque ' +
                                ' set i_cod_usu = cast(i_emp_fil || ''0''  || i_cod_usu as integer) ' +
                                ' where i_cod_usu is not null; ' +
                                ' update movcontasapagar ' +
                                ' set i_cod_usu = cast(i_emp_fil || ''0'' || i_cod_usu as integer) ' +
                                ' where i_cod_usu is not null; ' +
                                ' update movcontasareceber ' +
                                ' set i_cod_usu = cast(i_emp_fil || ''0'' || i_cod_usu as integer) ' +
                                ' where i_cod_usu is not null; ' +
                                ' update movordemservico ' +
                                ' set i_cod_usu = cast(i_emp_fil || ''0''  || i_cod_usu as integer) ' +
                                ' where i_cod_usu is not null; ' +
                                ' update movHistoricoCliente ' +
                                ' set i_cod_usu = cast(110  || i_cod_usu as integer) ' +
                                ' where i_cod_usu is not null; ' +
                                ' update crp_parcial ' +
                                ' set cod_usuario = cast(110  || cod_usuario as integer) ' +
                                ' where cod_usuario is not null; ' +
                                ' update mov_alteracao ' +
                                ' set cod_usuario_alteracao = cast(110  || cod_usuario_alteracao as integer) ' +
                                ' where cod_usuario_alteracao is not null; ' +
                                ' update mov_diario ' +
                                ' set cod_usuario_abertura = cast(110  || cod_usuario_abertura as integer) ' +
                                ' where cod_usuario_abertura is not null; ' +
                                ' update mov_diario ' +
                                ' set cod_usuario_Fechamento = cast(110  || cod_usuario_fechamento as integer) ' +
                                ' where cod_usuario_fechamento is not null; ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 323' );
       end;

       if VpaNumAtualizacao < 324 Then
       begin
          VpfErro := '324';
          ExecutaComandoSql(Aux,' alter table CadUsuarios ' +
                                ' add C_FIL_NEG varChar(100) null; ');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 324' );
       end;

       if VpaNumAtualizacao < 325 Then
       begin
          VpfErro := '325';
          ExecutaComandoSql(Aux,' alter table CadUsuarios ' +
                                ' add I_FIL_INI integer null; ');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 325' );
       end;

       if VpaNumAtualizacao < 326 Then
       begin
          VpfErro := '326';
          ExecutaComandoSql(Aux,' alter table CadProdutos ' +
                                ' add I_ORI_MER integer null; '  +
                                ' update cadprodutos set i_ori_mer = 0;');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 326' );
       end;

       if VpaNumAtualizacao < 327 Then
       begin
          VpfErro := '327';
          ExecutaComandoSql(Aux,' alter table cfg_fiscal ' +
                                ' delete c_cst_not; ');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 327' );
       end;

       if VpaNumAtualizacao < 328 Then
       begin
          VpfErro := '328';
          ExecutaComandoSql(Aux,' alter table movnatureza ' +
                                ' add C_ATI_NAT char(1) null, ' +
                                ' add C_NAT_IMP char(10) null, ' +
                                ' add C_CLI_FOR char(1) null; ' +
                                ' update movnatureza set c_cli_for = c_ent_sai; ' +
                                ' update movnatureza mov ' +
                                ' set c_nat_imp = (select c_cod_nat from cadnatureza mov1 where mov.c_cod_nat = mov1.c_cod_nat); ' +
                                ' alter table CadNotafiscais ' +
                                ' drop foreign Key CADNATUREZA_FK_234; ' +
                                ' alter table MovNatureza ' +
                                ' drop foreign Key FK_MOVNATUR_REF_67857_CADNATUR; ' +
                                ' update movnatureza mov ' +
                                ' set c_ent_sai = (select c_ent_sai from cadnatureza mov1 where mov.c_cod_nat = mov1.c_cod_nat); ' +
                                ' drop table cadnatureza; ' +
                                ' alter table movnatureza rename CADNATUREZA; ' +
                                ' drop index MOVNATUREZA_PK; ' +
                                ' alter TABLE cadnatureza drop primary key; ' +
                                ' update cadnatureza ' +
                                ' set c_cod_nat = c_cod_nat ||''.'' || i_seq_mov; ' +
                                ' alter table cadnatureza delete i_seq_mov; ' +
                                ' alter table cadnatureza add primary key (C_COD_NAT); ' +
                                ' create index CADNATUREZA_PK on cadnatureza (C_COD_NAT); ' +
                                ' update cadNotaFiscais ' +
                                ' set c_cod_nat = c_cod_nat ||''.'' || i_ite_nat; ' +
                                ' update movNotasFiscaisFor ' +
                                ' set c_cod_nat = c_cod_nat ||''.'' || i_ite_nat; ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 328' );
       end;

       if VpaNumAtualizacao < 329 Then
       begin
          VpfErro := '329';
          ExecutaComandoSql(Aux,' update cadnotafiscais ' +
                                ' set c_cod_nat = null ' +
                                ' where c_cod_nat not in( select c_cod_nat from cadnatureza); ' +
                                ' update movnotasfiscaisfor ' +
                                ' set c_cod_nat = null ' +
                                ' where c_cod_nat not in( select c_cod_nat from cadnatureza); ' +
                                ' alter table CadNotaFiscais ' +
                                ' add foreign key FK_NATUREZA_REF_121 (C_COD_NAT) ' +
                                ' references CadNatureza(C_COD_NAT) on update cascade on delete restrict; ' +
                                ' alter table MovNotasFiscaisFor ' +
                                ' add foreign key FK_NATUREZA_REF_345 (C_COD_NAT) ' +
                                ' references CadNatureza(C_COD_NAT) on update cascade on delete restrict; ' +
                                ' alter table cadnotafiscais delete i_ite_nat; ' +
                                ' alter table MOvnotasfiscaisfor delete i_ite_nat; ' +
                                ' create index FK_CADNAT_8498 on MovNotasFiscaisFor (C_COD_NAT); ' +
                                ' alter table cadnatureza add C_TIP_NAT char(1) null; ' +
                                ' alter table cadnatureza ' +
                                ' rename c_nom_mov to C_NOM_NAT; ' +
                                ' update cadnatureza set c_ati_nat = ''S'';'  );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 329' );
       end;

   if VpaNumAtualizacao < 330 Then                             // CADEMITENTES
   begin
        VpfErro := '330';
        ExecutaComandoSql(Aux,'create table CADEMITENTES ' +
                           '( '+
                              '  I_COD_EMI  integer               not null, ' +
                              '  C_NOM_EMI  char(50)                  null, ' +
                              '  C_TIP_PES  char(1)                   null, ' +
                              '  D_ULT_ALT  date                      null, ' +
                              '  C_CGC_EMI  char(18)                  null, ' +
                              '  C_CPF_EMI  char(14)                  null, ' +
                              '  primary key (I_COD_EMI)                    ' +
                           ');'+
                              '  create table CADFACTORI ' +   // CADFACTORI
                           '( '+
                              '  I_EMP_FIL  integer               not null, ' +
                              '  I_LAN_FAC  integer               not null, ' +
                              '  I_COD_CLI  integer               not null, ' +
                              '  D_DAT_MOV  date                      null, ' +
                              '  D_ULT_ALT  date                      null, ' +
                              '  N_PER_CPM  numeric(17,5)             null, ' +
                              '  N_VAL_TOT  numeric(17,5)             null, ' +
                              ' primary key (I_EMP_FIL, I_LAN_FAC)          ' +
                           ');'+
                              '  create table MOVFACTORI  ' +  // MOVFACTORI
                            '( '+
                              '  I_EMP_FIL  integer               not null, ' +
                              '  I_LAN_FAC  integer               not null, ' +
                              '  I_NRO_LAN  integer               not null, ' +
                              '  I_COD_EMI  integer                   null,' +
                              '  I_COD_BAN  integer                   null, ' +
                              '  C_NRO_DOC  char(20)                  null, ' +
                              '  N_VLR_DOC  numeric(17,2)             null, ' +
                              '  D_DAT_VEN  date                      null, ' +
                              '  I_DIA_VEN  integer                   null, ' +
                              '  N_PER_JUR  numeric(17,5)             null, ' +
                              '  N_VLR_JUR  numeric(17,2)             null, ' +
                              '  N_TOT_LIQ  numeric(17,2)             null, ' +
                              '  C_TIP_DOC  char(1)                   null, ' +
                              '  D_DAT_PAG  date                      null, ' +
                              '  N_VLR_PAG  numeric(17,2)             null, ' +
                              '  D_ULT_ALT  date                      null, ' +
                              '  N_PER_CPM  numeric(17,5)             null, ' +
                              '  N_VLR_CPM  numeric(17,2)             null, ' +
                              '  D_EMI_DOC  date                      null, ' +
                              '  C_NRO_CON  char(13)                  null, ' +
                              '  C_SIT_DOC  char(1)                   null, ' +
                              '  D_DAT_DEV  date                      null, ' +
                              '  D_DAT_DEP  date                      null, ' +
                              '  D_DAT_REN  date                      null, ' +
                              '  D_DAT_REA  date                      null, ' +
                              '  primary key (I_EMP_FIL, I_LAN_FAC, I_NRO_LAN) ' +
                          ');'+
                                                                 // COMENTÁRIOS
                              '  comment on table CADFACTORI is ''CADASTRAR FACTORING ''; ' +
                              '  comment on table CADEMITENTES is ''CADASTRAR EMITENTES'';' +
                              '  comment on table MOVFACTORI is ''MOVIMENTO DA FACTORI''; ' +

                              '  alter table MOVFACTORI ' +
                              '    add foreign key FK_MOVFACTO_REF_17466_CADFACTO (I_EMP_FIL, I_LAN_FAC)' +
                              '    references CADFACTORI (I_EMP_FIL, I_LAN_FAC) on update restrict on delete restrict; ' +

                              '  alter table MOVFACTORI ' +
                              '    add foreign key FK_MOVFACTO_REF_112_CADEMITE (I_COD_EMI) '+
                              '    references CADEMITENTES (I_COD_EMI) on update restrict on delete restrict; ' +

                              '  create unique index CADEMITENTES_PK on CADEMITENTES (I_COD_EMI asc); ' +
                              '  create index "FK_CADFACTO_REF_17465_CADCLIEN(foreign key)" on CADFACTORI (I_COD_CLI asc); ' +
                              '  create index "FK_CADFACTO_REF_17465_CADFILIA(foreign key)" on CADFACTORI (I_EMP_FIL asc); ' +
                              '  create index Ref_174652_FK on CADFACTORI (I_EMP_FIL asc); ' +
                              '  create index Ref_174656_FK on CADFACTORI (I_COD_CLI asc); ' +
                              '  create unique index CADFACTORI_PK on CADFACTORI (I_EMP_FIL asc, I_LAN_FAC asc); ' +
                              '  create index "FK_MOVFACTO_REF_17555_CADBANCO(foreign key)" on MOVFACTORI (I_COD_BAN asc); ' +
                              '  create index Ref_175550_FK on MOVFACTORI (I_COD_BAN asc); ' +
                              '  create unique index MOVFACTORI_PK on MOVFACTORI (I_EMP_FIL asc, I_LAN_FAC asc, I_NRO_LAN asc); ' +
                              '  create index FK_MOVFACTO_REF_17466_CADFACTO_FK on MOVFACTORI (I_EMP_FIL asc, I_LAN_FAC asc); ' +
                              '  create index Ref_112_FK on MOVFACTORI (I_COD_EMI asc)');
        ExecutaComandoSql(Aux,'  Update Cfg_Geral set I_Ult_Alt = 330');
    end;

   if VpaNumAtualizacao < 331 Then
   begin
      VpfErro := '331';
      ExecutaComandoSql(Aux,' alter table cfg_fiscal ' +
                            ' add C_PER_NOT char(1) null; ' +
                            ' alter table cfg_servicos ' +
                            ' add C_KIT_ORC char(1) null;');
      ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 331' );
   end;

   if VpaNumAtualizacao < 332 Then
   begin
      VpfErro := '332';
      ExecutaComandoSql(Aux,' alter table CadClientes ' +
                            ' add C_NOM_FAN VarChar(30) null; ' );
      ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 332' );
   end;

   if VpaNumAtualizacao < 333 Then
   begin
      VpfErro := '333';
      ExecutaComandoSql(Aux,' alter table CadNatureza ' +
                            ' add C_GER_IMP Char(1) null; '  +
                            ' update cadnatureza set c_ger_imp = c_mos_fat ;' );
      ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 333' );
   end;

   if VpaNumAtualizacao < 334 Then
   begin
      VpfErro := '334';
      ExecutaComandoSql(Aux,' alter table CadNatureza ' +
                            ' add C_NOT_CUP Char(1) null; ' +
                            ' update cadnatureza set c_not_cup = ''N'' ;' );
      ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 334' );
   end;

   if VpaNumAtualizacao < 335 Then
   begin
      VpfErro := '335';
      ExecutaComandoSql(Aux,' alter table CadNatureza ' +
                            ' add C_FIL_PER Char(20) null; '  );
      ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 335' );
   end;

   if VpaNumAtualizacao < 336 Then
   begin
      VpfErro := '336';
      ExecutaComandoSql(Aux,' alter table Perfil_Exportacao ' +
                            ' add FILIAL_EXPORTACAO Char(40) null; '  );
      ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 336' );
   end;

       if VpaNumAtualizacao < 337 Then
       begin
          VpfErro := '337';
          ExecutaComandoSql(Aux,' alter table cadordemservico ' +
                                ' add C_CHA_TEC char(1) null, ' +
                                ' add C_TIP_CHA char(1) null; ' +
                                ' alter table cfg_financeiro ' +
                                ' add C_PLA_ABE char(1) null; ' +
                                ' alter table cfg_fiscal ' +
                                ' add C_CAR_INA integer null; '  +
                                ' update cadnatureza ' +
                                ' set c_cod_nat = ''ECF'' ' +
                                ' where c_nat_imp = ''ECF'';');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 337' );
       end;

      if VpaNumAtualizacao < 338 Then
      begin
         VpfErro := '338';
         ExecutaComandoSql(Aux,' alter table CADVENDEDORES ' +
                               ' add C_ATI_VEN char(1) null, ' +
                               ' add I_EMP_FIL integer null, ' +
                               ' add I_IND_VEN integer null; ' +
                               ' Update CADVENDEDORES set C_ATI_VEN = ''S'' ;');
         ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 338' );
      end;

      if VpaNumAtualizacao < 339 Then
      begin
         VpfErro := '339';
         ExecutaComandoSql(Aux,' alter table CFG_MODULO ' +
                               ' add FLA_ACADEMICO char(1) null; ' +
                               ' Update CFG_MODULO set FLA_ACADEMICO = ''F'' ;');
         ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 339' );
      end;

      if VpaNumAtualizacao < 340 Then
      begin
         VpfErro := '340';
         ExecutaComandoSql(Aux,' alter table CadUsuarios ' +
                               ' add C_MOD_ACA char(1) null; ' );
         ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 340' );
      end;

      if VpaNumAtualizacao < 341 Then
      begin
         VpfErro := '341';
         ExecutaComandoSql(Aux,' alter table CadContasaReceber ' +
                               ' add I_NRO_MAT integer null; ' +
                               ' alter table cadempresas ' +
                               ' add C_MAS_AUL char(15) null; ' +
                               ' alter table cfg_geral ' +
                               ' add I_TIP_NOM integer null;' +
                               ' update cfg_geral set i_tip_nom = 1');
         ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 341' );
      end;

      if VpaNumAtualizacao < 342 Then
      begin
         VpfErro := '342';
         ExecutaComandoSql(Aux,' alter table CadContasaReceber ' +
                               ' rename I_NRO_MAT to I_COD_MAT; ' );
         ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 342' );
      end;

      if VpaNumAtualizacao < 343 Then
      begin
         VpfErro := '343';
         ExecutaComandoSql(Aux,' alter table CFG_GERAL ' +
                               ' add D_ULT_EXP date null; ' +
                               ' update cfg_geral set d_ult_exp = ''1998/01/01'';');
         ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 343' );
      end;

      if VpaNumAtualizacao < 344 Then
      begin
         VpfErro := '344';
         ExecutaComandoSql(Aux,' alter table CFG_GERAL ' +
                               ' add C_MAN_COP char(1) null, ' +
                               ' add C_MAN_COR char(1) null; ' +
                               ' update cfg_geral set c_man_cop = ''T'';' +
                               ' update cfg_geral set c_man_cor = ''T'';' );
         ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 344' );
      end;

      if VpaNumAtualizacao < 345 Then
      begin
         VpfErro := '345';
         ExecutaComandoSql(Aux,' alter table CFG_FINANCEIRO ' +
                               ' add C_RET_MES char(1) null ' );
         ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 345' );
      end;

      if VpaNumAtualizacao < 346 Then
      begin
         VpfErro := '346';
         ExecutaComandoSql(Aux,' alter table MOVCONTASARECEBER ' +
                               ' add D_DAT_EST date null, ' +
                               ' add I_USU_EST integer null; ' +
                               ' alter table MOVCONTASAPAGAR ' +
                               ' add D_DAT_EST date null, ' +
                               ' add I_USU_EST integer null; ' );
         ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 346' );
      end;

      if VpaNumAtualizacao < 347 Then
      begin
         VpfErro := '347';
         ExecutaComandoSql(Aux,' alter table CFG_GERAL' +
                               ' add I_VER_PER integer null ' );
         ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 347' );
      end;

      if VpaNumAtualizacao < 348 Then
      begin
         VpfErro := '348';
         ExecutaComandoSql(Aux,' alter table CadOrdemServico' +
                               ' delete c_vlr_per ' );
         ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 348' );
      end;

      if VpaNumAtualizacao < 349 Then
      begin
         VpfErro := '349';
         ExecutaComandoSql(Aux,' alter table CadOrdemServico' +
                               ' add I_NRO_ATE integer null' );
         ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 349' );
      end;

      if VpaNumAtualizacao < 350 Then
      begin
         VpfErro := '350';
         ExecutaComandoSql(Aux,' alter table CFG_FISCAL' +
                               ' add C_NAT_ORS char(10) null;' +
                               ' alter table CFG_SERVICOS '  +
                               ' add I_SIT_ORC integer null ' );
         ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 350' );
      end;

      if VpaNumAtualizacao < 351 Then
      begin
         VpfErro := '351';
         ExecutaComandoSql(Aux,' update cadordemservico ' +
                               ' set c_cha_tec = ''N'' ' +
                               ' where c_cha_tec is null; ' +
                               ' update cadordemservico ' +
                               ' set c_tip_cha = ''N'' ' +
                               ' where c_tip_cha is null ' );
         ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 351' );
      end;

      if VpaNumAtualizacao < 352 Then
      begin
         VpfErro := '352';
         ExecutaComandoSql(Aux,' alter table CFG_SERVICOS '  +
                               ' add C_ADI_OBS char(1) null ' );
         ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 352' );
      end;

       if VpaNumAtualizacao < 353 Then
       begin
          VpfErro := '353';
          ExecutaComandoSql(Aux,' create index CP_CONTRATO on CADCONTASARECEBER (I_COD_MAT asc); ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 353' );
        end;

       if VpaNumAtualizacao < 354 Then
       begin
          VpfErro := '354';
          ExecutaComandoSql(Aux,' alter table CadNatureza '  +
                                ' add C_CST_PAD char(3) null ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 354' );
        end;

       if VpaNumAtualizacao < 355 Then
       begin
          VpfErro := '355';
          ExecutaComandoSql(Aux,' alter table CFG_GERAL '  +
                                ' add C_VER_DAT char(3) null ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 355' );
        end;

       if VpaNumAtualizacao < 356 Then
       begin
          VpfErro := '356';
          ExecutaComandoSql(Aux,' alter table CFG_SERVICOS '  +
                                ' add C_VAL_ORC char(1) null ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 356' );
        end;

       if VpaNumAtualizacao < 357 Then
       begin
          VpfErro := '357';
    ExecutaComandoSql(Aux,' create table MOVATENDIMENTOLABOS ' + // MOVATENDIMENTOLABOS
                          ' ( ' +
                          '     I_EMP_FIL  integer               not null, ' +
                          '     I_COD_ORS  integer               not null, ' +
                          '     I_SEQ_MOV  integer               not null, ' +
                          '     I_COD_USU  integer                   null, ' +
                          '     H_HOR_INI  time                      null, ' +
                          '     H_HOR_FIM  time                      null, ' +
                          '     D_DAT_TRA  date                      null, ' +
                          '     D_ULT_ALT  date                      null, ' +
                          '     primary key (I_EMP_FIL, I_COD_ORS, I_SEQ_MOV) ' +
                          ' ); ' +

                          ' comment on table MOVATENDIMENTOLABOS is ''MOVATENDIMENTOLABOS''; ' +
                          ' comment on column MOVATENDIMENTOLABOS.I_EMP_FIL is ''EMPRESA FILIAL''; ' +
                          ' comment on column MOVATENDIMENTOLABOS.I_COD_ORS is ''CODIGO DA ORDEM DE SERVICO''; ' +
                          ' comment on column MOVATENDIMENTOLABOS.I_SEQ_MOV is ''SEQUENCIAL DA TABELA''; ' +
                          ' comment on column MOVATENDIMENTOLABOS.I_COD_USU is ''CODIGO DO USUARIO (TCNICO)''; ' +
                          ' comment on column MOVATENDIMENTOLABOS.H_HOR_INI is ''HORA DO INICIO DO TRABALHO''; ' +
                          ' comment on column MOVATENDIMENTOLABOS.H_HOR_FIM is ''HORA DO FINAL DO TRABALHO''; ' +
                          ' comment on column MOVATENDIMENTOLABOS.D_DAT_TRA is ''DATA DO TRABALHO''; ' +
                          ' comment on column MOVATENDIMENTOLABOS.D_ULT_ALT is ''DATA DA ULTIMA ALTERACAO''; ' +

                          ' alter table MOVATENDIMENTOLABOS ' +
                          ' add foreign key FK_MOVATEND_REF_11_CADORDEM (I_EMP_FIL, I_COD_ORS) ' +
                          ' references CADORDEMSERVICO (I_EMP_FIL, I_COD_ORS) on update restrict on delete restrict; ' +

                          ' create unique index MOVATENDIMENTOLABOS_PK on MOVATENDIMENTOLABOS (I_EMP_FIL asc, I_COD_ORS asc, I_SEQ_MOV asc); ' +
                          ' create index Ref_11_FK on MOVATENDIMENTOLABOS (I_EMP_FIL asc, I_COD_ORS asc); ' );
     ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 357');
  end;

  if VpaNumAtualizacao < 358 Then                             //MOVATENDIMENTOCAMPOOS
  begin
    VpfErro := '358';
    ExecutaComandoSql(Aux,' create table MOVATENDIMENTOCAMPOOS ' +
                          ' ( ' +
                          '     I_EMP_FIL  integer               not null, ' +
                          '     I_COD_ORS  integer               not null, ' +
                          '     I_SEQ_MOV  integer               not null, ' +
                          '     I_COD_USU  integer                   null, ' +
                          '     I_INS_USU  integer                   null, ' +
                          '     I_KME_INI  integer                   null, ' +
                          '     I_KME_FIN  integer                   null, ' +
                          '     I_KME_TOT  integer                   null, ' +
                          '     I_INS_INI  integer                   null, ' +
                          '     I_INS_FIN  integer                   null, ' +
                          '     I_INS_TOT  integer                   null, ' +
                          '     H_HOR_INI  time                      null, ' +
                          '     H_HOR_FIM  time                      null, ' +
                          '     H_INS_INI  time                      null, ' +
                          '     H_INS_FIM  time                      null, ' +
                          '     H_HOR_TOT  time                      null, ' +
                          '     D_DAT_INI  date                      null, ' +
                          '     D_INS_INI  date                      null, ' +
                          '     D_ULT_ALT  date                      null, ' +
                          '     primary key (I_EMP_FIL, I_COD_ORS, I_SEQ_MOV) ' +
                          ' ); ' +
                          ' comment on table MOVATENDIMENTOCAMPOOS is ''MOVATENDIMENTOCAMPOOS''; ' +
                          ' comment on column MOVATENDIMENTOCAMPOOS.I_EMP_FIL is ''EMPRESA FILIAL''; ' +
                          ' comment on column MOVATENDIMENTOCAMPOOS.I_COD_ORS is ''CODIGO DA ORDEM DE SERVICO''; ' +
                          ' comment on column MOVATENDIMENTOCAMPOOS.I_SEQ_MOV is ''SEQUENCIAL DA TABELA''; ' +
                          ' comment on column MOVATENDIMENTOCAMPOOS.I_COD_USU is ''CODIGO DO USUARIO (TECNICO)''; ' +
                          ' comment on column MOVATENDIMENTOCAMPOOS.D_DAT_INI is ''DATA DO INICIO DO TRABALHO''; ' +
                          ' comment on column MOVATENDIMENTOCAMPOOS.H_HOR_INI is ''HOTA DE INICIO DO TRABALHO''; ' +
                          ' comment on column MOVATENDIMENTOCAMPOOS.H_HOR_FIM is ''HOTA DO FIM DO TRABALHO''; ' +
                          ' comment on column MOVATENDIMENTOCAMPOOS.I_KME_INI is ''KILOMETRAGEM INICIAL''; ' +
                          ' comment on column MOVATENDIMENTOCAMPOOS.I_KME_FIN is ''KILOMETRAGEM FINAL''; ' +
                          ' comment on column MOVATENDIMENTOCAMPOOS.I_KME_TOT is ''KILOMETRAGEM TOTAL''; ' +
                          ' comment on column MOVATENDIMENTOCAMPOOS.D_ULT_ALT is ''DATA DA ULTIMA ALTERACAO''; ' +
                          ' comment on column MOVATENDIMENTOCAMPOOS.I_INS_USU is ''CODIFGO DO TECNICO DA DEVOLUCAO''; ' +
                          ' comment on column MOVATENDIMENTOCAMPOOS.D_INS_INI is ''DATA DA DEVOLUCAO''; ' +
                          ' comment on column MOVATENDIMENTOCAMPOOS.H_INS_INI is ''HORA DE INICIO DA DEVOLUCAO''; ' +
                          ' comment on column MOVATENDIMENTOCAMPOOS.H_INS_FIM is ''HORA DO FINAL DA DEVOLUCAO''; ' +
                          ' comment on column MOVATENDIMENTOCAMPOOS.H_HOR_TOT is ''HORA TOTAL ATENDIMENTO/ABERTURA''; ' +
                          ' comment on column MOVATENDIMENTOCAMPOOS.I_INS_INI is ''KILOMATRAGEM INCICAL DA DEVOLUCAO''; ' +
                          ' comment on column MOVATENDIMENTOCAMPOOS.I_INS_FIN is ''KILOMETRAGEM FINAL DA DECOLUCAO''; ' +
                          ' comment on column MOVATENDIMENTOCAMPOOS.I_INS_TOT is ''KILOMETRAGEM TOTAL DA DEVOLUCAO''; ' +

                          ' alter table MOVATENDIMENTOCAMPOOS ' +
                          '     add foreign key FK_MOVATEND_REF_18_CADORDEM (I_EMP_FIL, I_COD_ORS) ' +
                          '        references CADORDEMSERVICO (I_EMP_FIL, I_COD_ORS) on update restrict on delete restrict; ' +

                          ' create unique index MOVATENDIMENTOCAMPOOS_PK on MOVATENDIMENTOCAMPOOS (I_EMP_FIL asc, I_COD_ORS asc, I_SEQ_MOV asc); ' +
                          ' create index Ref_18_FK on MOVATENDIMENTOCAMPOOS (I_EMP_FIL asc, I_COD_ORS asc); ');

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 358' );
        end;

       if VpaNumAtualizacao < 359 Then
       begin
          VpfErro := '359';
          ExecutaComandoSql(Aux,' alter table CadNatureza '  +
                                ' add C_SOM_IPI char(1) null ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 359' );
        end;

       if VpaNumAtualizacao < 360 Then
       begin
          VpfErro := '360';
          ExecutaComandoSql(Aux,' alter table CadNatureza '  +
                                ' add C_ICM_EST char(1) null; ' +
                                ' update cadnatureza set C_ICM_EST = ''N''; ' +
                                ' update cadnatureza set C_SOM_IPI = ''N''; ');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 360' );
        end;

       if VpaNumAtualizacao < 361 Then
       begin
          VpfErro := '361';
          ExecutaComandoSql(Aux,' alter table MOVATENDIMENTOCAMPOOS ' +
                                ' modify H_HOR_INI timestamp; ' +
                                ' alter table MOVATENDIMENTOCAMPOOS ' +
                                ' modify H_HOR_FIM timestamp; ' +
                                ' alter table MOVATENDIMENTOCAMPOOS ' +
                                ' modify H_INS_INI timestamp; ' +
                                ' alter table MOVATENDIMENTOCAMPOOS ' +
                                ' modify H_INS_FIM timestamp; ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 361' );
        end;

       if VpaNumAtualizacao < 362 Then
       begin
          VpfErro := '362';
          ExecutaComandoSql(Aux,' alter table MovOrcamentos '  +
                                ' add C_IMP_VAL char(1) null; ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 362' );
        end;

       if VpaNumAtualizacao < 363 Then
       begin
          VpfErro := '363';
          ExecutaComandoSql(Aux,'create table CFG_FACTORI  ' +    //CFG_FACTORI
                       ' ( ' +
                           ' C_JUR_DIA  char(1)  NULL,'  +
                           ' C_SEN_LIB  char(15) NULL '  +
                       ' );' +
                           ' comment on table CFG_FACTORI is ''CONFIGURACOES FACTORING '';' +
                           ' comment on column CFG_FACTORI.C_JUR_DIA is ''CALCULA JURO DIARIO'';' +
                           ' comment on column CFG_FACTORI.C_SEN_LIB is ''SENHA DE LIBERACAO PARA ALTERAR VALOR'';' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 363' );
        end;

       if VpaNumAtualizacao < 364 Then
       begin
          VpfErro := '364';
          ExecutaComandoSql(Aux,' alter table CadEmitentes '  +
                                ' add C_CID_EMI char(25) null, '+
                                ' add C_EST_EMI char(2) null; ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 364' );
        end;

       if VpaNumAtualizacao < 365 Then
       begin
          VpfErro := '365';
          ExecutaComandoSql(Aux,' alter table CadEmitentes '  +
                                ' add I_COD_CID integer null; ');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 365' );
        end;

       if VpaNumAtualizacao < 366 Then
       begin
          VpfErro := '366';
          ExecutaComandoSql(Aux,' alter table CadOrdemServico '  +
                                ' add C_ACE_EMP varchar(60) null; ' +
                                ' alter table CadOrdemServico '  +
                                ' modify c_cha_tec char(8) null; ' +
                                ' alter table MOVEQUIPAMENTOOS '  +
                                ' modify C_ORC_EQU char(10) null; ' +
                                ' alter table MOVEQUIPAMENTOOS '  +
                                ' delete C_GAR_EQU; ' +
                                ' update CadOrdemServico '  +
                                ' set c_cha_tec = ''Balcao''; ' +
                                ' update MOVEQUIPAMENTOOS '  +
                                ' set c_orc_equ = ''Orcamento''; ' +
                                ' Alter table MovTerceiroOS ' +
                                ' add C_ACE_TER varchar(60) null, ' +
                                ' add I_COD_TRA integer null, ' +
                                ' add C_MOD_GRA varchar(60) null, ' +
                                ' add C_LAU_GAR varchar(30) null; ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 366' );
        end;

       if VpaNumAtualizacao < 367 Then
       begin
          VpfErro := '367';
          ExecutaComandoSql(Aux,' Alter table CadUsuarios ' +
                                ' add C_CPF_USU char(14) null, ' +
                                ' add C_FON_USU char(20) null, ' +
                                ' add C_MAI_USU varchar(60) null, ' +
                                ' add C_RAM_USU integer null; ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 367' );
        end;

       if VpaNumAtualizacao < 368 Then
       begin
          VpfErro := '368';
          ExecutaComandoSql(Aux,' Alter table CAD_DOC ' +
                                ' add C_MAT_PER char(1) null; ' +
                                ' Update CAD_DOC ' +
                                ' set C_MAT_PER = ''M''; ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 368' );
        end;

       if VpaNumAtualizacao < 369 Then
       begin
          VpfErro := '369';
          ExecutaComandoSql(Aux,' create table TEMPORARIADOC (' +
                                ' I_EMP_FIL integer null, ' +
                                ' I_LAN_REC integer null, ' +
                                ' I_NRO_PAR integer null); ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 369' );
        end;

       if VpaNumAtualizacao < 370 Then
       begin
          VpfErro := '370';
          ExecutaComandoSql(Aux,' alter table TEMPORARIADOC ' +
                                ' add C_EXT_VAL varchar(100) null; ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 370' );
        end;

       if VpaNumAtualizacao < 371 Then
       begin
          VpfErro := '371';
          ExecutaComandoSql(Aux,' alter table CFG_GERAL ' +
                                ' add C_ALI_REL char(10) null; ' +
                                ' update cfg_geral set c_ali_rel = ''SigRel'' ');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 371' );
        end;

       if VpaNumAtualizacao < 372 Then
       begin
          VpfErro := '372';
          ExecutaComandoSql(Aux,' alter table CadOrdemServico ' +
                                ' add I_COD_EQU  integer        null, ' +
                                ' add I_COD_MAR  integer        null, ' +
                                ' add I_COD_MOD  integer        null, ' +
                                ' add C_VOL_ENT  char(10)        null, ' +
                                ' add C_ORC_EQU  char(25)        null, ' +
                                ' add C_NRO_NOT  char(40)       null, ' +
                                ' add C_DEF_APR  varchar(250)   null, ' +
                                ' add C_NRO_SER  char(20)       null, ' +
                                ' add C_ACE_EQU  varchar(100)   null ' );
          ExecutaComandoSql(Aux,
          ' comment on column CadOrdemServico.I_COD_EQU is ''CODIGO DA EQUIPAMENTO''; ' +
          ' comment on column CadOrdemServico.I_COD_MAR is ''CODIGO DA MARCA''; ' +
          ' comment on column CadOrdemServico.I_COD_MOD is ''CODIGO DO MODELO''; ' +
          ' comment on column CadOrdemServico.C_ACE_EQU is ''ACESSORIOS DO EQUIPAMENTO''; ' +
          ' comment on column CadOrdemServico.C_ORC_EQU is ''FAZER ORCAMENTO S/N''; ' +
          ' comment on column CadOrdemServico.C_DEF_APR is ''DEFEITO APRESENTADO''; ' +
          ' comment on column CadOrdemServico.C_NRO_NOT is ''NUMERO DA NOTA CASO GARANTIA''; ' +
          ' comment on column CadOrdemServico.C_NRO_SER is ''NUMERO DE SERIE DO EQUIPAMENTO''; ' +
          ' comment on column CadOrdemServico.C_VOL_ENT is ''VOLTAGEM DO EQUIPAMENTO''; ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 372' );
        end;

       if VpaNumAtualizacao < 373 Then
       begin
          VpfErro := '373';
          ExecutaComandoSql(Aux,
                ' alter table CadOrdemServico ' +
                '     add foreign key FK_CADORDEM_REF_CADMODEL (I_COD_MOD) ' +
                '        references CADMODELO (I_COD_MOD) on update restrict on delete restrict; ' +

                ' alter table CadOrdemServico ' +
                '     add foreign key FK_CADORDEM_REF_CADMARCA (I_COD_MAR) ' +
                '        references CADMARCAS (I_COD_MAR) on update restrict on delete restrict; ' +

                ' alter table CadOrdemServico ' +
                '     add foreign key FK_CADORDEM_REF_CADEQUIP (I_COD_EQU) ' +
                '        references CADEQUIPAMENTOS (I_COD_EQU) on update restrict on delete restrict; ' );
          ExecutaComandoSql(Aux,
               ' create index Ref_Modelo_FK on CadOrdemServico (I_COD_MOD asc); ' +
               ' create index Ref_Marca on CadOrdemServico (I_COD_MAR asc); ' +
               ' create index Ref_Equi_FK on CadOrdemServico (I_COD_EQU asc); ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 373' );
        end;

       if VpaNumAtualizacao < 374 Then
       begin
          VpfErro := '374';
          ExecutaComandoSql(Aux,
            ' update cadordemservico cad ' +
            ' set I_COD_EQU  = (select  max( i_cod_equ) from MOVEQUIPAMENTOOS where i_cod_ors = cad.i_cod_ors and i_emp_fil = cad.i_emp_fil), ' +
            ' I_COD_MAR      = (select max( i_cod_mar) from MOVEQUIPAMENTOOS where i_cod_ors = cad.i_cod_ors and i_emp_fil = cad.i_emp_fil), ' +
            ' I_COD_MOD      = (select max(i_cod_mod) from MOVEQUIPAMENTOOS where i_cod_ors = cad.i_cod_ors and i_emp_fil = cad.i_emp_fil), ' +
            ' C_VOL_ENT      = (select  max(c_vol_ent) from MOVEQUIPAMENTOOS where i_cod_ors = cad.i_cod_ors and i_emp_fil = cad.i_emp_fil), ' +
            ' C_ORC_EQU      = (select max(c_orc_equ) from MOVEQUIPAMENTOOS where i_cod_ors = cad.i_cod_ors and i_emp_fil = cad.i_emp_fil), ' +
            ' C_NRO_NOT      = (select  max(c_nro_not) from MOVEQUIPAMENTOOS where i_cod_ors = cad.i_cod_ors and i_emp_fil = cad.i_emp_fil), ' +
            ' C_DEF_APR      = (select max(c_def_apr) from MOVEQUIPAMENTOOS where i_cod_ors = cad.i_cod_ors and i_emp_fil = cad.i_emp_fil), ' +
            ' C_NRO_SER      = (select max(c_nro_ser) from MOVEQUIPAMENTOOS where i_cod_ors = cad.i_cod_ors and i_emp_fil = cad.i_emp_fil), ' +
            ' C_ACE_EQU      = (select max(c_ace_equ) from MOVEQUIPAMENTOOS where i_cod_ors = cad.i_cod_ors and i_emp_fil = cad.i_emp_fil); ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 374' );
        end;

       if VpaNumAtualizacao < 375 Then
       begin
          VpfErro := '375';
          ExecutaComandoSql(Aux,' Drop table MOVEQUIPAMENTOOS ' );
          ExecutaComandoSql(Aux,' Drop table CadCor ' );
          ExecutaComandoSql(Aux,' Drop table CadTipo ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 375' );
        end;

       if VpaNumAtualizacao < 376 Then
       begin
          VpfErro := '376';
          ExecutaComandoSql(Aux,' alter table movterceiroos ' +
                                ' add C_NRO_SER  char(20)       null, ' +
                                ' add I_COD_EQU  integer        null, ' +
                                ' add I_COD_MAR  integer        null, ' +
                                ' add I_COD_MOD  integer        null; ' );
          ExecutaComandoSql(Aux,
                ' alter table movterceiroos ' +
                '     add foreign key FK_CADMODEL (I_COD_MOD) ' +
                '        references CADMODELO (I_COD_MOD) on update restrict on delete restrict; ' +

                ' alter table movterceiroos ' +
                '     add foreign key FK_CADMARCA (I_COD_MAR) ' +
                '        references CADMARCAS (I_COD_MAR) on update restrict on delete restrict; ' +

                ' alter table movterceiroos ' +
                '     add foreign key FK_CADEQUIP (I_COD_EQU) ' +
                '        references CADEQUIPAMENTOS (I_COD_EQU) on update restrict on delete restrict; ' );
          ExecutaComandoSql(Aux,
               ' create index Ref_123_Modelo_FK on movterceiroos (I_COD_MOD asc); ' +
               ' create index Ref_124_Marca_FK on movterceiroos (I_COD_MAR asc); ' +
               ' create index Ref_125_Equi_FK on movterceiroos (I_COD_EQU asc); ' );

          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 376' );
        end;

       if VpaNumAtualizacao < 377 Then
       begin
          VpfErro := '377';
          ExecutaComandoSql(Aux,' update movterceiroos mov ' +
                        ' set i_cod_equ = ( select max(i_cod_equ) from cadordemservico cad where cad.i_cod_ors = mov.i_cod_ors and cad.i_emp_fil = mov.I_emp_fil), ' +
                        ' i_cod_mar = ( select max(i_cod_equ) from cadordemservico cad where cad.i_cod_ors = mov.i_cod_ors and cad.i_emp_fil = mov.I_emp_fil), ' +
                        ' i_cod_mod = ( select max(i_cod_equ) from cadordemservico cad where cad.i_cod_ors = mov.i_cod_ors and cad.i_emp_fil = mov.I_emp_fil), ' +
                        ' c_nro_ser = ( select max(c_nro_ser) from cadordemservico cad where cad.i_cod_ors = mov.i_cod_ors and cad.i_emp_fil = mov.I_emp_fil); ' );
          ExecutaComandoSql(Aux,' alter table cadordemservico ' +
                                ' modify T_HOR_PRE timestamp; ');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 377' );
        end;

       if VpaNumAtualizacao < 378 Then
       begin
          VpfErro := '378';
          ExecutaComandoSql(Aux,' update CadOrdemServico ' +
                                ' set C_ORC_EQU = ''Garantia de Servico ''' +
                                ' where C_ORC_EQU = ''Garantia'';');
          ExecutaComandoSql(Aux,' alter table cfg_servicos ' +
                                ' add C_INA_SER char(1) null; ');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 378' );
        end;

       if VpaNumAtualizacao < 379 Then
       begin
          VpfErro := '379';
          ExecutaComandoSql(Aux,' alter table Cad_Plano_conta ' +
                                ' add C_NIL_001 char(5) null, ' +
                                ' add C_NIL_002 char(5) null, ' +
                                ' add C_NIL_003 char(5) null, ' +
                                ' add C_NIL_004 char(5) null, ' +
                                ' add C_NIL_005 char(5) null, ' +
                                ' add C_NIL_006 char(5) null, ' +
                                ' add C_NIL_007 char(5) null, ' +
                                ' add I_COD_RED integer null ');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 379' );
        end;

       if VpaNumAtualizacao < 380 Then
       begin
          VpfErro := '380';
          AtualizaPlanoConta;
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 380' );
        end;

       if VpaNumAtualizacao < 381 Then
       begin
          VpfErro := '381';
          ExecutaComandoSql(Aux,' drop index CadOrdemServico_fk_cadtipo_857;' );
          ExecutaComandoSql(Aux,' create index CadOrdemServico_fk_cadtipo on CADOrdemServico (I_COD_ENT asc); ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 381' );
       end;

       if VpaNumAtualizacao < 382 Then
       begin
          VpfErro := '382';
          ExecutaComandoSql(Aux,' alter table Cfg_geral ' +
                                ' add I_DEC_UNI integer null ' );
          ExecutaComandoSql(Aux,' update Cfg_geral ' +
                                ' set I_DEC_UNI = 2 ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 382' );
       end;

       if VpaNumAtualizacao < 383 Then
       begin
          VpfErro := '383';
          ExecutaComandoSql(Aux,' alter table Cfg_fiscal ' +
                                ' add C_DEV_NOT varchar(100) null ' );
          ExecutaComandoSql(Aux,' update Cfg_fiscal ' +
                                ' set C_DEV_NOT = ''Devolução referente a nota fiscal nº ''' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 383' );
       end;

       if VpaNumAtualizacao < 384 Then
       begin
          VpfErro := '384';
          ExecutaComandoSql(Aux,' alter table MOVFACTORI ' +
                                ' add D_DAT_CAD date null ' );
          ExecutaComandoSql(Aux,' update MOVFACTORI ' +
                                ' set D_DAT_CAD = D_EMI_DOC' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 384' );
       end;

       if VpaNumAtualizacao < 385 Then
       begin
          VpfErro := '385';
          ExecutaComandoSql(Aux,' alter table  MOVATENDIMENTOLABOS ' +
                                ' modify H_HOR_INI TimeStamp null, ' +
                                ' modify H_HOR_FIM TimeStamp null ' );
          ExecutaComandoSql(Aux,' alter table CADORDEMSERVICO ' +
                                ' add H_HOR_ABE TimeStamp null ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 385' );
       end;

       if VpaNumAtualizacao < 386 Then
       begin
          VpfErro := '386';
          ExecutaComandoSql(Aux,' alter table CadOrdemServico ' +
                                ' add I_SEQ_NOT integer null, ' +
                                ' add I_NRO_NOT integer null ' );
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 386' );
       end;

       if VpaNumAtualizacao < 387 Then
       begin
          VpfErro := '387';
          ExecutaComandoSql(Aux,' alter table CadNotaFiscais ' +
                                ' add L_NRO_ORS Long VarChar null ');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 387' );
       end;

       if VpaNumAtualizacao < 388 Then
       begin
          VpfErro := '388';
          ExecutaComandoSql(Aux,' alter table cfg_servicos ' +
                                ' add C_RES_PRO char(1) null ');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 388' );
       end;

       if VpaNumAtualizacao < 389 Then
       begin
          VpfErro := '389';
          ExecutaComandoSql(Aux,' alter table cfg_servicos ' +
                                ' add C_BAI_RES char(1) null ');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 389' );
       end;

       if VpaNumAtualizacao < 390 Then
       begin
          VpfErro := '390';
          ExecutaComandoSql(Aux,' alter table Cad_Plano_conta ' +
                                ' modify C_NIL_001 char(20) null, ' +
                                ' modify C_NIL_002 char(20) null, ' +
                                ' modify C_NIL_003 char(20) null, ' +
                                ' modify C_NIL_004 char(20) null, ' +
                                ' modify C_NIL_005 char(20) null, ' +
                                ' modify C_NIL_006 char(20) null, ' +
                                ' modify C_NIL_007 char(20) null ');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 390' );
        end;

       if VpaNumAtualizacao < 391 Then
       begin
          VpfErro := '391';
          AtualizaPlanoConta;
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 391' );
        end;

       if VpaNumAtualizacao < 392 Then
       begin
          VpfErro := '392';
          ExecutaComandoSql(Aux,' alter table cfg_servicos ' +
                                ' add C_NRO_EQU char(1) null; ' +
                                ' alter table movordemservico ' +
                                ' add C_RES_PRO char(1) null ');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 392' );
        end;

       if VpaNumAtualizacao < 393 Then
       begin
          VpfErro := '393';
          ExecutaComandoSql(Aux,' update movordemservico ' +
                                ' set C_RES_PRO = ''N'' ');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 393' );
        end;

       if VpaNumAtualizacao < 394 Then
       begin
          VpfErro := '394';
          ExecutaComandoSql(Aux,' alter table CadOrdemServico ' +
                                ' add C_RES_PRO char(1) null '+
                                ' update CadOrdemservico ' +
                                ' set C_RES_PRO = ''N'' ');
          ExecutaComandoSql(Aux,' Update Cfg_Geral set I_Ult_Alt = 394' );
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

