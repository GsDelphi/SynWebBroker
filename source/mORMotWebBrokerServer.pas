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
unit mORMotWebBrokerServer;

interface

uses
  mORMotHttpServer,
  SynCommons,
  SynCrtSock;

type
  TSQLWebBrokerServer = class(TSQLHttpServer)
  private
    FActive: Boolean;
  protected
    function Request(Ctxt: THttpServerRequest): Cardinal; override;
    procedure AuthorizeUri(AURI: RawUTF8); virtual;
    procedure AuthorizeWebModules; virtual;
  public
    procedure AfterConstruction; override;
    property Active: Boolean read FActive write FActive;
  end;

implementation

uses
  SynWebBrokerServer,
  mORMot,
  SynHttpApp,
  SynWebReq,
  SysUtils;

{ TSQLWebBrokerServer }

procedure TSQLWebBrokerServer.AfterConstruction;
begin
  inherited;

  AuthorizeWebModules;
  FActive := True;
end;

procedure TSQLWebBrokerServer.AuthorizeUri(AURI: RawUTF8);
var
  I:      Integer;
  ErrMsg: RawUTF8;
begin
  for I := 0 to High(fDBServers) do
    with fDBServers[I].Server.Model do
    begin
      if (URIMatch(AURI) <> rmNoMatch) then
        FormatUTF8('Duplicated Root URI: % and %', [Root, AURI], ErrMsg);
    end;

  if (ErrMsg <> '') then
    raise EHttpServerException.CreateUTF8('%.EnumWebDispatchers/VerifyURI( % ): %', [Self, AURI, ErrMsg]);

  if fHttpServerKind in [useHttpApi, useHttpApiRegisteringURI] then
    HttpApiAddUri(AURI, fDomainName, fDBServers[0].Security,
      fHttpServerKind = useHttpApiRegisteringURI, True);
end;

procedure TSQLWebBrokerServer.AuthorizeWebModules;
begin
  TSynWebRequestHandler(SynWebRequestHandler).AuthorizeURIs(AuthorizeUri);
end;

function TSQLWebBrokerServer.Request(Ctxt: THttpServerRequest): Cardinal;
var
  ErrorMsg: string;
begin
  try
    Result := HTTP_NONE;

    try
      // Enabled temporary deactivation of the server, e.g. in case of pausing
      // a service.
      if not FActive then
      begin
        Result   := HTTP_UNAVAILABLE;
        ErrorMsg := 'Server not ready to answer the request, please try again later!';
        Exit;
      end;

      // Do mORMot's default REST handling
      Result := inherited Request(Ctxt);

      // In case of error try to handle the request by the SynWebRequestHandler
      if (Result = HTTP_NOTFOUND) then
        Result := TSynWebRequestHandler(SynWebRequestHandler).Request(Ctxt);
    finally
      if (Result = HTTP_NONE) or (ErrorMsg <> '') then
        Result := ServerError(Result, ErrorMsg, Ctxt);
    end;
  except
    on E: Exception do
      Result := ServerError(HTTP_SERVERERROR, E.Message, Ctxt);
  end;
end;

end.

