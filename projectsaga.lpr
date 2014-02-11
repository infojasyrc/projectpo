program projectsaga;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, CustApp,
  sqldb, oracleconnection, BaseUnix, Dos, envia_notificaciones;

type

  { saga }

  saga = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

{ saga }

function data_oracle():TOracleConnection;
var
  conexion_oracle: TOracleConnection;
  parameters_conexion: TStringList;

begin
  parameters_conexion:=datos_saga_conexion();
  conexion_oracle:=TOracleConnection.Create(nil);

  conexion_oracle.HostName:=parameters_conexion[0];
  conexion_oracle.DatabaseName:=parameters_conexion[1];
  conexion_oracle.UserName:=parameters_conexion[2];
  conexion_oracle.Password:=parameters_conexion[3];

  try
     conexion_oracle.Connected:=True;
     //WriteLn('Conexion satisfactoria');
     Result:=conexion_oracle;

  except on e: Exception do
  begin
    WriteLn('Error al realizar la conexion a la Base de Datos: ',e.Message);
    WriteLn(e.Message);
    Exit;
  end;

  end;

end;

procedure filepo(new_file: String);
var
  // Variables relacionadas al archivo PO
  content_file: TextFile;

  file_po: File of LongInt;
  filesize_int: LongInt;
  line,fecha_creacion,fecha_modificacion,fecha_ultimo_acceso: String;
  fecha_transaccion,fecha_transaccion_final,nombre_completo_archivo: String;
  directorio:DirStr;
  nombre_archivo:NameStr;
  extension_archivo:ExtStr;
  file_information: Stat;
  i,items,estado: Integer;
  descripcion,carpeta_general: String;

  // Variables de la cabecera del archivo PO
  orden_compra,referencia,referenciax: String;
  beneficiario,trader,embarque,proveedor: String;

  // Variables de los detalles del archivo PO
  code_transaccion,ci,po_number,correlativo,style,sku: String;
  item_description,composicion,num_ordcompra,modelo: String;
  unidad_solicitadas,peso_neto,unimed_peso,talla: String;
  color,costo_unitario,moneda,unid_carton,cartones: String;
  unimed_longitud,alto_carton,ancho_carton,largo_carton: String;

  correlativo_int,unidad_solicitadas_int,costo_unitario_real: Integer;
  cartones_real,cantidad_productos,costo_total,costo_total_por_item: Integer;
  alto_carton_real,ancho_carton_real,largo_carton_real: Integer;

  string_sql,string_sql_details: String;

  // Variables para la conexion y ejecucion de consultas en Oracle
  final_conexion: TOracleConnection;
  query_oracle: TSQLQuery;
  transaction_oracle: TSQLTransaction;

  // Variables para el envio de notificaciones
  asunto,contenido,contenido_items:String;
  item_errors_flag:Boolean;
  cantidad_items_errados:Integer;

begin

  // Inicializo variables relacionadas al archivo
  directorio:='/home/';
  carpeta_general:=obtiene_general_path();
  nombre_archivo:='';
  extension_archivo:='';
  nombre_completo_archivo:='';
  fecha_creacion:='';
  fecha_modificacion:='';
  fecha_ultimo_acceso:='';
  estado:=0;
  descripcion:='';

  // Inicializa variables relacionadas al envio de notificaciones
  asunto:='';
  contenido:='';
  contenido_items:='';
  item_errors_flag:=False;
  cantidad_items_errados:=0;

  FSplit(new_file,directorio,nombre_archivo,extension_archivo);
  nombre_completo_archivo:=nombre_archivo+extension_archivo;

  FpStat(new_file,file_information);
  fecha_creacion:= FormatDateTime('DD-MMM-YYYY',FileDateTodateTime(file_information.st_atime));
  fecha_modificacion:= FormatDateTime('DD-MMM-YYYY',FileDateTodateTime(file_information.st_mtime));
  fecha_ultimo_acceso:= FormatDateTime('DD-MMM-YYYY',FileDateTodateTime(file_information.st_ctime));

  i:=0;
  items:=0;
  cantidad_productos:=0;
  costo_total:=0;
  costo_total_por_item:=0;
  beneficiario:='';
  trader:='';
  fecha_transaccion:='';
  embarque:='';
  proveedor:='';

  // Obtiene la conexion a la BD
  final_conexion:=data_oracle();

  transaction_oracle:=TSQLTransaction.Create(nil);
  query_oracle:=TSQLQuery.create(nil);

  final_conexion.Transaction:=transaction_oracle;
  transaction_oracle.DataBase:=final_conexion;
  query_oracle.DataBase:=final_conexion;
  query_oracle.Transaction:=transaction_oracle;

  transaction_oracle.StartTransaction;

  AssignFile(content_file, new_file);
  Reset(content_file);

  while not eof(content_file) do
  begin
    ReadLn(content_file,line);

    // Obtiene los datos de la cabecera: Linea 1 hasta la linea 3
    if i<=2 then
    begin
      orden_compra:= Copy(line,11,15);
      referencia:= orden_compra;
      referenciax:= Copy(referencia,1,13);
      i:=i+1;
      if i=1 then
      begin
        fecha_transaccion:= Trim(Copy(line,26,8));
        if fecha_transaccion<>'' then
        begin
          fecha_transaccion:= Copy(line,32,2)+'-'+Copy(line,30,2)+'-'+Copy(line,26,4);
          fecha_transaccion_final:= FormatDateTime('DD-MMM-YYYY',StrToDate(fecha_transaccion));
        end
        else fecha_transaccion_final:='';

        trader:= Trim(Copy(line,180,25));
        proveedor:= Trim(Copy(line,217,30));
      end;
      if i=3 then
      begin
        beneficiario:= Trim(Copy(line,385,30));
        embarque:= Trim(Copy(line,26,2));
      end;
    end
    // Obtiene los detalles: Linea 4 hacia abajo
    else
    begin

      if line<>'' then
      begin
        items:=items+1;
        try
          code_transaccion:= Copy(line,1,8);
          ci:= Copy(line,9,2);
          po_number:= Trim(Copy(line,11,15));

          correlativo:= Trim(Copy(line,26,4));
          if correlativo<>'' then begin correlativo_int:= StrToInt(correlativo); end
          else begin correlativo_int:=0; end;

          style:= Trim(Copy(line,30,25));
          sku:= Trim(Copy(line,55,15));
          item_description:= Trim(Copy(line,70,100));
          composicion:= Trim(Copy(line,170,30));
          num_ordcompra:= Trim(Copy(line,200,15));
          modelo:= Trim(Copy(line,215,80));

          unidad_solicitadas:= Copy(line,295,10);
          if unidad_solicitadas<>'' then begin unidad_solicitadas_int:= StrToInt(unidad_solicitadas); end
          else begin unidad_solicitadas_int:=0; end;

          peso_neto:= Trim(Copy(line,305,10));
          unimed_peso:= Trim(Copy(line,315,15));
          talla:= Trim(Copy(line,330,25));
          color:= Trim(Copy(line,355,25));

          costo_unitario:= Copy(line,380,10);
          if costo_unitario<>'' then begin costo_unitario_real:= StrToInt(costo_unitario); end
          else begin costo_unitario_real:=0; end;

          moneda:= Copy(line,390,3);
          unid_carton:= Copy(line,393,5);

          cartones:= Trim(Copy(line,398,5));
          if cartones<>'' then begin cartones_real:= StrToInt(cartones); end
          else begin cartones_real:=0; end;

          unimed_longitud:= Copy(line,403,10);

          alto_carton:= Trim(Copy(line,413,10));
          if alto_carton<>'' then begin alto_carton_real:= StrToInt(alto_carton); end
          else begin alto_carton_real:=0; end;

          ancho_carton:= Trim(Copy(line,423,10));
          if ancho_carton<>'' then begin ancho_carton_real:= StrToInt(ancho_carton); end
          else begin ancho_carton_real:=0; end;

          largo_carton:= Trim(Copy(line,433,10));
          if largo_carton<>'' then begin largo_carton_real:= StrToInt(largo_carton); end
          else begin largo_carton_real:=0; end;

          cantidad_productos:= cantidad_productos + unidad_solicitadas_int;
          costo_total_por_item:= unidad_solicitadas_int * costo_unitario_real;
          costo_total:=costo_total+costo_total_por_item;
          {
          // Imprime las variables necesarias de cada detalle
          WriteLn('Codigo de Transaccion:', code_transaccion);
          WriteLn('CI:', ci);
          WriteLn('Orden de Compra - PO Number:', po_number);
          WriteLn('Correlativo:', correlativo_int);
          WriteLn('Style:', style);
          WriteLn('SKU:', sku);
          WriteLn('Item Description:', item_description);
          WriteLn('Composicion:', composicion);
          WriteLn('Numero de Orden de compra:', num_ordcompra);
          WriteLn('Modelo:', modelo);
          WriteLn('Unidades solicitadas:', unidad_solicitadas_int);
          WriteLn('Peso Neto:', peso_neto);
          WriteLn('Unidad de Medida (Peso):', unimed_peso);
          WriteLn('Talla:', talla);
          WriteLn('Color:', color);
          WriteLn('Costo Unitario:', costo_unitario_real);
          WriteLn('Moneda:', moneda);
          WriteLn('Unidad de carton:', unid_carton);
          WriteLn('Cartones:', cartones_real);
          WriteLn('Unidad de medida (Longitud):', unimed_longitud);
          WriteLn('Alto carton:', alto_carton_real);
          WriteLn('Ancho carton:', ancho_carton_real);
          WriteLn('Largo carton:', largo_carton_real);
          WriteLn('Costo total del item:', costo_total_por_item);
          }

          string_sql_details:='INSERT INTO BUSCAR_ARCHIVOS_DET (EMPRESA, RUTA, ARCHIVO,';
          string_sql_details:=string_sql_details+' CODE_TRANSACCION, CI, PO_NUMBER, CORRELATIVO, STYLE, SKU,';
          string_sql_details:=string_sql_details+' ITEM_DESCRIPCION, COMPOSICION, NUM_ORDCOMPRA, MODELO,';
          string_sql_details:=string_sql_details+' UNID_SOLICITADAS, PESO_NETO, UNIMED_PESO, TALLA, COLOR,';
          string_sql_details:=string_sql_details+' COSTO_UNITARIO, MONEDA, UNID_CARTON, CARTONES,';
          string_sql_details:=string_sql_details+' UNIMED_LONGTIUD, ALTO_CARTON, ANCHO_CARTON, LARGO_CARTON,';
          string_sql_details:=string_sql_details+' FECHA_MINIMA, ARCHIVO_MINIMA, ANO_PRESE, CODI_ADUAN, CODI_REGI,';
          string_sql_details:=string_sql_details+' NUME_ORDEN) VALUES(''001'', ''';
          //string_sql_details:=string_sql_details+directorio+''', '''+nombre_completo_archivo+''', ''';
          string_sql_details:=string_sql_details+carpeta_general+''', '''+nombre_completo_archivo+''', ''';
          string_sql_details:=string_sql_details+code_transaccion+''', '''+ci+''', '''+po_number+''', ';
          string_sql_details:=string_sql_details+IntToStr(correlativo_int)+', '''+style+''', '''+sku+''', ''';
          string_sql_details:=string_sql_details+item_description+''', '''+composicion+''', '''+num_ordcompra+''', '''+modelo+''', ';
          string_sql_details:=string_sql_details+IntToStr(unidad_solicitadas_int)+', '''+peso_neto+''', '''+unimed_peso+''', '''+talla+''', '''+color+''', ';
          string_sql_details:=string_sql_details+IntToStr(costo_unitario_real)+', '''+moneda+''', '''+unid_carton+''', ''';
          string_sql_details:=string_sql_details+IntToStr(cartones_real)+''', '''+unimed_longitud+''', '+IntToStr(alto_carton_real)+', ';
          string_sql_details:=string_sql_details+IntToStr(ancho_carton_real)+', '+IntToStr(largo_carton_real)+', ';
          string_sql_details:=string_sql_details+'NULL, NULL, NULL, NULL, NULL, NULL)';

          //WriteLn('Cadena a Ejecutar es:'+string_sql_details);

          query_oracle.SQL.Clear;
          query_oracle.SQL.Text:= string_sql_details;
          query_oracle.ExecSQL;
          query_oracle.SQL.Clear;

        except on E: Exception do
        begin
          item_errors_flag:=True;
          cantidad_items_errados:=cantidad_items_errados+1;

          contenido_items:=contenido_items+'Item: '+IntToStr(items)+#10;
          contenido_items:=contenido_items+'Linea: '+#10+line+#10+E.Message;

          Continue;
        end;
      end;
    end;

  end;
  end;

  AssignFile(file_po, new_file);
  Reset(file_po);
  filesize_int:= FileSize(file_po);

  try

    if item_errors_flag=False then
    begin
      estado:=1;
      descripcion:='Registro de archivo exitoso.';
    end
    else
    begin
      estado:=0;
      descripcion:='Registro de archivo con errores.'+#10+contenido_items;
    end;

    string_sql:='INSERT INTO BUSCAR_ARCHIVOS (EMPRESA, RUTA, ARCHIVO, TAMANO, FECHA, REFERENCIA,';
    string_sql:=string_sql+' TOTAL_ITEMS, CANTIDAD_PRODUCTOS, FECHA_HORAC, PROVEEDOR,';
    string_sql:=string_sql+' MONTO_TOTAL, EMBARQUE, ANO_PRESE, CODI_ADUAN, CODI_REGI,';
    string_sql:=string_sql+' NUME_ORDEN, FECHA_ASIGNACION_ORDEN, FECHA_MINIMA, REFERENCIAX,';
    string_sql:=string_sql+' FLAG_MINIMA, TRADER, BENEFICIARIO, ESTADO, DESCRIPCION) VALUES(';
    //string_sql:=string_sql+'''001'', '''+directorio+''', '''+nombre_completo_archivo+''', '+IntToStr(filesize_int)+', ''';
    string_sql:=string_sql+'''001'', '''+carpeta_general+''', '''+nombre_completo_archivo+''', '+IntToStr(filesize_int)+', ''';
    string_sql:=string_sql+fecha_creacion+''', '''+orden_compra+''', '+IntToStr(items)+', '+IntToStr(cantidad_productos)+', ''';
    string_sql:=string_sql+fecha_transaccion_final+''', '''+proveedor+''', '+IntToStr(costo_total)+', '''+embarque+''', NULL, NULL, NULL,';
    string_sql:=string_sql+'NULL, NULL, NULL, '''+referenciax+''', ''F'', '''+trader+''', ''';
    string_sql:=string_sql+beneficiario+''', '+IntToStr(estado)+', '''+descripcion+''')';

    //WriteLn('Cadena a Ejecutar es:'+string_sql);

    query_oracle.SQL.Clear;
    query_oracle.SQL.Text:= string_sql;
    query_oracle.ExecSQL;
    query_oracle.SQL.Clear;
    {
    WriteLn();
    WriteLn('Orden de compra:', orden_compra);
    WriteLn('ReferenciaX:', referenciax);
    WriteLn('Numero de Lineas Encontradas en la cabecera:', i);
    WriteLn('Numero de Lineas Encontradas en los detalles:', items);
    WriteLn('Cantidad total de Productos:', cantidad_productos);
    WriteLn('Costo total de Productos:', costo_total);
    }

    transaction_oracle.Commit;

    query_oracle.Close;
    query_oracle.Free;

    asunto:='REGISTRO DE ARCHIVO PO: '+nombre_completo_archivo;
    contenido:='Archivo registrado: '+new_file+#10;
    contenido:=contenido+'Numero de items encontrados: '+IntToStr(items)+#10;
    contenido:=contenido+'Numero de items errados: '+IntToStr(cantidad_items_errados)+#10;

    // Envia mensaje de notificacion de registro de archivo
    notificacion('','','','',asunto,contenido);

  except on E: Exception do
    begin

      WriteLn('Error en archivo: ',new_file);

      asunto:='ERROR AL REGISTRAR ARCHIVO:::';
      contenido:='Error en archivo: '+new_file+#10;
      contenido:=contenido+E.Message;

      // Envia el mensaje de error
      notificacion('','','','',asunto,contenido);

    end;
  end;

  if item_errors_flag=True then
  begin

    WriteLn('Error en los items: ',contenido_items);

    asunto:='ERROR AL REGISTRAR ITEMS DEL ARCHIVO:::';
    contenido:='Error en archivo: '+new_file+#10;
    contenido:=contenido+contenido_items;

    // Envia el mensaje de error
    notificacion('','','','',asunto,contenido);

  end;

  transaction_oracle.Free;

  final_conexion.Close;
  final_conexion.Free;

  CloseFile(content_file);
  CloseFile(file_po);

end;

procedure saga.DoRun;
var
  //ErrorMsg: String;
  archivo: String;
  numero_parametros: Integer;
begin
  {
  // quick check parameters
  ErrorMsg:=CheckOptions('h','help');
  if ErrorMsg<>'' then begin
    ShowException(Exception.Create(ErrorMsg));
    Terminate;
    Exit;
  end;

  // parse parameters
  if HasOption('h','help') then begin
    WriteHelp;
    Terminate;
    Exit;
  end;
  }
  { add your program here }
  numero_parametros:=ParamCount;

  if numero_parametros<1 then
  begin
    WriteLn('Numero de parametros incorrectos');
    Terminate;
    Exit;
  end;

  archivo:=ParamStr(1);
  //WriteLn(ParamStr(0));

  if FileExists(archivo) then
  begin
    filepo(archivo);
  end;

  // stop program loop
  //ReadLn();
  Terminate;
end;

constructor saga.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
end;

destructor saga.Destroy;
begin
  inherited Destroy;
end;

procedure saga.WriteHelp;
begin
  { add your help code here }
  writeln('Usage: ',ExeName,' -h');
end;

var
  Application: saga;
begin
  Application:=saga.Create(nil);
  Application.Title:='Saga';
  Application.Run;
  Application.Free;
end.

