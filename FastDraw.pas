unit FastDraw;

interface

uses
  Math, Graphics,
  RTypes, RCore,
  TypId, DoubleFn, ExtAlgs;

type
  TGetDrawStepFunc = function(PointCount: Integer): Integer of object;

procedure FastDrawArray(Layer: TRLayer; const X, Y: TArrayAdapter;
  DispCoeffs: TLinearCoeffs; GetStep: TGetDrawStepFunc = nil);

var
  IdentityCoeffs: TLinearCoeffs = (C : 0; K : 1); 

implementation

procedure FastDrawArray(Layer: TRLayer; const X, Y: TArrayAdapter;
  DispCoeffs: TLinearCoeffs; GetStep: TGetDrawStepFunc = nil);
var i, step, XX, YY, Length, From, Till: Integer;
    idx: TValuePos;
    YValue: Double;
    _x, _xi, _yi, _y0, _y1, _yMin, _yMax: Integer;
    inside: Boolean;
begin
  Length := Y.Length;
  if Length = 0 then Exit; 

  _x := 0;
  _y0 := 0;
  _y1 := 0;
  _yMin := 0;
  _yMax := 0;

  BinSearch(X, Layer.ViewPort.XMin, idx);
  From := idx.I0-1;
  if From < 0 then From := 0;

  BinSearch(X, Layer.ViewPort.XMax, idx);
  Till := idx.I1+1;
  if Till >= Length then Till := Length-1;

  if Assigned(GetStep)
    then step := GetStep(Till - From + 1)
    else step := 1;

  inside := False;
  for i := From to Till do
  begin
    if i mod step <> 0 then Continue;

    {-----------}
    YValue := Y.Get(i)*DispCoeffs.K + DispCoeffs.C;
    Layer.Converter.LogicToScreen(X.Get(i), {Y.Get(i)} YValue, XX, YY);
    {-----------}

    _xi := XX;
    _yi := YY;

    if (_xi <> _x)and inside then
    begin
      Layer.Canvas.LineTo(_x, _y0);

      if (_yMax <> _y0)and(_yMax <> _y1)  then Layer.Canvas.LineTo(_x, _yMax);
      if (_yMin <> _y0)and(_yMin <> _y1)  then Layer.Canvas.LineTo(_x, _yMin);
      if (_yMin <> _yMax)                 then Layer.Canvas.LineTo(_x, _y1);

      _x := _xi;
      _y0 := _yi;
      _y1 := _yi;
      _yMin := _yi;
      _yMax := _yi;
    end;

    if (not inside) then
    begin
      inside := True;
      _x := _xi;
      _y0 := _yi;
      _y1 := _yi;
      _yMin := _yi;
      _yMax := _yi;

      Layer.Canvas.MoveTo(_xi, _yi);
    end;

    if (_xi = _x)and inside then
    begin
      _y1 := _yi;
      if _yi < _yMin then _yMin := _yi;
      if _yi > _yMax then _yMax := _yi;
    end;
  end;

  Layer.Canvas.LineTo(_x, _y0);
  if (_yMax <> _y0)and(_yMax <> _y1)  then Layer.Canvas.LineTo(_x, _yMax);
  if (_yMin <> _y0)and(_yMin <> _y1)  then Layer.Canvas.LineTo(_x, _yMin);
  if (_yMin <> _yMax)                 then Layer.Canvas.LineTo(_x, _y1);

end;

end.
