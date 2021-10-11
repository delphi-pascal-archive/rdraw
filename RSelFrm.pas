{*******************************************************************************
*                                                                              *
*                       Author: Reonid                                         *
*                       Categoty: vector graphic                               *
*                       mailto: reonid@yahoo.com                               *
*                                                                              *
*******************************************************************************}

unit RSelFrm;

interface

uses
  {$IFDEF UNIX} {$ELSE} Windows, {$ENDIF}
  RSysDep,
  Classes, Controls, Graphics,

  RCore, RTypes, RIntf, RUndo;

const
  Sens = 3;

type
  TSide = (sdN, sdS, sdE, sdW, sdNE, sdNW, sdSE, sdSW);
  TSide8 = sdN..sdSW;

  TSide4 = sdN..sdW;
  TSideX = sdNE..sdSW;

  TSides = set of TSide;

  THitElement = (heNone, heBody, heSelObject, heCenterMarker, heResizeMarker,
    heWideBorder);

  TRSelectionFrameOption = (sfoCenterMarker,
    sfoBorderLine, sfoWideBorder, sfoResizeMarkers,
    sfoHollowBody, sfoHitSelObject,
    sfoDelayedTransform,
    sfoProportional
    {,sfoMoveAfterPress});

  TResizeMarkerLocation = (rmlOutside, rmlInside, rmlCentered);

  TRSelectionFrameOptions = set of TRSelectionFrameOption;

  TRSelectionFrameDrawData = record
    BodyRect: TRect;
    FrameRect: TRect;
    PrevTempRect: TRect;
    CurrTempRect: TRect;
    ResizeMarkers: array [TSide8] of TRect;
    WideBounds: array [TSide4] of TRect;
    CenterMarker: TRect;
    MoveElements: set of THitElement;
    DeniedMarkers: TSides;
  end;

  TRSelectionFrame = class(TRAgentDecorator)
  private
    FFrameRect: TRectF;
    FTempRect: TRectF;
    FMarkerSize: Integer;
    FOptions: TRSelectionFrameOptions;
    FMarkerLocation: TResizeMarkerLocation;

    FDrawData: TRSelectionFrameDrawData;

    procedure SetFrameRect(const Value: TRectF);
  protected
    property DrawData: TRSelectionFrameDrawData read FDrawData;

    procedure Draw(Layer: TRLayer); override;
    procedure InitDrawData(Layer: TRLayer; var Data: TRSelectionFrameDrawData); virtual;
    procedure RefreshDrawData(Layer: TRLayer);

    procedure DrawBorder(Layer: TRLayer); virtual;
    procedure DrawMarkers(Layer: TRLayer); virtual;

    function TestScale(Layer: TRLayer; R: TRectF; XC, YC, KX, KY: TFloat): Boolean;
    function DoTransform(Layer: TRLayer; var Data: TTransformData): Boolean;
  public
    //property Content: TRFigure read GetDecoree write SetDecoree;

    property FrameRect: TRectF read FFrameRect write SetFrameRect; // ??Does'nt modify the content???
    property MarkerSize: Integer read FMarkerSize write FMarkerSize;
    property Options: TRSelectionFrameOptions read FOptions write FOptions;

    constructor Create; override;

    procedure Adjust; override;
  end;

  TRSelectionFrameController = class(TRControllerEx)
  private
    FHitElement: THitElement;
    FHitResizeMarker: TSide8;
    FHitWideBoundRect: TSide4;

    FHitDisplacement: TPoint;
    FHitOppositePt: TPointF;
  protected
    function SelFrame: TRSelectionFrame;

    procedure Transmute(Layer: TRLayer);
    procedure CalcScaleCoefs(Layer: TRLayer; var KX, KY: TFloat);
    procedure HitResizeMarkerRect(Layer: TRLayer);
    procedure PutUndoPoint(Layer: TRLayer);
  public
    function HitTest(Layer: TRLayer; const Pt: TPointF): Boolean; override; 

    procedure MouseDown(Layer: TRLayer; var Handled: Boolean); override;
    procedure MouseMove(Layer: TRLayer; var Cursor: TCursor); override;
    procedure MouseUp(Layer: TRLayer); override;

    procedure KeyDown(Layer: TRLayer; var Key: Word); override;

    procedure HandleMouse(Layer: TRLayer); override;

    function Agent: TRFigure; override;

    function Supports(AObject: TObject): Boolean; override;
  end;
  
implementation

uses
  SysUtils, Math, {$IFDEF UNIX} FPCanvas, {$ENDIF}
  RGeom, RFigHlp;

var
  theChessBmp: TBitmap;
{$IFDEF UNIX}
  theChessPat: TBrushPattern;
{$ENDIF}

{------------------------------ TRSelectionFrame ------------------------------------}

constructor TRSelectionFrame.Create;
begin
  inherited;
  Style := Style + [fsServant];
  Options := Options + [sfoBorderLine, sfoResizeMarkers{, sfoProportional}];
  FMarkerSize := 10;
end;

procedure TRSelectionFrame.Draw(Layer: TRLayer);
begin
  inherited;
  RefreshDrawData(Layer);
  DrawBorder(Layer);
  DrawMarkers(Layer);
end;

procedure TRSelectionFrame.DrawBorder(Layer: TRLayer);
var i: TSide4;
    procedure FillBoundaryBand(Canvas: TCanvas; const R: TRect);
    begin
      {$IFDEF UNIX}
      Canvas.Rectangle(R);
      {$ELSE}
      PatBlt(Canvas.Handle, R.Left,R.Top, R.Right-R.Left, R.Bottom-R.Top, PATINVERT);
      {$ENDIF}
    end;
    function _Rect(const R: TRect): TRect;
    begin
      Result := R;
      Inc(Result.Right);
      Inc(Result.Bottom);
    end;
begin
  if sfoBorderLine in Options then
  begin
    Layer.Canvas.Brush.Style := bsClear;
    Layer.Canvas.Pen.Color := clBlack;
    Layer.Canvas.Pen.Style := psDot;
    Layer.Canvas.Rectangle(_Rect(DrawData.FrameRect));
  end;

  if sfoWideBorder in Options then
  begin
    {$IFDEF UNIX}
    Layer.Canvas.Brush.Style := bsPattern;
    Layer.Canvas.Brush.Color := clBlack;
    Layer.Canvas.Brush.Pattern := theChessPat;
    Layer.Canvas.Pen.Style := psClear;
    {$ELSE}
    Layer.Canvas.Brush.Style := bsClear;
    Layer.Canvas.Brush.Color := clWhite;
    Layer.Canvas.Brush.Bitmap := theChessBmp;
    {$ENDIF}

    for i := Low(TSide4) to High(TSide4) do
      FillBoundaryBand(Layer.Canvas, DrawData.WideBounds[i]);

    Layer.Canvas.Brush.Bitmap := nil;
    Layer.Canvas.Brush.Style := bsSolid;
  end;
end;

procedure TRSelectionFrame.DrawMarkers(Layer: TRLayer);
var i: TSide8;
begin
  Layer.Canvas.Brush.Style := bsSolid;
  Layer.Canvas.Brush.Color := clBlack;
  Layer.Canvas.Pen.Style := psSolid;
  Layer.Canvas.Pen.Color := clBlack;

  if sfoResizeMarkers in Options then
    for i := Low(TSide8) to High(TSide8) do
      Layer.Canvas.Rectangle(DrawData.ResizeMarkers[i]);

  if sfoCenterMarker in Options then
    with DrawData do
    begin
      Layer.Canvas.Pen.Width := 3;
      Layer.Canvas.MoveTo(CenterMarker.Left, CenterMarker.Top);
      Layer.Canvas.LineTo(CenterMarker.Right, CenterMarker.Bottom);
      Layer.Canvas.MoveTo(CenterMarker.Left, CenterMarker.Bottom);
      Layer.Canvas.LineTo(CenterMarker.Right, CenterMarker.Top);
      Layer.Canvas.Pen.Width := 1;
    end;
end;

procedure TRSelectionFrame.RefreshDrawData(Layer: TRLayer);
begin
  InitDrawData(Layer, FDrawData);
end;

procedure TRSelectionFrame.InitDrawData(Layer: TRLayer; var Data: TRSelectionFrameDrawData);
const
  Signs: array[Boolean]of Integer = (-1, 1);
var
  Rct, PrevRect: TRect;
  L, R, T, B, LL, RR, TT, BB: Integer;
  dIn, dOut: Integer;
  xSign, ySign: Integer;
begin
  Data.DeniedMarkers := [];

  PrevRect := Data.CurrTempRect;

  Layer.Converter.LogicToScreen(FTempRect, Data.CurrTempRect);
  Layer.Converter.LogicToScreen(FFrameRect, Rct);

  with Data.CurrTempRect do
    if (Left <> Right)and(Top <> Bottom) then
      Data.PrevTempRect := PrevRect;             // Avoiding scale by 0

  with Rct do
  begin
    // BodyRect

    Data.BodyRect := Rct;
    {$IFDEF FPC}
      {$IFDEF UNIX}
      if Right < Left then InflateRect(Rct, -1, 0);
      if Bottom < Top then InflateRect(Rct, 0, -1);
      {$ELSE}
      if Right < Left then InflateRect(Rct, -2, 0);
      if Bottom < Top then InflateRect(Rct, 0, -2);
      {$ENDIF}
    {$ELSE}
    {$ENDIF}

    Data.FrameRect := Rct;

    {$IFDEF FPC}
    Inc(Bottom);
    Inc(Right);
    {$ELSE}
    {$ENDIF}

    dOut := 0;
    case FMarkerLocation of
      rmlOutside: dOut := FMarkerSize;
      rmlInside:  dOut := 0;
      rmlCentered: dOut := FMarkerSize div 2;
    end;
    dIn := FMarkerSize - dOut;

    with Data.BodyRect do
    begin
      if Right = Left then Data.DeniedMarkers := Data.DeniedMarkers + [sdE, sdW, sdNE, sdNW, sdSE, sdSW];
      if Bottom = Top then Data.DeniedMarkers := Data.DeniedMarkers + [sdN, sdS, sdNE, sdNW, sdSE, sdSW];
    end;

    xSign := Signs[Right >= Left];
    ySign := Signs[Bottom >= Top];

    // Outer points
    L  := Left     - dOut * xSign;
    R  := Right    + dOut * xSign;
    T  := Top      - dOut * ySign;
    B  := Bottom   + dOut * ySign;

    // Inner points
    LL := Left     + dIn  *xSign;
    RR := Right    - dIn  *xSign;
    TT := Top      + dIn  *ySign;
    BB := Bottom   - dIn  *ySign;
    
    // ResizeMarkers
    Data.ResizeMarkers[sdNW] := Rect(L, T, LL, TT);
    Data.ResizeMarkers[sdNE] := Rect(RR, T, R, TT);
    Data.ResizeMarkers[sdSW] := Rect(L, BB, LL, B);
    Data.ResizeMarkers[sdSE] := Rect(RR, BB, R, B);

    {if sfoBoundResizer in Options then
      Data.ResizeMarkers[sdN] := Rect(LL, T,  RR, TT);
      Data.ResizeMarkers[sdS] := Rect(LL, BB, RR, B);
      Data.ResizeMarkers[sdE] := Rect(RR, TT, R, BB);
      Data.ResizeMarkers[sdW] := Rect(L,  TT, LL, BB); }

    Data.ResizeMarkers[sdN] := Rect((L + RR) div 2, T, (R + LL) div 2, TT);
    Data.ResizeMarkers[sdS] := Rect((L + RR) div 2, BB, (R + LL) div 2, B);
    Data.ResizeMarkers[sdE] := Rect(RR, (BB + T) div 2, R, (TT + B) div 2);
    Data.ResizeMarkers[sdW] := Rect(L, (BB + T) div 2, LL, (TT + B) div 2);

    // CenterMarker
    Data.CenterMarker := Rect((L + RR) div 2, (BB + T) div 2,
                              (R + LL) div 2, (TT + B) div 2);

    // WideBounds
    Data.WideBounds[sdN] := Rect(LL, T,  RR, TT);
    Data.WideBounds[sdS] := Rect(LL, BB, RR, B);
    Data.WideBounds[sdE] := Rect(RR, TT, R,  BB);
    Data.WideBounds[sdW] := Rect(L,  TT, LL, BB);

    // Appearance Correction
    if sfoBorderLine in Options then
    begin
      Inc(Data.WideBounds[sdS].Top);
      Inc(Data.WideBounds[sdE].Left);
    end;

    {$IFDEF FPC}
    Inc(Data.WideBounds[sdS].Bottom);
    Inc(Data.WideBounds[sdE].Right);
    
    if Right < Left then
    begin
      InflateRect(Rct, -2, 0);
    end;
    if Bottom < Top then
    begin
      InflateRect(Rct, 0, -2);
    end;
    {$ELSE}
    {$ENDIF}
  end;

  Data.MoveElements := [];
  if not (sfoHollowBody in Options) then Include(Data.MoveElements, heBody);
  if sfoHitSelObject in Options then Include(Data.MoveElements, heSelObject);
  if sfoCenterMarker in Options then Include(Data.MoveElements, heCenterMarker);
  if sfoWideBorder in Options then Include(Data.MoveElements, heWideBorder);
end;

function TRSelectionFrame.TestScale(Layer: TRLayer; R: TRectF; XC, YC, KX, KY: TFloat): Boolean;
var RR: TRect;
begin
  ScaleRectF(R, XC, YC, KX, KY);
  Layer.Converter.LogicToScreen(R, RR);
  Result := (  (RR.Left <> RR.Right)or(KX = 1)  )and
            (  (RR.Top <> RR.Bottom)or(KY = 1)  );
end;

function TRSelectionFrame.DoTransform(Layer: TRLayer; var Data: TTransformData): Boolean;
var oldFrameRect: TRectF;
begin
  oldFrameRect := FFrameRect;
  Result := True;

  with Data do
  begin
    case Operation of
      opTranslate: OffsetRectF(FFrameRect, DX, DY);
      opScale: ScaleRectF(FFrameRect, Center.X, Center.Y, KX, KY);
    end;

    if Operation = opScale then
      Result := TestScale(Layer, FFrameRect, Center.X, Center.Y, KX, KY);
  end;

  if Result then
    Result := TRFigureHelper(Decoree).Transform(Data);

  if not Result then
    FFrameRect := oldFrameRect;
end;

procedure TRSelectionFrame.SetFrameRect(const Value: TRectF);
begin
  FFrameRect := Value;
end;

procedure TRSelectionFrame.Adjust;
begin
  FFrameRect := TRFigureHelper(Decoree).ContainingRect;
end;

procedure TRSelectionFrameController.PutUndoPoint(Layer: TRLayer);
begin
  UndoStack(Layer.Sheet).Push(
    GetUndoPoint(SelFrame.Decoree, Layer.Sheet, Layer, [daGeometry])
  );
end;

{----------------------------- TRSelectionFrameController ---------------------------}

function TRSelectionFrameController.Agent: TRFigure;
begin
  Result := nil; // Never called
end;

procedure TRSelectionFrameController.HitResizeMarkerRect(Layer: TRLayer);
var R: TRect;
begin
  FHitOppositePt := PointF(0, 0);

  FHitDisplacement := Point(0, 0);
  R := SelFrame.DrawData.BodyRect;

  if FHitResizeMarker in [sdNE, sdE, sdSE] then begin
    FHitOppositePt.X := SelFrame.FrameRect.XMin;
    FHitDisplacement.X := Layer.Sheet.CurrPt.X - R.Right;
  end else
  if FHitResizeMarker in [sdNW, sdW, sdSW] then begin
    FHitOppositePt.X := SelFrame.FrameRect.XMax;
    FHitDisplacement.X := Layer.Sheet.CurrPt.X - R.Left;
  end;

  if FHitResizeMarker in [sdNW, sdN, sdNE] then begin
    FHitOppositePt.Y := SelFrame.FrameRect.YMin;
    FHitDisplacement.Y := Layer.Sheet.CurrPt.Y - R.Top;
  end else
  if FHitResizeMarker in [sdSW, sdS, sdSE] then begin
    FHitOppositePt.Y := SelFrame.FrameRect.YMax;
    FHitDisplacement.Y := Layer.Sheet.CurrPt.Y - R.Bottom;
  end;
end;

function TRSelectionFrameController.HitTest(Layer: TRLayer; const Pt: TPointF): Boolean;
var i: TSide8;
    scrPt: TPoint;
    DrawData: TRSelectionFrameDrawData;
begin
  SelFrame.RefreshDrawData(Layer);
  DrawData := SelFrame.DrawData;

  //Result := False;
  FHitElement := heNone;

  Layer.Converter.LogicToScreen(Pt.X, Pt.Y, scrPt.X, scrPt.Y);
  scrPt := Layer.Sheet.CurrPt;

  for i := Low(TSide8) to High(TSide8) do
    if PtInRect(DrawData.ResizeMarkers[i], scrPt)then
    begin
      if (i in DrawData.DeniedMarkers) then
      begin
        Result := True;
        Exit; 
        //Break; {Exit;}
      end;
      FHitElement := heResizeMarker;
      FHitResizeMarker := i;
      HitResizeMarkerRect(Layer);
      Break;
    end;

  if FHitElement = heNone then
  begin
    if (sfoCenterMarker in SelFrame.Options)and
        PtInRect(DrawData.CenterMarker, scrPt) then
      FHitElement := heCenterMarker
    else
    if ( sfoHollowBody in SelFrame.Options              )and
       ( sfoHitSelObject in SelFrame.Options            )and
       ( Layer.HitTest(SelFrame.Decoree, Layer.CurrPt ) )
    then
      FHitElement := heSelObject
    else
    if PtInRect(DrawData.BodyRect, scrPt) then
      FHitElement := heBody;
  end;

  if (FHitElement = heNone)and(sfoWideBorder in SelFrame.Options) then
    for i := Low(TSide4) to High(TSide4) do
      if PtInRect(DrawData.WideBounds[i], scrPt) then
      begin
        FHitElement := heWideBorder;
        FHitWideBoundRect := i;
        Break;
      end;

  Result := FHitElement <> heNone;
  if (FHitElement = heBody)and(sfoHollowBody in SelFrame.Options) then Result := False;
end;

procedure TRSelectionFrameController.HandleMouse(Layer: TRLayer);
begin
  inherited;
end;

procedure TRSelectionFrameController.MouseDown(Layer: TRLayer; var Handled: Boolean);
begin
  SelFrame.FTempRect := SelFrame.FFrameRect;
  if HitTest(Layer, Layer.CurrPt) then Handled := True;
  Layer.Sheet.Redraw := True;
end;

const
  ResizeCursors: array[TSide8] of TCursor = (crSizeNS, crSizeNS, crSizeWE, crSizeWE,
     crSizeNESW, crSizeNWSE, crSizeNWSE, crSizeNESW);

procedure TRSelectionFrameController.MouseMove(Layer: TRLayer; var Cursor: TCursor);
begin
  if ssLeft in Layer.Sheet.ShiftState then
  begin
    if Layer.SelectMode <> smNormal then Exit;
    if Layer.Sheet.PrevMouseEvent = evMouseDown then PutUndoPoint(Layer);
    Transmute(Layer);
  end
  else
  begin
    SelFrame.RefreshDrawData(Layer);   //?????????????
    if HitTest(Layer, Layer.CurrPt) then
    begin
      if FHitElement in SelFrame.DrawData.MoveElements then Cursor := crMoveObj
      else if FHitElement = heResizeMarker then Cursor := ResizeCursors[FHitResizeMarker];
    end;
  end;
end;

procedure TRSelectionFrameController.MouseUp(Layer: TRLayer);
var
  Data: TTransformData;
  XC, YC, KX, KY: TFloat;
begin
  if sfoDelayedTransform in SelFrame.Options then
    with Layer do
    begin
      if FHitElement in SelFrame.DrawData.MoveElements then
        InitTranslateData(Data, CurrPt.X-DownPt.X, CurrPt.Y-DownPt.Y)
      else
      begin
        //Layer.Converter.ScreenToLogic(FHitOppositePt.X, FHitOppositePt.Y, XC, YC);
        XC := FHitOppositePt.X;
        YC := FHitOppositePt.Y;

        CalcScaleCoefs(Layer, KX, KY);
        Assert( (KX <> 0)and(KY <> 0) );  
        InitScaleData(Data, XC, YC, KX, KY);
      end;
      SelFrame.DoTransform(Layer, Data);
    end;

  FHitElement := heNone;

  // Orient Selection Frame Rect
  SelFrame.Adjust;
  SelFrame.RefreshDrawData(Layer);  //??????????
end;

function TRSelectionFrameController.SelFrame: TRSelectionFrame;
begin
  Result := Controllee as TRSelectionFrame;
end;

procedure TRSelectionFrameController.CalcScaleCoefs(Layer: TRLayer; var KX, KY: TFloat);
const Signs: array[Boolean]of TFloat = (-1, 1);
var R: TRect;
    scrOppositePt: TPoint;
begin
  KX := 1;
  KY := 1;

  R := SelFrame.DrawData.BodyRect;

  Layer.Converter.LogicToScreen(FHitOppositePt, scrOppositePt);

  if not (FHitResizeMarker in [sdN, sdS]) then
    KX := Signs[FHitResizeMarker in [sdNE, sdE, sdSE] ]*
      (Layer.Sheet.CurrPt.X - scrOppositePt.X - FHitDisplacement.X)/(R.Right - R.Left);

  if not (FHitResizeMarker in [sdW, sdE]) then
    KY := Signs[FHitResizeMarker in [sdSW, sdS, sdSE] ]*
      (Layer.Sheet.CurrPt.Y - scrOppositePt.Y - FHitDisplacement.Y)/(R.Bottom - R.Top);

end;

procedure TRSelectionFrameController.Transmute(Layer: TRLayer);
var
  XC, YC, KX, KY, K: TFloat;
  Data: TTransformData;

  procedure DrawOrientedFocuseRect(R: TRect);
  begin
    OrientRect(R);
    {$IFDEF FPC}
    Layer.Canvas.Rectangle(R);
    {$ELSE}
    Layer.Canvas.DrawFocusRect(R);
    {$ENDIF FPC}
  end;

begin
  SelFrame.RefreshDrawData(Layer);   // !!!

  if FHitElement = heNone then Exit;  {!!!!!!!!!!!}

  with Layer do
  begin
    if FHitElement in SelFrame.DrawData.MoveElements then
    begin
      InitTranslateData(Data, CurrPt.X-PrevPt.X, CurrPt.Y-PrevPt.Y);

      if sfoDelayedTransform in SelFrame.Options
        then OffsetRectF(SelFrame.FTempRect, Data.DX, Data.DY)
        else SelFrame.DoTransform(Layer, Data);

    end
    else if FHitElement = heResizeMarker then
    begin
      XC := FHitOppositePt.X;
      YC := FHitOppositePt.Y;

      CalcScaleCoefs(Layer, KX, KY);

      if (KX <> 0)and(KY <> 0) then
      begin
        if (sfoProportional in SelFrame.Options)and
           (FHitResizeMarker in [sdNE, sdNW, sdSE, sdSW]) then
        begin
          K := Min(Abs(KX), Abs(KY));
          if KX < 0 then KX := -K else KX := K;
          if KY < 0 then KY := -K else KY := K; 
        end;

        InitScaleData(Data, XC, YC, KX, KY);

        if SelFrame.TestScale(Layer, SelFrame.FFrameRect, XC, YC, KX, KY) then
        begin
          SelFrame.FTempRect := SelFrame.FFrameRect;

          if sfoDelayedTransform in SelFrame.Options
            then ScaleRectF(SelFrame.FTempRect, XC, YC, KX, KY)
            else SelFrame.DoTransform(Layer, Data);
        end;
      end;
    end;
  end;

  Layer.Sheet.Redraw := not (sfoDelayedTransform in SelFrame.Options);

  if (sfoDelayedTransform in SelFrame.Options)and
     (Layer.Sheet.Event = evMouseMove) then
  begin
    SelFrame.RefreshDrawData(Layer); // temp rects were changed

    DrawOrientedFocuseRect(SelFrame.DrawData.PrevTempRect);
    DrawOrientedFocuseRect(SelFrame.DrawData.CurrTempRect);
  end;

end;

function TRSelectionFrameController.Supports(AObject: TObject): Boolean;
begin
  Result := AObject is TRSelectionFrame;
end;

procedure TRSelectionFrameController.KeyDown(Layer: TRLayer; var Key: Word);
var nudge, delta: TPointF;
  Data: TTransformData;
begin
  if Key in [VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN] then
  begin
    delta := PointF(0, 0);
    nudge := Layer.Nudge;

    case Key of
      VK_LEFT:  OffsetPointF(delta, -nudge.X, 0);
      VK_RIGHT: OffsetPointF(delta, nudge.X, 0);
      VK_UP:    OffsetPointF(delta, 0, nudge.Y);
      VK_DOWN:  OffsetPointF(delta, 0, -nudge.Y);
    end;

    PutUndoPoint(Layer);
    InitTranslateData(Data, delta.X, delta.Y);
    SelFrame.DoTransform(Layer, Data);
    Key := 0;
    Layer.Sheet.Redraw := True;
  end;
end;

{------------------------------------------------------------------------------}

function CreateChessBitmap: TBitmap;
const
  Pattern: array[0..3, 0..3]of Byte = (
    (1,0,0,0),
    (0,0,1,0),
    (1,0,0,0),
    (0,0,1,0)
  );

  PatColors: array[0..1]of TColor = (clBlack, clWhite);
var
  i, j: Integer;
begin
  Result := TBitmap.Create;
  Result.Width := 8;
  Result.Height := 8;
  Result.PixelFormat := pf1bit;

  for i := 0 to 7 do
    for j := 0 to 7 do
      Result.Canvas.Pixels[j, i] := PatColors[Pattern[i mod 4, j mod 4]];
end;

{$IFDEF UNIX}
function CreateChessPat: TBrushPattern;
var  i: Integer;
begin
  for i := 0 to PatternBitCount-1 do
    Result[i] := (i mod 2)*$FFFFFF;
end;
{$ENDIF}

initialization
  theChessBmp := CreateChessBitmap;
{$IFDEF UNIX}
  theChessPat := CreateChessPat;
{$ENDIF}

finalization
  theChessBmp.Free;
end.

