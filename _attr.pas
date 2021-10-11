unit _attr;

interface

uses
  Classes, Graphics,

  RTypes, RCore;

type
  TAttributeAspect = (aaPen, aaBrush, aaFont);

  TRDrawingAttributes = class;

  IDrawingAttributes = interface
  ['{B180540C-6639-402A-9234-7D841594977D}']
    function Attributes: TRDrawingAttributes;
  end;

  TRDrawingAttributes = class
  private
    FPen: TPen;
    FBrush: TBrush;
    FFont: TFont;
    procedure SetBrush(Value: TBrush);
    procedure SetFont(Value: TFont);
    procedure SetPen(Value: TPen);
  public
    property Pen: TPen read FPen write SetPen;
    property Brush: TBrush read FBrush write SetBrush;
    property Font: TFont read FFont write SetFont;

    procedure Apply(Layer: TRLayer); //virtual;
    procedure SaveToStream(Stream: TStream);
    procedure LoadFromStream(Stream: TStream);

    constructor Create;
    destructor Destroy; override;
  end;

  function GetAttrColor(Attr: IDrawingAttributes; Aspect: TAttributeAspect): TColor;
  procedure SetAttrColor(Attr: IDrawingAttributes; Aspect: TAttributeAspect; Color: TColor);

implementation

{-------------------------- TRDrawingAttributes -------------------------------}

procedure TRDrawingAttributes.Apply(Layer: TRLayer);
begin
  Layer.Canvas.Brush.Assign(FBrush);
  Layer.Canvas.Pen.Assign(FPen);
  Layer.Canvas.Font.Assign(FFont);
end;

constructor TRDrawingAttributes.Create;
begin
  inherited;
  FPen := TPen.Create;
  FBrush := TBrush.Create;
  FFont := TFont.Create;
end;

destructor TRDrawingAttributes.Destroy;
begin
  FPen.Free;
  FBrush.Free;
  FFont.Free;
  inherited;
end;

procedure TRDrawingAttributes.SaveToStream(Stream: TStream);
var cl: TColor;
    pm: TPenMode;
    ps: TPenStyle;
    bs: TBrushStyle;
    n: Integer;
    fs: TFontStyles;
    fp: TFontPitch;
    fc: TFontCharset;
    s: string;
begin
  cl := FBrush.Color;      Stream.WriteBuffer(cl, SizeOf(cl));
  bs := FBrush.Style;      Stream.WriteBuffer(bs, SizeOf(bs));

  cl := FPen.Color;        Stream.WriteBuffer(cl, SizeOf(cl));
  ps := FPen.Style;        Stream.WriteBuffer(ps, SizeOf(ps));
  pm := FPen.Mode;         Stream.WriteBuffer(pm, SizeOf(pm));
  n := FPen.Width;         Stream.WriteBuffer(n, SizeOf(n));

  cl := FFont.Color;       Stream.WriteBuffer(cl, SizeOf(cl));
  fs := FFont.Style;       Stream.WriteBuffer(fs, SizeOf(fs));
  fc := FFont.Charset;     Stream.WriteBuffer(fc, SizeOf(fc));
  n := FFont.Height;       Stream.WriteBuffer(n, SizeOf(n));
  n := FFont.Size;         Stream.WriteBuffer(n, SizeOf(n));
  fp := FFont.Pitch;       Stream.WriteBuffer(fp, SizeOf(fp));
  n := Length(FFont.Name); Stream.WriteBuffer(n, SizeOf(n));
  s := FFont.Name;         Stream.WriteBuffer(s[1], n);
end;

procedure TRDrawingAttributes.LoadFromStream(Stream: TStream);
var cl: TColor;
    pm: TPenMode;
    ps: TPenStyle;
    bs: TBrushStyle;
    n: Integer;
    fs: TFontStyles;
    fp: TFontPitch;
    fc: TFontCharset;
    s: string;
begin
  Stream.ReadBuffer(cl, SizeOf(cl));   FBrush.Color := cl;
  Stream.ReadBuffer(bs, SizeOf(bs));   FBrush.Style := bs;

  Stream.ReadBuffer(cl, SizeOf(cl));   FPen.Color := cl;
  Stream.ReadBuffer(ps, SizeOf(ps));   FPen.Style := ps;
  Stream.ReadBuffer(pm, SizeOf(pm));   FPen.Mode := pm;
  Stream.ReadBuffer(n, SizeOf(n));     FPen.Width := n;

  Stream.ReadBuffer(cl, SizeOf(cl));   FFont.Color := cl;
  Stream.ReadBuffer(fs, SizeOf(fs));   FFont.Style := fs;
  Stream.ReadBuffer(fc, SizeOf(fs));   FFont.Charset := fc;
  Stream.ReadBuffer(n, SizeOf(n));     FFont.Height := n;
  Stream.ReadBuffer(n, SizeOf(n));     FFont.Size := n;
  Stream.ReadBuffer(fp, SizeOf(fp));   FFont.Pitch := fp;
  Stream.ReadBuffer(n, SizeOf(n));     SetLength(s, n);
  Stream.ReadBuffer(s[1], n);          FFont.Name := s;
end;

procedure TRDrawingAttributes.SetBrush(Value: TBrush);
begin
  if FBrush <> Value then
  begin
    FBrush.Assign(Value);
  end;
end;

procedure TRDrawingAttributes.SetFont(Value: TFont);
begin
  if FFont <> Value then
  begin
    FFont.Assign(Value);
  end;
end;

procedure TRDrawingAttributes.SetPen(Value: TPen);
begin
  if FPen <> Value then
  begin
    FPen.Assign(Value);
  end;
end;

{------------------------------------------------------------------------------}

function GetAttrColor(Attr: IDrawingAttributes; Aspect: TAttributeAspect): TColor;
begin
  Result := clWhite;
  if not Assigned(Attr) then Exit;

  case Aspect of
    aaPen: Result := Attr.Attributes.Pen.Color;
    aaBrush: Result := Attr.Attributes.Brush.Color;
    aaFont: Result := Attr.Attributes.Font.Color;
  end;
end;

procedure SetAttrColor(Attr: IDrawingAttributes; Aspect: TAttributeAspect; Color: TColor);
begin
  case Aspect of
    aaPen: Attr.Attributes.Pen.Color := Color;
    aaBrush: Attr.Attributes.Brush.Color := Color;
    aaFont: Attr.Attributes.Font.Color := Color;
  end;
end;

end.

