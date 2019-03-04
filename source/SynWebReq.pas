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

{$IFDEF CONDITIONALEXPRESSIONS}
  // RTLVersion >= Delphi 2009
  {$IF (RTLVersion >= 20.0)}
    {$DEFINE HAS_CLASSVARS}
  {$IFEND}
  // RTLVersion >= Delphi 2010
  {$IF (RTLVersion >= 21.0)}
    {$DEFINE HAS_CLASSDESTRUCTOR}
  {$IFEND}
{$ENDIF}

interface

uses
  Classes,
  SynCommons,
  SynCrtSock,
  WebReq;

type
  TSynAuthorizeUriCallback = procedure(AURI: RawUTF8) of object;

  TSynWebRequestHandler = class(TWebRequestHandler)
  private
    FURIsAuthorized: Boolean;
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
    procedure AuthorizeURIs(ACallback: TSynAuthorizeUriCallback);
    function Request(AContext: THttpServerRequest): Cardinal;
  end;

function SynWebRequestHandler: TWebRequestHandler;

implementation

uses
  AutoDisp,
  HTTPApp,
  SynHttpApp,
  SysUtils,
  TypInfo;

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

procedure TSynWebRequestHandler.AuthorizeURIs(ACallback: TSynAuthorizeUriCallback);

  procedure ProcessWebDispatcher(AWebDispatcher: TCustomWebDispatcher);

    procedure AuthorizeURI(const AURI: string);
    begin
      if (AURI[Length(AURI)] <> '/') then
        Exit;

      if Assigned(ACallback) then
        ACallback(StringToUTF8(AURI));
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
                  AuthorizeURI(ExpandPathInfo(PathInfo));
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
      AuthorizeURI(AWebDispatcher.Action[I].PathInfo);

      if (AWebDispatcher.Owner <> nil) then
        Component := AWebDispatcher.Owner
      else
        Component := AWebDispatcher;

      with Component do
        for J := 0 to ComponentCount - 1 do
          ProcessWebDispatchProperties(Components[J]);
    end;
  end;

var
  I, J:       Integer;
  WebModules: TWebModuleList;
  WebModule:  TComponent;
begin
  if FURIsAuthorized then
    Exit;

  WebModules := ActivateWebModules;

  if Assigned(WebModules) then
    try
      WebModules.AutoCreateModules;

      if (WebModules.ItemCount = 0) then
        Exit;

      // Look for web application modules
      for I := 0 to WebModules.ItemCount - 1 do
      begin
        WebModule := WebModules[I];

        if (WebModule is TCustomWebDispatcher) then
          ProcessWebDispatcher(TCustomWebDispatcher(WebModule));

        for J := 0 to WebModule.ComponentCount - 1 do
          if WebModule.Components[J] is TCustomWebDispatcher then
            ProcessWebDispatcher(TCustomWebDispatcher(WebModule));
      end;

      FURIsAuthorized := True;
    finally
      DeactivateWebModules(WebModules);
    end;
end;

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
            Format('The requested URL ''%s'' was not found on this server. Please check the URL or contact the webmaster.', [AContext.URL]), LResponse.Context);
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

