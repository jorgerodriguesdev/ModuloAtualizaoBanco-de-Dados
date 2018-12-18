unit AAtualizaSistema;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, unatualizacao, DBTables, ComCtrls, PainelGradiente,
  ExtCtrls, Componentes1, Db, funsql, ConstMsg, funsistema, Shellapi, funstring,
  UnOutros, UnAtualizacao1, UnAtualizacao2, UnAtualizacao3;

type
  TFAtualizaSistema = class(TForm)
    BaseDados: TDatabase;
    Panel1: TPanel;
    Panel2: TPanel;
    CorPainelGra1: TCorPainelGra;
    Anima: TAnimate;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    MemoColor1: TMemoColor;
    Aux: TQuery;
    BitBtn3: TBitBtn;
    BitBtn4: TBitBtn;
    BitBtn5: TBitBtn;
    Salvar: TSaveDialog;
    Label1: TLabel;
    At: TLabel;
    BitBtn6: TBitBtn;
    BitBtn7: TBitBtn;
    EditColor1: TEditColor;
    Label2: TLabel;
    procedure BitBtn1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure BitBtn4Click(Sender: TObject);
    procedure BitBtn5Click(Sender: TObject);
    procedure BitBtn6Click(Sender: TObject);
    procedure BitBtn7Click(Sender: TObject);
  private
      NroAtualizacao : integer;
      TabelaAlteracao : string;
      AtualizaOutros : TAtualizaOutros;
      Atualizacao : TAtualiza;
      Atualizacao1 : TAtualiza1;
      Atualizacao2 : TAtualiza2;
      Atualizacao3 : TAtualiza3;
      procedure Atualizacoes;
  public
    procedure MostraAtualizacao( Atualiza : string);
    procedure MostraErro( Texto : Tstrings; TabelaUltimaAlteracao : string);
  end;

var
  FAtualizaSistema: TFAtualizaSistema;

implementation

             uses constantes;
{$R *.DFM}

procedure TFAtualizaSistema.Atualizacoes;
begin
   if Atualizacao.AtualizaBanco then
     if Atualizacao1.AtualizaBanco then
       if Atualizacao2.AtualizaBanco then
         if Atualizacao3.AtualizaBanco then
           if AtualizaOutros.AtualizaOutros then
             aviso('Atualização Concluída ');
end;

procedure TFAtualizaSistema.BitBtn1Click(Sender: TObject);
begin
  if BaseDados.Connected then
    BaseDados.Connected := false;

  BaseDados.AliasName := EditColor1.text;
  BaseDados.Connected := true;

  if BaseDados.Connected then
  begin
    self.Height := 222;
    Anima.Visible := true;
    Anima.Active := true;
    //atualiza sistema
    Atualizacoes;
    Anima.Active :=false;
    Anima.Visible := false;
    At.Caption := '';
  end
  else
    aviso('Não foi possível conectar-se com o Banco de dados ' +  EditColor1.text);
end;

procedure TFAtualizaSistema.FormCreate(Sender: TObject);
begin
  FAtualizaSistema.EditColor1.Text := 'Sig';
  FAtualizaSistema.Caption := 'Tudo Azul Sistemas  -  ( Atualização - Azul!) - ' + inttostr(CT_VersaoBanco);
  AtualizaOutros := TAtualizaOutros.Criar(self,BaseDados);
  Atualizacao := TAtualiza.Criar(self,BaseDados);
  Atualizacao1 := TAtualiza1.Criar(self,BaseDados);
  Atualizacao2 := TAtualiza2.Criar(self,BaseDados);
  Atualizacao3 := TAtualiza3.Criar(self,BaseDados);
end;


procedure TFAtualizaSistema.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  BaseDados.Connected := false;
  Atualizacao.Free;
  Atualizacao1.free;
  Atualizacao2.free;
  Atualizacao3.free;
end;

procedure TFAtualizaSistema.BitBtn2Click(Sender: TObject);
begin
  self.close;
end;

procedure TFAtualizaSistema.MostraAtualizacao( Atualiza : string);
begin
  At.Caption := 'AT - ' + Atualiza;
  at.Refresh;
end;

{(((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
                          ERRO
))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))}

procedure TFAtualizaSistema.MostraErro( Texto : Tstrings; TabelaUltimaAlteracao : string );
begin
 self.Height := 415;
// self.Top := self.Top - 100;
 MemoColor1.Lines := Texto;
 TabelaAlteracao := TabelaUltimaAlteracao;
 self.Refresh;
end;

procedure TFAtualizaSistema.BitBtn3Click(Sender: TObject);
begin
  Atualizacoes;
end;

procedure TFAtualizaSistema.BitBtn4Click(Sender: TObject);
begin
  AdicionaSQLAbreTabela(Aux,'Select i_ult_alt from ' + TabelaAlteracao );
  if aux.FieldByName('i_ult_alt').AsInteger < ct_versaoBanco then
  begin
    ExecutaComandoSql(Aux,' Update ' + TabelaAlteracao + ' set L_ATU_IGN = L_ATU_IGN || ''; '' || (i_ult_alt + 1), ' +
                          ' i_ult_alt = i_ult_alt + 1 ');
    Atualizacoes;
  end;
end;

procedure TFAtualizaSistema.BitBtn5Click(Sender: TObject);
begin
  if Salvar.Execute then
    MemoColor1.Lines.SaveToFile(Salvar.FileName);
end;

procedure TFAtualizaSistema.BitBtn6Click(Sender: TObject);
begin
  try
    ExecutaComandoSql(Aux,MemoColor1.Text);
  except
    Erro('OCORREU UM ERRO DURANTE A ATUALIZAÇÃO DO SISTEMA!.');
  end;
end;

procedure TFAtualizaSistema.BitBtn7Click(Sender: TObject);
begin
{  shellExecute( Handle,'open', StrToPChar(PathE_MailPadrao),
                nil,
                nil ,SW_NORMAL );}
end;

end.
