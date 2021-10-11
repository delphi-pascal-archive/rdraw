unit _createFig;

interface

uses
  Classes, Graphics,

  RTypes, RCore, RCurve, RBezier, RCrvCtl, RBzrCtl, RLine;

  function CreateEllipse(const Rect: TRectF): TRBezier;
  function CreateRectangle(const Rect: TRectF): TRBezier;
  function CreateStraightLine(const Pt0, Pt1: TPointF): TRBezier;
  function CreateLinearCurve(const Pt0, Pt1: TPointF): TRBezier;

implementation

uses
   RFigHlp, _myBzr, _myCrv;

function CreateEllipse(const Rect: TRectF): TRBezier;
var i: Integer;
const MAGIC_NUMBER = 0.551897; //0.54858;
begin
  Result := TMyBezier.CreateEx(4);
  Result.Closed := True;

  for i := Result.Low to Result.High do // !!!!!
    Result.SegmentType[i] := stBezier;

  for i := Result.Low to Result.High do
  begin
    //Result.SegmentType[i] := stBezier;
    Result.NodeType[i] := ntSymmet;
    Result.Y[i] := sin(i*Pi/2);
    Result.X[i] := -cos(i*Pi/2);

    Result.LCtrlPt[i] := PointF(  -MAGIC_NUMBER*sin(i*Pi/2), -MAGIC_NUMBER*cos(i*Pi/2)  );
    //Result.RCtrlPt[i] := PointF(  MAGIC_NUMBER*sin(i*Pi/2), MAGIC_NUMBER*cos(i*Pi/2)  );
  end;

  Result.Controller := TRBezierController.Create;
  TRFigureHelper(Result).PlaceInRect(Rect);
end;

function CreateRectangle(const Rect: TRectF): TRBezier;
var i: Integer;
const data: array[0..3]of Double = (0, 1, 1, 0);
begin
  Result := TMyBezier.CreateEx(4);
  Result.Closed := True;

  for i := Result.Low to Result.High do
  begin
    Result.Y[i] := data[(i+1)mod 4];
    Result.X[i] := data[i];
    Result.NodeType[i] := ntCusp;
    Result.SegmentType[i] := stLine;
  end;

  Result.Controller := TRBezierController.Create;
  TRFigureHelper(Result).PlaceInRect(Rect);
end;

function CreateStraightLine(const Pt0, Pt1: TPointF): TRBezier;
begin
  Result := TMyBezier.CreateEx(2);
  Result.Closed := False;

  Result.Points[0] := Pt0;
  Result.Points[1] := Pt1;

  Result.NodeType[0] := ntCusp;
  Result.NodeType[1] := ntCusp;

  Result.SegmentType[0] := stLine;
  Result.SegmentType[1] := stLine;

  Result.Marker.Shape := mkCircle;

  Result.Controller := TRStraightLineController.Create;
end;

function CreateLinearCurve(const Pt0, Pt1: TPointF): TRBezier;
begin
  Result := TMyBezier.CreateEx(2);
  Result.Closed := False;

  Result.Points[0] := Pt0;
  Result.Points[1] := Pt1;

  Result.NodeType[0] := ntCusp;
  Result.NodeType[1] := ntCusp;

  Result.SegmentType[0] := stBezier;
  Result.SegmentType[1] := stBezier;

  Result.Marker.Shape := mkSquare;

  Result.Controller := TRBezierController.Create;
end;

end.

