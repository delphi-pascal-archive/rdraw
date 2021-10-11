{*******************************************************************************
*                                                                              *
*                       Author: Reonid                                         *
*                       Categoty: vector graphic                               *
*                       mailto: reonid@yahoo.com                               *
*                                                                              *
*******************************************************************************}

unit RGuidLn;

interface

uses
  Classes, Graphics, Controls, Windows,
  RTypes, RCore;

type

  TOrientation = (orVertical, orHorizontal);

  TRGuideLine = class(TRFigure)
  private
    FOnChanged: TNotifyEvent;
    FOrientation: TOrientation;
    FPoint: TPointF; // One coordinate is ignored

    FColor: TColor;
    FActiveColor: TColor;

    function GetPosition: TFloat;
    procedure SetPosition(const Value: TFloat);
    procedure SetOrientation(const Value: TOrientation);
    procedure SetPoint(const Value: TPointF);
  protected
    property InternalPoint: TPointF read FPoint write SetPoint;

    procedure PrepareDraw(Layer: TRLayer; Active: Boolean); virtual;
    procedure Draw(Layer: TRLayer); override;
    procedure DrawLine(Layer: TRLayer); virtual;
    function Hit(Layer: TRLayer; Pt: TPointF; var Displacement: TPoint): Boolean;
  public
    property Color: TColor read FColor write FColor;
    property ActiveColor: TColor read FActiveColor write FActiveColor;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;

    constructor Create; override;
  published
    property Orientation: TOrientation read FOrientation write SetOrientation;
    property Position: TFloat read GetPosition write SetPosition;
  end;

  TRGuideLineController = class(TRControllerEx)
  private
    FHitDisplacement: TPoint;
  protected
    function GuideLine: TRGuideLine;

    procedure MouseDown(Layer: TRLayer; var Handled: Boolean); override;
    procedure MouseMove(Layer: TRLayer; var Cursor: TCursor); override;
    procedure MouseUp(Layer: TRLayer); override;

    procedure DecorateByTransformer(Layer: TRLayer); override;
  public
    procedure ExtraDraw(Layer: TRLayer; Reason: TRExtraDrawReason); override;
    function Agent: TRFigure; override;
  end;

implementation

const
  Sens = 5;

{-------------------------------- TRGuideLine ---------------------------------}

constructor TRGuideLine.Create;
begin
  inherited;
  Style := Style - [fsSelectable];

  FColor := clBlue;
  FActiveColor := clRed;
end;

procedure TRGuideLine.Draw(Layer: TRLayer);
begin
  PrepareDraw(Layer, False);
  DrawLine(Layer);
end;

procedure TRGuideLine.PrepareDraw(Layer: TRLayer; Active: Boolean);
begin
  if Active
    then Layer.Canvas.Pen.Color := FActiveColor
    else Layer.Canvas.Pen.Color := FColor;

  Layer.Canvas.Pen.Style := psDot;
  Layer.Canvas.Pen.Mode := pmCopy;
  Layer.Canvas.Brush.Style := bsClear;
  Layer.Canvas.Pen.Width := 1;
end;

procedure TRGuideLine.DrawLine(Layer: TRLayer);
var scrPos: TPoint;
begin
  Layer.Converter.LogicToScreen(FPoint, scrPos);
  case FOrientation of
    orVertical:
    begin
      Layer.Canvas.MoveTo(scrPos.X, Layer.Rect.Top);
      Layer.Canvas.LineTo(scrPos.X, Layer.Rect.Bottom);
    end;
    orHorizontal:
    begin
      Layer.Canvas.MoveTo(Layer.Rect.Left, scrPos.Y);
      Layer.Canvas.LineTo(Layer.Rect.Right, scrPos.Y);
    end;
  end;
end;

function TRGuideLine.GetPosition: TFloat;
begin
  Result := 0;
  case FOrientation of
    orVertical: Result := FPoint.X;
    orHorizontal: Result := FPoint.Y;
  end;
end;

function TRGuideLine.Hit(Layer: TRLayer; Pt: TPointF; var Displacement: TPoint): Boolean;
var scrPos, scrPt: TPoint;
begin
  Result := False;
  Layer.Converter.LogicToScreen(Pt, scrPt);
  Layer.Converter.LogicToScreen(FPoint, scrPos);
  case FOrientation of
    orVertical:
    begin
      Result := (Abs(scrPt.X- scrPos.X)< Sens)and
                (scrPt.Y > Layer.Rect.Top)and(scrPt.Y < Layer.Rect.Bottom);
    end;
    orHorizontal:
    begin
      Result := (Abs(scrPt.Y-scrPos.Y)< Sens)and
                (scrPt.X > Layer.Rect.Left)and(scrPt.X < Layer.Rect.Right);
    end;
  end;
  Displacement := Point(scrPos.X - scrPt.X, scrPos.Y - scrPt.Y);
end;

procedure TRGuideLine.SetPosition(const Value: TFloat);
begin
  case FOrientation of
    orVertical: FPoint.X := Value;
    orHorizontal: FPoint.Y := Value;
  end;
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

procedure TRGuideLine.SetOrientation(const Value: TOrientation);
var tmp: TFloat;
begin
  if FOrientation <> Value then
  begin
    FOrientation := Value;
    tmp := FPoint.X;
    FPoint.Y := FPoint.X;
    FPoint.X := tmp;
  end;
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

procedure TRGuideLine.SetPoint(const Value: TPointF);
begin
  FPoint := Value;
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

{------------------------- TRGuideLineController ------------------------------}

function TRGuideLineController.GuideLine: TRGuideLine;
begin
  Result := (Controllee as TRGuideLine);
end;

procedure TRGuideLineController.MouseDown(Layer: TRLayer; var Handled: Boolean);
begin
  Handled := GuideLine.Hit(Layer, Layer.CurrPt, FHitDisplacement) and
    (Layer.Sheet.MouseBtn = mbLeft);
end;

procedure TRGuideLineController.MouseMove(Layer: TRLayer;
  var Cursor: TCursor);
var logPt: TPointF;
    scrPt, d: TPoint;
begin
  if (ssLeft in Layer.Sheet.ShiftState) then
  begin
    if (csCaptured in State) then
    begin
      scrPt := Point(Layer.Sheet.CurrPt.X + FHitDisplacement.X,
        Layer.Sheet.CurrPt.Y + FHitDisplacement.Y);
      Layer.Converter.ScreenToLogic(scrPt, logPt);
      GuideLine.InternalPoint := logPt;
      Layer.Sheet.Redraw := True;
    end;
  end
  else
    if GuideLine.Hit(Layer, Layer.CurrPt, d) then
    begin
      case GuideLine.FOrientation of
        orVertical: Cursor := crSizeWE;
        orHorizontal: Cursor := crSizeNS;
      end;
    end;
end;

procedure TRGuideLineController.MouseUp(Layer: TRLayer);
begin
  {;}
end;

function TRGuideLineController.Agent: TRFigure;
begin
  Result := GuideLine;
end;

procedure TRGuideLineController.DecorateByTransformer(Layer: TRLayer);
begin
  {;}
end;

procedure TRGuideLineController.ExtraDraw(Layer: TRLayer; Reason: TRExtraDrawReason);
begin
  if Reason = drSelection then
  begin
    GuideLine.PrepareDraw(Layer, True);
    GuideLine.DrawLine(Layer);
  end;
end;

end.
