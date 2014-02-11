unit envia_notificaciones;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,sqldb, oracleconnection, IniFiles;
  procedure notificacion(remitente:String;destinatario:String;cc:String;bcc:String;asunto:String;contenido:String);
  procedure ejecuta_query(string_query:String);
  function datos_notificaciones():TStringList;
  function datos_saga_conexion():TStringList;
  function obtiene_archivo_ini():String;
  function obtiene_general_path():String;

implementation

function obtiene_archivo_ini():String;
var
  config_file: String;

begin
  config_file:=ExtractFilePath(ParamStr(0))+'config.ini';
  result:=config_file;
end;

function obtiene_general_path():String;
var
  general_path,config_file: String;
  Ini: TIniFile;

begin
  config_file:=obtiene_archivo_ini();

  try
     Ini:= TIniFile.Create(config_file);

     general_path:=Ini.ReadString('po','path','');

     Ini.Free;

     result:=general_path;

  except on e: Exception do
  begin
    WriteLn('Error al leer el archivo de configuracion: ',e.Message);
    WriteLn(e.Message);
    Exit;
  end;

  end;

end;

function datos_notificaciones():TStringList;
var
  parameters_conexion: TStringList;
  hostname,databasename,username,password: String;
  config_file: String;
  Ini:TIniFile;

begin
  config_file:=obtiene_archivo_ini();

  try
     Ini:= TIniFile.Create(config_file);

     hostname:=Ini.ReadString('notification','hostname','');
     databasename:=Ini.ReadString('notification','database','');
     username:=Ini.ReadString('notification','username','');
     password:=Ini.ReadString('notification','password','');

     Ini.Free;

  except on e: Exception do
  begin
    WriteLn('Error al leer el archivo de configuracion: ',e.Message);
    WriteLn(e.Message);
    Exit;
  end;

  end;

  parameters_conexion:=TStringList.Create;
  parameters_conexion.Add(hostname);
  parameters_conexion.Add(databasename);
  parameters_conexion.Add(username);
  parameters_conexion.Add(password);

  result:=parameters_conexion;
end;

function datos_saga_conexion():TStringList;
var
  parameters_conexion: TStringList;
  hostname,databasename,username,password: String;
  config_file: String;
  Ini:TIniFile;

begin
  config_file:=obtiene_archivo_ini();

  try
     Ini:= TIniFile.Create(config_file);
     hostname:=Ini.ReadString('saga_db','hostname','');
     databasename:=Ini.ReadString('saga_db','database','');
     username:=Ini.ReadString('saga_db','username','');
     password:=Ini.ReadString('saga_db','password','');

     Ini.Free;

  except on e: Exception do
  begin
    WriteLn('Error al leer el archivo de configuracion: ',e.Message);
    WriteLn(e.Message);
    Exit;
  end;

  end;

  parameters_conexion:=TStringList.Create;
  parameters_conexion.Add(hostname);
  parameters_conexion.Add(databasename);
  parameters_conexion.Add(username);
  parameters_conexion.Add(password);

  result:=parameters_conexion;
end;

procedure ejecuta_query(string_query:String);
var
  // Crea una conexion a SIG
  conexion_oracle: TOracleConnection;
  query_oracle: TSQLQuery;
  transaction_oracle: TSQLTransaction;

  // Almacena los parametros de la conexion
  parameters_conexion: TStringList;

begin
  parameters_conexion:=datos_notificaciones();

  conexion_oracle:=TOracleConnection.Create(nil);

  conexion_oracle.HostName:=parameters_conexion[0];
  conexion_oracle.DatabaseName:=parameters_conexion[1];
  conexion_oracle.UserName:=parameters_conexion[2];
  conexion_oracle.Password:=parameters_conexion[3];

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
  config_file: String;
  Ini:TIniFile;

  // Variables del archivo de configuracion
  const_remitente,const_destinatario,const_cc,const_bcc: String;
  const_asunto,const_contenido: String;

begin
  config_file:=obtiene_archivo_ini();

  try
     Ini:= TIniFile.Create(config_file);
     const_remitente:=Ini.ReadString('mail','from','');
     const_destinatario:=Ini.ReadString('mail','to','');
     const_cc:=Ini.ReadString('mail','cc','');
     const_bcc:=Ini.ReadString('mail','bcc','');
     const_asunto:=Ini.ReadString('mail','subject','');
     const_contenido:=Ini.ReadString('mail','content','');

     Ini.Free;

  except on e: Exception do
  begin
    WriteLn('Error al leer el archivo de configuracion: ',e.Message);
    WriteLn(e.Message);
    Exit;
  end;

  end;

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
