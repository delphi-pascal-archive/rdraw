{*******************************************************************************
*                                                                              *
*                       Author: Reonid                                         *
*                       Categoty: vector graphic                               *
*                       mailto: reonid@yahoo.com                               *
*                                                                              *
*******************************************************************************}

unit RLine; // RStLine

interface

uses
  RTypes, RCore, RCurve, RCrvCtl,
  Controls, Classes;

type
  TRStraightLineController = class(TRCurveController)
  public
    class function Options: TRCurveEditOptions; override;
    function CreateMultiselector: TRAgentDecorator; override;
  end;

  TRLineCreateEvent = function(Layer: TRLayer;
    const FirstPt, SecondPt: TPointF): TRFigure of object;

  TRLineCreationTool = class(TRTool)
  private
    FFigure: TRFigure;
    FOnCreate: TRLineCreateEvent;

    procedure DrawLine(Sheet: TRSheet; const Rect: TRect;
      const FirstPt, SecondPt: TPoint);
  protected
    function CreateFigure(Sheet: TRSheet): TRFigure;

    procedure BeginHandleMouse(Sheet: TRSheet; var Handled: Boolean); override;
    procedure EndHandleMouse(Sheet: TRSheet); override;

    function KeepActiveFigure(Sheet: TRSheet): Boolean; override;
  public
    property Figure: TRFigure read FFigure write FFigure;
    property OnCreate: TRLineCreateEvent read FOnCreate write FOnCreate;
  end;

function LineCreationTool: TRLineCreationTool;

implementation

uses
  RFigHlp, RUndo, RTool;

var
  theOptions: TRCurveEditOptions;
  theLineCreation: TRLineCreationTool;

function LineCreationTool: TRLineCreationTool;
begin
  if theLineCreation = nil then
    theLineCreation := TRLineCreationTool.Create('Creation');
  Result := theLineCreation;
end;

{------------------------- TRStraightLineController ---------------------------}

function TRStraightLineController.CreateMultiselector: TRAgentDecorator;
begin
  Result := nil; 
end;

class function TRStraightLineController.Options: TRCurveEditOptions;
begin
  Result := theOptions;
end;

{----------------------------- TRLineCreationTool -----------------------------}

function TRLineCreationTool.CreateFigure(Sheet: TRSheet): TRFigure;
begin
  Result := nil;
  if Assigned(FOnCreate) and Assigned(Sheet.WorkingLayer) then
    Result := FOnCreate(Sheet.WorkingLayer, Sheet.WorkingLayer.DownPt, Sheet.WorkingLayer.CurrPt);

  if Assigned(Result) then
    UndoStack(Sheet).Push(
      TRCreationUndoPoint.Create(Result, Sheet, Sheet.WorkingLayer)
    );
end;

procedure TRLineCreationTool.BeginHandleMouse(Sheet: TRSheet; var Handled: Boolean);
begin
{  Sheet.ProcessActiveFigure;
  if Sheet.EventHandled then Exit; }

  Handled := True;
  if not Assigned(Sheet.WorkingLayer) then Exit;

  Sheet.WorkingLayer.Prepare(prHandleMouse);

  case Sheet.Event of
    evMouseDown: FFigure := nil;

    evMouseUp:
    begin
      Sheet.WorkingLayer.Deselect;

      with Sheet.WorkingLayer.Sheet do
        if (Abs(CurrPt.X - DownPt.X) > 5)or(Abs(CurrPt.Y - DownPt.Y) > 5)then
        begin
          FFigure := CreateFigure(Sheet);
          if Assigned(FFigure) then FFigure.SelectProgramly(Sheet.WorkingLayer);
          Sheet.WorkingLayer.Sheet.Redraw := true;
        end;
    end;

    evMouseMove:
    begin
      if (ssLeft in Sheet.ShiftState) then
      begin
        XORDraw(Sheet, DrawLine);
      end;
    end;

  end;
end;

function TRLineCreationTool.KeepActiveFigure(Sheet: TRSheet): Boolean;
begin
  Result := False;
end;

procedure TRLineCreationTool.EndHandleMouse(Sheet: TRSheet);
begin
  {}
end;

procedure TRLineCreationTool.DrawLine(Sheet: TRSheet; const Rect: TRect;
  const FirstPt, SecondPt: TPoint);
begin
  Sheet.Canvas.MoveTo(FirstPt.X, FirstPt.Y);
  Sheet.Canvas.LineTo(SecondPt.X, SecondPt.Y);
end;

initialization

  theOptions := TRCurveEditOptions.Create;
  with theOptions do
  begin
    Point := eoEdit;
    Segment := eoMoveObj;
    Area := eoIgnore;
    MultiPointMode := mpmAllOp;
    AllowSelectFigureAsWhole := True;
    AllowAddAndDeletePoints := False;
  end;
  
finalization
  theOptions.Free;
  theLineCreation.Free; 
end.
