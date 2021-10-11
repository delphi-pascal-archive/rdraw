{*******************************************************************************
*                                                                              *
*                       Author: Reonid                                         *
*                       Categoty: vector graphic                               *
*                       mailto: reonid@yahoo.com                               *
*                                                                              *
*******************************************************************************}

unit RBzrUtils;

interface

uses
  Classes, RTypes, RCore, RGeom, RBezier;

type
  TDynArrayOfTPointF = array of TPointF;
  TDynArrayOfDouble = array of Double;

function GetBezierTotalLength(Bzr: TRBezier): Double;
function ConvertBezierToArray(Bzr: TRBezier; Step: Double): TDynArrayOfTPointF;

function BezierValuesAt(Bzr: TRBezier; Position: Double; Coord: Char): TDynArrayOfDouble;

implementation

const
  BEZIER_ACCURACY = 2000;

function GetBezierTotalLength(Bzr: TRBezier): Double;
var i, j, N: Integer;
    h: Double;
    pt0, pt1: TPointF;
begin
  N := BEZIER_ACCURACY;
  h := 1/N;

  Result := 0;

  pt1 := Bzr.GetIntermediatePoint(0, 0);

  for i := Bzr.Low to Bzr.High + Integer(Bzr.Closed)-1 do
    for j := 1{!} to N do
    begin
      pt0 := pt1;
      pt1 := Bzr.GetIntermediatePoint(i, j*h);

      Result := Result + DistanceF(pt0, pt1);
    end;
end;

function ConvertBezierToArray(Bzr: TRBezier; Step: Double): TDynArrayOfTPointF;
var i, j, k, N: Integer;
    h, L, D, u: Double;
    pt, pt0, pt1: TPointF;

    procedure Add(const Pt: TPointF);
    var M: Integer;
    begin
      M := Length(Result);
      SetLength(Result, M+1);
      Result[M] := Pt;
    end;

begin
  SetLength(Result, 0);

  N := BEZIER_ACCURACY;
  h := 1/N;

  k := 0;
  L := 0;

  pt1 := Bzr.GetIntermediatePoint(0, 0);

  Add(pt1); {Step*0}
  Inc(k);

  for i := Bzr.Low to Bzr.High + Integer(Bzr.Closed)-1 do
    for j := 1{!} to N do
    begin
      pt0 := pt1;
      pt1 := Bzr.GetIntermediatePoint(i, j*h);

      D := DistanceF(pt0, pt1);
      L := L + D;

      if L >= Step*k then
      begin
        u := ( Step*k - (L-D) )/D;

        pt.X := u*pt1.X + (1-u)*pt0.X;
        pt.Y := u*pt1.Y + (1-u)*pt0.Y;

        Add(pt);
        Inc(k);
      end;
    end;
end;

function BezierValuesAt(Bzr: TRBezier; Position: Double; Coord: Char): TDynArrayOfDouble;
var i, j, N: Integer;
    h, L, D, u, z: Double;
    pt, pt0, pt1, d10, d0, d1: TPointF;
    b, skipNext: Boolean;

    procedure Add(const V: Double);
    var M: Integer;
    begin
      M := Length(Result);
      SetLength(Result, M+1);
      Result[M] := V;
    end;

begin
  SetLength(Result, 0);

  N := BEZIER_ACCURACY;
  h := 1/N;
  skipNext := False;

  L := 0;

  pt1 := Bzr.GetIntermediatePoint(0, 0);

  for i := Bzr.Low to Bzr.High + Integer(Bzr.Closed)-1 do
    for j := 1{!} to N do
    begin
      pt0 := pt1;
      pt1 := Bzr.GetIntermediatePoint(i, j*h);

      if skipNext then
      begin
        skipNext := False;
        Continue;
      end;

      d0 := PointF(pt0.X - Position, pt0.Y - Position);
      d1 := PointF(pt1.X - Position, pt1.Y - Position);
      d10  := PointF(pt1.X - pt0.X, pt1.Y - pt0.Y);

      case Coord of
        'x', 'X': z := d0.X*d1.X;
        'y', 'Y': z := d0.Y*d1.Y;
      end;

      b := (z <= 0);
      if z = 0 then skipNext := True; 

      if b then
      begin
        case Coord of
          'x', 'X': u := -d0.X/d10.X;
          'y', 'Y': u := -d0.Y/d10.Y;
        end;

        pt.X := u*pt1.X + (1-u)*pt0.X;
        pt.Y := u*pt1.Y + (1-u)*pt0.Y;

        case Coord of
          'x', 'X': Add(pt.Y);
          'y', 'Y': Add(pt.X);
        end;
      end;
    end;
end;

end.

