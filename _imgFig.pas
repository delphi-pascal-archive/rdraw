unit _imgFig;

interface

uses
  Classes, Graphics, Menus, JPEG,
  RCore, RTypes, RGeom, RCurve, RIntf, RUtils, RUndo;

type

  TRImage = class(TRFigure, IRectangular, {IContextPopup,} IStreamable)
  private
    FRect: TRectF;
    FPicture: TPicture;
    procedure SetPicture(const Value: TPicture);
  protected
    procedure Draw(Layer: TRLayer); override;
    {IRectangular}
    function GetRect: TRectF;
    procedure SetRect(const Value: TRectF);
    function HitTest(Layer: TRLayer; const Pt: TPointF): Boolean;
    {IPartiallyStreamable}
    procedure SaveDataToStream(Stream: TStream; Aspects: TDataAspects);
    procedure LoadDataFromStream(Stream: TStream; Aspects: TDataAspects);
  public
    property Picture: TPicture read FPicture write SetPicture; 
    property Rect: TRectF read GetRect write SetRect; 

    constructor Create; override;
    destructor Destroy; override;
    procedure UndoablyLoadFromFile(Sheet: TRSheet; const AFileName: string);
  end;

implementation

{ TRImage }

constructor TRImage.Create;
begin
  inherited;
  FPicture := TPicture.Create;
end;

destructor TRImage.Destroy;
begin
  FPicture.Free;
  inherited;
end;

procedure TRImage.Draw(Layer: TRLayer);
var R: TRect;
begin
  if Assigned(FPicture.Graphic) then
    Layer.DrawGraphic(FPicture.Graphic, FRect)
  else
  begin
    Layer.Converter.LogicToScreen(FRect, R);

    Inc(R.Right);
    Inc(R.Bottom);

    Layer.Canvas.Pen.Style := psSolid;
    Layer.Canvas.Pen.Color := clBlack;
    Layer.Canvas.Brush.Style := bsClear;
    Layer.Canvas.Rectangle(R);

    Dec(R.Right);
    Dec(R.Bottom);

    Layer.Canvas.Pen.Style := psDot;
    Layer.Canvas.MoveTo(R.Right, R.Bottom);
    Layer.Canvas.LineTo(R.Left, R.Top);
    Layer.Canvas.MoveTo(R.Right, R.Top);
    Layer.Canvas.LineTo(R.Left, R.Bottom);
  end;
end;

function TRImage.GetRect: TRectF;
begin
  Result := FRect;
end;

function TRImage.HitTest(Layer: TRLayer; const Pt: TPointF): Boolean;
begin
  Result := PtInRectF(FRect, Pt);
end;

procedure TRImage.SetPicture(const Value: TPicture);
begin
  FPicture.Assign(Value);
end;

procedure TRImage.SetRect(const Value: TRectF);
begin
  FRect := Value;
  OrientRectF(FRect);
end;

procedure TRImage.LoadDataFromStream(Stream: TStream; Aspects: TDataAspects);
var R: TRectF;
    s: string;
    g: TGraphic;
    cls: TGraphicClass;
begin
  if daGeometry in Aspects then
  begin
    Stream.ReadBuffer(R, SizeOf(R));
    SetRect(R);
  end;

  if daPicture in Aspects then
  begin
    s := ReadStringFromStream(Stream);
    if s = 'nil' then
      FPicture.Graphic := nil
    else
    begin
      cls := TGraphicClass(FindClass(s));
      Assert(cls.InheritsFrom(TGraphic));
      g := cls.Create;
      try
        //g.LoadFromStream(Stream);
        ReadGraphicsFromStream(Stream, g);
        FPicture.Graphic := g;
      finally
        g.Free;
      end;
    end;
  end;
end;

procedure TRImage.SaveDataToStream(Stream: TStream; Aspects: TDataAspects);
var R: TRectF;
begin
  if daGeometry in Aspects then
  begin
    R := GetRect;
    Stream.WriteBuffer(R, SizeOf(R));
  end;

  if daPicture in Aspects then
  begin
    if Assigned(FPicture.Graphic) then
    begin
      WriteStringToStream(Stream, FPicture.Graphic.ClassName);
      //FPicture.Graphic.SaveToStream(Stream);
      WriteGraphicsToStream(Stream, FPicture.Graphic);
    end
    else
    begin
      WriteStringToStream(Stream, 'nil');
    end;
  end;
end;

procedure TRImage.UndoablyLoadFromFile(Sheet: TRSheet; const AFileName: string);
var up: TRUndoPoint;
begin
  up := GetUndoPoint(Self, nil, nil, [daPicture]);
  FPicture.LoadFromFile(AFileName);
  UndoStack(Sheet).Push(up);
end;

initialization

  RegisterClasses([TBitmap, TIcon, TJPEGImage, TMetaFile, TIcon]);

end.
