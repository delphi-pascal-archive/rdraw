{*******************************************************************************
*                                                                              *
*                       Author: Reonid                                         *
*                       Categoty: vector graphic                               *
*                       mailto: reonid@yahoo.com                               *
*                                                                              *
*******************************************************************************}

unit RZoom;

interface

uses
  RTypes, RCore,


  {$IFDEF UNIX} {$ELSE} Windows, {$ENDIF}
  RSysDep,
  Messages, Classes, Graphics, Controls, Forms;

type
  TRZoomEvent = procedure(Layer: TRLayer; var NewViewPort: TRectF) of object;

  TZoomToolOption = (ztoXScroll, ztoYScroll, ztoZoomOut);
  TZoomToolOptions = set of TZoomToolOption;

  TRZoomTool = class(TRTool)
  private
    FOnZoomOut: TRZoomEvent;
    FOnZoom: TRZoomEvent;
    FOptions: TZoomToolOptions;
    //FTeeChartMode: Boolean;
  protected
    procedure DrawSelRect(Sheet: TRSheet; const Rect: TRect;
      const FirstPt, SecondPt: TPoint); virtual;
    procedure DoDrawSelRect(Sheet: TRSheet);
    procedure ForceCursor(Sheet: TRSheet; Cursor: TCursor; Pressing: Boolean);
    procedure Zoom(Layer: TRLayer);
    procedure DoZoomChanged(Layer: TRLayer; var ViewPort: TRectF); virtual;
    procedure DoZoomOut(Layer: TRLayer; var ViewPort: TRectF); virtual;
  public
    property Options: TZoomToolOptions read FOptions write FOptions;
    property OnZoomOut: TRZoomEvent read FOnZoomOut write FOnZoomOut;
    property OnZoom: TRZoomEvent read FOnZoom write FOnZoom;

    constructor Create(AName: string); override;

    function Filter(Figure: TRFigure): Boolean; override;
    function KeepActiveFigure(Sheet: TRSheet): Boolean; override;
    procedure BeginHandleMouse(Sheet: TRSheet; var Handled: Boolean); override;
    procedure EndHandleMouse(Sheet: TRSheet); override;
    procedure HandleKbd(Sheet: TRSheet); override;
    procedure ProcessLayer(Layer: TRLayer); override;

    procedure ZoomOut(Layer: TRLayer);
  end;

function ZoomTool: TRZoomTool;

implementation

uses
  RGeom;

var
  theZoomTool: TRZoomTool;

function ZoomTool: TRZoomTool;
begin
  if theZoomTool= nil then
    theZoomTool := TRZoomTool.Create('Zoom');
  Result := theZoomTool;
end;

{------------------------------ TRZoomTool ------------------------------------}

constructor TRZoomTool.Create(AName: string);
begin
  inherited;
  //FTeeChartMode := True;
  FOptions := [ztoXScroll, ztoYScroll, ztoZoomOut];
end;

procedure TRZoomTool.DoDrawSelRect(Sheet: TRSheet);
begin
  Sheet.Canvas.Pen.Style := psDot;
  Sheet.Canvas.Brush.Style := bsClear;
  XORDraw(Sheet, DrawSelRect, pmNot);
end;

procedure TRZoomTool.BeginHandleMouse(Sheet: TRSheet; var Handled: Boolean);
begin
  if Sheet.Event = evMouseDown then
    Sheet.AllowSelectRect := True;

  if (Sheet.Event = evMouseDown)and
     (Sheet.MouseBtn = mbRight) then
    ForceCursor(Sheet, crZoomHand, False);

  if Sheet.Event = evMouseUp then
    ForceCursor(Sheet, crDefault, True{!});
end;

procedure TRZoomTool.EndHandleMouse(Sheet: TRSheet);
begin
  if (Sheet.Event = evMouseMove) and
     (Sheet.AllowSelectRect) and (ssLeft in Sheet.ShiftState) then
  begin
    DoDrawSelRect(Sheet);
  end;
end;

function TRZoomTool.Filter(Figure: TRFigure): Boolean;
begin
  Result := False;
end;

procedure TRZoomTool.HandleKbd(Sheet: TRSheet);
begin
end;

function TRZoomTool.KeepActiveFigure(Sheet: TRSheet): Boolean;
begin
  Result := True;
end;

procedure TRZoomTool.ProcessLayer(Layer: TRLayer);
begin
  Zoom(Layer);
end;

procedure TRZoomTool.DoZoomChanged(Layer: TRLayer; var ViewPort: TRectF);
begin
  if Assigned(FOnZoom) then FOnZoom(Layer, ViewPort);
end;

procedure TRZoomTool.DoZoomOut(Layer: TRLayer; var ViewPort: TRectF);
begin
  if Assigned(FOnZoomOut) then FOnZoomOut(Layer, ViewPort);
  //Layer.ViewPort := ViewPort;
  DoZoomChanged(Layer, ViewPort);
end;

procedure TRZoomTool.Zoom(Layer: TRLayer);
var R: TRectF;
  Curr, Prev, D: TPointF;
begin
  if Assigned(Layer.Sheet.WorkingLayer)and(Layer <> Layer.Sheet.WorkingLayer) then Exit;
  if (Layer = nil) then Exit;

  case Layer.Sheet.Event of
    evMouseDown:{*};
    evMouseMove:
      if (  ssRight in Layer.Sheet.ShiftState       )and {FTeeChartMode}
         ( [ztoXScroll, ztoYScroll]*FOptions <> []  ) then
      begin
        R := Layer.ViewPort;
        Layer.Converter.ScreenToLogic(Layer.Sheet.CurrPt, Curr);
        Layer.Converter.ScreenToLogic(Layer.Sheet.PrevPt, Prev);

        D.X := -Curr.X + Prev.X;  if not (ztoXScroll in FOptions) then D.X := 0;
        D.Y := -Curr.Y + Prev.Y;  if not (ztoYScroll in FOptions) then D.Y := 0;

        OffsetRectF(R, D.X, D.Y);
        DoZoomChanged(Layer, R);
        Layer.ViewPort := R;
        Layer.Sheet.Redraw := True;
      end
      else if ssLeft in Layer.Sheet.ShiftState then
      begin
        R := CalcSelRectF(Layer.DownPt, Layer.CurrPt, False);

        if (  ztoZoomOut in FOptions                )and  //( FTeeChartMode )and
           (  (R.XMin > R.XMax)or(R.YMin < R.YMax)  )
          then ForceCursor(Layer.Sheet, crZoomOut, False)
          else ForceCursor(Layer.Sheet, crZoomIn, False);

      end;
    evMouseUp:
      if Layer.Sheet.MouseBtn = mbLeft then
      begin
        R := CalcSelRectF(Layer.DownPt, Layer.CurrPt, False);

        if (Abs(Layer.Sheet.DownPt.X - Layer.Sheet.CurrPt.X) < 8) or
           (Abs(Layer.Sheet.DownPt.Y - Layer.Sheet.CurrPt.Y) < 8) then Exit;

        if (  ztoZoomOut in FOptions                )and  //( FTeeChartMode )and
           //(  (R.XMin > R.XMax)or(R.YMin < R.YMax)  )
           (
              (Layer.Sheet.DownPt.X > Layer.Sheet.CurrPt.X)or
              (Layer.Sheet.DownPt.Y > Layer.Sheet.CurrPt.Y)
           )
        then
        begin
          R := Layer.ViewPort;
          DoZoomOut(Layer, R);
          Layer.ViewPort := R;
        end
        else
        begin
          OrientRectF(R);
          DoZoomChanged(Layer, R);
          Layer.ViewPort := R;
        end;

        Layer.Sheet.Redraw := True;
      end;
    evKeyDown:
      if {True} (ssCtrl in Layer.Sheet.ShiftState) then
      begin
        case Layer.Sheet.Key of
          VK_ADD: begin
            R := Layer.ViewPort;
            InflateRectF(R, -(R.XMax - R.XMin)/8, -(R.YMax - R.YMin)/8);
            DoZoomChanged(Layer, R);
            Layer.ViewPort := R;
          end;
          VK_SUBTRACT: begin
            R := Layer.ViewPort;
            InflateRectF(R, (R.XMax - R.XMin)/6, (R.YMax - R.YMin)/6);
            DoZoomChanged(Layer, R);
            Layer.ViewPort := R;
          end;
        end;
        Layer.Sheet.Redraw := True;
      end;
  end;
end;

procedure TRZoomTool.DrawSelRect(Sheet: TRSheet; const Rect: TRect;
  const FirstPt, SecondPt: TPoint);
begin
  Sheet.Canvas.Rectangle(Rect);
end;

procedure TRZoomTool.ForceCursor(Sheet: TRSheet; Cursor: TCursor; Pressing: Boolean);
begin
  Sheet.Cursor := Cursor;
  if Pressing then Sheet.Dest.Cursor := Cursor;
  Screen.Cursor := Cursor;
end;

procedure TRZoomTool.ZoomOut(Layer: TRLayer);
var R: TRectF;
begin
  DoZoomOut(Layer, R);
  Layer.ViewPort := R;
end;

initialization
finalization
  theZoomTool.Free;
end.
