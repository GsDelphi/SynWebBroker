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
unit SynWebReq;

interface

uses
  Classes,
  HTTPApp,
  SynCrtSock,
  WebReq;

type
  TSynEnumWebDispatchersCallback = procedure(AWebDispatcher: TCustomWebDispatcher) of object;

  TSynWebRequestHandler = class(TWebRequestHandler)
  private
  {$IFDEF HAS_CLASSVARS}
  private class var
    FWebRequestHandler: TSynWebRequestHandler;
  {$ENDIF}
  public
    constructor Create(AOwner: TComponent); override;
    {$IFDEF HAS_CLASSVARS}
      {$IFDEF HAS_CLASSDESTRUCTOR}
    class destructor Destroy;
      {$ENDIF}
    {$ENDIF}
    destructor Destroy; override;
    procedure EnumWebDispatchers(ACallback: TSynEnumWebDispatchersCallback);
    function Request(AContext: THttpServerRequest): Cardinal;
  end;

function SynWebRequestHandler: TWebRequestHandler;

implementation

uses
  SynHttpApp,
  SysUtils;

{$IFNDEF HAS_CLASSVARS}
var
  LSynWebRequestHandler: TSynWebRequestHandler = nil;

{$ENDIF}

function SynWebRequestHandler: TWebRequestHandler;
begin
  {$IFDEF HAS_CLASSVARS}
  if not Assigned(TSynWebRequestHandler.FWebRequestHandler) then
    TSynWebRequestHandler.FWebRequestHandler := TSynWebRequestHandler.Create(nil);

  Result := TSynWebRequestHandler.FWebRequestHandler;
  {$ELSE}
  if not Assigned(LSynWebRequestHandler) then
    LSynWebRequestHandler := TSynWebRequestHandler.Create(nil);

  Result := LSynWebRequestHandler;
  {$ENDIF}
end;

{ TSynWebRequestHandler }

constructor TSynWebRequestHandler.Create(AOwner: TComponent);
begin
  inherited;

  Classes.ApplicationHandleException := HandleException;
end;

destructor TSynWebRequestHandler.Destroy;
begin
  Classes.ApplicationHandleException := nil;

  inherited;
end;

{$IFDEF HAS_CLASSVARS}
  {$IFDEF HAS_CLASSDESTRUCTOR}
class destructor TSynWebRequestHandler.Destroy;
begin
  FreeAndNil(FWebRequestHandler);
end;
  {$ENDIF}
{$ENDIF}

procedure TSynWebRequestHandler.EnumWebDispatchers(ACallback: TSynEnumWebDispatchersCallback);
var
  I, J:       Integer;
  WebModules: TWebModuleList;
  WebModule:  TComponent;
begin
  WebModules := ActivateWebModules;

  if Assigned(WebModules) then
    try
      WebModules.AutoCreateModules;

      if (WebModules.ItemCount = 0) then
        Exit;

      // Look at modules for a web application
      for I := 0 to WebModules.ItemCount - 1 do
      begin
        WebModule := WebModules[I];

        if (WebModule is TCustomWebDispatcher) then
          ACallback(TCustomWebDispatcher(WebModule));

        for J := 0 to WebModule.ComponentCount - 1 do
          if WebModule.Components[J] is TCustomWebDispatcher then
            ACallback(TCustomWebDispatcher(WebModule));
      end;
    finally
      DeactivateWebModules(WebModules);
    end;
end;

function TSynWebRequestHandler.Request(AContext: THttpServerRequest): Cardinal;
var
  LRequest:  TSynWebRequest;
  LResponse: TSynWebResponse;
begin
  try
    LRequest := TSynWebRequest.Create(AContext);

    try
      LResponse := TSynWebResponse.Create(LRequest);

      try
        if HandleRequest(LRequest, LResponse) then
        begin
          if not LResponse.Sent then
            LResponse.SendResponse;

          Result := LResponse.StatusCode;
        end
        else
          Result := ServerError(HTTP_NOTFOUND,
            Format('The requested URL ''%s'' was not found on this server. Please check the URL or contact the webmaster.',
            [AContext.URL]), LResponse.Context);
      finally
        FreeAndNil(LResponse);
      end;
    finally
      FreeAndNil(LRequest);
    end;
  except
    on E: Exception do
      Result := ServerError(HTTP_SERVERERROR, E.Message, AContext);
  end;
end;

initialization
  WebReq.WebRequestHandlerProc := SynWebRequestHandler;
{$IFDEF HAS_CLASSVARS}
  {$IFNDEF HAS_CLASSDESTRUCTOR}
finalization
  FreeAndNil(TSynWebRequestHandler.FWebRequestHandler);
  {$ENDIF}
{$ELSE}

finalization
  FreeAndNil(LSynWebRequestHandler);
{$ENDIF}
end.

