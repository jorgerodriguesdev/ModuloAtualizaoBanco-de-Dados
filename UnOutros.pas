Unit UnOutros;

interface
  Uses Classes, DbTables,SysUtils;

Type
  TAtualizaOutros = Class
    Private
    public
      constructor criar( aowner : TComponent; ADataBase : TDataBase );
      function AtualizaOutros : Boolean;
end;

Const
  CT_SenhaAtual = '9774';

implementation

Uses FunSql, ConstMsg, FunNumeros, Registry, Constantes, FunString, funvalida, AAtualizaSistema;

{*************************** cria a classe ************************************}
constructor TAtualizaOutros.criar( aowner : TComponent; ADataBase : TDataBase );
begin
  inherited Create;
end;

function TAtualizaOutros.AtualizaOutros : Boolean;
begin
   result := true;
end;

end.

