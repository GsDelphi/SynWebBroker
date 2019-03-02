{
  This file is part of Gilbertsoft SynWebBroker (GSSWB).

  Copyright (C) 2018-2019 Simon Gilli
    Gilbertsoft | https://delphi.gilbertsoft.org

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
}
unit SynHttpApp;

{$IFDEF CONDITIONALEXPRESSIONS}
  // RTLVersion >= Delphi 2009 or RTLVersion < Delphi 10.1 Berlin
  {$IF (RTLVersion >= 20.0) or (RTLVersion < 31.0)}
    {$DEFINE WB_ANSI}
  {$IFEND}
  // RTLVersion >= Delphi XE
  {$IF (RTLVersion >= 22.0)}
    {$DEFINE RTL220_UP}
  {$IFEND}
  // RTLVersion >= Delphi 10.1 Berlin
  {$IF (RTLVersion >= 31.0)}
    {$DEFINE RTL310_UP}
  {$IFEND}
  // RTLVersion >= Delphi 6
  {$IF (RTLVersion >= 14.0)}
    {$DEFINE RTL140_UP_OR_CLR}
  {$IFEND}
{$ENDIF}
{$IFDEF CLR}
  {$DEFINE RTL140_UP_OR_CLR}
{$ENDIF}

interface

uses
  Classes,
  HTTPApp,
  SynCommons,
  SynCrtSock;

const
  // Request header indices
  Idx_Req_Method          = 0;  // string
  Idx_Req_ProtocolVersion = 1;  // string
  Idx_Req_URL             = 2;  // string
  Idx_Req_Query           = 3;  // string
  Idx_Req_PathInfo        = 4;  // string
  Idx_Req_PathTranslated  = 5;  // string
  Idx_Req_CacheControl    = 6;  // string
  Idx_Req_Date            = 7;  // date
  Idx_Req_Accept          = 8;  // string
  Idx_Req_From            = 9;  // string
  Idx_Req_Host            = 10; // string
  Idx_Req_IfModifiedSince = 11; // date
  Idx_Req_Referer         = 12; // string
  Idx_Req_UserAgent       = 13; // string
  Idx_Req_ContentEncoding = 14; // string
  Idx_Req_ContentType     = 15; // string
  Idx_Req_ContentLength   = 16; // integer
  Idx_Req_ContentVersion  = 17; // string
  Idx_Req_DerivedFrom     = 18; // string
  Idx_Req_Expires         = 19; // date
  Idx_Req_Title           = 20; // string
  Idx_Req_RemoteAddr      = 21; // string
  Idx_Req_RemoteHost      = 22; // string
  Idx_Req_ScriptName      = 23; // string
  Idx_Req_ServerPort      = 24; // integer
  Idx_Req_Content         = 25; // string
  Idx_Req_Connection      = 26; // string
  Idx_Req_Cookie          = 27; // string
  Idx_Req_Authorization   = 28; // string

  // Response header string indices
  Idx_Res_Version         = 0;
  Idx_Res_ReasonString    = 1;
  Idx_Res_Server          = 2;
  Idx_Res_WWWAuthenticate = 3;
  Idx_Res_Realm           = 4;
  Idx_Res_Allow           = 5;
  Idx_Res_Location        = 6;
  Idx_Res_ContentEncoding = 7;
  Idx_Res_ContentType     = 8;
  Idx_Res_ContentVersion  = 9;
  Idx_Res_DerivedFrom     = 10;
  Idx_Res_Title           = 11;

  // Response header integer indices
  Idx_Res_ContentLength = 0;

  // Response header date indices
  Idx_Res_Date         = 0;
  Idx_Res_Expires      = 1;
  Idx_Res_LastModified = 2;

  // Status codes copied from unit mORMot to avoid inclusion of it
  HTTP_NONE                    = 0;
  HTTP_CONTINUE                = 100;
  HTTP_SWITCHINGPROTOCOLS      = 101;
  HTTP_SUCCESS                 = 200;
  HTTP_CREATED                 = 201;
  HTTP_ACCEPTED                = 202;
  HTTP_NONAUTHORIZEDINFO       = 203;
  HTTP_NOCONTENT               = 204;
  HTTP_RESETCONTENT            = 205;
  HTTP_PARTIALCONTENT          = 206;
  HTTP_MULTIPLECHOICES         = 300;
  HTTP_MOVEDPERMANENTLY        = 301;
  HTTP_FOUND                   = 302;
  HTTP_SEEOTHER                = 303;
  HTTP_NOTMODIFIED             = 304;
  HTTP_USEPROXY                = 305;
  HTTP_TEMPORARYREDIRECT       = 307;
  HTTP_BADREQUEST              = 400;
  HTTP_UNAUTHORIZED            = 401;
  HTTP_FORBIDDEN               = 403;
  HTTP_NOTFOUND                = 404;
  HTTP_NOTALLOWED              = 405;
  HTTP_NOTACCEPTABLE           = 406;
  HTTP_PROXYAUTHREQUIRED       = 407;
  HTTP_TIMEOUT                 = 408;
  HTTP_CONFLICT                = 409;
  HTTP_PAYLOADTOOLARGE         = 413;
  HTTP_SERVERERROR             = 500;
  HTTP_NOTIMPLEMENTED          = 501;
  HTTP_BADGATEWAY              = 502;
  HTTP_UNAVAILABLE             = 503;
  HTTP_GATEWAYTIMEOUT          = 504;
  HTTP_HTTPVERSIONNONSUPPORTED = 505;

type
  {$IFDEF WB_ANSI}
  RawWBString = Ansistring;
  {$ELSE}
  RawWBString = string;
  {$ENDIF}

  /// This class will do the conversion from and to the webbroker string types,
  // which are quite different in various RTL versions and some decoding.
  TSynWebContext = class(TObject)
  private
    FContext: THttpServerRequest;
    function GetAuthenticationStatus: THttpServerRequestAuthentication;
    function GetConnectionID: Int64;
    function GetConnectionThread: TSynThread;
    function GetServer: THttpServerGeneric;
    function GetUseSSL: Boolean;
  protected
    FURL:               RawWBString;
    FMethod:            RawWBString;
    FInHeaders:         RawWBString;
    FInContent:         RawWBString;
    FInContentType:     RawWBString;
    FOutContent:        RawWBString;
    FOutContentType:    RawWBString;
    FOutCustomHeaders:  RawWBString;
    FAuthenticatedUser: RawWBString;
    FHost:              RawWBString;
    FPort:              Integer;
    FRemoteIP:          RawWBString;
    FPathInfo:          RawWBString;
    FQueryString:       RawWBString;
    FAnchor:            RawWBString;
  protected
    function Copy(const S: RawWBString; Index: Integer; Count: Integer): RawWBString;
    function Pos(const SubStr, Str: RawWBString): Integer;
    procedure InitFromContext; virtual;
    procedure UpdateContext; virtual;
  public
    constructor Create(AContext: THttpServerRequest); virtual;
    destructor Destroy; override;

    function GetHeader(const AFieldName: RawUTF8): RawWBString;

    /// the associated server request
    property Context: THttpServerRequest read FContext;

    // This properties are equal to the THttpServerRequest properties and are
    // converted from / to the webbroker string type or direct accessed by
    // getter and setter methods
    property URL: RawWBString read FURL;
    property Method: RawWBString read FMethod;
    property InHeaders: RawWBString read FInHeaders;
    property InContent: RawWBString read FInContent;
    property InContentType: RawWBString read FInContentType;
    property OutContent: RawWBString read FOutContent write FOutContent;
    property OutContentType: RawWBString read FOutContentType write FOutContentType;
    property OutCustomHeaders: RawWBString read FOutCustomHeaders write FOutCustomHeaders;
    property Server: THttpServerGeneric read GetServer;
    property ConnectionID: Int64 read GetConnectionID;
    property ConnectionThread: TSynThread read GetConnectionThread;
    property UseSSL: Boolean read GetUseSSL;
    property AuthenticationStatus: THttpServerRequestAuthentication read GetAuthenticationStatus;
    property AuthenticatedUser: RawWBString read FAuthenticatedUser;
  end;

  TSynWebRequest = class(TWebRequest)
  private
  protected
    FContext: TSynWebContext;
    //FEnv: TSynWebEnv;
    function GetStringVariable(Index: Integer): RawWBString; override;
    function GetDateVariable(Index: Integer): TDateTime; override;
    function GetIntegerVariable(Index: Integer): Integer; override;

    //function GetInternalPathInfo: RawWBString; override;
    //function GetInternalScriptName: RawWBString; override;

    {$IFDEF RTL220_UP}
    function GetRemoteIP: string; override;
    function GetRawPathInfo: RawWBString; override;
    {$ENDIF}
    {$IFDEF RTL310_UP}
    function GetRawContent: TBytes; override;
    {$ENDIF}
  public
    //constructor Create(AContext: TSynWebContext);
    //constructor Create(AEnv: TSynWebEnv);
    constructor Create(AContext: THttpServerRequest);
    destructor Destroy; override;

    property Context: TSynWebContext read FContext;
    //property Env: TSynWebEnv read FEnv;

    // Read count bytes from client
    function ReadClient(var Buffer{$IFDEF CLR}: TBytes{$ENDIF}; Count: Integer): Integer; override;
    // Read count characters as a WBString from client
    function ReadString(Count: Integer): RawWBString; override;
    // Translate a relative URI to a local absolute path
    function TranslateURI(const URI: string): string; override;
    // Write count bytes back to client
    function WriteClient(var Buffer{$IFDEF CLR}: TBytes{$ENDIF}; Count: Integer): Integer; override;
    // Write WBString contents back to client
    function WriteString(const AString: RawWBString): Boolean; override;
    // Write HTTP header WBString
    {$IFDEF RTL140_UP_OR_CLR}
    function WriteHeaders(StatusCode: Integer; const ReasonString, Headers: RawWBString): Boolean; override;
    {$ENDIF}
    // Read an arbitrary HTTP/Server Field not lists here
    function GetFieldByName(const AName: RawWBString): RawWBString; override;
  end;

  TSynWebResponse = class(TWebResponse)
  private
    FStatusCode:       Integer;
    FStringVariables:  array[0..MAX_STRINGS - 1] of RawWBString;
    FIntegerVariables: array[0..MAX_INTEGERS - 1] of Integer;
    FDateVariables:    array[0..MAX_DATETIMES - 1] of TDateTime;
    FContent:          RawWBString;
    FSent:             Boolean;
    function GetContext: TSynWebContext;
  protected
    function GetStringVariable(Index: Integer): RawWBString; override;
    procedure SetStringVariable(Index: Integer; const Value: RawWBString);
      override;
    function GetDateVariable(Index: Integer): TDateTime; override;
    procedure SetDateVariable(Index: Integer; const Value: TDateTime); override;
    function GetIntegerVariable(Index: Integer): Integer; override;
    procedure SetIntegerVariable(Index: Integer; Value: Integer); override;
    function GetContent: RawWBString; override;
    procedure SetContent(const Value: RawWBString); override;
    //procedure SetContentStream(Value: TStream); override;
    function GetStatusCode: Integer; override;
    procedure SetStatusCode(Value: Integer); override;
    function GetLogMessage: string; override;
    procedure SetLogMessage(const Value: string); override;
    procedure InitResponse; virtual;
  public
    constructor Create(HTTPRequest: TSynWebRequest);
    destructor Destroy; override;

    property Context: TSynWebContext read GetContext;
    //property Env: TSynWebEnv read GetEnv;

    procedure SendResponse; override;
    procedure SendRedirect(const URI: RawWBString); override;
    procedure SendStream(AStream: TStream); override;
    function Sent: Boolean; override;
  end;

function UTF8ToWBString(const AVal: RawUTF8): RawWBString;
function WBStringToUTF8(const AVal: RawWBString): RawUTF8;

function ServerError(AStatusCode: Cardinal; const AErrorMessage: string; AContext: TSynWebContext): Cardinal; overload;
function ServerError(AStatusCode: Cardinal; const AErrorMessage: string; AContext: THttpServerRequest): Cardinal;
  overload;

implementation

uses
  BrkrConst,
  SysUtils;

resourcestring
  // String is external to be protected from code formatting and not messed up
  SHttpError = '' +
  {$I SynHttpAppError.inc};

 //  '<html><head></head><body style="font-family:verdana">' +
 //    '<h1>%s Server Error %d</h1><hr><p>HTTP %d %s</p><p>%s</p>' + '<p><small>%s</small></p></body></html>';

function UTF8ToWBString(const AVal: RawUTF8): RawWBString;
begin
  {$IFDEF WB_ANSI}
  Result := CurrentAnsiConvert.UTF8ToAnsi(AVal);
  {$ELSE}
  Result := UTF8ToString(AVal);
  {$ENDIF}
end;

function WBStringToUTF8(const AVal: RawWBString): RawUTF8;
begin
  {$IFDEF WB_ANSI}
  Result := CurrentAnsiConvert.AnsiToUTF8(AVal);
  {$ELSE}
  Result := StringToUTF8(AVal);
  {$ENDIF}
end;

function HtmlEncodeString(const S: string): string;
var
  I: Integer;
begin // not very fast, but working
  Result := '';
  for I := 1 to Length(S) do
    case S[I] of
      '<': Result := Result + '&lt;';
      '>': Result := Result + '&gt;';
      '&': Result := Result + '&amp;';
      '"': Result := Result + '&quot;';
    else
      Result := Result + S[I];
    end;
end;

function ServerError(AStatusCode: Cardinal; AErrorMessage: string;
  var CustomHeaders, ContentType, Content: SockString): Cardinal; overload;
var
  Reason: SockString;
begin
  if (AStatusCode = HTTP_NONE) then
  begin
    Result        := HTTP_NOTIMPLEMENTED;
    Reason        := 'Implementation Error';
    AErrorMessage := 'Unexpected status code';
  end
  else
  begin
    Result := AStatusCode;
    Reason := StatusCodeToReason(AStatusCode);
  end;

  CustomHeaders := '';
  ContentType   := 'text/html; charset=utf-8';
  Content       := StringToUTF8(Format(SHttpError, [Reason, Result div 100, AStatusCode,
    Reason, HtmlEncodeString(AErrorMessage)]));
end;

function ServerError(AStatusCode: Cardinal; const AErrorMessage: string; AContext: TSynWebContext): Cardinal;
var
  CustomHeaders, ContentType, Content: SockString;
begin
  Result := ServerError(AStatusCode, AErrorMessage, CustomHeaders, ContentType, Content);

  AContext.OutCustomHeaders := CustomHeaders;
  AContext.OutContentType   := ContentType;
  AContext.OutContent       := Content;
end;

function ServerError(AStatusCode: Cardinal; const AErrorMessage: string; AContext: THttpServerRequest): Cardinal;
var
  CustomHeaders, ContentType, Content: SockString;
begin
  Result := ServerError(AStatusCode, AErrorMessage, CustomHeaders, ContentType, Content);

  AContext.OutCustomHeaders := CustomHeaders;
  AContext.OutContentType   := ContentType;
  AContext.OutContent       := Content;
end;

{ TSynWebContext }

function TSynWebContext.Copy(const S: RawWBString; Index, Count: Integer): RawWBString;
begin
  {$IFDEF WB_ANSI}
  Result := System.Copy(S, Index, Count);
  {$ELSE}
  Result := System.Copy(S, Index, Count);
  {$ENDIF}
end;

constructor TSynWebContext.Create(AContext: THttpServerRequest);
begin
  FContext := AContext;

  inherited Create;

  InitFromContext;
end;

destructor TSynWebContext.Destroy;
begin
  inherited;

  FContext := nil;
end;

function TSynWebContext.GetAuthenticationStatus: THttpServerRequestAuthentication;
begin
  Result := FContext.AuthenticationStatus;
end;

function TSynWebContext.GetConnectionID: Int64;
begin
  Result := FContext.ConnectionID;
end;

function TSynWebContext.GetConnectionThread: TSynThread;
begin
  Result := FContext.ConnectionThread;
end;

function TSynWebContext.GetHeader(const AFieldName: RawUTF8): RawWBString;
var
  UpperName: RawUTF8;
  P:         PUTF8Char;
  Value:     RawUTF8;
begin
  if (Length(AFieldName) > 0) then
  begin
    SetLength(UpperName, Length(AFieldName));
    SynCommons.UpperCopy(PAnsiChar(UpperName), AFieldName);

    if (UpperName[Length(UpperName)] <> ':') then
      UpperName := UpperName + ':';

    P := StrPosI(PUTF8Char(UpperName), PUTF8Char(FContext.InHeaders));

    if IdemPCharAndGetNextItem(P, PUTF8Char(UpperName), Value) then
      Result := UTF8ToWBString(SynCommons.Trim(Value))
    else
      Result := '';
  end
  else
    Result := '';
end;

function TSynWebContext.GetServer: THttpServerGeneric;
begin
  Result := FContext.Server;
end;

function TSynWebContext.GetUseSSL: Boolean;
begin
  Result := FContext.UseSSL;
end;

procedure TSynWebContext.InitFromContext;
const
  DefaultPort: array [Boolean] of Integer = (80, 443);
var
  PPos, QPos, APos: Integer;
begin
  FURL               := FContext.URL;
  FMethod            := FContext.Method;
  FInHeaders         := FContext.InHeaders;
  FInContent         := FContext.InContent;
  FInContentType     := FContext.InContentType;
  FOutContent        := FContext.OutContent;
  FOutContentType    := FContext.OutContentType;
  FOutCustomHeaders  := FContext.OutCustomHeaders;
  FAuthenticatedUser := FContext.AuthenticatedUser;

  //FQueryFields   := TStringList.Create;
  //FContentFields := TStringList.Create;
  //FContext       := AContext;
  FHost := GetHeader('HOST:');

  PPos := Pos(':', FHost);
  if (PPos > 0) then
    FPort := StrToIntDef(String(Copy(FHost, PPos + 1, MaxInt)), DefaultPort[UseSSL])
  else
  begin
    { TODO : get port from one of the two server impls}
    //FPort := FContext.ConnectionThread.
    FPort := DefaultPort[UseSSL];
  end;

  FRemoteIP := GetHeader('REMOTEIP:');

  // Get PathInfo, QueryString and Anchor
  APos := Pos('#', FURL);
  QPos := Pos('?', FURL);

  if (QPos > 0) then
  begin
    FPathInfo := Copy(FURL, 1, QPos - 1);

    if (APos > QPos) then
    begin
      FQueryString := Copy(FURL, QPos + 1, APos - QPos - 1);
      FAnchor      := Copy(FURL, APos + 1, Length(FURL) - APos);
    end
    else
    begin
      FQueryString := Copy(FURL, QPos + 1, Length(FURL) - QPos);
      FAnchor      := '';
    end;
  end
  else
  begin
    FQueryString := '';

    if (APos > 0) then
    begin
      FPathInfo := Copy(FURL, 1, APos - 1);
      FAnchor   := Copy(FURL, APos + 1, Length(FURL) - APos);
    end
    else
    begin
      FPathInfo := FURL;
      FAnchor   := '';
    end;
  end;
end;

function TSynWebContext.Pos(const SubStr, Str: RawWBString): Integer;
begin
  {$IFDEF WB_ANSI}
  Result := SynCommons.Pos(WBStringToUTF8(SubStr), WBStringToUTF8(Str));
  {$ELSE}
  Result := System.Pos(SubStr, Str);
  {$ENDIF}
end;

procedure TSynWebContext.UpdateContext;
begin
  FContext.OutContent       := FOutContent;
  FContext.OutContentType   := FOutContentType;
  FContext.OutCustomHeaders := FOutCustomHeaders;
end;

{ TSynWebRequest }

constructor TSynWebRequest.Create(AContext: THttpServerRequest);
begin
  FContext := TSynWebContext.Create(AContext);

  inherited Create;
end;

destructor TSynWebRequest.Destroy;
begin
  inherited;

  FContext.Free;
end;

function TSynWebRequest.GetDateVariable(Index: Integer): TDateTime;
var
  LValue: string;
begin
  LValue := String(GetStringVariable(Index));
  if Length(LValue) > 0 then
    Result := ParseDate(LValue)
  else
    Result := -1;
end;

function TSynWebRequest.GetFieldByName(const AName: RawWBString): RawWBString;
begin
  Result := FContext.GetHeader(WBStringToUTF8(AName));
end;

function TSynWebRequest.GetIntegerVariable(Index: Integer): Integer;
begin
  case Index of
    Idx_Req_ContentLength: Result := Length(FContext.InContent);
    Idx_Req_ServerPort: Result    := FContext.FPort;
  else
    Result := StrToIntDef(String(GetStringVariable(Index)), -1);
  end;
end;

{$IFDEF RTL310_UP}
function TSynWebRequest.GetRawContent: TBytes;
begin
  RawByteStringToBytes(Context.InContent, Result);
end;

{$ENDIF}

{$IFDEF RTL220_UP}
function TSynWebRequest.GetRawPathInfo: RawWBString;
begin
  Result := FContext.URL;
end;

{$ENDIF}

{$IFDEF RTL220_UP}
function TSynWebRequest.GetRemoteIP: string;
begin
  {$IFDEF WB_ANSI}
  Result := String(FContext.FRemoteIP);
  {$ELSE}
  Result := FContext.FRemoteIP;
  {$ENDIF}
end;

{$ENDIF}

function TSynWebRequest.GetStringVariable(Index: Integer): RawWBString;
begin
  case Index of
    Idx_Req_Method: Result          := FContext.FMethod;
    Idx_Req_ProtocolVersion: Result := '';
    Idx_Req_URL: Result             := FContext.FURL;
    Idx_Req_Query: Result           := RawWBString(URLDecode(RawUTF8(FContext.FQueryString)));
    Idx_Req_PathInfo: Result        := FContext.FPathInfo;
    Idx_Req_PathTranslated: Result  := FContext.FPathInfo;
    Idx_Req_CacheControl: Result    := FContext.GetHeader('CACHE-CONTROL:');
    Idx_Req_Date: Result            := FContext.GetHeader('DATE:');
    Idx_Req_Accept: Result          := FContext.GetHeader('ACCEPT:');
    Idx_Req_From: Result            := FContext.GetHeader('FROM:');
    Idx_Req_Host: Result            := FContext.FHost;
    Idx_Req_IfModifiedSince: Result := FContext.GetHeader('IF-MODIFIED-SINCE:');
    Idx_Req_Referer: Result         := FContext.GetHeader('REFERER:');
    Idx_Req_UserAgent: Result       := FContext.GetHeader('USER-AGENT:');
    Idx_Req_ContentEncoding: Result := FContext.GetHeader('CONTENT-ENCODING:');
    Idx_Req_ContentType: Result     := FContext.GetHeader('CONTENT-TYPE:');
    Idx_Req_ContentLength: Result   := RawWBString(IntToStr(Length(FContext.InContent)));
    Idx_Req_ContentVersion: Result  := FContext.GetHeader('CONTENT_VERSION:');
    Idx_Req_DerivedFrom: Result     := FContext.GetHeader('DERIVED-FROM:');
    Idx_Req_Expires: Result         := FContext.GetHeader('EXPIRES:');
    Idx_Req_Title: Result           := FContext.GetHeader('TITLE:');
    Idx_Req_RemoteAddr: Result      := FContext.FRemoteIP;
    Idx_Req_RemoteHost: Result      := FContext.GetHeader('REMOTE_HOST:');
    Idx_Req_ScriptName: Result      := '';
    Idx_Req_ServerPort: Result      := RawWBString(IntToStr(FContext.FPort));
    Idx_Req_Content: Result         := FContext.InContent;
    Idx_Req_Connection: Result      := FContext.GetHeader('CONNECTION:');
    Idx_Req_Cookie: Result          := FContext.GetHeader('COOKIE:');
    Idx_Req_Authorization: Result   := FContext.GetHeader('AUTHORIZATION:');
  else
    Result := '';
  end;
end;

function TSynWebRequest.ReadClient(var Buffer; Count: Integer): Integer;
begin
  Result := 0;
end;

function TSynWebRequest.ReadString(Count: Integer): RawWBString;
var
  Len: Integer;
begin
  SetLength(Result, Count);
  Len := ReadClient(Pointer(Result)^, Count);
  if Len > 0 then
    SetLength(Result, Len)
  else
    Result := '';
end;

function TSynWebRequest.TranslateURI(const URI: string): string;
begin
  Result := '';
end;

function TSynWebRequest.WriteClient(var Buffer; Count: Integer): Integer;
var
  L: Integer;
begin
  Result := Count;

  if (Count > 0) then
  begin
    L := Length(Context.FOutContent);
    SetLength(Context.FOutContent, L + Count);
    MoveFast(Buffer, Context.FOutContent[L + 1], Count);
  end;
end;

{$IFDEF RTL140_UP_OR_CLR}
function TSynWebRequest.WriteHeaders(StatusCode: Integer; const ReasonString, Headers: RawWBString): Boolean;
begin
  Context.FOutCustomHeaders := Headers;
  Result                    := True;
end;

{$ENDIF}

function TSynWebRequest.WriteString(const AString: RawWBString): Boolean;
begin
  Result := WriteClient(Pointer(AString)^, Length(AString)) = Length(AString);
end;

{ TSynWebResponse }

constructor TSynWebResponse.Create(HTTPRequest: TSynWebRequest);
begin
  inherited Create(HTTPRequest);

  InitResponse;
end;

destructor TSynWebResponse.Destroy;
begin
  if not Sent then
    SendResponse;

  inherited;
end;

function TSynWebResponse.GetContent: RawWBString;
begin
  Result := FContent;
end;

function TSynWebResponse.GetContext: TSynWebContext;
begin
  Result := TSynWebRequest(FHTTPRequest).Context;
end;

function TSynWebResponse.GetDateVariable(Index: Integer): TDateTime;
begin
  if (Index >= Low(FDateVariables)) and (Index <= High(FDateVariables)) then
    Result := FDateVariables[Index]
  else
    Result := 0.0;
end;

function TSynWebResponse.GetIntegerVariable(Index: Integer): Integer;
begin
  if (Index >= Low(FIntegerVariables)) and (Index <= High(FIntegerVariables)) then
    Result := FIntegerVariables[Index]
  else
    Result := -1;
end;

function TSynWebResponse.GetLogMessage: string;
begin
  // Logging currently not supported
  Result := '';
end;

function TSynWebResponse.GetStatusCode: Integer;
begin
  Result := FStatusCode;
end;

function TSynWebResponse.GetStringVariable(Index: Integer): RawWBString;
begin
  if (Index = Idx_Res_ReasonString) then
    Result := ''
  else
  if (Index >= Low(FStringVariables)) and (Index <= High(FStringVariables)) then
    Result := FStringVariables[Index];
end;

procedure TSynWebResponse.InitResponse;
begin
  if FHTTPRequest.ProtocolVersion = '' then
    Version := '1.0';
  StatusCode := 200;
  LastModified := -1;
  Expires      := -1;
  Date         := -1;
  ContentType  := 'text/html';  { do not localize }
end;

procedure TSynWebResponse.SendRedirect(const URI: RawWBString);
begin
  Location    := URI;
  StatusCode  := 302;
  ContentType := 'text/html';  { do not localize }
  Content     := Format(sDocumentMoved, [URI]);
  SendResponse;
end;

procedure TSynWebResponse.SendResponse;
var
  Headers: string;
  I:       Integer;

  procedure AddHeaderItem(const Item: Ansistring; FormatStr: string); overload;
  begin
    if Item <> '' then
      Headers := Headers + Format(FormatStr, [Item]);
  end;

  procedure AddHeaderItem(const Item: UnicodeString; FormatStr: string); overload;
  begin
    if Item <> '' then
      Headers := Headers + Format(FormatStr, [Item]);
  end;

begin
  /// Assign values to context. The headers 'Content-Length', 'Connection',
  // 'Accept-Encoding' and 'Content-Type' are written by THttpServer and must
  // be ignored here!
  Context.FOutContentType := ContentType;

  /// Assign headers
  AddHeaderItem(Location, 'Location: %s'#13#10);
  {do not localize }
  AddHeaderItem(Allow, 'Allow: %s'#13#10);
  {do not localize }
  for I := 0 to Cookies.Count - 1 do
    AddHeaderItem(Cookies[I].HeaderValue, 'Set-Cookie: %s'#13#10);
  {do not localize }
  AddHeaderItem(DerivedFrom, 'Derived-From: %s'#13#10);
  {do not localize }
  if Expires > 0 then
    AddHeaderItem(Format(FormatDateTime(sDateFormat + ' "GMT"',
      {do not localize}
      Expires), [DayOfWeekStr(Expires), MonthStr(Expires)]), 'Expires: %s'#13#10);
  {do not localize}
  if LastModified > 0 then
    AddHeaderItem(Format(FormatDateTime(sDateFormat + ' "GMT"', LastModified),
      [DayOfWeekStr(LastModified),                   {do not localize}
      MonthStr(LastModified)]), 'Last-Modified: %s'#13#10);
  {do not localize}
  AddHeaderItem(Title, 'Title: %s'#13#10);
  {do not localize }
  AddHeaderItem(FormatAuthenticate, 'WWW-Authenticate: %s'#13#10);
  {do not localize }
  AddCustomHeaders(Headers);
  AddHeaderItem(ContentVersion, 'Content-Version: %s'#13#10);
  {do not localize }
  AddHeaderItem(ContentEncoding, 'Content-Encoding: %s'#13#10);
  {do not localize }
  //AddHeaderItem(ContentType, 'Content-Type: %s'#13#10);                       {do not localize }
  //if (RawContent <> '') or (ContentStream <> nil) then
  //  AddHeaderItem(IntToStr(ContentLength), 'Content-Length: %s'#13#10);       {do not localize }
  Headers := Headers + #13#10;

  // Assign header fields, StatusString will always be ignored and created
  // by THttpServer from StatusCode
  HTTPRequest.WriteHeaders(StatusCode, '', RawWBString(Headers));

  // Assign the content
  if ContentStream = nil then
    HTTPRequest.WriteString(RawContent)
  else
  if ContentStream <> nil then
  begin
    SendStream(ContentStream);
    ContentStream := nil; // Drop the stream
  end;

  // Finally write response to the THttpServerRequest
  Context.UpdateContext;

  FSent := True;
end;

procedure TSynWebResponse.SendStream(AStream: TStream);
var
  Buffer: SockString;
begin
  if (AStream.Size > 0) then
  begin
    SetLength(Buffer, AStream.Size);
    SetLength(Buffer, AStream.Read(Buffer[1], AStream.Size));
    HTTPRequest.WriteString(Buffer);
  end;
end;

function TSynWebResponse.Sent: Boolean;
begin
  Result := FSent;
end;

procedure TSynWebResponse.SetContent(const Value: RawWBString);
begin
  FContent := Value;
  if ContentStream = nil then
    ContentLength := Length(FContent);
end;

procedure TSynWebResponse.SetDateVariable(Index: Integer; const Value: TDateTime);
begin
  if (Index >= Low(FDateVariables)) and (Index <= High(FDateVariables)) then
    if Value <> FDateVariables[Index] then
      FDateVariables[Index] := Value;
end;

procedure TSynWebResponse.SetIntegerVariable(Index, Value: Integer);
begin
  if (Index >= Low(FIntegerVariables)) and (Index <= High(FIntegerVariables)) then
    if Value <> FIntegerVariables[Index] then
      FIntegerVariables[Index] := Value;
end;

procedure TSynWebResponse.SetLogMessage(const Value: string);
begin
  // Logging currently not supported
end;

procedure TSynWebResponse.SetStatusCode(Value: Integer);
begin
  FStatusCode := Value;
end;

procedure TSynWebResponse.SetStringVariable(Index: Integer; const Value: RawWBString);
begin
  if (Index <> Idx_Res_ReasonString) and (Index >= Low(FStringVariables)) and (Index <= High(FStringVariables)) then
    FStringVariables[Index] := Value;
end;

end.

