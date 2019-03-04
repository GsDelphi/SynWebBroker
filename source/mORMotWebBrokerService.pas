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
unit mORMotWebBrokerService;

interface

uses
  Classes,
  SvcMgr,
  SysUtils;

type
  ESQLWebBrokerServiceError = class(Exception);

  TSQLWebBrokerService = class(TService)
  private
    FServer:              TObject;
    FOwnsServer:          Boolean;
    FCreateServerOnStart: Boolean;
    procedure CreateServer;
    procedure DestroyServer;
    procedure SetServer(const Value: TObject);
    function GetServerActive: Boolean;
    procedure SetServerActive(const Value: Boolean);
  protected
    /// override this function and create the desired class instance, must be
    // a descendant of TSQLWebBrokerServer:
    // ! function TYourService.CreateServerInstance: TSQLWebBrokerServer;
    // ! begin
    // !   Result := TSQLWebBrokerServer.Create(...);
    // ! end;
    function CreateServerInstance: TObject; virtual; abstract;
    procedure DoStart; override;
    function DoStop: Boolean; override;
    function DoPause: Boolean; override;
    function DoContinue: Boolean; override;
    //procedure DoInterrogate; override;
    procedure DoShutdown; override;
    //function DoCustomControl(CtrlCode: DWord): Boolean; override;
    function IsTSQLWebBrokerServer(AClass: TClass): Boolean;
  public
    constructor CreateNew(AOwner: TComponent; Dummy: Integer = 0); override;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    /// the associated running TSQLWebBrokerServer instance
    // - because it is not possible to include mORMot to a package we must point
    // here to a simple TObject class. You can override this property with the
    // TSQLWebBrokerServer class type in your descedant class to have normal
    // access to the TSQLWebBrokerServer class properties:
    // ! property Server: TSQLWebBrokerServer read GetServer write SetServer;
    // ! ...
    // ! function TYourService.GetServer: TSQLWebBrokerServer;
    // ! begin
    // !   Result := TSQLWebBrokerServer(inherited Server);
    // ! end;
    // !
    // ! procedure TYourService.SetServer(const Value: TSQLWebBrokerServer);
    // ! begin
    // !   inherited Server := Value;
    // ! end;
    // or by an implicit conversion on each access:
    // ! TSQLWebBrokerServer(FSQLWebBrokerService.Server).Active := True;
    property Server: TObject read FServer write SetServer;
    property ServerActive: Boolean read GetServerActive write SetServerActive;
  published
    property CreateServerOnStart: Boolean read FCreateServerOnStart write FCreateServerOnStart;
  end;

implementation

uses
  TypInfo;

const
  SERVER_CLASS_NAME = 'TSQLWebBrokerServer';

resourcestring
  SErrorInvalidAncestor = '''%s'' is not a descendant of ''%s.''.';

{ TSQLWebBrokerService }

procedure TSQLWebBrokerService.AfterConstruction;
begin
  inherited;

  if not FCreateServerOnStart then
    CreateServer;
end;

constructor TSQLWebBrokerService.CreateNew(AOwner: TComponent; Dummy: Integer);
begin
  inherited;

  FCreateServerOnStart := True;
end;

procedure TSQLWebBrokerService.CreateServer;
var
  AServer: TObject;
begin
  if not Assigned(FServer) then
  begin
    FServer := CreateServerInstance;

    if Assigned(FServer) and not IsTSQLWebBrokerServer(FServer.ClassType) then
    begin
      AServer := FServer;
      FServer := nil;
      raise ESQLWebBrokerServiceError.CreateResFmt(@SErrorInvalidAncestor, [AServer.ClassName, SERVER_CLASS_NAME]);
    end;

    ServerActive := False;
    FOwnsServer  := True;
  end;
end;

destructor TSQLWebBrokerService.Destroy;
begin
  DestroyServer;

  inherited;
end;

procedure TSQLWebBrokerService.DestroyServer;
begin
  if FOwnsServer and Assigned(FServer) then
    FServer.Free;

  FOwnsServer := False;
end;

function TSQLWebBrokerService.DoContinue: Boolean;
begin
  ServerActive := True;

  Result := ServerActive and inherited DoContinue;
end;

function TSQLWebBrokerService.DoPause: Boolean;
begin
  ServerActive := False;

  Result := not ServerActive and inherited DoPause;
end;

procedure TSQLWebBrokerService.DoShutdown;
begin
  ServerActive := False;

  inherited;
end;

procedure TSQLWebBrokerService.DoStart;
begin
  inherited;

  CreateServer;

  ServerActive := True;
end;

function TSQLWebBrokerService.DoStop: Boolean;
begin
  ServerActive := False;

  Result := not ServerActive and inherited DoStop;
end;

function TSQLWebBrokerService.GetServerActive: Boolean;
begin
  if Assigned(FServer) then
    Result := Boolean(GetOrdProp(FServer, 'Active'))
  else
    Result := False;
end;

function TSQLWebBrokerService.IsTSQLWebBrokerServer(AClass: TClass): Boolean;
begin
  repeat
    if AClass.ClassNameIs(SERVER_CLASS_NAME) then
    begin
      Result := True;
      Exit;
    end;

    AClass := AClass.ClassParent;
  until (AClass = nil);

  Result := False;
end;

procedure TSQLWebBrokerService.SetServer(const Value: TObject);
begin
  if Assigned(FServer) and not IsTSQLWebBrokerServer(Value.ClassType) then
    raise ESQLWebBrokerServiceError.CreateResFmt(@SErrorInvalidAncestor, [Value.ClassName, SERVER_CLASS_NAME]);

  DestroyServer;

  FServer := Value;

  ServerActive := (Status in [csStartPending, csRunning, csContinuePending]);
end;

procedure TSQLWebBrokerService.SetServerActive(const Value: Boolean);
begin
  if Assigned(FServer) and (Value <> ServerActive) then
    SetOrdProp(FServer, 'Active', Ord(Value));
end;

end.

