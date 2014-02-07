unit envia_notificaciones;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,sqldb, oracleconnection;
  procedure notificacion(remitente:String;destinatario:String;cc:String;bcc:String;asunto:String;contenido:String);
  procedure ejecuta_query(string_query:String);

const
  const_remitente='sig@isco.com.pe';
  const_destinatario='jsalyrosas@isco.com.pe,mreyes@isco.com.pe,ozelada@isco.com.pe';
  const_cc='';
  const_bcc='';
  const_asunto='ERROR:::';
  const_contenido='Mensaje:::';

implementation

procedure ejecuta_query(string_query:String);
var
  // Crea una conezion a SIG
  conexion_oracle: TOracleConnection;
  query_oracle: TSQLQuery;
  transaction_oracle: TSQLTransaction;

begin
  conexion_oracle:=TOracleConnection.Create(nil);

  conexion_oracle.HostName:='172.16.105.194';
  conexion_oracle.DatabaseName:='orcl';
  conexion_oracle.UserName:='sig';
  conexion_oracle.Password:='sig2009';

  try
     conexion_oracle.Connected:=True;
     //WriteLn('Conexion satisfactoria a SIG');

     transaction_oracle:=TSQLTransaction.Create(nil);
     query_oracle:=TSQLQuery.create(nil);

     conexion_oracle.Transaction:=transaction_oracle;
     transaction_oracle.DataBase:=conexion_oracle;
     query_oracle.DataBase:=conexion_oracle;
     query_oracle.Transaction:=transaction_oracle;

     transaction_oracle.StartTransaction;

     query_oracle.SQL.Clear;
     query_oracle.SQL.Text:= string_query;
     query_oracle.ExecSQL;
     query_oracle.SQL.Clear;

     transaction_oracle.Commit;
     transaction_oracle.Free;

     query_oracle.Close;
     query_oracle.Free;

     conexion_oracle.Close;
     conexion_oracle.Free;

  except on e: Exception do
  begin
    WriteLn('Error al realizar la conexion a la Base de Datos: ',e.Message);
    WriteLn(e.Message);
    Exit;
  end;

  end;

end;

procedure notificacion(remitente:String;destinatario:String;cc:String;bcc:String;asunto:String;contenido:String);
var
  var_remitente,var_destinatario,var_cc,var_bcc: String;
  var_asunto,var_contenido,string_query: String;

begin

  if remitente='' then begin var_remitente:=const_remitente; end
  else begin var_remitente:=remitente; end;

  if destinatario='' then begin var_destinatario:=const_destinatario; end
  else begin var_destinatario:=destinatario; end;

  if cc='' then begin var_cc:=const_cc; end
  else begin var_cc:=cc; end;

  if bcc='' then begin var_bcc:=const_bcc; end
  else begin var_bcc:=bcc; end;

  if asunto='' then begin var_asunto:=const_asunto; end
  else begin var_asunto:=asunto; end;

  if contenido='' then begin var_contenido:=const_contenido; end
  else begin var_contenido:=contenido; end;

  //select f_send_mail('DE','PARA','CON COPIA','CON_COPIA_OCULTA ','ASUNTO','CUERPO') from dual;
  string_query:='SELECT F_SEND_MAIL('''+var_remitente+''', '''+var_destinatario+''', ''';
  string_query:=string_query+var_cc+''', '''+var_bcc+''', '''+var_asunto+''', '''+var_contenido+''') FROM DUAL';
  //WriteLn(string_query);
  //ReadLn;
  ejecuta_query(string_query);

end;

end.
