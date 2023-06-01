// Проверка нового комментария
unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, IdBaseComponent, IdComponent, IdCustomTCPServer,
  IdCustomHTTPServer, IdHTTPServer, Vcl.Menus, IdContext;

type
  TForm1 = class(TForm)
    btnPlay: TButton;
    btnStop: TButton;
    MainPanel: TPanel;
    TopPanel: TPanel;
    SecPanel: TPanel;
    IdHTTPServer1: TIdHTTPServer;
    Memo1: TMemo;
    TrayIcon1: TTrayIcon;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    NumPlate: TPanel;
    Timer1: TTimer;
    // N1: TMenuItem;
    procedure btnPlayClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    function GetVLCLibPath: String;
    function LoadVLCLibrary(APath: string): integer;
    function GetAProcAddress(handle: integer; var addr: Pointer;
      procName: string; failedList: TStringList): integer;
    function LoadVLCFunctions(vlcHandle: integer;
      failedList: TStringList): Boolean;
    procedure FormResize(Sender: TObject);
    procedure TopPanelDblClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure IdHTTPServer1CommandGet(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure TrayIcon1Click(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure Delay(ms: Cardinal);
    procedure Timer1Timer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure IdHTTPServer1Connect(AContext: TIdContext);
    procedure IdHTTPServer1Disconnect(AContext: TIdContext);
    procedure IdHTTPServer1SessionStart(Sender: TIdHTTPSession);
    procedure IdHTTPServer1SessionEnd(Sender: TIdHTTPSession);
    procedure Button1Click(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

  plibvlc_instance_t = type Pointer;
  plibvlc_media_player_t = type Pointer;
  plibvlc_media_t = type Pointer;

var
  Form1: TForm1;
  H: HWND;
  DCB: TDCB;
  hPort: THandle;
  size, NumberOfBytesWritten: Cardinal;
  CT: TCommTimeouts;
  SerialBuffer: AnsiString;
  HM: THandle;
  HMName: PWideChar = 'HttpServerForICCTV';

implementation

{$R *.dfm}

var
  libvlc_media_new_path: function(p_instance: plibvlc_instance_t;
    path: PAnsiChar): plibvlc_media_t; cdecl;
  libvlc_media_new_location: function(p_instance: plibvlc_instance_t;
    psz_mrl: PAnsiChar): plibvlc_media_t; cdecl;
  libvlc_media_player_new_from_media: function(p_media: plibvlc_media_t)
    : plibvlc_media_player_t; cdecl;
  libvlc_media_player_set_hwnd
    : procedure(p_media_player: plibvlc_media_player_t;
    drawable: Pointer); cdecl;
  libvlc_media_player_play: procedure(p_media_player
    : plibvlc_media_player_t); cdecl;
  libvlc_media_player_stop: procedure(p_media_player
    : plibvlc_media_player_t); cdecl;
  libvlc_media_player_release
    : procedure(p_media_player: plibvlc_media_player_t); cdecl;
  libvlc_media_player_is_playing
    : function(p_media_player: plibvlc_media_player_t): integer; cdecl;
  libvlc_media_release: procedure(p_media: plibvlc_media_t); cdecl;
  libvlc_new: function(argc: integer; argv: PAnsiChar)
    : plibvlc_instance_t; cdecl;
  libvlc_release: procedure(p_instance: plibvlc_instance_t); cdecl;

  vlcLib: integer;
  vlcInstance: plibvlc_instance_t;
  vlcMedia: plibvlc_media_t;
  vlcMediaPlayer: plibvlc_media_player_t;
  vlcInstance2: plibvlc_instance_t;
  vlcMedia2: plibvlc_media_t;
  vlcMediaPlayer2: plibvlc_media_player_t;
  select: Boolean;

procedure TForm1.btnPlayClick(Sender: TObject);
begin
  try
    begin
      // create new vlc instance
      vlcInstance := libvlc_new(0, nil);
      vlcInstance2 := libvlc_new(0, nil);
      // create new vlc media from file
      vlcMedia := libvlc_media_new_location(vlcInstance, { path }
        'rtsp://user:abcd1234@192.168.0.35:554/' { 'e:\udp\239.10.10.9.ts' } );
      vlcMedia2 := libvlc_media_new_location(vlcInstance2,
        'rtsp://user:abcd1234@192.168.0.36:554/' { 'e:\udp\239.10.10.9.ts' } );
      // create new vlc media player
      vlcMediaPlayer := libvlc_media_player_new_from_media(vlcMedia);
      vlcMediaPlayer2 := libvlc_media_player_new_from_media(vlcMedia2);
      // now no need the vlc media, free it
      libvlc_media_release(vlcMedia);
      libvlc_media_release(vlcMedia2);
      if select then
      Begin
        // vlcMedia := libvlc_media_new_location(vlcInstance, { path }
        // 'rtsp://user:abcd1234@192.168.0.35:554/' { 'e:\udp\239.10.10.9.ts' } );
        // vlcMedia2 := libvlc_media_new_location(vlcInstance2,
        // 'rtsp://user:abcd1234@192.168.0.36:554/' { 'e:\udp\239.10.10.9.ts' } );
        // play video in a TPanel, if not call this routine, vlc media will open a new window
        libvlc_media_player_set_hwnd(vlcMediaPlayer, Pointer(MainPanel.handle));
        libvlc_media_player_set_hwnd(vlcMediaPlayer2, Pointer(SecPanel.handle));
      End
      else
      begin
        // vlcMedia2 := libvlc_media_new_location(vlcInstance, { path }
        // 'rtsp://user:abcd1234@192.168.0.35:554/' { 'e:\udp\239.10.10.9.ts' } );
        // vlcMedia := libvlc_media_new_location(vlcInstance2,
        // 'rtsp://user:abcd1234@192.168.0.36:554/' { 'e:\udp\239.10.10.9.ts' } );
        // play video in a TPanel, if not call this routine, vlc media will open a new window
        libvlc_media_player_set_hwnd(vlcMediaPlayer2,
          Pointer(MainPanel.handle));
        libvlc_media_player_set_hwnd(vlcMediaPlayer, Pointer(SecPanel.handle));
      end;
      select := not select;
      // if you want to play from network, use libvlc_media_new_location instead
      // vlcMedia := libvlc_media_new_location(vlcInstance, 'udp://@225.2.1.27:5127');

      // play video in a TPanel, if not call this routine, vlc media will open a new window
      // libvlc_media_player_set_hwnd(vlcMediaPlayer, Pointer(MainPanel.handle));
      // libvlc_media_player_set_hwnd(vlcMediaPlayer2, Pointer(SecPanel.handle));
      // play media
      libvlc_media_player_play(vlcMediaPlayer);
      libvlc_media_player_play(vlcMediaPlayer2);
    end;
  finally

  end;

end;

procedure TForm1.btnStopClick(Sender: TObject);
begin
  try
    begin
      if not Assigned(vlcMediaPlayer) then
      begin
        Showmessage('Not playing 1');
        Exit;
      end;
      // stop vlc media player
      libvlc_media_player_stop(vlcMediaPlayer);
      // and wait until it completely stops
      while libvlc_media_player_is_playing(vlcMediaPlayer) = 1 do
      begin
        Sleep(100);
      end;
      // release vlc media player
      libvlc_media_player_release(vlcMediaPlayer);
      vlcMediaPlayer := nil;

      // release vlc instance
      libvlc_release(vlcInstance);

      if not Assigned(vlcMediaPlayer2) then
      begin
        Showmessage('Not playing 2');
        Exit;
      end;
      // stop vlc media player
      libvlc_media_player_stop(vlcMediaPlayer2);
      // and wait until it completely stops
      while libvlc_media_player_is_playing(vlcMediaPlayer2) = 1 do
      begin
        Sleep(1000);
      end;
      // release vlc media player
      libvlc_media_player_release(vlcMediaPlayer2);
      vlcMediaPlayer2 := nil;

      // release vlc instance
      libvlc_release(vlcInstance2);
    end;
  finally

  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  NumPlate.Visible := not NumPlate.Visible;
end;

procedure TForm1.Delay(ms: Cardinal);
var
  TheTime: Cardinal;
begin
  NumPlate.Visible := true;
  TheTime := GetTickCount + ms;
  while GetTickCount < TheTime do
    Application.ProcessMessages;
  NumPlate.Visible := False;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  // unload vlc library
  // FreeLibrary(vlcLib);
  // IdHTTPServer1.Active := False;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := False;
  TrayIcon1.Icon.Assign(Application.Icon);
  // свою икону можно и из Инспектора назначить. просто без иконы не будет видно  значка в трее
  TrayIcon1.Visible := true;
  ShowWindow(handle, SW_HIDE);
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  sL: TStringList;
  tHM: THandle;
begin
  // load vlc library
  { vlcLib := LoadVLCLibrary(GetVLCLibPath());
    if vlcLib = 0 then
    begin
    Showmessage('Load vlc library failed');
    Exit;
    end;
    // sL will contains list of functions fail to load
    sL := TStringList.Create;
    if not LoadVLCFunctions(vlcLib, sL) then
    begin
    Showmessage('Some functions failed to load : ' + #13#10 + sL.Text);
    FreeLibrary(vlcLib);
    sL.Free;
    Exit;
    end;
    sL.Free;
    select := true; }
  // btnPlayClick(Self);
  // Form1.WindowState := wsMaximized;

  /// ///////////////////////////////////////////////////////////////////
  tHM := OpenMutex(MUTEX_ALL_ACCESS, False, HMName);
  if (tHM <> 0) then
  begin
    Showmessage('Приложение уже запушено');
    CloseHandle(tHM);
    Application.Terminate;
  end
  else { if tHM = 0 then }
  begin
    HM := CreateMutex(nil, False, HMName);
    ReleaseMutex(HM);
    CloseHandle(tHM);
    // Application.ShowMainForm := False;
    ShowWindow(handle, SW_HIDE);
    TrayIcon1.Icon.Assign(Application.Icon);
    // свою икону можно и из Инспектора назначить. просто без иконы не будет видно  значка в трее
    TrayIcon1.Visible := true;
    IdHTTPServer1.Active := true;
    /// /////////////////////////////////////////////////////////////////////////////////
    // 1. Открываем файл
    hPort := CreateFile('COM8', GENERIC_READ or GENERIC_WRITE,
      FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING,
      FILE_ATTRIBUTE_NORMAL, 0);
    // 2. Контроль ошибок
    if hPort = INVALID_HANDLE_VALUE then
    begin
      Memo1.Lines.Add('Обнаружена ошибка, порт открыть не удалось');
      // Обнаружена ошибка, порт открыть не удалось
      Exit;
    end
    else
      Memo1.Lines.Add('COM порт был открыт');
    // 3. Чтение текущих настроек порта
    if GetCommState(hPort, DCB) then;
    // 4. Настройки:
    // Скорость обмена
    Memo1.Lines.Add(IntToStr(DCB.BaudRate));
    DCB.BaudRate := 115200;
    // Число бит на символ
    Memo1.Lines.Add(IntToStr(DCB.ByteSize));
    DCB.ByteSize := 8;
    // Стоп-биты
    Memo1.Lines.Add(IntToStr(DCB.StopBits));
    DCB.StopBits := 1;
    // Четность
    Memo1.Lines.Add(IntToStr(DCB.Parity));
    DCB.Parity := 0;
    Memo1.Lines.Add(IntToStr(DCB.Flags));
    DCB.Flags := 20625;
    // 5. Передача настроек
    if not SetCommState(hPort, DCB) then
      Memo1.Lines.Add('ошибка настройки порта');
    // 6. Настройка буферов порта (очередей ввода и вывода)
    if not SetupComm(hPort, 16, 16) then
      Memo1.Lines.Add('ошибка настройки буферов');
    // 7. Сброс буфферов и очередей
    if PurgeComm(hPort, PURGE_TXABORT or PURGE_RXABORT or PURGE_TXCLEAR or
      PURGE_RXCLEAR) then;
    // ...............

    if not SetCommState(hPort, DCB) or not GetCommTimeouts(hPort, CT) then
      Exit;
    If Not SetCommState(hPort, DCB) Then

      CT.ReadTotalTimeoutConstant := 50;
    CT.ReadIntervalTimeout := 50;
    CT.ReadTotalTimeoutMultiplier := 10;
    // Какие только значения не ставил, не работает...(В версии программы когда работала, время
    // опроса контроллера ~70ms
    CT.WriteTotalTimeoutMultiplier := 10;
    CT.WriteTotalTimeoutConstant := 50;

    if not SetCommTimeouts(hPort, CT) or
      not SetCommMask(hPort, EV_RING + EV_RXCHAR + EV_RXFLAG + EV_TXEMPTY)
    then { Showmessage('Error' };
    PurgeComm(hPort, PURGE_RXCLEAR or PURGE_TXCLEAR or PURGE_TXABORT or
      PURGE_RXABORT);

  end;
  /// /////////////////////////////////////////////////////////////////////////////////
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  // CloseHandle(HM);
end;

procedure TForm1.FormResize(Sender: TObject);
var
  mainH, topH, { SecH, } mainW { ,  topW,  SecW } : integer;
begin
  mainH := MainPanel.Height;
  topH := TopPanel.Height;
  // SecH := SecPanel.Height;
  mainW := MainPanel.Width;
  // SecW := SecPanel.Width;
  { TopPanel.Height := }
  if (mainH + topH - (mainW * 9) div 16) < 100 then
    TopPanel.Height := 100
  else
    TopPanel.Height := (mainH + topH - (mainW * 9) div 16);
  SecPanel.Height := (topH + mainH) div 3;
  SecPanel.Width := (SecPanel.Height * 16) div 9;
  SecPanel.Top := 0;
  SecPanel.Left := MainPanel.Left + MainPanel.Width - SecPanel.Width;
  { Memo1.Width := }
  if (((MainPanel.Left + MainPanel.Width - SecPanel.Width) * 9) div 10) < 300
  then
    Memo1.Width := 300
  else
    Memo1.Width := (((MainPanel.Left + MainPanel.Width - SecPanel.Width) *
      9) div 10);
end;

procedure TForm1.FormShow(Sender: TObject);
begin

end;

// -----------------------------------------------------------------------------
// Read registry to get VLC installation path
// -----------------------------------------------------------------------------
function TForm1.GetVLCLibPath: String;
var
  handle: HKEY;
  RegType: integer;
  DataSize: Cardinal;
  Key: PWideChar;
begin
  Result := '';
  Key := 'Software\VideoLAN\VLC';
  if RegOpenKeyEx(HKEY_LOCAL_MACHINE, Key, 0, KEY_READ, handle) = ERROR_SUCCESS
  then
  begin
    if RegQueryValueEx(handle, 'InstallDir', nil, @RegType, nil, @DataSize) = ERROR_SUCCESS
    then
    begin
      SetLength(Result, DataSize);
      RegQueryValueEx(handle, 'InstallDir', nil, @RegType, PByte(@Result[1]),
        @DataSize);
      Result[DataSize] := '\';
    end
    else
      Showmessage('Error on reading registry');
    RegCloseKey(handle);
    Result := String(PChar(Result));
  end;
end;

procedure TForm1.IdHTTPServer1CommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  k: string;
  S: string;
  MyBuff: Array [0 .. 1] Of Char; // буфер для чтения данных
  GetStr, tempStr: String;
  // l: Cardinal;
  // ch: array of AnsiChar;
  // i: TObject;
  int: Byte;
  LWrited: Cardinal;
  Buf: AnsiString;
  nToWrite: Cardinal;
begin
  k := '_' +
    '012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234'
    + '_' + '012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234';
  Memo1.Lines.Add('Document: ' + ARequestInfo.Document);
  Memo1.Lines.Add('Text: ' + ARequestInfo.Params.GetText);
  Memo1.Lines.Add('k: ' + k);
  Memo1.Lines.Add(DateToStr(Date) + ' - ' + TimeToStr(Time) +
    ':  Найден новый объект:');
  GetStr := ARequestInfo.Params.GetText;
  // GetStr := 'http://localhost/get?stream={streamIdx}&dt={datetime}&pl={plate}&dr=Enter&img={image}';
  tempStr := GetStr;
  // 'http://localhost/get?stream={streamIdx}&dt={datetime}&pl={plate}&dr=Enter&img={image}';
  Delete(tempStr, 1, pos('pl=', tempStr) + 2);
  Delete(tempStr, pos('dr=', tempStr), tempStr.Length);
  Memo1.Lines.Add(GetStr);
  // Showmessage(tempStr);
  /// ////////////////////////////////////////////////////////
  /// Тут парсим данные номера и показываем его на экране крупным шрифтом
  // NumPlate.Caption := tempStr;
  // Memo1.Visible := False;
  // NumPlate.Visible := True;
  // NumPlate.Top := Memo1.Top;
  // NumPlate.Left := TopPanel.Left;

  // NumPlate.TabOrder := 2;
  // NumPlate.Show;
  // Delay(5000);
  // NumPlate.Visible := False;

  // Timer1.Interval := 7000; // устанавливаем паузу в мс
  // Timer1.Enabled := True; // включаем таймер
  // while Timer1.Enabled do // пока таймер включен, держим паузу
  // begin
  // Application.ProcessMessages;
  // end;

  // NumPlate.Visible := False;
  // Memo1.Visible := True;
  /// ////////////////////////////////////////////////////////
  AResponseInfo.ContentText := '<H1>Открыть шлагбаум</H1>';
  AResponseInfo.charset := 'windows-1251';
  AResponseInfo.ContentLanguage := 'ru';

  { try
    begin
    H := FindWindow(nil, 'Орион Про. Монитор оперативной задачи');
    if H = 0 then
    s := 'Не удалось передать команду управления:  Орион Про закрыт.'
    else
    begin
    SetForegroundWindow(H); // Окно на передний план - иначе не воспринимает
    PostMessage(H, WM_KEYDOWN, VK_F11, 0);
    PostMessage(H, WM_KEYUP, VK_F11, 0);
    s := 'Доступ предоставлен';
    end;
    Memo1.Lines.Add(s);
    Memo1.Lines.Add('');
    end;
    finally

    end; }
  try
    begin
      /// //////////////////////////////////////////////////////

      // var
      // Str: AnsiString; // array [0 .. 4] of char;
      // size: word;
      // begin
      // Str[0] := 'S';
      // Str[1] := 't';
      // Str[2] := 'a';
      // Str[3] := 'r';
      // Str[4] := 't';
      // MyBuff := 'S';
      // #83 + #116 + #97 + #114 + #116 + #59; // 'Start;';   ;

      // SerialBuffer := '';
      { for int := 0 to (Length(s) - 1) do
        begin
        SerialBuffer := SerialBuffer + PChar(s[int]);
        end; }
      S := '2'; // 'GetMillis'; // 'Start relay 1'; //
      // s := s + PChar(';');
      // SetLength(Str,5);
      // WriteFile(hPort, s, Length(s), NumberOfBytesWritten, nil);
      // ch := ['S', 't', 'a', 'r', 't'];
      // l := Length(MyBuff);
      // FillChar(MyBuff, SizeOf(MyBuff), #0);
      // WriteFile(hPort, MyBuff, l, NumberOfBytesWritten, nil);
      // ch := char($0);
      // WriteFile(hPort, ch, l, NumberOfBytesWritten, nil);
      // Переводим в ANSI
      Buf := AnsiString(S { + #13 } );
      // Длина входящих байт
      nToWrite := Length(S { + #13 } ); // SizeOf
      // пишем в порт
      S := Buf;
      WriteFile(hPort, Buf[1], nToWrite, LWrited, nil);
      Memo1.Lines.Add( { s + } ' Количество переданных байт: ' +
        IntToStr(LWrited) + ' :: ' + S);

      // Buf := AnsiString('');
      // PurgeComm(hPort, PURGE_TXABORT or PURGE_RXABORT or PURGE_TXCLEAR or
      // PURGE_RXCLEAR);

      if not readFile(hPort, Buf[1], 64, LWrited, nil) then
      begin
        { Raise an exception }
      end;
      S := '';
      for int := 1 to LWrited do
      begin
        S := S + Buf[int];
      end;
      // S := ANSI2KOI8R(S);
      // Memo1.Lines.Add(Buf);
      Memo1.Lines.Add( { s + } 'Количество принятых байт: ' + IntToStr(LWrited)
        + ' :: ' + S);

      // Memo1.Lines.Add('Добавлено символов: ' + IntToStr(PostComm(Str, size)));
      // end;

    end;
    /// //////////////////////////////////////////////////////
  finally

  end;
end;

procedure TForm1.IdHTTPServer1Connect(AContext: TIdContext);
begin
  // Memo1.Lines.Add('Server is started');
end;

procedure TForm1.IdHTTPServer1Disconnect(AContext: TIdContext);
begin
  // Memo1.Lines.Add('Server is stoped');
end;

procedure TForm1.IdHTTPServer1SessionEnd(Sender: TIdHTTPSession);
begin
  Memo1.Lines.Add('Server is stoped');
end;

procedure TForm1.IdHTTPServer1SessionStart(Sender: TIdHTTPSession);
begin
  Memo1.Lines.Add('Server is started');
end;

// -----------------------------------------------------------------------------
// Load libvlc library into memory
// -----------------------------------------------------------------------------
function TForm1.LoadVLCLibrary(APath: string): integer;
begin
  Result := LoadLibrary(PWideChar(APath + '\libvlccore.dll'));
  Result := LoadLibrary(PWideChar(APath + '\libvlc.dll'));
  TopPanel.Caption := APath;
end;

procedure TForm1.N1Click(Sender: TObject);
begin
  TrayIcon1.Visible := False;
  IdHTTPServer1.Active := False;
  Application.Terminate;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := False;
end;

procedure TForm1.TopPanelDblClick(Sender: TObject);
begin
  // btnStopClick(Self);
  // btnPlayClick(Self);
end;

procedure TForm1.TrayIcon1Click(Sender: TObject);
begin
  TrayIcon1.Visible := False;
  ShowWindow(handle, SW_SHOWNORMAL);
end;

// -----------------------------------------------------------------------------
// Get address of libvlc functions
// -----------------------------------------------------------------------------
function TForm1.LoadVLCFunctions(vlcHandle: integer;
  failedList: TStringList): Boolean;
begin
  GetAProcAddress(vlcHandle, @libvlc_new, 'libvlc_new', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_new_location,
    'libvlc_media_new_location', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_player_new_from_media,
    'libvlc_media_player_new_from_media', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_release, 'libvlc_media_release',
    failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_player_set_hwnd,
    'libvlc_media_player_set_hwnd', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_player_play,
    'libvlc_media_player_play', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_player_stop,
    'libvlc_media_player_stop', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_player_release,
    'libvlc_media_player_release', failedList);
  GetAProcAddress(vlcHandle, @libvlc_release, 'libvlc_release', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_player_is_playing,
    'libvlc_media_player_is_playing', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_new_path, 'libvlc_media_new_path',
    failedList);
  // if all functions loaded, result is an empty list, otherwise result is a list of functions failed
  Result := failedList.Count = 0;
end;

// -----------------------------------------------------------------------------
function TForm1.GetAProcAddress(handle: integer; var addr: Pointer;
  procName: string; failedList: TStringList): integer;
begin
  addr := GetProcAddress(handle, PWideChar(procName));
  if Assigned(addr) then
    Result := 0
  else
  begin
    if Assigned(failedList) then
      failedList.Add(procName);
    Result := -1;
  end;
end;

end.
