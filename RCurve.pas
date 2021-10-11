{*******************************************************************************
*                                                                              *
*                       Author: Reonid                                         *
*                       Categoty: vector graphic                               *
*                       mailto: reonid@yahoo.com                               *
*                                                                              *
*******************************************************************************}

unit RCurve;

interface

uses
  RCore, RTypes, RIntf, RUndo, IdxList,

  {$IFDEF UNIX}
  {$ELSE}
  Windows,
  {$ENDIF}
  Graphics, Classes, Menus;

type

  TRMarker = class;

  TRCurveElement = (cePoint, ceSegment, ceArea, ceNone);

  TRMarkerDrawMode = (dmNormal, dmSelected, dmHighlighted);
  TRMarkerDrawModes = set of TRMarkerDrawMode;

  TRCurve = class(TRFigure, ITransformable, IStreamPersist, IStreamable, IUndoable)
  private
    FClosed: Boolean;
    FFilled: Boolean;
    FMarker: TRMarker;
  protected
    procedure _AccomodatePen(Layer: TRLayer); virtual;

    procedure PointChanged(I: Integer); virtual;

    function GetX(I: Integer): Double; virtual; abstract;
    procedure SetX(I: Integer; const Value: Double); virtual; abstract;
    function GetY(I: Integer): Double; virtual; abstract;
    procedure SetY(I: Integer; const Value: Double); virtual; abstract;

    procedure SetXUpd(I: Integer; const Value: Double);
    procedure SetYUpd(I: Integer; const Value: Double);

    function GetPoint(I: Integer): TPointF;
    procedure SetPointUpd(I: Integer; const Value: TPointF);

    function GetHigh: Integer;
    function GetLow: Integer;
    function GetEmpty: Boolean; virtual; 
    procedure SetClosed(Value: Boolean); virtual;

    procedure PrepareDraw(Layer: TRLayer; Element: TRCurveElement); virtual;
    procedure DrawLine(Layer: TRLayer); virtual;
    procedure DrawMarkers(Layer: TRLayer; Mode: TRMarkerDrawMode); virtual;
    procedure FillArea(Layer: TRLayer); virtual;
    procedure Draw(Layer: TRLayer); override;

    function CreateMarker: TRMarker; virtual;

    {ITransformable}
    function HitTest(Layer: TRLayer; const Pt: TPointF): Boolean; virtual;
    function ContainingRect: TRectF; virtual;
    function Transform(var Data: TTransformData): Boolean; virtual;

    {IStreamPersist}
    procedure SaveToStream(Stream: TStream); //virtual;
    procedure LoadFromStream(Stream: TStream); //virtual;

    {IStreamable}
    procedure SaveDataToStream(Stream: TStream; Aspects: TDataAspects); virtual;
    procedure LoadDataFromStream(Stream: TStream; Aspects: TDataAspects); virtual;

    {IUndoable}
    function CreateUndoPoint(ASheet: TRSheet; ALayer: TRLayer;
      Aspects: TDataAspects): TRUndoPoint; virtual;
  public
    property X[I: Integer]: Double read GetX write SetXUpd;
    property Y[I: Integer]: Double read GetY write SetYUpd;
    property Points[I: Integer]: TPointF read GetPoint write SetPointUpd; default;

    property Low: Integer read GetLow;
    property High: Integer read GetHigh;
    property Empty: Boolean read GetEmpty;
    property Closed: Boolean read FClosed write SetClosed;
    property Filled: Boolean read FFilled write FFilled;

    constructor Create; override;
    destructor Destroy; override;

    function Length: Integer; virtual; abstract;
    function Marker: TRMarker;

    procedure Scale(XC, YC, KX, KY: TFloat); virtual;
    procedure Translate(DX, DY: TFloat); virtual;
    procedure Rotate(XC, YC, Angle: TFloat); virtual;

    function GetIntermediatePoint(I: Integer; t: TFloat): TPointF; virtual;
    function ActualizeIntermediatePoint(I: Integer; t: TFloat): Integer; virtual;
    procedure CalcSegmentCenter(I: Integer; var t: TFloat); virtual;

    function HitSegment(Layer: TRLayer; const Pt: TPointF; Sens: Integer; var Index: Integer;
      var t: TFloat): Boolean; virtual;
    function HitPoint(Layer: TRLayer; const Pt: TPointF; Sens: Integer;
      var Index: Integer): Boolean; virtual;
    function HitArea(Layer: TRLayer; const Pt: TPointF): Boolean; virtual;

    procedure DrawSample(Layer: TRLayer; Rect: TRect); virtual;
  end;

  TRMarkerStyle = (msSolid, msOpen);

  TRMarkerShape = (mkNone, mkSquare, mkCircle, mkUpTriangle, mkDownTriangle, mkDiamond,
    mkCross, mkXCross, mkOther);

  TRMarker = class(TRInterfacedObject, IStreamable)
  private
    FCurve: TRCurve;
    FSize: Integer;
    FShape: TRMarkerShape;
    FStyle: TRMarkerStyle;
  protected
    procedure _AccomodateSize(Layer: TRLayer; var ASize: Integer); virtual;

    {IStreamable}
    procedure SaveDataToStream(Stream: TStream; Aspects: TDataAspects);
    procedure LoadDataFromStream(Stream: TStream; Aspects: TDataAspects);
  public
    property Curve: TRCurve read FCurve; // write FCurve;
    property Size: Integer read FSize write FSize;
    property Shape: TRMarkerShape read FShape write FShape;
    property Style: TRMarkerStyle read FStyle write FStyle;

    constructor Create(ACurve: TRCurve);
    procedure PrepareDraw(Layer: TRLayer; Mode: TRMarkerDrawMode); virtual;
    procedure Draw(Layer: TRLayer; X, Y: Integer; Index: Integer; Mode: TRMarkerDrawMode); virtual;
  end;

  TRCurveSelection = class(TRCurve)
  private
    FSourceCurve: TRCurve;
    FIndexList: TIndexList;
  protected
    function  GetX(I: Integer): Double; override;
    procedure SetX(I: Integer; const Value: Double); override;
    function  GetY(I: Integer): Double; override;
    procedure SetY(I: Integer; const Value: Double); override;

    function GetPopupMenu: TPopupMenu; override;
    procedure SetPopupMenu(const Value: TPopupMenu); override;

    procedure DrawMarkers(Layer: TRLayer; Mode: TRMarkerDrawMode); override;
    procedure DrawLine(Layer: TRLayer); override;

    function CreateMarker: TRMarker; override;
    function CreateUndoPoint(ASheet: TRSheet; ALayer: TRLayer;
      Aspects: TDataAspects): TRUndoPoint; override;
  public
    constructor Create; override;
    destructor Destroy; override;

    function SourceCurve: TRCurve;

    function GetIndex(I: Integer): Integer;
    procedure UndoablyDelete(Layer: TRLayer); override;
    function Length: Integer; override;

    procedure UndoablyDeletePoints(Layer: TRLayer);
    procedure AcquirePoints(Source: TRCurve; Rect: TRectF; Mode: TRSelectMode);
    procedure AddPoint(Source: TRCurve; I: Integer; Mode: TRSelectMode);
    procedure UndoablyRedouble(Layer: TRLayer);
    procedure Rarefy(Layer: TRLayer);
    procedure Clear;
    procedure ClearExceptFirst;
  end;

implementation

uses
  SysUtils,

//  TypId, DoubleFn, GeomAlgs, RCrvFn,

  RGeom, RCrvHlp;

{------------------------------- TRMarker -------------------------------------}

constructor TRMarker.Create(ACurve: TRCurve);
begin
  FCurve := ACurve;
  FSize := 7;
  FShape := mkSquare;
  FStyle := msOpen; //msSolid;
end;

procedure TRMarker.PrepareDraw(Layer: TRLayer; Mode: TRMarkerDrawMode);
begin
  case Mode of
    dmHighlighted:
    begin
      Layer.Canvas.Brush.Style := bsClear;
      Layer.Canvas.Pen.Color := clBlack;
      Layer.Canvas.Pen.Mode := pmNotXor;
    end;
    dmSelected:
    begin
      Layer.Canvas.Brush.Color := clBlack;
      Layer.Canvas.Pen.Color := clBlack;
      Layer.Canvas.Pen.Mode := pmCopy;
    end;
    dmNormal:
    begin
      Layer.Canvas.Brush.Style := bsSolid;
      if FStyle = msOpen
        then Layer.Canvas.Brush.Color := Layer.BgColor
        else Layer.Canvas.Brush.Color := Layer.Canvas.Pen.Color;

      Layer.Canvas.Pen.Mode := pmCopy;
    end;
  end;
  {?}
  Layer.Canvas.Pen.Width := 1;
  Curve._AccomodatePen(Layer);
end;

procedure TRMarker.Draw(Layer: TRLayer; X, Y: Integer; Index: Integer; Mode: TRMarkerDrawMode);
var sz, SzMinus, SzPlus, Sz13, Sz23: Integer;
    shp: TRMarkerShape;
begin
  sz := Size;
  {!} sz := sz + 1;
  shp := FShape;
  if Mode = dmHighlighted then sz := sz + 4;
  if (Mode <> dmNormal)and(shp = mkNone) then shp := mkSquare;

  _AccomodateSize(Layer, sz);

  szMinus := (sz + 1) div 2 - 1;
  szPlus := sz div 2;
  sz23 := (sz*2)div 3;
  sz13 := sz div 3;

  with Layer do begin
    case shp of
      mkNone: {};
      mkSquare: Canvas.Rectangle(X-szMinus, Y-szMinus, X+szPlus, Y+szPlus);
      mkCircle: Canvas.Ellipse  (X-szMinus, Y-szMinus, X+szPlus, Y+szPlus);
      mkUpTriangle: Canvas.Polygon([Point(X, Y - sz23),
                    Point(X - szPlus, Y + sz13), Point(X + szPlus, Y + sz13)]);
      mkDownTriangle: Canvas.Polygon([Point(X, Y + sz23),
                    Point(X - szPlus, Y - sz13), Point(X + szPlus, Y - sz13)]);
      mkDiamond: Canvas.Polygon([Point(X, Y + szPlus), Point(X - szPlus, Y),
                    Point(X, Y - szPlus), Point(X + szPlus, Y)]);
      mkCross:
      begin
        Canvas.MoveTo(X, Y + szPlus); Canvas.LineTo(X, Y - szPlus);
        Canvas.MoveTo(X + szPlus, Y); Canvas.LineTo(X - szPlus, Y);
      end;
      mkXCross:
      begin
        Canvas.MoveTo(X + szPlus, Y + szPlus); Canvas.LineTo(X - szPlus, Y - szPlus);
        Canvas.MoveTo(X + szPlus, Y - szPlus); Canvas.LineTo(X - szPlus, Y + szPlus);
      end;
    end;
  end;
end;

procedure TRMarker._AccomodateSize(Layer: TRLayer; var ASize: Integer);
begin
  if Layer.Printing then
    ASize := Round(  ASize*MinPtCoordF(Layer.Sheet.PrintData.RectScale)  );
end;

procedure TRMarker.LoadDataFromStream(Stream: TStream; Aspects: TDataAspects);
begin
  if daAttributes in Aspects then
  begin
    Stream.ReadBuffer(FSize, SizeOf(FSize));
    Stream.ReadBuffer(FShape, SizeOf(FShape));
    Stream.ReadBuffer(FStyle, SizeOf(FStyle));
  end;
end;

procedure TRMarker.SaveDataToStream(Stream: TStream; Aspects: TDataAspects);
begin
  if daAttributes in Aspects then
  begin
    Stream.WriteBuffer(FSize, SizeOf(FSize));
    Stream.WriteBuffer(FShape, SizeOf(FShape));
    Stream.WriteBuffer(FStyle, SizeOf(FStyle));
  end;
end;

{------------------------------- TRCurve --------------------------------------}

constructor TRCurve.Create;
begin
  inherited;
  FMarker := CreateMarker;
end;

destructor TRCurve.Destroy;
begin
  FMarker.Free;
  inherited;
end;

function TRCurve.Marker: TRMarker;
begin
  Result := FMarker;
end;

procedure TRCurve.PointChanged(I: Integer);
begin
  {}
end;

procedure TRCurve.SetXUpd(I: Integer; const Value: Double);
begin
  SetX(I, Value);
  PointChanged(I);
end;

procedure TRCurve.SetYUpd(I: Integer; const Value: Double);
begin
  SetY(I, Value);
  PointChanged(I);
end;

function TRCurve.GetPoint(I: Integer): TPointF;
begin
  Result.X := X[I];
  Result.Y := Y[I];
end;

procedure TRCurve.SetPointUpd(I: Integer; const Value: TPointF);
begin
  SetX(I, Value.X);
  SetY(I, Value.Y);
  PointChanged(I);
end;

procedure TRCurve.SetClosed(Value: Boolean);
begin
  FClosed := Value;
end;

function TRCurve.ContainingRect: TRectF;
var
  i: Integer;
  xx, yy: TFloat;
begin
  if Low <= High then
  begin
    Result := RectF(X[Low], Y[Low], X[Low], Y[Low]);
    for i := Low+1 to High do
    begin
      xx := X[i];
      yy := Y[i];
      if Result.XMin > xx then Result.XMin := xx;
      if Result.XMax < xx then Result.XMax := xx;
      if Result.YMin > yy then Result.YMin := yy;
      if Result.YMax < yy then Result.YMax := yy;
    end;
  end
  else Result := EmptyRectF;
end;

function TRCurve.CreateMarker: TRMarker;
begin
  Result := TRMarker.Create(Self);
end;

procedure TRCurve.Draw(Layer: TRLayer);
begin
  if Closed and Filled then
  begin
    PrepareDraw(Layer, ceArea);
    FillArea(Layer);
  end;

  PrepareDraw(Layer, ceSegment);
  DrawLine(Layer);

  //PrepareDraw(cePoint);
  DrawMarkers(Layer, dmNormal);
end;

function TRCurve.HitTest(Layer: TRLayer; const Pt: TPointF): Boolean;
var
  Idx: Integer;
  t: TFloat;
begin
  Result := HitPoint(Layer, Pt, 5, Idx) or HitSegment(Layer, Pt, 3, Idx, t)
    or (Closed and Filled and HitArea(Layer, Pt));
end;

procedure TRCurve.PrepareDraw(Layer: TRLayer; Element: TRCurveElement);
begin
  Layer.Canvas.Pen.Mode := pmCopy;
end;

procedure TRCurve.DrawLine(Layer: TRLayer);
var i, XX, YY: Integer;
begin
  for i := Low to High do
  begin          
    Layer.Converter.LogicToScreen(X[i], Y[i], XX, YY);
    if i = 0
      then Layer.Canvas.MoveTo(XX, YY)
      else Layer.Canvas.LineTo(XX, YY);
  end;
  if Closed and (not Empty) then
  begin
    Layer.Converter.LogicToScreen(X[Low], Y[Low], XX, YY);
    Layer.Canvas.LineTo(XX, YY);
  end;
end;

procedure TRCurve.DrawMarkers(Layer: TRLayer; Mode: TRMarkerDrawMode);
var i, XX, YY: Integer;
begin
  PrepareDraw(Layer, cePoint);
  FMarker.PrepareDraw(Layer, Mode);
  for i := Low to High do
  begin
    Layer.Converter.LogicToScreen(X[i], Y[i], XX, YY);
    FMarker.Draw(Layer, XX, YY, i, Mode);
  end;
end;

procedure TRCurve.DrawSample(Layer: TRLayer; Rect: TRect);
var Y, X0, X1, X: Integer;
begin
  Y := (Rect.Top + Rect.Bottom) div 2;
  X := (Rect.Left + Rect.Right) div 2;
  X0 := Rect.Left;
  X1 := Rect.Right;

  PrepareDraw(Layer, ceSegment);
  Layer.Canvas.MoveTo(X0, Y);
  Layer.Canvas.LineTo(X1, Y);

  PrepareDraw(Layer, cePoint);
  FMarker.PrepareDraw(Layer, dmNormal);
  Marker.Draw(Layer, X, Y, 0, dmNormal);
end;

procedure TRCurve.FillArea(Layer: TRLayer);
var i: Integer;
    pt: TPoint;
begin
  if Empty then Exit; 

  {$IFDEF UNIX}
  {$ELSE}
  BeginPath(Layer.Canvas.Handle);

  Layer.Converter.LogicToScreen(X[Low], Y[Low], pt.X, pt.Y);
  MoveToEx(Layer.Canvas.Handle, pt.X, pt.Y, nil);

  for i := Low+1 to High do
  begin
    Layer.Converter.LogicToScreen(X[i], Y[i], pt.X, pt.Y);
    PolyLineTo(Layer.Canvas.Handle, pt, 1);
  end;
  CloseFigure(Layer.Canvas.Handle);
  EndPath(Layer.Canvas.Handle);

  FillPath(Layer.Canvas.Handle);
  {$ENDIF}
end;

function TRCurve.GetEmpty: Boolean;
begin
  Result := Length = 0;
end;

function TRCurve.GetHigh: Integer;
begin
  Result := Length-1;
end;

function TRCurve.GetIntermediatePoint(I: Integer; t: TFloat): TPointF;
var X0, Y0, X1, Y1: TFloat;
    iplus1: Integer;
begin
  X0 := X[I];
  Y0 := Y[I];
  iplus1 := I+1 mod Length;
  X1 := X[iplus1];
  Y1 := Y[iplus1];
  Result.X := X0 + (X1-X0)*t;
  Result.Y := Y0 + (Y1-Y0)*t;   //???Closed
end;

function TRCurve.ActualizeIntermediatePoint(I: Integer; t: TFloat): Integer;
var pt: TPointF;
begin
  Result := -1;
  if TRCurveHelper(Self).IsResizeable then
  begin
    pt := GetIntermediatePoint(I, t);
    Result := TRCurveHelper(Self).InsertBlock(I+1, 1);
    if Result > -1 then
    begin
      X[Result] := pt.X;
      Y[Result] := pt.Y;
    end;
  end;
end;

procedure TRCurve.CalcSegmentCenter(I: Integer; var t: TFloat);
begin
  t := 0.5;
end;

function TRCurve.GetLow: Integer;
begin
  Result := 0;
end;

function TRCurve.Transform(var Data: TTransformData): Boolean;
begin
  Result := True;
  with Data do
    case Operation of
      opTranslate: Translate(DX, DY);
      opRotate: Rotate(Center.X, Center.Y, Angle);
      opSkew: Result := False;
      opScale: if (Abs(KX) > MinScaleCoef)and(Abs(KY) > MinScaleCoef)
                 then Scale(Center.X, Center.Y, KX, KY)
                 else Result := False;
    end;
end;

procedure TRCurve.Scale(XC, YC, KX, KY: TFloat);
var i: Integer;
begin
  for i := Low to High do
  begin
    X[i] := (X[i] - XC)*KX + XC;
    Y[i] := (Y[i] - YC)*KY + YC;
  end;
end;

procedure TRCurve.Translate(DX, DY: TFloat);
var i: Integer;
begin
  for i := Low to High do
  begin
    X[i] := X[i] + DX;
    Y[i] := Y[i] + DY;
  end;
end;

procedure TRCurve.Rotate(XC, YC, Angle: TFloat);
var i: Integer;
    Xi, Yi: Double;
begin
  for i := Low to High do
  begin
    Xi := X[i] - XC;
    Yi := Y[i] - YC;
    X[i] := XC + Xi*Cos(Angle) - Yi*Sin(Angle);
    Y[i] := YC + Yi*Cos(Angle) + Xi*Sin(Angle);
  end;
end;

function TRCurve.HitSegment(Layer: TRLayer; const Pt: TPointF; Sens: Integer;
  var Index: Integer; var t: TFloat): Boolean;
var
  i: Integer;
  hitPt, startPt, finPt, pt0: TPoint;
begin
  Result := False;
  Index := -1;
  if Empty then Exit;
  //Sens := 3;

  Layer.Converter.LogicToScreen(Pt.X, Pt.Y, hitPt.X, hitPt.Y);
  Layer.Converter.LogicToScreen(X[Low], Y[Low], pt0.X, pt0.Y);

  finPt := pt0;
  for i := Low+1 to High do
  begin
    startPt := finPt;
    Layer.Converter.LogicToScreen(X[i], Y[i], finPt.X, finPt.Y);
    if PtInLine(hitPt.X, hitPt.Y, startPt.X, startPt.Y, finPt.X, finPt.Y, Sens, t) then
    begin
      Result := True;
      Index := i-1;
      Break;
    end;
  end;

  if not Result and Closed then
    if PtInLine(hitPt.X, hitPt.Y, finPt.X, finPt.Y, pt0.X, pt0.Y, Sens, t) then
    begin
      Result := True;
      Index := High;
    end;
end;

function TRCurve.HitPoint(Layer: TRLayer; const Pt: TPointF; Sens: Integer;
  var Index: Integer): Boolean;
var
  i: Integer;
  xx, yy: Integer;
  scrPt: TPoint;
begin
  Result := False;
  Index := -1;
  if IsEmptyF(Pt) then Exit;

  Layer.Converter.LogicToScreen(Pt.X, Pt.Y, scrPt.X, scrPt.Y);
  for i := Low to High do
  begin
    Layer.Converter.LogicToScreen(X[i], Y[i], xx, yy);
    if (scrPt.X > xx - Sens)and(scrPt.X < xx + Sens) then
      if (scrPt.Y > yy - Sens)and(scrPt.Y < yy + Sens) then
      begin
        Result := True;
        Index := i;
        Break;
      end;
  end;
end;

function TRCurve.HitArea(Layer: TRLayer; const Pt: TPointF): Boolean;
var i, j, k, Intersect: Integer;
    t: TFloat;
begin
  //Result := PtInPolygon(ArrayAdapter(Self, 'x'), ArrayAdapter(Self, 'y'), Pt.X, Pt.Y);

  Result := False;
  if (not Closed) {or(not Filled)} then Exit;

  Intersect := 0;
  for i := Low to High do
  begin
    j := (i+1) mod (Length);
    if not(    Y[i] =  Y[j]                        )and
       not(    ( Pt.Y < Y[i] )and( Pt.Y < Y[j] )   )and
       not(    ( Pt.Y > Y[i] )and( Pt.Y > Y[j] )   )then
      if MaxValueF(Y[i], Y[j], i, j, k) = Pt.Y then
      begin
        if X[k] > Pt.X then Inc(Intersect)
      end
      else if not (MinValueF(Y[i], Y[j], i, j, k) = Pt.Y) then
      begin
        t := (Pt.Y - Y[i])/(Y[j] - Y[i]);
        if (t>0)and(t<1)and(X[i] + t*(X[j] - X[i]) > Pt.X)then Inc(Intersect);
      end;
  end;
  Result := Intersect mod 2 = 1;
end;

procedure TRCurve.SaveDataToStream(Stream: TStream; Aspects: TDataAspects);
var i, N: Integer;
    Xi, Yi: Double;
begin
  if daGeometry in Aspects then
  begin
    N := Length;
    Stream.WriteBuffer(N, SizeOf(N));

    for i := 0 to Length-1 do
    begin
      Xi := X[i];
      Yi := Y[i];
      Stream.WriteBuffer(Xi, SizeOf(Xi));
      Stream.WriteBuffer(Yi, SizeOf(Yi));
    end;

    Stream.WriteBuffer(FClosed, SizeOf(FClosed));
    Stream.WriteBuffer(FFilled, SizeOf(FFilled));
  end;

  if daAttributes in Aspects then
  begin
    Marker.SaveDataToStream(Stream, daAll{?});
  end;
end;

procedure TRCurve.LoadDataFromStream(Stream: TStream; Aspects: TDataAspects);
var i, N: Integer;
    Xi, Yi: Double;
begin
  if daGeometry in Aspects then
  begin
    Stream.ReadBuffer(N, SizeOf(N));
    if Length <> N then TRCurveHelper(Self).Resize(N);

    for i := 0 to Length-1 do
    begin
      Stream.ReadBuffer(Xi, SizeOf(Xi));
      Stream.ReadBuffer(Yi, SizeOf(Yi));
      X[i] := Xi;
      Y[i] := Yi;
    end;

    Stream.ReadBuffer(FClosed, SizeOf(FClosed));
    Stream.ReadBuffer(FFilled, SizeOf(FFilled));
  end;

  if daAttributes in Aspects then
  begin
    Marker.LoadDataFromStream(Stream, daAll{?});
  end;
end;

procedure TRCurve.SaveToStream(Stream: TStream);
begin
  SaveDataToStream(Stream, daAll);
end;

procedure TRCurve.LoadFromStream(Stream: TStream);
begin
  LoadDataFromStream(Stream, daAll); 
end;

function TRCurve.CreateUndoPoint(ASheet: TRSheet; ALayer: TRLayer;
  Aspects: TDataAspects): TRUndoPoint;
begin
  Result := TRStreamableUndoPoint.Create(Self, ASheet, ALayer, Aspects);
end;

procedure TRCurve._AccomodatePen(Layer: TRLayer);
begin
  if Layer.Printing then
    with Layer.Canvas.Pen do
      Width := Round(  Width * MinPtCoordF(Layer.Sheet.PrintData.PixelScale)  );
end;

{-------------------------- TRCurveSelection ----------------------------------}

constructor TRCurveSelection.Create;
begin
  inherited;
  FIndexList := TIndexList.Create;
  Style := Style + [fsServant];
end;

destructor TRCurveSelection.Destroy;
begin
  FIndexList.Free;
  inherited;
end;

function TRCurveSelection.CreateMarker: TRMarker;
begin
  Result := nil; {Unused}
end;

procedure TRCurveSelection.UndoablyDeletePoints(Layer: TRLayer);
var
  i, j: Integer;
  Resizeable: IResizeable;
begin
  if Empty then Exit;
  if not FSourceCurve.GetInterface(IResizeable, Resizeable) then Exit;

  if Length = SourceCurve.Length then
  begin
    SourceCurve.UndoablyDelete(Layer);
    Layer.Deselect;
    Exit;
  end;

  UndoStack(Layer.Sheet).Push(FSourceCurve.CreateUndoPoint(Layer.Sheet, Layer, [daGeometry]));

  FIndexList.Sort;
  j := FSourceCurve.Low;
  for i := FSourceCurve.Low to FSourceCurve.High do
  begin
    if FIndexList.FindIndex(i) = -1 then {not selected}
    begin
      FSourceCurve.Y[j] := FSourceCurve.Y[i];
      FSourceCurve.X[j] := FSourceCurve.X[i];
      Inc(j);
      if i >= FSourceCurve.High then
      begin
        Resizeable.Resize(j);
        Exit;
      end;
    end;
  end;

  TRCurveHelper(FSourceCurve).DeleteBlock(j, FIndexList[High]-j+1);
  //Resizeable.Resize(j);
end;

function TRCurveSelection.Length: Integer;
begin
  Result := FIndexList.Count;
end;

procedure TRCurveSelection.UndoablyDelete(Layer: TRLayer);
begin
  UndoablyDeletePoints(Layer);
end;

function TRCurveSelection.GetX(I: Integer): Double;
begin
  Result := FSourceCurve.X[ FIndexList[I] ];
end;

function TRCurveSelection.GetY(I: Integer): Double;
begin
  Result := FSourceCurve.Y[ FIndexList[I] ];
end;

procedure TRCurveSelection.SetX(I: Integer; const Value: Double);
begin
  FSourceCurve.X[ FIndexList[I] ] := Value;
end;

procedure TRCurveSelection.SetY(I: Integer; const Value: Double);
begin
  FSourceCurve.Y[ FIndexList[I] ] := Value;
end;

procedure TRCurveSelection.AcquirePoints(Source: TRCurve; Rect: TRectF; Mode: TRSelectMode);
var i: Integer;
begin
  FSourceCurve := Source;
  if Mode = smNormal then FIndexList.Clear;

  for i := FSourceCurve.Low to FSourceCurve.High do
  begin
    if PtInRectF(Rect, PointF(FSourceCurve.X[i], FSourceCurve.Y[i])) then
      case Mode of
        smNormal, smPlus: AddPoint(Source, i, smPlus);
        smMinus,  smXor : AddPoint(Source, i, Mode);
      end;
  end;
end;

procedure TRCurveSelection.AddPoint(Source: TRCurve; I: Integer; Mode: TRSelectMode);
begin
  FSourceCurve := Source;
  if Mode = smNormal then FIndexList.Clear;

  case Mode of
   smNormal, smPlus: if FIndexList.FindIndex(I) = -1 then FIndexList.Add(I);
   smMinus: FIndexList.Remove(I);
   smXor: if FIndexList.FindIndex(I) > -1
            then FIndexList.Remove(I)
            else FIndexList.Add(I);
  end;
end;

procedure TRCurveSelection.Clear;
begin
  FSourceCurve := nil;
  FIndexList.Clear;
end;

procedure TRCurveSelection.ClearExceptFirst;
var I0: Integer;
begin
  I0 := FIndexList.First;
  FIndexList.Clear;
  FIndexList.Add(I0);
end;

function TRCurveSelection.GetIndex(I: Integer): Integer;
begin
  Result := FIndexList[I];
end;

function TRCurveSelection.SourceCurve: TRCurve;
begin
  Result := FSourceCurve;
end;

procedure TRCurveSelection.DrawMarkers(Layer: TRLayer; Mode: TRMarkerDrawMode);
var i, XX, YY: Integer;
begin
  SourceCurve.Marker.PrepareDraw(Layer, dmSelected);
  for i := Low to High do
  begin
    Layer.Converter.LogicToScreen(X[i], Y[i], XX, YY);
    SourceCurve.Marker.Draw(Layer, XX, YY, FIndexList[i], dmSelected);
  end;
end;

procedure TRCurveSelection.DrawLine(Layer: TRLayer);
begin
  // no line
end;

procedure TRCurveSelection.UndoablyRedouble(Layer: TRLayer);
var i, ii, jj, m, L: Integer;
    t: TFloat;
begin
  UndoStack(Layer.Sheet).Push(FSourceCurve.CreateUndoPoint(Layer.Sheet, Layer, [daGeometry]));

  FIndexList.Sort;
  L := Length;
  for i := 0 to L-1 do
  begin
    ii := FIndexList[i*2];
    if (ii = SourceCurve.High)and(not SourceCurve.Closed) then Break;
    SourceCurve.CalcSegmentCenter(ii, t);
    jj := SourceCurve.ActualizeIntermediatePoint(ii, t);
    for m := i*2{?} + 1 to FIndexList.Count-1 do FIndexList[m] := FIndexList[m] + 1;
    FIndexList.Insert(i*2{?}+1, jj);
  end;
end;

procedure TRCurveSelection.Rarefy(Layer: TRLayer);
var i, ii, L: Integer;
begin
  FIndexList.Sort;
  L := Length;
  ii := -1;
  for i := 0 to L-1 do
  begin
    Inc(ii);
    if i mod 2 = 1 then
    begin
      FIndexList.Delete(ii);
      Dec(ii);
    end;
  end;
  Layer.Sheet.ReadjustSelection := True; 
end;

function TRCurveSelection.CreateUndoPoint(ASheet: TRSheet; ALayer: TRLayer;
  Aspects: TDataAspects): TRUndoPoint;
begin
  Result := SourceCurve.CreateUndoPoint(ASheet, ALayer, Aspects);
end;

function TRCurveSelection.GetPopupMenu: TPopupMenu;
begin
  Result := SourceCurve.GetPopupMenu;
end;

procedure TRCurveSelection.SetPopupMenu(const Value: TPopupMenu);
begin
  // inherited;
end;

end.
