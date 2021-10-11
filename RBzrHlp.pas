{*******************************************************************************
*                                                                              *
*                       Author: Reonid                                         *
*                       Categoty: vector graphic                               *
*                       mailto: reonid@yahoo.com                               *
*                                                                              *
*******************************************************************************}

unit RBzrHlp;

interface

uses
  RCore, RTypes, RGeom, RIntf, RBezier;

type
  TRBezierHelper = class
  private
    function GetNodeType: TNodeType;
    function GetSegmentType: TSegmentType;
    procedure SetNodeType(Value: TNodeType);
    procedure SetSegmentType(Value: TSegmentType);
  public
    property AllNodesType: TNodeType read GetNodeType write SetNodeType;
    property AllSegmentsType: TSegmentType read GetSegmentType write SetSegmentType;
  end;

implementation

{------------------------------ TRBezierHelper --------------------------------}

function TRBezierHelper.GetNodeType: TNodeType;
var i: Integer;
    all: Boolean;
    bzr: TRBezier;
begin
  all := True;
  bzr := TRBezier(Self);

  Result := ntNone;
  if bzr.Empty then Exit;

  Result := bzr.NodeType[bzr.Low];
  for i := bzr.Low+1 to bzr.High do
    if Result <> bzr.NodeType[i] then
    begin
      all := False;
      Break;
    end;
  if not all then Result := ntNone;
end;

function TRBezierHelper.GetSegmentType: TSegmentType;
var i: Integer;
    all: Boolean;
    bzr: TRBezier;
begin
  all := True;
  bzr := TRBezier(Self);

  Result := stNone;
  if bzr.Empty then Exit;

  Result := bzr.SegmentType[bzr.Low];
  for i := bzr.Low+1 to bzr.High do
    if Result <> bzr.SegmentType[i] then
    begin
      all := False;
      Break;
    end;
  if not all then Result := stNone;
end;

procedure TRBezierHelper.SetNodeType(Value: TNodeType);
var i: Integer;
    bzr: TRBezier;
begin
  bzr := TRBezier(Self);
  if bzr.Empty then Exit;

  for i := bzr.Low to bzr.High do
    bzr.NodeType[i] := Value;
end;

procedure TRBezierHelper.SetSegmentType(Value: TSegmentType);
var i: Integer;
    bzr: TRBezier;
begin
  bzr := TRBezier(Self);
  if bzr.Empty then Exit;

  for i := bzr.Low to bzr.High do
    bzr.SegmentType[i] := Value;
end;

end.
