{*******************************************************************************
*                                                                              *
*                       Author: Reonid                                         *
*                       Categoty: vector graphic                               *
*                       mailto: reonid@yahoo.com                               *
*                                                                              *
*******************************************************************************}

unit RCrvUtils;

interface

uses
  RTypes, RCore, RCurve;

function GetCurveArray(ACurve: TRCurve): TDynArrayOfTPointF;
procedure SetCurveArray(ACurve: TRCurve; const Pts: array of TPointF);

function GetCurveArrayScr(ACurve: TRCurve; ALayer: TRLayer): TDynArrayOfTPoint;
procedure SetCurveArrayScr(ACurve: TRCurve; ALayer: TRLayer; const Pts: array of TPoint);

implementation

uses
  RCrvHlp;

function GetCurveArray(ACurve: TRCurve): TDynArrayOfTPointF;
var i, L: Integer;
begin
  L := ACurve.Length;
  SetLength(Result, L);
  for i := 0 to L-1 do
    Result[i] := ACurve.Points[i];
end;

procedure SetCurveArray(ACurve: TRCurve; const Pts: array of TPointF);
var i, L: Integer;
begin
  L := Length(Pts);
  TRCurveHelper(ACurve).Resize(L);
  for i := 0 to L-1 do
    ACurve.Points[i] := Pts[i];
end;

function GetCurveArrayScr(ACurve: TRCurve; ALayer: TRLayer): TDynArrayOfTPoint;
var i, L: Integer;
    pt: TPoint;
begin
  L := ACurve.Length;
  SetLength(Result, L);
  for i := 0 to L-1 do
  begin
    ALayer.Converter.LogicToScreen(ACurve.Points[i], pt);
    Result[i] := pt;
  end;
end;

procedure SetCurveArrayScr(ACurve: TRCurve; ALayer: TRLayer; const Pts: array of TPoint);
var i, L: Integer;
    pt: TPointF;
begin
  L := Length(Pts);
  TRCurveHelper(ACurve).Resize(L);
  for i := 0 to L-1 do
  begin
    ALayer.Converter.ScreenToLogic(Pts[i], pt);
    ACurve.Points[i] := pt;
  end;
end;

end.
