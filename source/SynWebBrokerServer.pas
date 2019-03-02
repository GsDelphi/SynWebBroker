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
unit SynWebBrokerServer;

interface

uses
  SynCommons,
  SynCrtSock;

type
  EHttpApiWebBrokerServer = class(ESynException);

  TSynHttpApiWebBrokerServer = class(THttpApiServer)
  protected
    procedure AuthorizeUri(AURI: RawUTF8); virtual;
  public
    //procedure AfterConstruction; override;
    procedure AuthorizeWebModules(const APort: SockString; Https: Boolean = False;
      const ADomainName: SockString = '*');
    function Request(Ctxt: THttpServerRequest): Cardinal; override;
  end;

  TSynHttpWebBrokerServer = class(THttpServer)
  public
    function Request(Ctxt: THttpServerRequest): Cardinal; override;
  end;

implementation

uses
  (*
  Classes,
  SysUtils,
  WebReq,
  *)
  SynWebReq,
  Windows;

threadvar
  LPort:       SockString;
  LHttps:      Boolean;
  LDomainName: SockString;

{ TSynHttpApiWebBrokerServer }

procedure TSynHttpApiWebBrokerServer.AuthorizeUri(AURI: RawUTF8);
const
  HTTPS_TEXT: array[Boolean] of string[1] = ('', 's');
var
  Error:    Integer;
  ErrorMsg: RawUTF8;
begin
  Error := AddUrl(AURI, LPort, LHttps, LDomainName, True);

  if (Error = NO_ERROR) then
    Exit;

  FormatUTF8('http.sys URI registration error #% for http%://%:%/%',
    [Error, HTTPS_TEXT[LHttps], LDomainName, LPort, AURI], ErrorMsg);

  if (Error = ERROR_ACCESS_DENIED) then
    ErrorMsg := ErrorMsg + ' (administrator rights needed, at least once to register the URI)';

  raise EHttpApiWebBrokerServer.CreateUTF8('%: %', [Self, ErrorMsg]);
end;

procedure TSynHttpApiWebBrokerServer.AuthorizeWebModules(const APort: SockString; Https: Boolean;
  const ADomainName: SockString);
begin
  LPort       := APort;
  LHttps      := Https;
  LDomainName := ADomainName;

  TSynWebRequestHandler(SynWebRequestHandler).AuthorizeURIs(AuthorizeUri);
end;

function TSynHttpApiWebBrokerServer.Request(Ctxt: THttpServerRequest): Cardinal;
begin
  Result := TSynWebRequestHandler(SynWebRequestHandler).Request(Ctxt);
end;

{ TSynHttpWebBrokerServer }

function TSynHttpWebBrokerServer.Request(Ctxt: THttpServerRequest): Cardinal;
begin
  Result := TSynWebRequestHandler(SynWebRequestHandler).Request(Ctxt);
end;

end.

