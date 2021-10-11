{*******************************************************************************
*                                                                              *
*                       Author: Reonid                                         *
*                       Categoty: vector graphic                               *
*                       mailto: reonid@yahoo.com                               *
*                                                                              *
*******************************************************************************}

unit RBezier;

interface

uses
  {$IFDEF UNIX} {$ELSE} Windows, {$ENDIF}
  Graphics, Classes, Math,

  RTypes, RIntf, RCore, RCurve, RCrvCtl;

type
  TCtrlPointEx = (cpNone, cpLeft, cpRight, cpPrevRight, cpNextLeft);
  TCtrlPointId = cpLeft..cpRight;
  TCtrlPointUpdateId = cpNone..cpRight;

  TNodeType = (ntNone, ntCusp, ntSmooth, ntSymmet);
  TSegmentType = (stNone, stBezier, stLine);

  TRBezier = class(TRCurve)
  private
    procedure SetNodeTypeUpd(I: Integer; const Value: TNodeType);
    procedure SetSegmentTypeUpd(I: Integer; const Value: TSegmentType);

    function GetLCtrlPt(I: Integer): TPointF;
    procedure SetLCtrlPt(I: Integer; const Value: TPointF);
    function GetRCtrlPt(I: Integer): TPointF;
    procedure SetRCtrlPt(I: Integer; const Value: TPointF);
  protected
    function GetCtrlPoint (id: TCtrlPointId; I: Integer): TPointF; virtual; abstract;
    procedure SetCtrlPoint(id: TCtrlPointId; I: Integer; const Value: TPointF); virtual; abstract;

    function GetNodeType(I: Integer): TNodeType; virtual; abstract;
    procedure SetNodeType(I: Integer; const Value: TNodeType); virtual; abstract;
    function GetSegmentType(I: Integer): TSegmentType; virtual; abstract;
    procedure SetSegmentType(I: Integer; const Value: TSegmentType); virtual; abstract;

    procedure DrawLine(Layer: TRLayer); override;
    procedure FillArea(Layer: TRLayer); override;

    procedure __UpdateNode(id: TCtrlPointEx; I: Integer);
    procedure _UpdateNode(id: TCtrlPointEx; I: Integer);
    procedure UpdateNode(id: TCtrlPointEx; I: Integer); virtual;
    function IsUnchangeableCtrlPt(I: Integer; id: TCtrlPointId): Boolean;

    function CalcUnchangeableCtrlPt(id: TCtrlPointId; I: Integer): TPointF;
    procedure PointChanged(I: Integer); override;
    procedure SetClosed(Value: Boolean); override;

    function TechnicalRect: TRectF;

    {IStreamable}
    procedure SaveDataToStream(Stream: TStream; Aspects: TDataAspects); override;
    procedure LoadDataFromStream(Stream: TStream; Aspects: TDataAspects); override;
  public
    property LCtrlPt[I: Integer]: TPointF read GetLCtrlPt write SetLCtrlPt;
    property RCtrlPt[I: Integer]: TPointF read GetRCtrlPt write SetRCtrlPt;
    property NodeType[I: Integer]: TNodeType read GetNodeType write SetNodeTypeUpd;
    property SegmentType[I: Integer]: TSegmentType read GetSegmentType write SetSegmentTypeUpd;

    procedure CalcSegmentCenter(I: Integer; var t: TFloat); override;
    function GetIntermediatePoint(I: Integer; t: TFloat): TPointF; override;
    function ActualizeIntermediatePoint(I: Integer; t: TFloat): Integer; override;

    function HitSegment(Layer: TRLayer; const Pt: TPointF; Sens: Integer; var Ihit: Integer;
      var t: TFloat): Boolean; override;
    function HitArea(Layer: TRLayer; const Pt: TPointF): Boolean; override;

    procedure Scale(XC, YC, KX, KY: TFloat); override;
    procedure Rotate(XC, YC, Angle: TFloat); override;

    function ContainingRect: TRectF; override;
  end;

implementation

uses
  RCrvHlp, RGeom{, RGeomEx};

const
  BEZIER_ACCURACY: Integer = 150;
  SEGMENT_EXTRA_ACCURACY: Integer = 100;



{------------------------------- TRBezier -------------------------------------}

function TRBezier.GetIntermediatePoint(I: Integer; t: TFloat): TPointF; {+}
var t_sq,t_cb,r1,r2,r3,r4,
    Xi, Yi, Xip1, Yip1, RCXi, RCYi, LCXip1, LCYip1: Double;
    ip1: Integer;
begin
  ip1 := (i+1) mod Length;
  Xi := X[i];
  Yi := Y[i];
  Xip1 := X[ip1];
  Yip1 := Y[ip1];

  case SegmentType[I] of
    stBezier:
    begin
      RCXi := RCtrlPt[i].X;  // Relative ctrl point
      RCYi := RCtrlPt[i].Y;
      LCXip1 := LCtrlPt[ip1].X;
      LCYip1 := LCtrlPt[ip1].Y;

      t_sq := t * t;
      t_cb := t * t_sq;
      r1 := (1 - 3*t + 3*t_sq -   t_cb)* Xi;
      r2 := (    3*t - 6*t_sq + 3*t_cb)*( RCXi + Xi    );
      r3 := (          3*t_sq - 3*t_cb)*( LCXip1+ Xip1 );
      r4 := (                     t_cb)* Xip1;
      Result.X  := r1 + r2 + r3 + r4;

      r1 := (1 - 3*t + 3*t_sq -   t_cb)* Yi;
      r2 := (    3*t - 6*t_sq + 3*t_cb)*( RCYi + Yi    );
      r3 := (          3*t_sq - 3*t_cb)*( LCYip1+ Yip1 );
      r4 := (                     t_cb)* Yip1;
      Result.Y  := r1 + r2 + r3 + r4;
    end;
    stLine:
    begin
      Result.X := Xi + t*(Xip1 - Xi);
      Result.Y := Yi + t*(Yip1 - Yi);
    end;
  end;
end;

function TRBezier.ActualizeIntermediatePoint(I: Integer; t: TFloat): Integer;
var j,  ip1: Integer;
    RX0, RY0, LX1, LY1, X0, Y0, X1, Y1,
    t_sq, t_cb, rt, rt_sq, rt_cb: TFloat;
    NewPt, CPt: TPointF;
    Resizeable: IResizeable;
begin
  Result := -1;
  if not GetInterface(IResizeable, Resizeable) then Exit;

  NewPt := GetIntermediatePoint(i, t);

  ip1 := (i + 1) mod Length;
  if NodeType[i] = ntSymmet then SetNodeType(i, ntSmooth);
  if NodeType[ip1] = ntSymmet then SetNodeType(ip1, ntSmooth);
  Result := TRCurveHelper(Self).InsertBlock(i+1{! not ip1}, 1);
  if Result = -1 then Exit;


  {----------------}
  if NodeType[i]   = ntSymmet then SetNodeType(i,   ntSmooth);
  if NodeType[ip1] = ntSymmet then SetNodeType(ip1, ntSmooth);

  SetSegmentType(Result, GetSegmentType(I));
  if SegmentType[i] = stLine
    then SetNodeType(Result, ntCusp)
    else SetNodeType(Result, ntSmooth);
  {----------------}


  t_sq := t*t;
  t_cb := t*t_sq;
  rt := 1-t;
  rt_sq := rt*rt;
  rt_cb := rt*rt_sq;

  RX0 := RCtrlPt[i].X;
  RY0 := RCtrlPt[i].Y;
  LX1 := LCtrlPt[ip1].X;
  LY1 := LCtrlPt[ip1].Y;
  X0 := X[i];
  Y0 := Y[i];
  X1 := X[ip1];
  Y1 := Y[ip1];

  j := Result;
  ip1 := (j + 1) mod Length;

  X[j] := NewPt.X;
  Y[j] := NewPt.Y;


  CPt.X := RX0*t;
  CPt.Y := RY0*t;
  RCtrlPt[i] := CPt;

  CPt.X  := (-2*X0 -3*RX0 + 2*X1 + 3*LX1)*t_cb + (2*X0 -2*X1 - 2*LX1 + 4*RX0)*t_sq -RX0*t;
  CPt.Y  := (-2*Y0 -3*RY0 + 2*Y1 + 3*LY1)*t_cb + (2*Y0 -2*Y1 - 2*LY1 + 4*RY0)*t_sq -RY0*t;
  LCtrlPt[j] := CPt;

  CPt.X := (-2*X1 -3*LX1 + 2*X0 + 3*RX0)*rt_cb + (2*X1 -2*X0 - 2*RX0 + 4*LX1)*rt_sq -LX1*rt;
  CPt.Y := (-2*Y1 -3*LY1 + 2*Y0 + 3*RY0)*rt_cb + (2*Y1 -2*Y0 - 2*RY0 + 4*LY1)*rt_sq -LY1*rt;
  RCtrlPt[j] := CPt;

  CPt.X := LX1*rt;
  CPt.Y := LY1*rt;
  LCtrlPt[ip1] := CPt;

end;

procedure TRBezier.CalcSegmentCenter(I: Integer; var t: TFloat);
begin
  t := 0.5; // not implemented
end;

procedure TRBezier.DrawLine(Layer: TRLayer);  {+}
var i, ip1, Till: Integer;
    pt0, pt1, rpt, lpt: TPoint;
    _pt0, _pt1, _rpt, _lpt: TPointF;
begin
  if Closed then Till := High else Till := High-1;

  for i := Low to Till do
  begin
    ip1 := (i+1) mod Length;
    _pt0 := PointF(X[i], Y[i]);
    _pt1 := PointF(X[ip1], Y[ip1]);

    Layer.Converter.LogicToScreen(X[i], Y[i], pt0.X, pt0.Y);
    Layer.Converter.LogicToScreen(X[ip1], Y[ip1], pt1.X, pt1.Y);

    case SegmentType[i] of
      stBezier:
      begin
        _rpt := RCtrlPt[i];
        _lpt := LCtrlPt[ip1];
        OffsetPointF(_rpt, _pt0.X, _pt0.Y);
        OffsetPointF(_lpt, _pt1.X, _pt1.Y);

        Layer.Converter.LogicToScreen(_rpt.X, _rpt.Y, rpt.X, rpt.Y);
        Layer.Converter.LogicToScreen(_lpt.X, _lpt.Y, lpt.X, lpt.Y);

        Layer.Canvas.PolyBezier([pt0, rpt, lpt, pt1]);
      end;
      stLine: Layer.Canvas.PolyLine([pt0, pt1]);
    end;

  end;
end;

procedure TRBezier.FillArea(Layer: TRLayer);
var i, ip1: Integer;
    pt0, pt1, rpt, lpt: TPoint;
    _pt0, _pt1, _rpt, _lpt: TPointF;
    pts: array[0..3]of TPoint;
begin
  {$IFDEF UNIX}
  {$ELSE}
  BeginPath(Layer.Canvas.Handle);

  Layer.Converter.LogicToScreen(X[Low], Y[Low], pt0.X, pt0.Y);
  MoveToEx(Layer.Canvas.Handle, pt0.X, pt0.Y, nil);

  for i := Low to High + Integer(Closed)-1 do
  begin
    ip1 := (i+1) mod Length;
    _pt0 := PointF(X[i], Y[i]);
    _pt1 := PointF(X[ip1], Y[ip1]);

    Layer.Converter.LogicToScreen(X[ip1], Y[ip1], pt1.X, pt1.Y);

    case SegmentType[i] of
      stBezier:
      begin
        _rpt := RCtrlPt[i];
        _lpt := LCtrlPt[ip1];
        OffsetPointF(_rpt, _pt0.X, _pt0.Y);
        OffsetPointF(_lpt, _pt1.X, _pt1.Y);

        Layer.Converter.LogicToScreen(_rpt.X, _rpt.Y, rpt.X, rpt.Y);
        Layer.Converter.LogicToScreen(_lpt.X, _lpt.Y, lpt.X, lpt.Y);

        pts[1] := rpt;
        pts[2] := lpt;
        pts[3] := pt1;

        PolyBezierTo(Layer.Canvas.Handle, pts[1], 3);
      end;
      stLine: PolyLineTo(Layer.Canvas.Handle, pt1, 1);
    end;

  end;
  CloseFigure(Layer.Canvas.Handle);
  EndPath(Layer.Canvas.Handle);

  FillPath(Layer.Canvas.Handle);
  {$ENDIF}
end;


function TRBezier.GetLCtrlPt(I: Integer): TPointF; {?}
begin
  if IsUnchangeableCtrlPt(i, cpLeft)
    then Result := CalcUnchangeableCtrlPt(cpLeft, i)
    else Result := GetCtrlPoint(cpLeft, I);
end;

procedure TRBezier.SetLCtrlPt(I: Integer; const Value: TPointF);
begin
  SetCtrlPoint(cpLeft, I, Value);
  UpdateNode(cpRight, I);
end;

function TRBezier.GetRCtrlPt(I: Integer): TPointF;
begin
  if IsUnchangeableCtrlPt(i, cpRight)
    then Result := CalcUnchangeableCtrlPt(cpRight, i)
    else Result := GetCtrlPoint(cpRight, I);
end;

procedure TRBezier.SetRCtrlPt(I: Integer; const Value: TPointF);
begin
  SetCtrlPoint(cpRight, I, Value);
  UpdateNode(cpLeft, I);
end;

procedure TRBezier.SetNodeTypeUpd(I: Integer; const Value: TNodeType);
begin
  if (not Closed)and( (I=High)or(I=0) )
    then SetNodeType(I, ntCusp)
    else SetNodeType(I, Value);

  UpdateNode(cpNone, I);
end;

procedure TRBezier.SetSegmentTypeUpd(I: Integer; const Value: TSegmentType);
var ip1: Integer;
begin
  ip1 := NextIndex(i, Length, Closed);
  if (Value = stBezier) and (SegmentType[I] = stLine) then
  begin
    SetCtrlPoint(cpRight, i, CalcUnchangeableCtrlPt(cpRight, i));
    if (ip1 > -1) then SetCtrlPoint(cpLeft, ip1, CalcUnchangeableCtrlPt(cpLeft, ip1));
  end;

  if (Value = stLine) and (SegmentType[I] = stBezier) then
  begin
    ip1 := NextIndex(i, Length, Closed);
    if (ip1 > -1)and(GetSegmentType(ip1) = stLine) then SetNodeType{Upd}(ip1, ntCusp);
  end;

  SetSegmentType(I, Value);
  UpdateNode(cpNone, I);
  if (ip1 > -1) then UpdateNode(cpNone, ip1);  
end;

procedure TRBezier.__UpdateNode(id: TCtrlPointEx; I: Integer); {-}
var R, a, R1: Double;
begin
  case NodeType[I] of
    //-------------------------
    ntSmooth:
      case id of
        cpRight:
        begin
          R := ScalarF(RCtrlPt[I]);
          a := ArcTan2(LCtrlPt[I].Y, LCtrlPt[I].X);
          SetCtrlPoint(id, I, PointF(-R*cos(a), -R*sin(a)) );
        end;
        cpLeft:
        begin
          R := ScalarF(LCtrlPt[I]);
          a := ArcTan2(RCtrlPt[I].Y, RCtrlPt[I].X);
          SetCtrlPoint(id, I, PointF(-R*cos(a), -R*sin(a)) );
        end;
        cpNone:
        begin
          R := ScalarF(LCtrlPt[I]);
          R1 := ScalarF(RCtrlPt[I]);
          a := ArcTan2(RCtrlPt[I].Y - LCtrlPt[I].Y, RCtrlPt[I].X - LCtrlPt[I].X);
          SetCtrlPoint(cpLeft, I, PointF(-R*cos(a), -R*sin(a)) );
          SetCtrlPoint(cpRight, I, PointF(R1*cos(a), R1*sin(a)) );
        end;
      end;
    //-------------------------
    ntSymmet:
      case id of
        cpRight: SetCtrlPoint(id, I, PointF(-LCtrlPt[I].X, -LCtrlPt[I].Y) );
        cpLeft:  SetCtrlPoint(id, I, PointF(-RCtrlPt[I].X, -RCtrlPt[I].Y) );
        cpNone:
        begin
          R  := ScalarF(LCtrlPt[I]);
          R1 := ScalarF(RCtrlPt[I]);
          R  := (R + R1)*0.5;
          a  := ArcTan2(RCtrlPt[I].Y - LCtrlPt[I].Y, RCtrlPt[I].X - LCtrlPt[I].X);
          SetCtrlPoint(cpLeft,  I, PointF(-R*cos(a), -R*sin(a)) );
          SetCtrlPoint(cpRight, I, PointF( R*cos(a),  R*sin(a)) );
        end;
      end;
    //-------------------------
    ntCusp: {none} ;
    //-------------------------
  end;
end;

procedure TRBezier._UpdateNode(id: TCtrlPointEx; I: Integer);
begin
  if IsUnchangeableCtrlPt(i, cpLeft) then
  begin
    SetCtrlPoint(cpLeft,  i, CalcUnchangeableCtrlPt(cpLeft, i));
    if IsUnchangeableCtrlPt(i, cpRight) then
    begin
      SetCtrlPoint(cpRight, i, CalcUnchangeableCtrlPt(cpRight, i));
      SetNodeType(i, ntCusp);
    end
    else
      __UpdateNode(cpRight, i);
  end
  else if IsUnchangeableCtrlPt(i, cpRight) then
  begin
    SetCtrlPoint(cpRight, i, CalcUnchangeableCtrlPt(cpRight, i));
    __UpdateNode(cpLeft, i);
  end
  else
    __UpdateNode(id, i);
end;

procedure TRBezier.UpdateNode(id: TCtrlPointEx; I: Integer);
var updateId: TCtrlPointEx;
    updateIdx: Integer;
begin
  updateId := cpNone;
  updateIdx := i;

  if      (id = cpRight)or(id = cpPrevRight) then updateId := cpRight
  else if (id = cpLeft )or(id = cpNextLeft ) then updateId := cpLeft;

  if      id = cpPrevRight then updateIdx := PrevIndex(i, Length, Closed)
  else if id = cpNextLeft  then updateIdx := NextIndex(i, Length, Closed);

  if i > -1 then _UpdateNode(updateId, updateIdx);
end;

function TRBezier.IsUnchangeableCtrlPt(I: Integer; id: TCtrlPointId): Boolean;
var im1: Integer;
begin
  im1 := PrevIndex(i, Length, Closed);
  Result := (               (id = cpRight)and(SegmentType[i]   = stLine)  )or
            (  (im1 > -1)and(id = cpLeft )and(SegmentType[im1] = stLine)  )or
            (  (not Closed)and
               (
                   (  (I = Low )and(id = cpLeft)   )or
                   (  (I = High)and(id = cpRight)  )
               )
            );
end;

procedure TRBezier.SetClosed(Value: Boolean);
begin
  if Closed <> Value then
  begin
    SetNodeType(Low, ntCusp);
    SetNodeType(High, ntCusp);
    SetSegmentType(High, stLine);

    if Value then
    begin
      SetCtrlPoint(cpLeft,  Low,  CalcUnchangeableCtrlPt(cpLeft,  Low ));
      SetCtrlPoint(cpRight, High, CalcUnchangeableCtrlPt(cpRight, High));
    end;
  end;

  inherited;
end;

function TRBezier.CalcUnchangeableCtrlPt(id: TCtrlPointId; I: Integer): TPointF;
var im1, ip1: Integer;
begin
  case id of
    cpLeft:
    begin
      im1 := PrevIndex(i, Length, True);
      Result := PointF(
        (X[im1]-X[i])/3,
        (Y[im1]-Y[i])/3 );
    end;
    cpRight:
    begin
      ip1 := NextIndex(i, Length, True);
      Result := PointF(
        (X[ip1]-X[i])/3,
        (Y[ip1]-Y[i])/3 );
    end;
  end;
end;

procedure TRBezier.PointChanged(I: Integer);
var im1, im2, ip1: Integer;
begin
  ip1 := NextIndex(I, Length, True);
  im1 := PrevIndex(I, Length, True);
  im2 := PrevIndex(im1, Length, True);

  if SegmentType[i] = stLine then
  begin
    if SegmentType[ip1] = stBezier then UpdateNode(cpRight, ip1);
    if SegmentType[im1] = stBezier then UpdateNode(cpLeft, i);
  end;
  if SegmentType[im1] = stLine then
  begin
    if SegmentType[i] = stBezier then UpdateNode(cpRight, i);
    if SegmentType[im2] = stBezier then UpdateNode(cpLeft, im1);
  end;
end;

procedure TRBezier.Scale(XC, YC, KX, KY: TFloat);
var i: Integer;
    pt: TPointF;
begin
  {before inherited}
  for i := Low to High do
  begin
    pt := LCtrlPt[i];
    pt.X := pt.X*KX;
    pt.Y := pt.Y*KY;
    SetCtrlPoint(cpLeft, i, pt);

    pt := RCtrlPt[i];
    pt.X := pt.X*KX;
    pt.Y := pt.Y*KY;
    SetCtrlPoint(cpRight, i, pt);
  end;

  inherited;
end;

procedure TRBezier.Rotate(XC, YC, Angle: TFloat);
var i: Integer;
    pt, pt2: TPointF;
begin
  {before inherited}
  for i := Low to High do
  begin
    pt := LCtrlPt[i];
    pt2.X := pt.X*Cos(Angle) - pt.Y*Sin(Angle);
    pt2.Y := pt.Y*Cos(Angle) + pt.X*Sin(Angle);
    SetCtrlPoint(cpLeft, i, pt2);

    pt := RCtrlPt[i];
    pt2.X := pt.X*Cos(Angle) - pt.Y*Sin(Angle);
    pt2.Y := pt.Y*Cos(Angle) + pt.X*Sin(Angle);
    SetCtrlPoint(cpRight, i, pt2);
  end;

  inherited;
end;

{------------------------------------------------------------------------------}

function TRBezier.ContainingRect: TRectF;
var
  i, j, N: Integer;
  h: Double;
  pt: TPointF;
begin
  if Empty then
  begin
    Result := EmptyRectF;
    Exit;
  end;

  Result := RectF(X[Low], Y[Low], X[Low], Y[Low]);

  N := BEZIER_ACCURACY;
  h := 1/N;

  for i := Low to High + Integer(Closed)-1 do
    for j := 0 to N do
    begin
      pt := GetIntermediatePoint(i, j*h);

      if      (pt.Y > Result.YMax) then Result.YMax := pt.Y
      else if (pt.Y < Result.YMin) then Result.YMin := pt.Y;

      if      pt.X > Result.XMax   then Result.XMax := pt.X
      else if pt.X < Result.XMin   then Result.XMin := pt.X;
    end;
end;

function CalcSegmentRect(const Pt0, RPt0, LPt1, Pt1: TPointF): TRectF;
var _RPt0, _LPt1: TPointF;
begin
  _RPt0 := RPt0;
  _LPt1 := LPt1;
  OffsetPointF(_RPt0, Pt0.X, Pt0.Y);
  OffsetPointF(_LPt1, Pt1.X, Pt1.Y);
  Result := CircumscribedRectF([Pt0, _RPt0, _LPt1, Pt1]);
end;

function TRBezier.HitSegment(Layer: TRLayer; const Pt: TPointF;
  Sens: Integer; var Ihit: Integer; var t: TFloat): Boolean;
var
  P: TPointF;
  N, i, j, ip1: Integer;
  h, R, Rmin, Aspect, min_t, SensF: TFloat;
  Rct: TRectF;
  centerPt: TPoint;
begin
  Result := False;
  if Empty then Exit;

  N := BEZIER_ACCURACY * SEGMENT_EXTRA_ACCURACY; { !Temporary. => PtInLine }
  h := 1/N;

  centerPt := RectCenter(Layer.Rect);
  CalcAspect(Layer.Converter, Sens, centerPt, SensF, Aspect);

  for i := Low to High + Integer(Closed) - 1 do
  begin
    ip1 := (i+1) mod Length;

    Rct := CalcSegmentRect(Points[i], RCtrlPt[i], LCtrlPt[ip1], Points[ip1]);
    InflateRectF(Rct, SensF/Aspect, SensF);
    if not PtInRectF(Rct, Pt) then Continue;

    Rmin := 1e30;
    min_t := 0;
    for j := 0 to N{-1} do
    begin
      P := GetIntermediatePoint(I, j*h);
      R := DistanceF(Pt, P, Aspect);
      if R < Rmin then
      begin
        Rmin := R;
        min_t := j*h;
      end;
    end;

    if Rmin <= SensF then
    begin
      Result := True;
      t := min_t;
      Ihit := i;
      Break;
    end;
  end;

end;

function TRBezier.HitArea(Layer: TRLayer; const Pt: TPointF): Boolean;
var i, j, k, N, L, Total, Intersect: Integer;
    t, h, Xk: TFloat;
    pti, ptj: TPointF;
    techR: TRectF;
begin         
  Result := False;
  if (not Closed) {or(not Filled)} then Exit;

  techR := TechnicalRect;
  if not PtInRectF(techR, Pt) then Exit;

  N := BEZIER_ACCURACY;
  h := 1/N;
  L := Length;
  Total := N*L;

  Intersect := 0;
  for i := 0 to Total-1 do
  begin
    j := (i+1) mod Total;
    pti := GetIntermediatePoint((i div N)mod L, (i mod N)*h);
    ptj := GetIntermediatePoint((j div N)mod L, (j mod N)*h);

    if not(    ( pti.Y =  ptj.Y                  )   )and
       not(    ( Pt.Y < pti.Y )and( Pt.Y < ptj.Y )   )and
       not(    ( Pt.Y > pti.Y )and( Pt.Y > ptj.Y )   )then
         if MaxValueF(pti.Y, ptj.Y, i, j, k) = Pt.Y then
         begin
           Xk := GetIntermediatePoint((k div N)mod L, (k mod N)*h).X;
           if Xk > Pt.X then Inc(Intersect);
         end
         else if not (Min(pti.Y, ptj.Y) = Pt.Y) then
         begin
           t := (Pt.Y - pti.Y)/(ptj.Y - pti.Y);
           if (t>0)and(t<1)and(pti.X + t*(ptj.X - pti.X) > Pt.X)then Inc(Intersect);
         end;
  end;
  Result := Intersect mod 2 = 1;
end;

function TRBezier.TechnicalRect: TRectF;
var
  i, j: Integer;
  pt, addPt: TPointF;
begin
  if Empty then
  begin
    Result := EmptyRectF;
    Exit;
  end;

  Result := RectF(X[Low], Y[Low], X[Low], Y[Low]);

  for i := Low to High + Integer(Closed)-1 do
  begin
    for j := 0 to 2 do
    begin
      pt := Points[i];
      case j of
        0: addPt := PointF(0, 0);
        1: addPt := LCtrlPt[i];
        2: addPt := RCtrlPt[i];
      end;
      OffsetPointF(pt, addPt.X, addPt.Y);

      if      (pt.Y > Result.YMax) then Result.YMax := pt.Y
      else if (pt.Y < Result.YMin) then Result.YMin := pt.Y;

      if      pt.X > Result.XMax   then Result.XMax := pt.X
      else if pt.X < Result.XMin   then Result.XMin := pt.X;
    end;
  end;
end;

procedure TRBezier.SaveDataToStream(Stream: TStream; Aspects: TDataAspects);
var i: Integer;
    Pt: TPointF;
    nt: TNodeType;
    st: TSegmentType;
begin
  inherited;

  if daGeometry in Aspects then
  begin
    for i := 0 to Length-1 do
    begin
      st := GetSegmentType(i);
      Stream.WriteBuffer(st, SizeOf(st));
      nt := GetNodeType(i);
      Stream.WriteBuffer(nt, SizeOf(nt));

      Pt := GetCtrlPoint(cpLeft, i);
      Stream.WriteBuffer(Pt, SizeOf(Pt));
      Pt := GetCtrlPoint(cpRight, i);
      Stream.WriteBuffer(Pt, SizeOf(Pt));
    end;
  end;  
end;

procedure TRBezier.LoadDataFromStream(Stream: TStream; Aspects: TDataAspects);
var i: Integer;
    Pt: TPointF;
    nt: TNodeType;
    st: TSegmentType;
begin
  inherited;

  if daGeometry in Aspects then
  begin
    for i := 0 to Length-1 do
    begin
      Stream.ReadBuffer(st, SizeOf(st));
      SetSegmentType(i, st);
      Stream.ReadBuffer(nt, SizeOf(nt));
      SetNodeType(i, nt);

      Stream.ReadBuffer(Pt, SizeOf(Pt));
      SetCtrlPoint(cpLeft, i, Pt);
      Stream.ReadBuffer(Pt, SizeOf(Pt));
      SetCtrlPoint(cpRight, i, Pt);
    end;
  end;
end;

end.

