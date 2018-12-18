unit APrincipal;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, LabelCorMove, PainelGradiente, ExtCtrls, Icones, Menus, Buttons, Shellapi,
  DBTables, Componentes1, IniFiles, Registry, Db;

const
  CampoPermissaoModulo = 'C_USU_ATI';
  CampoFormModulos = 'c_mod_pon';
  NomeModulo = 'Gestor';

type
  TFPrincipal = class(TForm)
    IconeBarraStatus1: TIconeBarraStatus;
    PopupMenu1: TPopupMenu;
    MFinanceiro: TMenuItem;
    MPontodeLoja: TMenuItem;
    MFaturamento: TMenuItem;
    MEstoque: TMenuItem;
    MTransferencias: TMenuItem;
    MAmbiente: TMenuItem;
    MSistema: TMenuItem;
    N1: TMenuItem;
    Ocultar1: TMenuItem;
    Sair1: TMenuItem;
    Panel1: TPanel;
    Financeiro: TBitBtn;
    BPontoLoja: TBitBtn;
    BFaturamento: TBitBtn;
    BEstoqueCusto: TBitBtn;
    BCaixa: TBitBtn;
    BAcademico: TBitBtn;
    BTransferencia: TBitBtn;
    BAmbiente: TBitBtn;
    BSistema: TBitBtn;
    BSair: TBitBtn;
    BLogado: TSpeedButton;
    MCaixa: TMenuItem;
    MRelatorios: TMenuItem;
    BaseDados: TDatabase;
    BarraLateral: TPainelGradiente;
    LUsuario: TLabel;
    CorFoco: TCorFoco;
    MSempreVisivel: TMenuItem;
    MMostraTexto: TMenuItem;
    CorPainelGra1: TCorPainelGra;
    Alinhamento1: TMenuItem;
    MDireita: TMenuItem;
    Mesquerda: TMenuItem;
    MSuperior: TMenuItem;
    MInferior: TMenuItem;
    AtualizaModulos1: TMenuItem;
    AtualizaSistema1: TMenuItem;
    Aux: TQuery;
    AtualizaModulos2: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure Ocultar1Click(Sender: TObject);
    procedure Sair1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure MenuClick(Sender: TObject);
    procedure BLogadoClick(Sender: TObject);
    procedure MSempreVisivelClick(Sender: TObject);
    procedure IconeBarraStatus1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure MMostraTextoClick(Sender: TObject);
    procedure MesquerdaClick(Sender: TObject);
    procedure AtualizaModulos1Click(Sender: TObject);
    procedure AtualizaModulos2Click(Sender: TObject);
  private
    VprUsuarioLogado : Boolean;
    VprNomeModulos : TStringList;
    VprAlinhamento : integer; // 0 direita, 1 esquerda, 2 top, 3 base
    VprTopo,VprAlturaBotao, VprLarguraBotao, VprLeft, VprMaiorLargura : Integer;
    VprDiretorioCorrente, NomedoMenu : String;
    function UsuarioOk : boolean;
    procedure EscondeTexto(mostrar : Boolean );
    procedure AlinhaBotao( Botao : TBitBtn);
    procedure OrganizaBarra;
    procedure GravaIni;
    procedure LeIni;
    procedure ConfiguraTela;
    procedure CarregaNomeModulos;
    function HandleSistema(VpaNomeModulo : String) : THandle;
    procedure FechaAplicativos;
    function PermiteUsuario(Campo : string) : Boolean;
    procedure ConfiguraBotoes;
    procedure IniciaTela;

  public
    { Public declarations }
    VplParametroBaseDados : String;
    Function ProgramaEmExecucao(VpaNomePrograma, NomeMenu : String):Boolean;
    function AbreBaseDados( Alias : string ) : Boolean;
    procedure CarregaNomeUsuario;
    procedure MostraMenssagemDemostracao;
    procedure ResetaIni;
end;

var
  VglParametroOficial : String;
  FPrincipal: TFPrincipal;

implementation

Uses FunString, Constantes, FunObjeto, Abertura, FunValida,ConstMsg, FunArquivos, funsql;

{$R *.DFM}

{****************** quando o formulario é criado ******************************}
procedure TFPrincipal.FormCreate(Sender: TObject);
begin
  VprNomeModulos := TStringList.Create;
  VprDiretorioCorrente := RetornaDiretorioCorrente;
  IconeBarraStatus1.AAtiva := true;
  IconeBarraStatus1.AVisible := true;
  VprUsuarioLogado := false;
  CarregaNomeModulos;

  Varia := TVariaveis.Create;   // classe das variaveis principais
  Config := TConfig.Create;     // Classe das variaveis Booleanas
  ConfigModulos := TConfigModulo.create; // classe das variaveis de configuracao do modulo.
  LeIni;
  IniciaTela;
//  ConfiguraTela;
  Ocultar1.Checked := false; // nunca inicia oculto
end;


procedure TFPrincipal.IniciaTela;
begin
  self.Height := 112;
  BSair.top := 0;
  BLogado.top := BSair.Height;
end;
{******************** quando o formulario é mostrado **************************}
procedure TFPrincipal.FormShow(Sender: TObject);
var
  H : HWnd;
begin
  //esconte o botão da barra de tarefas quando o programa estiver executando
  H := FindWindow(Nil,strtopchar(NomedoMenu));
  if H <> 0 then
    ShowWindow(H,SW_HIDE);
end;

{****************** quando o formulario e fechado *****************************}
procedure TFPrincipal.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  BaseDados.Close;
  FechaAplicativos;
end;

{(((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
                             eventos do menu suspensos
)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))}

{***************** oculata a tela com os botões *******************************}
procedure TFPrincipal.Ocultar1Click(Sender: TObject);
begin
  Ocultar1.Checked := not Ocultar1.Checked;
  Visible := not Ocultar1.Checked;
end;

{******************** deixa a janela sempre visivel ***************************}
procedure TFPrincipal.MSempreVisivelClick(Sender: TObject);
begin
  MSempreVisivel.Checked := not MSempreVisivel.Checked;
  if MSempreVisivel.Checked then
    FormStyle := fsStayOnTop
  else
    FormStyle := fsNormal;
  GravaIni;
end;

{****************** mostra ou naum os texto da barra ************************ }
procedure TFPrincipal.MMostraTextoClick(Sender: TObject);
begin
  MMostraTexto.Checked := not MMostraTexto.Checked;
  EscondeTexto(MMostraTexto.Checked);
  ConfiguraTela;
  GravaIni;
end;

{(((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
                             eventos do usuario
)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))}

{******************** abre base de dados **************************************}
function TFPrincipal.AbreBaseDados( Alias : string ) : Boolean;
begin
  result := AbreBancoDadosAlias(BaseDados,Alias);
end;

{******************** carrega o nome do usuario *******************************}
procedure TFPrincipal.CarregaNomeUsuario;
var
  VpfLaco : Integer;
begin
  LUsuario.Caption :='';
  for VpfLaco := 1 to length(Varia.usuario) do
    LUsuario.Caption := LUsuario.Caption + Varia.Usuario[VpfLaco]+ ' ';

end;

{************** mostra a menssagem que é versao demonstração ******************}
procedure TFPrincipal.MostraMenssagemDemostracao;
begin
  aviso('VERSÃO DEMONSTRAÇÃO!!!'+ Char(13)+ Char(13)+ 'Esta verão do sistema é de demonstração, para poder utilizar os sistemas utlize o Usuário = 99 e Senha = 99');
end;

{***************** verifica se o usuario esta ok ******************************}
function TFPrincipal.UsuarioOk : boolean;
var
  VpfAcao : Boolean;
begin
  result := false;
  if VprUsuarioLogado Then
    Result := true
  else
  begin
    VpfAcao := true;
    if not BaseDados.Connected Then
      VpfAcao :=  AbreBaseDados(VplParametroBaseDados);
    if VpfAcao Then
    begin
      FAbertura := TFAbertura.Create(Application);
      FAbertura.ShowModal;
      if Varia.StatusAbertura = 'OK' then
      begin
        VprUsuarioLogado := True;
        result := true;
        BLogado.Down := true;
        ConfiguraBotoes;
        ConfiguraTela;
        CarregaNomeUsuario;
        BLogado.Caption := 'Fechar usuário';
        BLogado.Hint := BLogado.Caption;
      end
      else
        BLogado.Down := false;
    end;
  end;
end;

{***************** organiza sempre a barra na esquerda ***********************}
procedure TFPrincipal.OrganizaBarra;
begin
  case VprAlinhamento of
    0 :  begin
          self.Top := 0;
          self.left := (Screen.Width - self.Width);
          BarraLateral.Align := alRight;
          CorPainelGra1.AEfeitosDeFundos := bdTopo;
          BarraLateral.AConfiguracoes := CorPainelGra1;
         end;
    1 :  begin
          self.Top := 0;
          BarraLateral.Align := alLeft;
          self.left := 0;
          CorPainelGra1.AEfeitosDeFundos := bdTopo;
          BarraLateral.AConfiguracoes := CorPainelGra1;
        end;
    2 :  begin
          self.Top := 0;
          self.left := 0;
          BarraLateral.Align := alTop;
          LUsuario.WordWrap := false;
          CorPainelGra1.AEfeitosDeFundos := bdEsquerda;
          BarraLateral.AConfiguracoes := CorPainelGra1;
        end;
    3 :  begin
          self.Top := Screen.Height - self.Height - 28;
          self.left := 0;
          BarraLateral.Align := alTop;
          CorPainelGra1.AEfeitosDeFundos := bdEsquerda;
          BarraLateral.AConfiguracoes := CorPainelGra1;
        end;

  end;
end;

{************* grava configuracoes no regedit ******************************* }
procedure TFPrincipal.GravaIni;
var
 Ini : TRegIniFile;
begin
  Ini := TRegIniFile.Create('Software\Systec\Sistema');
  Ini.WriteBool('BARRA_INSIG','SEMPREVISIVEL', MSempreVisivel.Checked);
  Ini.WriteBool('BARRA_INSIG','MOSTRATEXTO', MMostraTexto.Checked);
  Ini.WriteInteger('BARRA_INSIG','ALINHAMENTO', VprAlinhamento);
end;

{************* le configuracoes no regedit *88****************************** }
procedure TFPrincipal.LeIni;
var
 Ini : TRegIniFile;
begin
  Ini := TRegIniFile.Create('Software\Systec\Sistema');
  MSempreVisivel.Checked := Ini.ReadBool('BARRA_INSIG','SEMPREVISIVEL', true);
  MMostraTexto.Checked := Ini.ReadBool('BARRA_INSIG','MOSTRATEXTO', true );
  VprAlinhamento := Ini.ReadInteger('BARRA_INSIG','ALINHAMENTO', 0);

  case VprAlinhamento of
    0 : MDireita.Checked := true;
    1 : MEsquerda.Checked := true;
    2 : MSuperior.Checked := true;
    3 : MInferior.Checked := true;
  end;
  if MSempreVisivel.Checked then
    FormStyle := fsStayOnTop
  else
    FormStyle := fsNormal;
  EscondeTexto(MMostraTexto.Checked);
end;

{*********** esconde todos os textos dos botoes *****************************}
procedure TFPrincipal.EscondeTexto(mostrar : Boolean );
var
  laco : integer;
begin
  if not mostrar then
    BLogado.Caption := ''
  else
    BLogado.Caption := BLogado.Hint;

  for laco := 0 to self.ComponentCount - 1 do
  begin
    if (self.Components[laco] is TbitBtn) then
    begin
      if not mostrar then
      begin
        (self.Components[laco] as TbitBtn).Caption := '';
        (self.Components[laco] as TbitBtn).Width := 45;
        BLogado.Width := 45;
        self.Width := 78;
      end
      else
      begin
        (self.Components[laco] as TbitBtn).Caption := (self.Components[laco] as TbitBtn).hint;
        (self.Components[laco] as TbitBtn).Width := 140;
        BLogado.Width := 140;
        self.Width := 175;
      end;
    end;
  end;
end;


{******************** alinha o botao ****************************************}
procedure  TFPrincipal.AlinhaBotao( Botao : TBitBtn);
begin
    if Botao.Visible then
    begin
      case VprAlinhamento of
        0, 1 : begin
                 Botao.Top := VprTopo;
                 Botao.Left := VprLeft;
                 VprTopo := VprTopo + VprAlturaBotao;
             end;
        2,3 : begin
                botao.Top := VprTopo;
                botao.Left := VprLeft;
                Vprleft := Vprleft + VprLarguraBotao;
                // caso seja maior que a tela
                if (VprLeft + VprLarguraBotao) > screen.Width then
                begin
                  VprLeft := 4;
                  VprTopo := VprTopo + VprAlturaBotao;
                end;
               if VprLeft > VprMaiorLargura then
                 VprMaiorLargura := VprLeft;
           end;
      end;
    end;
end;


function TFPrincipal.PermiteUsuario(Campo : string) : Boolean;
begin
  AdicionaSQLAbreTabela(aux, ' Select ' + Campo + ' from CadUsuarios ' +
                             ' where i_cod_usu = ' + Inttostr(varia.CodigoUsuario) );
  result := aux.FieldByName(Campo).AsString = 'S';
  aux.close;
end;

{************  configura a tela conforme os modulos disponiveis ***************}
procedure TFPrincipal.ConfiguraBotoes;
var
  VpfArquivo : TextFile;
  VpfLinha : String;
begin
  try
    if ExisteArquivo('Modulos.Mod') then
    begin

      // le arquivo de configuracoes
      AssignFile(VpfArquivo,'Modulos.Mod');
      reset(VpfArquivo);
      Readln(Vpfarquivo,Vpflinha);

      // configura botoes visiveis
      Financeiro.Visible := (ExisteLetraString('A',VpfLinha) and (PermiteUsuario('C_MOD_FIN')) );
      BPontoLoja.Visible := ExisteLetraString('B',VpfLinha) and (PermiteUsuario('C_MOD_PON'));
      BFaturamento.Visible := ExisteLetraString('E',VpfLinha) and (PermiteUsuario('C_MOD_FAT'));
      BEstoqueCusto.Visible := ExisteLetraString('D',VpfLinha) and (PermiteUsuario('C_MOD_EST'));
      BCaixa.Visible := ExisteLetraString('F',VpfLinha) and (PermiteUsuario('C_MOD_CAI'));
      BTransferencia.Visible := ExisteLetraString('C',VpfLinha) and (PermiteUsuario('C_MOD_TRX'));
      BAcademico.Visible := ExisteLetraString('M',VpfLinha) and (PermiteUsuario('C_MOD_ACA'));
      BSistema.Visible := PermiteUsuario('C_CON_SIS');
      BAmbiente.Visible := PermiteUsuario('C_CON_USU');

      CloseFile(VpfArquivo);
    end
    else
      BSistema.visible := true;
  except
  end;
end;

{************  configura a tela conforme os modulos disponiveis ***************}
procedure TFPrincipal.ConfiguraTela;
begin
  try
    // configura menu
    MFinanceiro.Visible := Financeiro.Visible;
    MPontodeLoja.Visible := BPontoLoja.Visible;
    MFaturamento.Visible := BFaturamento.Visible;
    MCaixa.Visible := BCaixa.Visible;
    MEstoque.Visible := BEstoqueCusto.Visible;
    MTransferencias.Visible := BTransferencia.Visible;
    MRelatorios.Visible := BAcademico.Visible;
    MSistema.Visible := BSistema.Visible;
    MAmbiente.Visible := BAmbiente.Visible;

    // muda posicao
    VprAlturaBotao := 41;
    VprLarguraBotao := BFaturamento.Width;
    VprMaiorLargura := VprLarguraBotao;
    VprTopo := 3;
    VprLeft := 4;

    if Financeiro.Visible then
      AlinhaBotao(Financeiro);
    if BPontoLoja.Visible then
      AlinhaBotao(BPontoLoja);
    if BFaturamento.Visible then
      AlinhaBotao(BFaturamento);
    if BEstoqueCusto.Visible then
      AlinhaBotao(BEstoqueCusto);
    if BCaixa.Visible then
      AlinhaBotao(BCaixa);
    if BTransferencia.Visible then
      AlinhaBotao(BTransferencia);
    if BAcademico.Visible then
      AlinhaBotao(BAcademico);
    if BSistema.Visible then
      AlinhaBotao(BSistema);
    if BAmbiente <> nil then
      if BAmbiente.Visible then
         AlinhaBotao(BAmbiente);
    AlinhaBotao(BSair);

    if VprAlinhamento in [0,1] then
    begin
      BLogado.Top := VprTopo;
      BLogado.Left := VprLeft;
      VprTopo := VprTopo + VprAlturaBotao;
      // formualrio
      self.Height := VprTopo + VprAlturaBotao - 12;
      self.Width := 35 + VprLarguraBotao;
    end
    else
    begin
      BLogado.Left := Vprleft;
      BLogado.Top := VprTopo;
      VprLeft := Vprleft + VprLarguraBotao;
      // formulario
      self.Width := VprMaiorLargura + VprLarguraBotao + 9;
      self.Height := VprTopo + VprAlturaBotao + 48;
    end;
    OrganizaBarra;
  except
  end;
end;

{*********************** reseta o arquivo ini *********************************}
procedure TFPrincipal.ResetaIni;
var
  VpfArquivoIni : TIniFile;
  VpfLaco : Integer;
begin
  try
    VpfArquivoIni := TIniFile.Create(VprDiretorioCorrente +'\'+ VplParametroBaseDados + '.ini');
    for VpfLaco := 0 to VprNomeModulos.Count -1 do
      VpfArquivoIni.WriteInteger(VprNomeModulos.Strings[Vpflaco],'EmUso',0);
    VpfArquivoIni.free;
  except
    aviso('Erro na gravação do arquivo ' + BaseDados.AliasName);
  end;
end;

{(((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
                             eventos dos botoes
)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))}

{********************** sai fora do formulario ********************************}
procedure TFPrincipal.Sair1Click(Sender: TObject);
begin
 close;
end;


{(((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
                             eventos diversos
)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))}

{*********** retorna se o programa esto ou nao em execução ********************}
Function TFPrincipal.ProgramaEmExecucao(VpaNomePrograma, NomeMenu : String) : Boolean;
var
hHandle : THandle;
begin
  NomedoMenu := NomeMenu;
  BLogado.Caption := 'Iniciar ' + NomedoMenu;
  hHandle := FindWindow( nil,StrToPChar(VpaNomePrograma));
  if hHandle <> 0 then
    result := true
  else
   result := false;
end;

{***************** carrega os nomes dos modulos *******************************}
procedure TFPrincipal.CarregaNomeModulos;
begin
  VprNomeModulos.Clear;
  VprNomeModulos.add('Financeiro');
  VprNomeModulos.Add('Ponto de Loja');
  VprNomeModulos.Add('Faturamento');
  VprNomeModulos.Add('Estoque/Custo');
  VprNomeModulos.Add('Caixa');
  VprNomeModulos.Add('Transferência');
  VprNomeModulos.Add('Relatórios');
  VprNomeModulos.add('Configurações do Ambiente');
  VprNomeModulos.Add('Configurações do Sistema');
end;

{************* retorna se o sistema esta em uso ou nao ************************}
function TFPrincipal.HandleSistema(VpaNomeModulo : String) : THandle;
var
  VpfArquivoIni : TIniFile;
begin
  result := 0;
  try
    VpfArquivoIni := TIniFile.Create(VprDiretorioCorrente+'\'+ BaseDados.AliasName+ '.ini');
    result :=  (VpfArquivoIni.ReadInteger(VpaNomeModulo,'EmUso',0));
    VpfArquivoIni.free;
  except
  end;
end;

{******************* fecha os aplicativos abertos *****************************}
// naum esta funcionando
procedure TFPrincipal.FechaAplicativos;
var
  VpfLaco : Integer;
  VpfHandleSistema : THandle;
begin
  for VpfLaco := 0 to VprNomeModulos.Count -1 do
  begin
    VpfHandleSistema := HandleSistema(VprNomeModulos.Strings[vpflaco]);
    if VpfHandleSistema <> 0 then
      DestroyWindow(VpfHandleSistema);
  end;

end;

{************** quando é presssionada algum botao ou menu *********************}
procedure TFPrincipal.MenuClick(Sender: TObject);
var
  VpfHandleSistema : THandle;
  VpfModulo : string;
begin
  if (Sender is TComponent) then
  begin
    case TComponent(Sender).Tag of
      0 : VpfModulo := 'Financeiro.exe';
      1 : VpfModulo := 'PontoLoja.exe';
      2 : VpfModulo := 'Faturamento.exe';
      3 : VpfModulo := 'EstoqueCusto.exe';
      4 : VpfModulo := 'Caixa.exe';
      5 : VpfModulo := 'Transferencia.exe';
      6 : VpfModulo := 'Academico.exe';
      7 : VpfModulo := 'ConfiguracoesAmbiente.exe';
      8 : VpfModulo := 'ConfiguracoesSistema.exe';
    end;

    if UsuarioOk Then
    begin
     VpfHandleSistema := HandleSistema(VprNomeModulos.Strings[TWinControl(sender).tag]);
     if VpfHandleSistema = 0 Then
        shellExecute( Handle,'open', StrToPChar(VpfModulo),
                            StrToPChar(VplParametroBaseDados + ' ' + varia.usuario + ' ' + Descriptografa(Varia.Senha) + ' ' +
                            inttostr(varia.CodigoEmpresa) + ' ' + inttostr(varia.CodigoEmpFil)),
                            nil ,SW_NORMAL )
     else
     begin
       closeWindow(VpfHandleSistema);
       ShowWindow(VpfHandleSistema,SW_NORMAL);
     end;
    end;
  end;
end;

{***************** desloga o usuario se ele estiver logado ********************}
procedure TFPrincipal.BLogadoClick(Sender: TObject);
begin
  if VprUsuarioLogado then
  begin
    VprUsuarioLogado := false;
    LUsuario.Caption := '';
    BLogado.Down := false;
    Financeiro.Visible := false;
    BPontoLoja.Visible := false;
    BFaturamento.Visible := false;
    BEstoqueCusto.Visible := false;
    BCaixa.Visible :=  false;
    BTransferencia.Visible := false;
    BAcademico.Visible := false;
    BSistema.Visible :=  false;
    BAmbiente.Visible :=  false;
    IniciaTela;
    BLogado.Caption := 'Iniciar ' + NomedoMenu;
    BLogado.Hint := BLogado.Caption;
  end
  else
    if not UsuarioOk then
      BLogado.Down := false;
end;


{********************* ativa a tela da aplicação ******************************}
procedure TFPrincipal.IconeBarraStatus1Click(Sender: TObject);
begin
  Application.BringToFront;
end;



procedure TFPrincipal.MesquerdaClick(Sender: TObject);
begin
  MDireita.Checked := false;
  Mesquerda.Checked := false;
  MSuperior.Checked := false;
  MInferior.Checked := false;
  if (Sender is TComponent) then
  begin
    case TComponent(Sender).Tag of
      0 : begin MDireita.Checked := true; VprAlinhamento := 0; end;
      1 : begin MEsquerda.Checked := true; VprAlinhamento := 1; end;
      2 : begin MSuperior.Checked := true; VprAlinhamento := 2; end;
      3 : begin MInferior.Checked := true; VprAlinhamento := 3; end;
    end;
    ConfiguraTela;
    GravaIni;
  end;
end;

procedure TFPrincipal.AtualizaModulos1Click(Sender: TObject);
begin
  shellExecute( Handle,'open', StrToPChar('AtualizaSistema.exe'),
                StrToPChar(VplParametroBaseDados + ' ' + varia.usuario + ' ' + Descriptografa(Varia.Senha)),
                nil ,SW_NORMAL );
  self.close;
end;

procedure TFPrincipal.AtualizaModulos2Click(Sender: TObject);
begin
  shellExecute( Handle,'open', StrToPChar('AtualizacaoModulos.exe'),
                nil,
                nil ,SW_NORMAL );
  self.close;                
end;

end.
