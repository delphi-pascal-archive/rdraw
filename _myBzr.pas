unit _myBzr;

interface

uses
  Classes, Graphics, Dialogs, Menus,
  RCore, RTypes, RIntf, RCurve, RBezier, RLine, _attr;

type

  TBezierNode = record
    Point: TPointF;
    LCtrlPt: TPointF;
    RCtrlPt: TPointF;
    NodeTp: TNodeType;
    SegmTp: TSegmentType;
  end;

  TMyBezier = class(TRBezier, IResizeable, IDrawingAttributes, INamedObject)
  private
    FName: string;
    FNodes: array of TBezierNode;
    FAttributes: TRDrawingAttributes;
    function GetAlwaysShowMarkers: Boolean;
    procedure SetAlwaysShowMarkers(const Value: Boolean);
  protected
    function  GetX(I: Integer): Double; override;
    procedure SetX(I: Integer; const Value: Double); override;
    function  GetY(I: Integer): Double; override;
    procedure SetY(I: Integer; const Value: Double); override;

    function GetCtrlPoint(id: TCtrlPointId; I: Integer): TPointF; override;
    procedure SetCtrlPoint(id: TCtrlPointId; I: Integer; const Value: TPointF); override;

    function GetNodeType(I: Integer): TNodeType; override;
    procedure SetNodeType(I: Integer; const Value: TNodeType); override;

    function GetSegmentType(I: Integer): TSegmentType; override;
    procedure SetSegmentType(I: Integer; const Value: TSegmentType); override;

    {IPartiallyStreamable}
    procedure SaveDataToStream(Stream: TStream; Aspects: TDataAspects); override;
    procedure LoadDataFromStream(Stream: TStream; Aspects: TDataAspects); override;

    procedure PrepareDraw(Layer: TRLayer; Element: TRCurveElement); override;
    function CreateMarker: TRMarker; override;
  public
    property AlwaysShowMarkers: Boolean read GetAlwaysShowMarkers write SetAlwaysShowMarkers;

    constructor CreateEx(PointCount: Integer);
    constructor Create; override;
    destructor Destroy; override;

    {IResizeable}
    procedure Resize(Count: Integer);
    procedure MoveBlock(SourcePos, DestPos, Count: Integer);

    {IDrawingAttributes}
    function Attributes: TRDrawingAttributes;

    {INamedObject}
    function Name: string;
    procedure Rename(const NewName: string);

    function Length: Integer; override;
  end;

  TMyMarker = class(TRMarker)
  private
    FAlwaysShow: Boolean;
  public
    property AlwaysShow: Boolean read FAlwaysShow write FAlwaysShow;
    procedure Draw(Layer: TRLayer; X, Y: Integer; Index: Integer; Mode: TRMarkerDrawMode); override;
  end;

implementation

uses
  SysUtils, Math,
  RCrvCtl, RFigHlp, RUtils;

{------------------- TMyCurve --------------------------}

constructor TMyBezier.CreateEx(PointCount: Integer);
var i: Integer;
begin
  inherited Create;
  SetLength(FNodes, PointCount);

  for i := 0 to PointCount-1 do
  begin
    FNodes[i].Point := PointF(i, i);
    {FNodes[i].LCtrlPt := PointF(1, -1);
    FNodes[i].RCtrlPt := PointF(-1, 1);}
    FNodes[i].NodeTp := ntCusp;
    FNodes[i].SegmTp := stLine; //stBezier;
  end;

  FAttributes := TRDrawingAttributes.Create;
end;

constructor TMyBezier.Create;
begin
  CreateEx(0);
end;

destructor TMyBezier.Destroy;
begin
  FAttributes.Free;
  inherited;
end;

function TMyBezier.CreateMarker: TRMarker;
begin
  Result := TMyMarker.Create(Self);
end;

procedure TMyBezier.PrepareDraw(Layer: TRLayer; Element: TRCurveElement);
begin
  inherited;
  case Element of
    ceSegment:
    begin
      FAttributes.Apply(Layer);
      _AccomodatePen(Layer);
    end;
    ceArea:
    begin
      FAttributes.Apply(Layer);
      _AccomodatePen(Layer);
    end;
  end;
end;

function TMyBezier.GetCtrlPoint(id: TCtrlPointId; I: Integer): TPointF;
begin
  case id of
    cpLeft:  Result := FNodes[i].LCtrlPt;
    cpRight: Result := FNodes[i].RCtrlPt;
  end;
end;

procedure TMyBezier.SetCtrlPoint(id: TCtrlPointId; I: Integer; const Value: TPointF);
begin
  case id of
    cpLeft:  FNodes[i].LCtrlPt := Value;
    cpRight: FNodes[i].RCtrlPt := Value;
  end;
end;

function TMyBezier.GetNodeType(I: Integer): TNodeType;
begin
  Result := FNodes[i].NodeTp;
end;

procedure TMyBezier.SetNodeType(I: Integer; const Value: TNodeType);
begin
  FNodes[i].NodeTp := Value;
end;

function TMyBezier.GetSegmentType(I: Integer): TSegmentType;
begin
  Result := FNodes[i].SegmTp;
end;

procedure TMyBezier.SetSegmentType(I: Integer; const Value: TSegmentType);
begin
  FNodes[i].SegmTp := Value;
end;

function TMyBezier.Length: Integer;
begin
  Result := System.Length(FNodes);
end;

function TMyBezier.GetX(I: Integer): Double;
begin
  Result := FNodes[i].Point.X;
end;

function TMyBezier.GetY(I: Integer): Double;
begin
  Result := FNodes[i].Point.Y;
end;

procedure TMyBezier.SetX(I: Integer; const Value: Double);
begin
  FNodes[I].Point.X := Value;
end;

procedure TMyBezier.SetY(I: Integer; const Value: Double);
begin
  FNodes[I].Point.Y := Value;
end;

procedure TMyBezier.MoveBlock(SourcePos, DestPos, Count: Integer);
begin
  Move(FNodes[SourcePos], FNodes[DestPos], SizeOf(FNodes[0])*Count);
end;

procedure TMyBezier.Resize(Count: Integer);
begin
  SetLength(FNodes, Count);
end;

function TMyBezier.Attributes: TRDrawingAttributes;
begin
  Result := FAttributes;
end;

procedure TMyBezier.SaveDataToStream(Stream: TStream; Aspects: TDataAspects);
begin
  inherited;
  if daAttributes in Aspects then
    FAttributes.SaveToStream(Stream);
  if daText in Aspects then
    WriteStringToStream(Stream, Name);
end;

procedure TMyBezier.LoadDataFromStream(Stream: TStream; Aspects: TDataAspects);
begin
  inherited;
  if daAttributes in Aspects then
    FAttributes.LoadFromStream(Stream);
  if daText in Aspects then
    FName := ReadStringFromStream(Stream);
end;

function TMyBezier.Name: string;
begin
  Result := FName;
end;

procedure TMyBezier.Rename(const NewName: string);
begin
  FName := NewName;
end;

{------------------------------- TMyMarker ------------------------------------}

procedure TMyMarker.Draw(Layer: TRLayer; X, Y: Integer; Index: Integer; Mode: TRMarkerDrawMode);
var sel: TRFigure;
begin
  if (not AlwaysShow)and(Mode in [dmNormal]) then
  begin
    if Assigned(Curve.Controller) and
       (TRCurveController(Curve.Controller).Options.Point = eoSelect)then Exit;

    if (Curve.Controller is TRStraightLineController)then
    begin
      sel := FindSelectionObject(Layer.Sheet, [TRCurveAttorney]);
      if (sel = nil)or(TRCurveAttorney(sel).Curve <> Curve)then Exit;
    end;
  end;

  inherited;
end;

function TMyBezier.GetAlwaysShowMarkers: Boolean;
begin
  Result := (Marker as TMyMarker).AlwaysShow;
end;

procedure TMyBezier.SetAlwaysShowMarkers(const Value: Boolean);
begin
  (Marker as TMyMarker).AlwaysShow := Value;
end;

initialization
finalization
end.
