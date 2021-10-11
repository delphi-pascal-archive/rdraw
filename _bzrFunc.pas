unit _bzrFunc;

interface

uses
  Classes, Graphics, Dialogs, Menus,

  TypId, DoubleFn, StdAlgs, ExtAlgs,

  RCore, RTypes, RIntf, RCurve, RBezier, RLine, _attr, _myBzr;

type

  TMyBezierFunction = class(TMyBezier)
  private
    function _InternalBezierLen: Integer;
    function _InternalBezierXVal(_I: Integer): Double;
  public
    function ValueAt(const X: Double): Double;
  end;

implementation

const
  N_BEZIER = 200;

function TMyBezierFunction._InternalBezierLen: Integer;
begin
  {Every segment is divided into N_BEZIER points}
  Result := (Length-1)*N_BEZIER + 1;
end;

function TMyBezierFunction._InternalBezierXVal(_I: Integer): Double;
var i: Integer;
    t: Single;
    pt: TPointF;
begin
  {Every segment is divided into N_BEZIER points}
  i := _I div N_BEZIER;
  t := (_I mod N_BEZIER)/N_BEZIER;
  pt := GetIntermediatePoint(i, t);
  Result := pt.X;
end;

function TMyBezierFunction.ValueAt(const X: Double): Double;
var idx: TValuePos;
    i: Integer;
    t: Single;
    pt: TPointF;
    aa: TArrayAdapter;
begin
  aa := ArrayAdapter(_InternalBezierLen, _InternalBezierXVal, SetMeth('*'));

  if BinSearch(aa, X, idx) then
  begin
    i := idx.I0 div N_BEZIER;
    t := (idx.I0 mod N_BEZIER + idx.t)/N_BEZIER;
    pt := GetIntermediatePoint(i, t);
    Result := pt.Y;
  end
  else
    Result := Y[idx.I0{=idx.I1} div N_BEZIER];
end;


end.
