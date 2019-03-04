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
  mORMotWebBrokerServer,
  SvcMgr;

type
  { TODO : register at IDE to get access to published properties}
  TSQLWebBrokerService = class(TService)
  private
    FServer:              TSQLWebBrokerServer;
    FOwnsServer:          Boolean;
    FCreateServerOnStart: Boolean;
    procedure CreateServer;
    procedure DestroyServer;
    procedure SetServer(const Value: TSQLWebBrokerServer);
  protected
    procedure DoStart; override;
    function DoStop: Boolean; override;
    function DoPause: Boolean; override;
    function DoContinue: Boolean; override;
    //procedure DoInterrogate; override;
    procedure DoShutdown; override;
    //function DoCustomControl(CtrlCode: DWord): Boolean; override;
  public
    constructor CreateNew(AOwner: TComponent; Dummy: Integer = 0); override;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    property Server: TSQLWebBrokerServer read FServer write SetServer;
  published
    property CreateServerOnStart: Boolean read FCreateServerOnStart write FCreateServerOnStart;
  end;

implementation

uses
  mORMot,
  SynHttpApp,
  SynWebReq,
  SysUtils;

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
begin
  if not Assigned(FServer) then
  begin
    FServer        := TSQLWebBrokerServer.Create();
    FServer.Active := False;
    FOwnsServer    := True;
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
  FServer.Active := True;

  Result := inherited DoContinue;
end;

function TSQLWebBrokerService.DoPause: Boolean;
begin
  FServer.Active := False;

  Result := inherited DoPause;
end;

procedure TSQLWebBrokerService.DoShutdown;
begin
  FServer.Active := False;

  inherited;
end;

procedure TSQLWebBrokerService.DoStart;
begin
  inherited;

  CreateServer;

  FServer.Active := True;
end;

function TSQLWebBrokerService.DoStop: Boolean;
begin
  FServer.Active := False;

  Result := inherited DoStop;
end;

procedure TSQLWebBrokerService.SetServer(const Value: TSQLWebBrokerServer);
begin
  DestroyServer;

  FServer        := Value;
  FServer.Active := (Status in [csStartPending, csRunning, csContinuePending]);
end;

end.

