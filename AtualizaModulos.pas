unit AtualizaModulos;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, formularios,
  StdCtrls, LabelCorMove, PainelGradiente, ExtCtrls, Componentes1, Buttons,
  ComCtrls, FileCtrl, registry, DBTables, Db;

type
  TFAtualizaModulos = class(TFormularioPermissao)
    PanelColor1: TPanelColor;
    PainelGradiente1: TPainelGradiente;
    Anima: TAnimate;
    Nome: TLabel3D;
    BitBtn1: TBitBtn;
    Barra: TProgressBar;
    Timer1: TTimer;
    BaseDados: TDatabase;
    Aux: TQuery;
    CorPainelGra1: TCorPainelGra;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BitBtn1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
  public
    PathInsig, PathNovoEXE : string;
    Paths : TstringList;
    ini : TRegIniFile;
    Alias : String;
    procedure CopiaArquivoModulo(Arquivo : String);
    procedure CopiaModulos;
  end;

var
  FAtualizaModulos: TFAtualizaModulos;

implementation

uses funarquivos, funstring, constmsg, funobjeto, funsql;

{$R *.DFM}


{ ****************** Na criação do Formulário ******************************** }
procedure TFAtualizaModulos.FormCreate(Sender: TObject);
begin
  ini := TRegIniFile.Create('Software\Systec\Sistema');
end;

{ ******************* Quando o formulario e fechado ************************** }
procedure TFAtualizaModulos.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 Paths.free;
 Action := CaFree;
end;

procedure TFAtualizaModulos.CopiaArquivoModulo(Arquivo : String);
begin
  if FileExists( PathNovoEXE + Arquivo) then
  begin
     Nome.Caption := 'Atualizando... ' + Arquivo;
     nome.Refresh;
    if FileExists( PathInsig + Arquivo) then
    begin
      if FileExists(PathInsig + 'BackupEXE\' + Arquivo) then
      begin
        SetFileAttributes(StrToPChar(PathInsig + 'BackupEXE\' + Arquivo), FILE_ATTRIBUTE_ARCHIVE);
        DeletaArquivo(PathInsig + 'BackupEXE\' + Arquivo);
      end;
      SetFileAttributes(StrToPChar(PathInsig + Arquivo), FILE_ATTRIBUTE_ARCHIVE);
      MoveArquivo( PathInsig + Arquivo, PathInsig + 'BackupEXE\' + Arquivo);
    end;
    SetFileAttributes(StrToPChar(PathNovoEXE), FILE_ATTRIBUTE_ARCHIVE);
    copiaarquivo( PathNovoEXE + Arquivo,PathInsig + Arquivo);
  end;
end;


procedure TFAtualizaModulos.CopiaModulos;
begin
  PathInsig := NormalDiretorio(ini.readString('PATH_INSIG','PATH','c:\OneNetWorks\'));

  if not DirectoryExists(PathInsig) then
  begin
    aviso('Não foi possível encontrar a pasta de destino - ' + PathInsig );
    abort;
  end;

  if DirectoryExists(PathNovoEXE) then
  begin
    Anima.Visible := true;
    anima.Active := true;
    nome.Visible := true;

    if not DirectoryExists(PathInsig + 'BackupEXE') then
      CriaDiretorio(PathInsig + 'BackupEXE');

    Barra.Position := 0;
    CopiaArquivoModulo('Financeiro.exe');
    barra.Position := Barra.Position + 1;
    CopiaArquivoModulo('PontoLoja.exe');
    barra.Position := Barra.Position + 1;
    CopiaArquivoModulo('Faturamento.exe');
    barra.Position := Barra.Position + 1;
    CopiaArquivoModulo('EstoqueCusto.exe');
    barra.Position := Barra.Position + 1;
    CopiaArquivoModulo('Caixa.exe');
    barra.Position := Barra.Position + 1;
    CopiaArquivoModulo('Transferencia.exe');
    barra.Position := Barra.Position + 1;
    CopiaArquivoModulo('Academico.exe');
    barra.Position := Barra.Position + 1;
    CopiaArquivoModulo('ConfiguracoesAmbiente.exe');
    barra.Position := Barra.Position + 1;
    CopiaArquivoModulo('ConfiguracoesSistema.exe');
    barra.Position := Barra.Position + 1;
    CopiaArquivoModulo('InSig.exe');
    barra.Position := Barra.Position + 1;
    CopiaArquivoModulo('AtualizaSistema.exe');
    barra.Position := Barra.Position + 1;
    Anima.Visible := false;
    anima.Active := false;
    Nome.Caption := 'Atualizando sistema, aguarde...';
    nome.Refresh;
    Barra.Max := 100;
    barra.Position := 0;
    Timer1.Interval := 50;
  end
  else
    aviso('Não foi possível encontrar a pasta de origem - ' + PathNovoEXE );
end;

{ *************** Registra a classe para evitar duplicidade ****************** }
procedure TFAtualizaModulos.BitBtn1Click(Sender: TObject);
begin
  AbreBancoDadosAlias(BaseDados, Alias);
  AdicionaSQLAbreTabela(aux, 'select c_pat_atu from cfg_geral');
  PathNovoEXE :=  aux.fieldByname('c_pat_atu').AsString;
  aux.close;
  BaseDados.Connected := false;
  CopiaModulos;
end;

procedure TFAtualizaModulos.Timer1Timer(Sender: TObject);
begin
  barra.Position := barra.Position + 1;
  if barra.Position >= 100 then
  begin
    Timer1.Interval := 0;
    self.close;
  end;
end;


Initialization
 RegisterClasses([TFAtualizaModulos]);
end.
