{*******************************************************************************
*                                                                              *
*                       Author: Reonid                                         *
*                       Categoty: vector graphic                               *
*                       mailto: reonid@yahoo.com                               *
*                                                                              *
*******************************************************************************}

unit RGeom;

interface

uses
  {$IFDEF UNIX} {$ELSE} Windows, {$ENDIF}
  Classes,
  RTypes;

procedure OrientRect(var Rect: TRect);
procedure OrientRectF(var Rect: TRectF);
function  CalcSelRect(const P1, P2: TPoint; Oriented: Boolean = True): TRect;
function  CalcSelRectF(const P1, P2: TPointF; Oriented: Boolean = True): TRectF;

{$IFDEF UNIX}
procedure OffsetRect(var Rect: TRect; DX, DY: Integer);
procedure InflateRect(var Rect: TRect; DX, DY: Integer);
function IntersectRect(var Rect: TRect; const R1, R2: TRect): Boolean;
function PtInRect(const Rect: TRect; const Pt: TPoint): Boolean;
{$ENDIF}
procedure OffsetRectF(var Rect: TRectF; DX, DY: TFloat);
procedure ScaleRectF(var Rect: TRectF; XC, YC, KX, KY: TFloat);
procedure InflateRectF(var Rect: TRectF; DX, DY: TFloat);

function PtInRectF(const Rect: TRectF; const Pt: TPointF): Boolean;
function RectInRectF(const Rout, Rin: TRectF): Boolean;
function UnionRectF(const R1, R2: TRectF): TRectF;

function RectWidth(const Rect: TRect): Integer;
function RectHeight(const Rect: TRect): Integer;
function RectWidthF(const Rect: TRectF): TFloat;
function RectHeightF(const Rect: TRectF): TFloat;

function PtInLine(X, Y, X0, Y0, X1, Y1, Sens: Integer; var param01: TFloat): Boolean;
function PtInPolygonF(const P: array of TPointF; const Pt: TPointF): Boolean;

function Distance(const p1, p2: TPoint): TFloat;
function Scalar(const pt: TPoint): TFloat;
function DistanceF(const p1, p2: TPointF): TFloat; overload;
function DistanceF(const p1, p2: TPointF; AspectRatio: TFloat): TFloat; overload;
function DifferenceF(const p1, p2: TPointF): TPointF;
function ScalarF(const pt: TPointF): TFloat;

function PointRect(const pt: TPoint; dx, dy: Integer): TRect; overload;
function PointRect(x, y, dx, dy: Integer): TRect; overload;
function PointRectF(const pt: TPointF; dx, dy: TFloat): TRectF; overload;
function PointRectF(x, y, dx, dy: TFloat): TRectF; overload;

procedure OffsetPoint(var pt: TPoint; dx, dy: Integer);
procedure OffsetPointF(var pt: TPointF; dx, dy: TFloat);

procedure ConfineRectInRect(var InnerR: TRect; const OuterR: TRect);
procedure ConfineRectInRectF(var InnerR: TRectF; const OuterR: TRectF);

function RectCenter(const R: TRect): TPoint;
function RectCenterF(const R: TRectF): TPointF;

function CircumscribedRect(const Pts: array of TPoint): TRect;
function CircumscribedRectF(const Pts: array of TPointF): TRectF;

function ProportionalRectF(const MasterRect: TRect; const R: TRectF; LockedCoord: Char): TRectF;

implementation

uses
  Math;

procedure OrientRect(var Rect: TRect);
    procedure Swap(var A, B: Integer);
    var tmp: Integer;
    begin
      tmp := A; A := B; B := tmp;
    end;
begin
  if Rect.Left > Rect.Right then Swap(Rect.Left, Rect.Right);
  if Rect.Top > Rect.Bottom then Swap(Rect.Top, Rect.Bottom);
end;

procedure OrientRectF(var Rect: TRectF);
    procedure Swap(var A, B: TFloat);
    var tmp: TFloat;
    begin
      tmp := A; A := B; B := tmp;
    end;
begin
  if Rect.XMin > Rect.XMax then Swap(Rect.XMin, Rect.XMax);
  if Rect.YMin > Rect.YMax then Swap(Rect.YMin, Rect.YMax);
end;

function CalcSelRect(const P1, P2: TPoint; Oriented: Boolean = True): TRect;
begin
  Result := Rect(P1.X, P1.Y, P2.X, P2.Y);
  if Oriented then OrientRect(Result);
end;

function CalcSelRectF(const P1, P2: TPointF; Oriented: Boolean = True): TRectF;
begin
  Result := RectF(P1.X, P1.Y, P2.X, P2.Y);
  if Oriented then OrientRectF(Result);
end;

{$IFDEF UNIX}
procedure OffsetRect(var Rect: TRect; DX, DY: Integer);
begin
  with Rect do
  begin
    Left   := Left + DX;
    Right  := Right + DX;
    Top    := Top + DY;
    Bottom := Bottom + DY;
  end;
end;

procedure InflateRect(var Rect: TRect; DX, DY: Integer);
begin
  with Rect do
  begin
    Left   := Left - DX;
    Right  := Right + DX;
    Top    := Top - DY;
    Bottom := Bottom + DY;
  end;
end;

function IntersectRect(var Rect: TRect; const R1, R2: TRect): Boolean;
    function _Intersect(var L, R: Integer; L1, R1, L2, R2: Integer): Boolean;
    begin
      Result := (L1 < R2)and(L2 < R1);
      if L1 > L2 then L := L1 else L := L2;
      if R1 < R2 then R := R1 else R := R2;
    end;
begin
  Result := _Intersect(Rect.Left, Rect.Right,  R1.Left, R1.Right,  R2.Left, R2.Right )and
            _Intersect(Rect.Top,  Rect.Bottom, R1.Top,  R1.Bottom, R2.Top,  R2.Bottom);
end;

function PtInRect(const Rect: TRect; const Pt: TPoint): Boolean;
begin
  Result := (Pt.X > Rect.Left)and
            (Pt.X < Rect.Right)and
            (Pt.Y > Rect.Top)and
            (Pt.Y < Rect.Bottom);
end;
{$ENDIF}

procedure OffsetRectF(var Rect: TRectF; DX, DY: TFloat);
begin
  with Rect do
   begin
    XMin := XMin + DX;
    XMax := XMax + DX;
    YMin := YMin + DY;
    YMax := YMax + DY;
  end;
end;

procedure ScaleRectF(var Rect: TRectF; XC, YC, KX, KY: TFloat);
begin
  with Rect do
  begin
    XMin := (Rect.XMin - XC)*KX + XC;
    XMax := (Rect.XMax - XC)*KX + XC;
    YMin := (Rect.YMin - YC)*KY + YC;
    YMax := (Rect.YMax - YC)*KY + YC;
  end;
end;

procedure InflateRectF(var Rect: TRectF; DX, DY: TFloat);
begin
  with Rect do
  begin
    XMin := XMin - DX;
    XMax := XMax + DX;
    YMin := YMin - DY;
    YMax := YMax + DY;
  end;
end;

function PtInRectF(const Rect: TRectF; const Pt: TPointF): Boolean;
begin
  if IsEmptyF(Rect)or IsEmptyF(Pt) then
    Result := False
  else
    Result := (Pt.X > Rect.XMin)and(Pt.X < Rect.XMax)and
              (Pt.Y > Rect.YMin)and(Pt.Y < Rect.YMax);
end;

function RectInRectF(const Rout, Rin: TRectF): Boolean;
begin
  if IsEmptyF(Rout)or IsEmptyF(Rin) then
    Result := False
  else
    Result := PtInRectF(Rout, PointF(Rin.XMin, Rin.YMin)) and
              PtInRectF(Rout, PointF(Rin.XMax, Rin.YMax));
end;

function UnionRectF(const R1, R2: TRectF): TRectF;
begin
  Result := R1;
  
  if IsEmptyF(R2) then Exit
  else if IsEmptyF(R1) then
  begin
    Result := R2;
    Exit;
  end;

  if Result.XMin > R2.XMin then Result.XMin := R2.XMin;
  if Result.YMin > R2.YMin then Result.YMin := R2.YMin;
  if Result.XMax < R2.XMax then Result.XMax := R2.XMax;
  if Result.YMax < R2.YMax then Result.YMax := R2.YMax;
end;

function RectWidth(const Rect: TRect): Integer;
begin
  Result := Rect.Right - Rect.Left;
end;

function RectHeight(const Rect: TRect): Integer;
begin
  Result := Rect.Bottom - Rect.Top;
end;

function RectWidthF(const Rect: TRectF): TFloat;
begin
  Result := Rect.XMax - Rect.XMin;
end;

function RectHeightF(const Rect: TRectF): TFloat;
begin
  Result := Rect.YMax - Rect.YMin;
end;

function PtInLine(X, Y, X0, Y0, X1, Y1, Sens: Integer; var param01: TFloat): Boolean;
var L, P, D: Double;
begin
  Result := False;
  if (X0 = X1)and(Y0 = Y1)then Exit;

  L := Sqrt( Sqr(X1-X0) + Sqr(Y1-Y0) );
  P := ((X-X0)*(X1-X0) + (Y-Y0)*(Y1-Y0))/L;

  if (P > -Sens)and(P < L + Sens) then
  begin
    D := Abs( ( (X-X0)*(Y1-Y0) - (X1-X0)*(Y-Y0) )/L );
    if D < Sens then
    begin
      Result := True;
      param01 := P/L;
    end;
  end;
end;

function PointRect(const pt: TPoint; dx, dy: Integer): TRect;
begin
  Result := Rect(pt.X-dx, pt.Y-dy, pt.X+dx, pt.Y+dy);
end;

function PointRect(x, y, dx, dy: Integer): TRect;
begin
  Result := Rect(x-dx, y-dy, x+dx, y+dy);
end;

function PointRectF(const pt: TPointF; dx, dy: TFloat): TRectF;
begin
  Result := RectF(pt.X-dx, pt.Y-dy, pt.X+dx, pt.Y+dy);
end;

function PointRectF(x, y, dx, dy: TFloat): TRectF;
begin
  Result := RectF(x-dx, y-dy, x+dx, y+dy);
end;

procedure OffsetPoint(var pt: TPoint; dx, dy: Integer);
begin
  Inc(pt.X, dx);
  Inc(pt.Y, dy);
end;

procedure OffsetPointF(var pt: TPointF; dx, dy: TFloat);
begin
  pt.X := pt.X + dx;
  pt.Y := pt.Y + dy;
end;

function DistanceF(const p1, p2: TPointF): TFloat;
begin
  Result := Sqrt( Sqr(p2.X - p1.X) + Sqr(p2.Y - p1.Y) );
end;

function DistanceF(const p1, p2: TPointF; AspectRatio: TFloat): TFloat; overload;
begin
  Result := Sqrt( Sqr(AspectRatio*(p2.X - p1.X)) + Sqr(p2.Y - p1.Y) );    
end;

function ScalarF(const pt: TPointF): TFloat;
begin
  Result := Sqrt( Sqr(pt.X) + Sqr(pt.Y) );
end;

function DifferenceF(const p1, p2: TPointF): TPointF;
begin
  Result.X := p2.X - p1.X;
  Result.Y := p2.Y - p1.Y;
end;

function Distance(const p1, p2: TPoint): TFloat;
begin
  Result := Sqrt( Sqr(p2.X - p1.X) + Sqr(p2.Y - p1.Y) );
end;

function Scalar(const pt: TPoint): TFloat;
begin
  Result := Sqrt( Sqr(pt.X) + Sqr(pt.Y) );
end;

procedure ConfineRectInRect(var InnerR: TRect; const OuterR: TRect);
begin
  if InnerR.Right > OuterR.Right then OffsetRect(InnerR, OuterR.Right - InnerR.Right, 0);
  if InnerR.Bottom > OuterR.Bottom then OffsetRect(InnerR, 0, OuterR.Bottom - InnerR.Bottom);

  if InnerR.Left < OuterR.Left then OffsetRect(InnerR, OuterR.Left - InnerR.Left, 0);
  if InnerR.Top < OuterR.Top then OffsetRect(InnerR, 0, OuterR.Top - InnerR.Top);
end;

procedure ConfineRectInRectF(var InnerR: TRectF; const OuterR: TRectF);
begin
  if InnerR.XMax > OuterR.XMax then OffsetRectF(InnerR, OuterR.XMax - InnerR.XMax, 0);
  if InnerR.YMax > OuterR.YMax then OffsetRectF(InnerR, 0, OuterR.YMax - InnerR.YMax);

  if InnerR.XMin < OuterR.XMin then OffsetRectF(InnerR, OuterR.XMin - InnerR.XMin, 0);
  if InnerR.YMin < OuterR.YMin then OffsetRectF(InnerR, 0, OuterR.YMin - InnerR.YMin);
end;

function RectCenter(const R: TRect): TPoint;
begin
  Result := Point(
    (R.Left + R.Right) div 2,
    (R.Top + R.Bottom) div 2
  );
end;

function RectCenterF(const R: TRectF): TPointF;
begin
  Result := PointF(
    (R.XMin + R.XMax)*0.5,
    (R.YMin + R.YMax)*0.5
  );
end;

function CircumscribedRect(const Pts: array of TPoint): TRect;
var i: Integer;
begin
  Result := Rect(Pts[0].X, Pts[0].Y, Pts[0].X, Pts[0].Y);
  for i := 1 to Length(Pts)-1 do
  begin
    if Pts[i].X < Result.Left then Result.Left := Pts[i].X;
    if Pts[i].Y < Result.Top then Result.Top := Pts[i].Y;

    if Pts[i].X > Result.Right then Result.Right := Pts[i].X;
    if Pts[i].Y > Result.Bottom then Result.Bottom := Pts[i].Y;
  end;
end;

function CircumscribedRectF(const Pts: array of TPointF): TRectF;
var i: Integer;
begin
  Result := RectF(Pts[0].X, Pts[0].Y, Pts[0].X, Pts[0].Y);
  for i := 1 to Length(Pts)-1 do
  begin
    if Pts[i].X < Result.XMin then Result.XMin := Pts[i].X;
    if Pts[i].Y < Result.YMin then Result.YMin := Pts[i].Y;

    if Pts[i].X > Result.XMax then Result.XMax := Pts[i].X;
    if Pts[i].Y > Result.YMax then Result.YMax := Pts[i].Y;
  end;
end;

function ProportionalRectF(const MasterRect: TRect; const R: TRectF; LockedCoord: Char): TRectF;
var KM, K, a: Double;
    C: TPointF;
begin
  KM := RectHeight(MasterRect)/RectWidth(MasterRect);
  K := RectHeightF(R)/RectWidthF(R);
  a := Sqrt(KM/K);
  C := RectCenterF(R);

  case LockedCoord of
    'x', 'X': Result := PointRectF(C, 0.5*RectWidthF(R), 0.5*RectHeightF(R)*a*a);
    'y', 'Y': Result := PointRectF(C, 0.5*RectWidthF(R)/a/a, 0.5*RectHeightF(R));
    else Result := PointRectF(C, 0.5*RectWidthF(R)/a, 0.5*RectHeightF(R)*a);
  end;
end;

function PtInPolygonF(const P: array of TPointF; const Pt: TPointF): Boolean;
var i, j, k, Count, Intersect: Integer;
    t: TFloat;
        function MaxY(i, j: Integer; var k: Integer): TFloat;
        begin
          if P[i].Y > P[j].Y then
          begin Result := P[i].Y; k := i; end else
          begin Result := P[j].Y; k := j; end;
        end;
        {function MinY(i, j: Integer; var k: Integer): TFloat;
        begin
          if P[i].Y > P[j].Y then
          begin Result := P[j].Y; k := j; end else
          begin Result := P[i].Y; k := i; end;
        end;}
begin
  Count := Length(P);
  Intersect := 0;
  for i := 0 to Count - 1 do
  begin
    j := (i+1)mod Count;
    if not(    ( Pt.Y<P[i].Y )and( Pt.Y<P[j].Y )   )and
       not(    ( Pt.Y>P[i].Y )and( Pt.Y>P[j].Y )   )and
       not(     P[i].Y =  P[j].Y                   )then
      if MaxY(i, j, k) = Pt.Y then
      begin
        if P[k].X > Pt.X then Inc(Intersect)
      end
      //else if not (MinY(i, j, k) = Pt.Y) then
      else if not (Min(P[i].Y, P[j].Y) = Pt.Y) then
      begin
        t := (Pt.Y - P[i].Y )/( P[j].Y - P[i].Y );
        if (t>0)and(t<1)and(P[i].X+t*(P[j].X-P[i].X)>Pt.X)then Inc(Intersect);
      end;
  end;
  Result := Intersect mod 2 = 1;
end;

end.
