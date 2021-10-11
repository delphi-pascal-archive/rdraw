unit _legend;

interface

uses
  Classes, Graphics, Controls, Windows,
  RTypes, RCore, RGeom, RGroup, RCurve, RFigHlp;

type
  ISimpleScreenFigure = interface
  ['{6054296B-498D-4903-BA09-E2DE28F0310F}']
    //function GetRect(Layer: TRLayer): TRect;
    function HitTest(Layer: TRLayer; const Pt: TPoint): Boolean;
    procedure Translate(Layer: TRLayer; DX, DY: Integer);
  end;

  TRLegendController = class(TRController)
  private
    FCaptured: Boolean;
  protected
    procedure Transmute(Layer: TRLayer); virtual;
  public
    procedure HandleMouse(Layer: TRLayer); override;
    procedure HandleKbd(Layer: TRLayer); override;

    function Supports(Figure: TObject): Boolean; override;

    function Agent: TRFigure; override;
    procedure DecorateByTransformer(Layer: TRLayer); override;
  end;

  TRSeriesLegends = class(TRFigure, ISimpleScreenFigure)
  private
    FSeriesList: TRGroup;
    FOrgPoint: TPoint;
    procedure _AccomodatePen(Layer: TRLayer);
    procedure _AccomodateFont(Layer: TRLayer);
    procedure _AccomodatePos(Layer: TRLayer; var OrgPt: TPoint);
    procedure _AccomodateSize(Layer: TRLayer; var ASize: Integer; Coord: Char);
  protected
    property OrgPoint: TPoint read FOrgPoint write FOrgPoint;
    procedure Draw(Layer: TRLayer); override;
    function GetRect(Layer: TRLayer): TRect;
    {ISimpleScreenFigure}
    function HitTest(Layer: TRLayer; const Pt: TPoint): Boolean;
    procedure Translate(Layer: TRLayer; DX, DY: Integer);
  public
    property SeriesList: TRGroup read FSeriesList write FSeriesList;  
  end;

implementation

uses
  Math, 
  _attr;

{----------------------------- TRLegendController -----------------------------}

procedure TRLegendController.HandleMouse(Layer: TRLayer);
var obj: ISimpleScreenFigure;
    inside: Boolean;
begin
  Controllee.GetInterface(ISimpleScreenFigure, obj);
  inside := obj.HitTest(Layer, Layer.Sheet.CurrPt);
  case Layer.Sheet.Event of
    evMouseDown:
    begin
      FCaptured := inside;
      Layer.Sheet.EventHandled := FCaptured;
    end;
    evMouseMove:
    begin
      if not ( Layer.Sheet.LBtnDown or Layer.Sheet.RBtnDown ) then
        if inside then Layer.Sheet.Cursor := crMoveObj; 

      if (FCaptured)and(ssLeft in Layer.Sheet.ShiftState) then
        Transmute(Layer);
    end;
    evMouseUp: FCaptured := False;
  end;
end;

procedure TRLegendController.Transmute(Layer: TRLayer);
var obj: ISimpleScreenFigure;
begin
  Controllee.GetInterface(ISimpleScreenFigure, obj);
  with Layer.Sheet do
    obj.Translate(Layer, CurrPt.X - PrevPt.X, CurrPt.Y - PrevPt.y);
  Layer.Sheet.Redraw := True;
end;

procedure TRLegendController.HandleKbd(Layer: TRLayer);
begin
  {*}
end;

procedure TRLegendController.DecorateByTransformer(Layer: TRLayer);
begin
  {}
end;

function TRLegendController.Agent: TRFigure;
begin
  Result := Controllee;
end;

function TRLegendController.Supports(Figure: TObject): Boolean;
var obj: IUnknown;
begin
  Result := Figure.GetInterface(ISimpleScreenFigure, obj);
end;

{------------------------------------------------------------------------------}

function GetLineColor(Curve: TRCurve): TColor;
var _attr: IDrawingAttributes;
begin
  Result := clBlack;
  if Curve.GetInterface(IDrawingAttributes, _attr) then
    Result := _attr.Attributes.Pen.Color;
end;

procedure TRSeriesLegends.Draw(Layer: TRLayer);
var i, k, h, line_w, dy, dy2: Integer;
    ser: TRCurve;
    R, rr: TRect;
    org, gap: TPoint;
    serColor, bgColor: TColor;
    serName: string;
begin
  org := FOrgPoint;
  _AccomodatePos(Layer, org);

  Layer.Canvas.Font.Size := 8;
  Layer.Canvas.Font.Color := clBlack;
  _AccomodateFont(Layer);

  h := Layer.Canvas.TextHeight('0');
  R := GetRect(Layer);

  bgColor := RGB(250, 250, 250);//clWindow; //clWhite;
  Layer.Canvas.Brush.Color := bgColor;
  Layer.Canvas.Brush.Style := bsSolid;

  Layer.Canvas.Pen.Width := 1;
  Layer.Canvas.Pen.Color := clBlack;
  Layer.Canvas.Pen.Style := psSolid;
  Layer.Canvas.Pen.Mode := pmCopy;
  _AccomodatePen(Layer);

  Layer.Canvas.Rectangle(R);

  gap := Point(3, 4);
  _AccomodateSize(Layer, gap.X, 'x');
  _AccomodateSize(Layer, gap.Y, 'y');

  dy := 3;
  _AccomodateSize(Layer, dy, 'y');

  dy2 := 2;
  _AccomodateSize(Layer, dy2, 'y');

  line_w := 40;
  _AccomodateSize(Layer, line_w, 'x');

  InflateRect(R, -1, -1);
  k := 0;
  for i := FSeriesList.Count-1 downto 0 do
  begin
    if not (FSeriesList[i] is TRCurve) then Continue;

    ser := FSeriesList[i] as TRCurve;
    serColor := GetLineColor(ser);
    serName := TRFigureHelper(ser).GetName;

    rr := Rect(
      org.x + gap.x,
      org.y + (h + gap.y)*k,
      org.x + (line_w - gap.x),
      org.y + (h + gap.y)*k + h
    );

    OffsetRect(rr, 0, dy);
    ser.DrawSample(Layer, rr);

    Layer.Canvas.Brush.Color := bgColor;
    Layer.Canvas.Font.Color := serColor;
    Layer.Canvas.Font.Size := 8;
    _AccomodateFont(Layer);

    Layer.Canvas.TextOut(
      org.x + line_w,
      org.y+(h+gap.y)*k + dy2,
      serName
    );

    Inc(k);
  end;
end;

function TRSeriesLegends.GetRect(Layer: TRLayer): TRect;
var i, h, wi, ww, x_gap, y_gap, line_w: Integer;
    org: TPoint;
    serName: string;
begin
  Layer.Canvas.Font.Size := 8;
  _AccomodateFont(Layer);

  org := OrgPoint;
  _AccomodatePos(Layer, org);

  x_gap := 4;
  _AccomodateSize(Layer, x_gap, 'x');

  y_gap := 4;
  _AccomodateSize(Layer, y_gap, 'y');


  h := Layer.Canvas.TextHeight('0');
  Result.TopLeft := org;
  Result.Bottom := Result.Top;


  ww := 0;
  for i := 0 to FSeriesList.Count-1 do
  begin
    if not (FSeriesList[i] is TRCurve) then Continue;

    Result.Bottom := Result.Bottom + (h + y_gap);
    serName := TRFigureHelper(FSeriesList[i]).GetName;
    wi := Layer.Canvas.TextWidth(serName) + x_gap;
    if wi > ww then ww := wi;
  end;

  line_w := 41;
  _AccomodateSize(Layer, line_w, 'x');
  Result.Right := Result.Left + ww + line_w;
end;

function TRSeriesLegends.HitTest(Layer: TRLayer; const Pt: TPoint): Boolean;
var R: TRect;
begin
  R := GetRect(Layer);
  Result := PtInRect(R, Pt);
end;

procedure TRSeriesLegends.Translate(Layer: TRLayer; DX, DY: Integer);
var R: TRect;
begin
  Inc(FOrgPoint.X, DX);
  Inc(FOrgPoint.Y, DY);

  R := GetRect(Layer);
  ConfineRectInRect(R,Layer.Sheet.Rect);

  FOrgPoint := R.TopLeft;
end;

procedure TRSeriesLegends._AccomodatePen(Layer: TRLayer);
begin
  if Layer.Printing then
    with Layer.Canvas.Pen do
      Width := Round(  Width * MinPtCoordF(Layer.Sheet.PrintData.PixelScale)  );
end;

procedure TRSeriesLegends._AccomodateFont(Layer: TRLayer);
begin
  if Layer.Printing then
    with Layer.Canvas.Font do
      Height := Round(  Height * MinPtCoordF(Layer.Sheet.PrintData.FontScale)  );
end;

procedure TRSeriesLegends._AccomodatePos(Layer: TRLayer; var OrgPt: TPoint);
begin
  if Layer.Printing then
  begin
    OrgPt.X := Round(OrgPt.X*Layer.Sheet.PrintData.RectScale.X);
    OrgPt.Y := Round(OrgPt.Y*Layer.Sheet.PrintData.RectScale.Y);

    OrgPt.X := OrgPt.X + Layer.Sheet.PrintRect.Left;
    OrgPt.Y := OrgPt.Y + Layer.Sheet.PrintRect.Top;
  end;
end;

procedure TRSeriesLegends._AccomodateSize(Layer: TRLayer; var ASize: Integer; Coord: Char);
begin
  if Layer.Printing then
    case Coord of
      'X', 'x': ASize := Round(ASize*Layer.Sheet.PrintData.RectScale.X);
      'Y', 'y': ASize := Round(ASize*Layer.Sheet.PrintData.RectScale.Y);
    end;
end;

end.
