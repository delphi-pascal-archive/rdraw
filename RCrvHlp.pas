{*******************************************************************************
*                                                                              *
*                       Author: Reonid                                         *
*                       Categoty: vector graphic                               *
*                       mailto: reonid@yahoo.com                               *
*                                                                              *
*******************************************************************************}

unit RCrvHlp;

interface

uses
  RCore, RTypes, RGeom, RIntf, RBezier;

type
  TRCurveHelper = class
  public
    procedure Resize(NewLength: Integer);
    function IsResizeable: Boolean;
    function AddBlock(Count: Integer): Integer;
    function InsertBlock(Position, Count: Integer): Integer;
    function DeleteBlock(Position, Count: Integer): Boolean;
  end;

implementation

procedure TRCurveHelper.Resize(NewLength: Integer);
var Resizer: IResizeable;
begin
  if Self.GetInterface(IResizeable, Resizer)
    then Resizer.Resize(NewLength)
    //else raise Exception.Create();
end;

function TRCurveHelper.IsResizeable: Boolean;
var Resizer: IResizeable;
begin
  Result := Self.GetInterface(IResizeable, Resizer);
end;

function TRCurveHelper.AddBlock(Count: Integer): Integer;
var Resizer: IResizeable;
begin
  Result := -1;
  if Self.GetInterface(IResizeable, Resizer) then
  begin
    Result := Resizer.Length;
    Resizer.Resize(Result + Count);
  end;
end;

function TRCurveHelper.InsertBlock(Position, Count: Integer): Integer;
var Resizer: IResizeable;
    OldLength: Integer;
begin
  Result := -1;
  if Self.GetInterface(IResizeable, Resizer) then
  begin
    Result := Position;
    OldLength := Resizer.Length;
    Resizer.Resize(OldLength + Count);
    if Position < OldLength then
      Resizer.MoveBlock(Position, Position + Count, OldLength - Position);
  end;
end;

function TRCurveHelper.DeleteBlock(Position, Count: Integer): Boolean;
var Resizer: IResizeable;
    OldLength: Integer;
begin
  Result := False;
  if Self.GetInterface(IResizeable, Resizer) then
  begin
    Result := True;
    OldLength := Resizer.Length;
    Resizer.MoveBlock(Position + Count, Position, OldLength - Position - Count);
    Resizer.Resize(OldLength - Count);
  end;
end;

end.
