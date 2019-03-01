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
  HTTPApp,
  mORMotHttpServer,
  SynCrtSock;

type
  TSQLWebBrokerServer = class(TSQLHttpServer)
  private
    FActive: Boolean;
    procedure EnumWebDispatchers(AWebDispatcher: TCustomWebDispatcher);
  protected
    function Request(Ctxt: THttpServerRequest): Cardinal; override;
    procedure CheckWebModuleURIs; virtual;
  public
    procedure AfterConstruction; override;
    property Active: Boolean read FActive write FActive;
  end;

implementation

uses
  AutoDisp,
  Classes,
  mORMot,
  SynCommons,
  SynHttpApp,
  SynWebReq,
  SysUtils,
  TypInfo,
  WebReq;

{ TSQLWebBrokerServer }

procedure TSQLWebBrokerServer.AfterConstruction;
begin
  inherited;

  CheckWebModuleURIs;
  FActive := True;
end;

procedure TSQLWebBrokerServer.CheckWebModuleURIs;
begin
  TSynWebRequestHandler(SynWebRequestHandler).EnumWebDispatchers(EnumWebDispatchers);
end;

procedure TSQLWebBrokerServer.EnumWebDispatchers(AWebDispatcher: TCustomWebDispatcher);

  procedure VerifyURI(const AURI: string);
  var
    UTF8URI: RawUTF8;
    I:       Integer;
    ErrMsg:  RawUTF8;
  begin
    UTF8URI := StringToUTF8(AURI);

    for I := 0 to High(fDBServers) do
      with fDBServers[I].Server.Model do
      begin
        if (URIMatch(UTF8URI) <> rmNoMatch) then
          FormatUTF8('Duplicated Root URI: % and %',
            [Root, UTF8URI], ErrMsg);
      end;

    if ErrMsg <> '' then
      raise EHttpServerException.CreateUTF8('%.EnumWebDispatchers/VerifyURI( % ): %', [Self, UTF8URI, ErrMsg]);

    if fHttpServerKind in [useHttpApi, useHttpApiRegisteringURI] then
      HttpApiAddUri(UTF8URI, fDomainName, fDBServers[0].Security,
        fHttpServerKind = useHttpApiRegisteringURI, True);
  end;

  procedure ProcessWebDispatchProperties(AComponent: TComponent);

    function ExpandPathInfo(const APathInfo: string): string;
    begin
      Result := APathInfo;

      if (Result[Length(Result)] = '*') then
        Result[Length(Result)] := '/';
    end;

  var
    I, Count: Integer;
    PropInfo: PPropInfo;
    TempList: PPropList;
    LObject:  TObject;
  begin
    Count := GetPropList(AComponent, TempList);

    if (Count > 0) then
      try
        for I := 0 to Count - 1 do
        begin
          PropInfo := TempList^[I];

          if (PropInfo^.PropType^.Kind = tkClass) then
          begin
            LObject := GetObjectProp(AComponent, PropInfo, TWebDispatch);

            if (LObject <> nil) then
            begin
              with TWebDispatch(LObject) do
              begin
                VerifyURI(ExpandPathInfo(PathInfo));
              end;
            end;
          end;
        end;
      finally
        FreeMem(TempList);
      end;
  end;

var
  I, J:      Integer;
  Component: TComponent;
  //DispatchIntf: IWebDispatch;
begin
  for I := 0 to AWebDispatcher.Actions.Count - 1 do
  begin
    VerifyURI(AWebDispatcher.Action[I].PathInfo);

    if (AWebDispatcher.Owner <> nil) then
      Component := AWebDispatcher.Owner
    else
      Component := AWebDispatcher;

    with Component do
      for J := 0 to ComponentCount - 1 do
        ProcessWebDispatchProperties(Components[J]);
  end;
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

