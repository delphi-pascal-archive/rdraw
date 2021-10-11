{*******************************************************************************
*                                                                              *
*                       Author: Reonid                                         *
*                       Categoty: vector graphic                               *
*                       mailto: reonid@yahoo.com                               *
*                                                                              *
*******************************************************************************}

unit RCrvCtl;

interface

uses
  {$IFDEF UNIX} {$ELSE} Windows, {$ENDIF}
  RSysDep,
  RCore, RTypes, RIntf, RCurve, Classes, Controls, RSelFrm, Graphics;

type
  TRSelCurvePoint = class;

  TRElementAction = (eoIgnore, eoSelect, eoMoveObj, eoEdit);
  TRMultiPointMode = (mpmNone, mpmTranslate, mpmAllOp);

  TRCurveEditOptions = class
  private
    FAllowSelectFigureAsWhole: Boolean;
    FAllowAddAndDeletePoints: Boolean;
    FMultiPointMode: TRMultiPointMode;
    FElements: array[TRCurveElement]of TRElementAction;
    FSegmentSensitivity: Integer;
    FPointSensitivity: Integer;

    function GetElements(Element: TRCurveElement): TRElementAction;
    procedure SetElements(Element: TRCurveElement; const Value: TRElementAction);
    procedure Assign(Source: TRCurveEditOptions);
  public
    constructor Create;

    property AllowSelectFigureAsWhole: Boolean read FAllowSelectFigureAsWhole write FAllowSelectFigureAsWhole;
    property AllowAddAndDeletePoints: Boolean read FAllowAddAndDeletePoints write FAllowAddAndDeletePoints;
    property MultiPointMode: TRMultiPointMode read FMultiPointMode write FMultiPointMode;
    property SegmentSensitivity: Integer read FSegmentSensitivity write FSegmentSensitivity; 

    property Elements[Element: TRCurveElement]: TRElementAction read GetElements write SetElements;
    property Point: TRElementAction index cePoint read GetElements write SetElements;
    property Segment: TRElementAction index ceSegment read GetElements write SetElements;
    property Area: TRElementAction index ceArea read GetElements write SetElements;
  end;

  TRCurveController = class(TRControllerEx)
  private
    FSelPoint: TRSelCurvePoint;
    FSelection: TRCurveSelection;
    FSelFrame: TRSelectionFrame;
    FMover: TRAgentDecorator;
    FMultiselector: TRAgentDecorator;
    FAttorney: TRAgentDecorator;

    FPointUnderCursor: Integer;
  protected
    function Curve: TRCurve;
    procedure ReviseSelection(Layer: TRLayer);
    function GetTransformerForWholeCurve(Layer: TRLayer): TRAgentDecorator;

    function CreateSelFrame: TRSelectionFrame; virtual;
    function CreateSelPoint: TRSelCurvePoint; virtual;
    function CreateSelection: TRCurveSelection; virtual;
    function CreateMover: TRAgentDecorator; virtual;
    function CreateMultiselector: TRAgentDecorator; virtual;
    function CreateAttorney: TRAgentDecorator; virtual;

    procedure UpgradeAgent(var AAgent: TRFigure); override;
    procedure DecorateByTransformer(Layer: TRLayer); override;
    function SelectRect(Layer: TRLayer; Rect: TRectF): Boolean; override;

    procedure MouseDown(Layer: TRLayer; var Handled: Boolean); override;
    procedure MouseMove(Layer: TRLayer; var Cursor: TCursor); override;
    procedure MouseUp(Layer: TRLayer); override;
    procedure KeyDown(Layer: TRLayer; var Key: Word); override;
  public
    class function Options: TRCurveEditOptions; virtual;
    class procedure SetOptions(Value: TRCurveEditOptions); //virtual;

    constructor Create; override;
    destructor Destroy; override;

    function Supports(AObject: TObject): Boolean; override;

    procedure Deselect; override;
    procedure ExtraDraw(Layer: TRLayer; Reason: TRExtraDrawReason); override;
    function AllowSelectFigureAsWhole: Boolean; override;
    function AllowFurtherMultiSelect: Boolean; override;
  end;

  TRSelCurvePoint = class(TRAgentDecorator)
  private
    FCurve: TRCurve;
    FIndex: Integer;
    FParam01: TFloat;
    FImaginary: Boolean;
    function GetCurvePoint: TPointF;
    procedure SetCurvePoint(const Value: TPointF);
  protected
    procedure DeletePoint(Layer: TRLayer); virtual;
    procedure Draw(Layer: TRLayer); override;
    procedure PutUndoPoint(Layer: TRLayer);
  public
    property Imaginary: Boolean read FImaginary;
    property Index: Integer read FIndex;
    property Param01: TFloat read FParam01;
    property CurvePoint: TPointF read GetCurvePoint write SetCurvePoint;

    constructor Create; override; 

    function Init(ACurve: TRCurve; I: Integer): TRSelCurvePoint;
    function InitImaginary(ACurve: TRCurve; I: Integer; t: TFloat): TRSelCurvePoint;

    function Curve: TRCurve;
    function Empty: Boolean;
    procedure UndoablyActualize(Layer: TRLayer); virtual;
    procedure UndoablyDelete(Layer: TRLayer); override;
    function Sensitivity: Integer;
    procedure Clear;
  end;

  TRSelCurvePointController = class(TRAgentDecoratorController)
  private
    FHitDisplacement: TPoint;
    FCurveController: TRCurveController;
  protected
    function SelPoint: TRSelCurvePoint;
    procedure Transmute(Layer: TRLayer); virtual;
  public
    constructor Create(ACurveController: TRCurveController); reintroduce;

    function  Hit(Layer: TRLayer; Pt: TPointF): Boolean; virtual;
    procedure MouseDown(Layer: TRLayer; var Handled: Boolean); override;
    procedure MouseMove(Layer: TRLayer; var Cursor: TCursor); override;
    procedure MouseUp(Layer: TRLayer); override;
    procedure KeyDown(Layer: TRLayer; var Key: Word); override;

    function Supports(AObject: TObject): Boolean; override;
    function Agent: TRFigure; override;
  end;

  TRCurveMultiselector = class(TRAgentDecorator);

  TRCurveMultiselectorController = class(TRAgentDecoratorController)
  private
    FCurveController: TRCurveController;
  public
    constructor Create(ACurveController: TRCurveController); reintroduce;

    function SelectRect(Layer: TRLayer; Rect: TRectF): Boolean; override;
    procedure MouseDown(Layer: TRLayer; var Handled: Boolean); override;
    procedure MouseMove(Layer: TRLayer; var Cursor: TCursor); override;
    procedure MouseUp(Layer: TRLayer); override;
    procedure KeyDown(Layer: TRLayer; var Key: Word); override;
  end;

  TRCurveMover = class(TRAgentDecorator);

  TRCurveMoverController = class(TRAgentDecoratorController)
  private
    FCurveController: TRCurveController;
    //FSelectedPoints: Boolean;
  protected
    procedure PutUndoPoint(Layer: TRLayer);
  public
    constructor Create(ACurveController: TRCurveController); reintroduce;

    procedure MouseDown(Layer: TRLayer; var Handled: Boolean); override;
    procedure MouseMove(Layer: TRLayer; var Cursor: TCursor); override;
    procedure MouseUp(Layer: TRLayer); override;
    procedure KeyDown(Layer: TRLayer; var Key: Word); override;
  end;

  TRCurveAttorney = class(TRAgentDecorator)
  private
    FCurveController: TRCurveController;
    function GetCurve: TRCurve;
  public
    property Curve: TRCurve read GetCurve;
    constructor Create(ACurveController: TRCurveController); reintroduce;
  end;

  TRCurveAttorneyController = class(TRAgentDecoratorController)
  public
    procedure MouseDown(Layer: TRLayer; var Handled: Boolean); override;
    procedure MouseMove(Layer: TRLayer; var Cursor: TCursor); override;
    procedure MouseUp(Layer: TRLayer); override;
  end;

implementation

uses Math, RCrvHlp, RFigHlp, RGeom, RUndo;

var
  theCurveEditOptions: TRCurveEditOptions;

const
  ImaginaryPointRadius = 3;

{---------------------------- TRCurveController -------------------------------}

constructor TRCurveController.Create;
begin
  inherited;

  FSelFrame := CreateSelFrame;
  FSelPoint := CreateSelPoint;
  FSelection := CreateSelection;
  FMover := CreateMover;
  FMultiselector := CreateMultiselector;
  FAttorney := CreateAttorney;

  FPointUnderCursor := -1;
end;

function TRCurveController.Curve: TRCurve;
begin
  Result := Controllee as TRCurve;
end;

destructor TRCurveController.Destroy;
begin
  FSelFrame.Free;
  FSelPoint.Free;
  FSelection.Free;
  FMover.Free;
  FMultiselector.Free;
  FAttorney.Free;

  inherited;
end;

function TRCurveController.CreateSelFrame: TRSelectionFrame;
begin
  Result := TRSelectionFrame.Create;
  Result.Controller := TRSelectionFrameController.Create;
end;

function TRCurveController.CreateSelection: TRCurveSelection;
begin
  Result := TRCurveSelection.Create;  {w/o controller}
end;

function TRCurveController.CreateSelPoint: TRSelCurvePoint;
begin
  Result := TRSelCurvePoint.Create;
  Result.Controller := TRSelCurvePointController.Create(Self);
end;

function TRCurveController.CreateMover: TRAgentDecorator;
begin
  Result := TRCurveMover.Create;
  Result.Controller := TRCurveMoverController.Create(Self);
end;

function TRCurveController.CreateMultiselector: TRAgentDecorator;
begin
  Result := TRCurveMultiselector.Create;
  Result.Controller := TRCurveMultiselectorController.Create(Self);
end;

function TRCurveController.CreateAttorney: TRAgentDecorator;
begin
  Result := TRCurveAttorney.Create(Self); 
  Result.Controller := TRCurveAttorneyController.Create;
end;

class function TRCurveController.Options: TRCurveEditOptions;
begin
  Result := theCurveEditOptions;
end;

class procedure TRCurveController.SetOptions(Value: TRCurveEditOptions);
begin
  Options.Assign(Value);
end;

function TRCurveController.Supports(AObject: TObject): Boolean;
begin
  Result := AObject is TRCurve;
end;

procedure TRCurveController.KeyDown(Layer: TRLayer; var Key: Word);
begin
  inherited;
end;

procedure TRCurveController.MouseDown(Layer: TRLayer; var Handled: Boolean);
var I: Integer;
    t: TFloat;
    ce: TRCurveElement;
    hit: Boolean;

    procedure SelectOnePoint;
    begin
      FSelection.Clear;
      FSelection.AddPoint(Curve, I, smNormal);
      ReviseSelection(Layer);
    end;

    procedure InitImaginaryPoint;
    begin
      FSelection.Clear;
      AssignAgent(FMultiselector.Init(FSelPoint.InitImaginary(Curve, I, t)));
    end;
begin
  if IsInAgentMode then Exit;

  hit := False;
  for ce := cePoint to ceArea do
  begin
    if Options.Elements[ce] = eoIgnore then Continue;
    case ce of
      cePoint: hit := Curve.HitPoint(Layer, Layer.CurrPt, 5, I);
      ceSegment: hit := Curve.HitSegment(Layer, Layer.CurrPt, 3, I, t);
      ceArea: hit := Curve.HitArea(Layer, Layer.CurrPt);
    end;

    if hit then
    begin
      case Options.Elements[ce] of
        eoIgnore: Exit;
        eoMoveObj: AssignAgent(FMultiselector.Init(FMover.Init(Curve)));
        eoSelect: AssignAgent(GetTransformerForWholeCurve(Layer).Init(Curve));
        eoEdit:
          case ce of
            cePoint: SelectOnePoint;
            ceSegment: InitImaginaryPoint;
            ceArea: AssignAgent(Curve); //nonsense????
          end;
      end;
      //FHitElement := ce;
      Handled := True;
      Break;
    end;
  end;
end;

procedure TRCurveController.MouseMove(Layer: TRLayer; var Cursor: TCursor);
var I: Integer;
    t: TFloat;
    ce: TRCurveElement;
    hit: Boolean;

    function HitPoint(var I: Integer): Boolean;
    begin
      Result := Curve.HitPoint(Layer, Layer.CurrPt, 5, I);
      if Result then
      begin
        if FPointUnderCursor <> i then Layer.Sheet.Redraw := True;
        FPointUnderCursor := i;
      end else
      begin
        if FPointUnderCursor > -1 then Layer.Sheet.Redraw := True;
        FPointUnderCursor := -1;
      end;
    end;

begin
  if IsInAgentMode and(csCaptured in State) then Exit;

  if not (ssLeft in Layer.Sheet.ShiftState) then
  begin

    hit := False;
    for ce := cePoint to ceArea do
    begin
      if Options.Elements[ce] = eoIgnore then Continue;
      case ce of
        cePoint: hit := HitPoint(I);//Curve.HitPoint(Layer, Layer.CurrPt, 5, I);
        ceSegment: hit := Curve.HitSegment(Layer, Layer.CurrPt, 3, I, t);
        ceArea: hit := Curve.HitArea(Layer, Layer.CurrPt);
      end;

      if hit then
      begin
        case Options.Elements[ce] of
          eoIgnore: Exit;
          eoMoveObj: Cursor := crMoveObj;
          eoSelect: Cursor := crMoveObj;
          eoEdit: Cursor := crMovePoint;
        end;
        Break;
      end;
    end;

  end;
end;

procedure TRCurveController.ExtraDraw(Layer: TRLayer; Reason: TRExtraDrawReason);
var i, xx, yy: Integer;
begin
  if Reason = drHighlight then
  begin
    i := FPointUnderCursor;
    if i = -1 then Exit;
    if Agent = FSelFrame then Exit; //!!!!!!
    if Options.Point <> eoEdit then Exit;

    Layer.Converter.LogicToScreen(Curve.X[i], Curve.Y[i], xx, yy);
    Curve.Marker.PrepareDraw(Layer, dmHighlighted);
    Curve.Marker.Draw(Layer, xx, yy, i, dmHighlighted);
  end;
end;

procedure TRCurveController.Deselect;
begin
  FSelection.Clear;
  FSelPoint.Clear;
  inherited;
end;

procedure TRCurveController.MouseUp(Layer: TRLayer);
begin
  //FHitElement := ceNone;
end;

procedure TRCurveController.UpgradeAgent(var AAgent: TRFigure);
begin
  inherited;
  AAgent := FAttorney.Init(AAgent);
end;

procedure TRCurveController.ReviseSelection(Layer: TRLayer);
begin
  case FSelection.Length of
    0: AssignAgent(FMultiselector.Init(Curve));
    1: AssignAgent(FMultiselector.Init(FSelPoint.Init(Curve, FSelection.GetIndex(0))));
    else
    begin
      if Options.MultiPointMode = mpmTranslate then
        AssignAgent(FMultiselector.Init(FMover.Init(FSelection)))
      else if Options.MultiPointMode = mpmAllOp then
        AssignAgent(FMultiselector.Init(FSelFrame.Init(FSelection)))
      else if Options.MultiPointMode = mpmNone then
      begin
        AssignAgent(FMultiselector.Init(FSelPoint.Init(Curve, FSelection.GetIndex(0))));
        FSelection.ClearExceptFirst;
      end;
    end;
  end;
end;

function TRCurveController.GetTransformerForWholeCurve(Layer: TRLayer): TRAgentDecorator;
begin
  if (Options.Segment = eoMoveObj)or
     (Options.Area = eoMoveObj)or
     (Options.Point = eoMoveObj)
    then Result := FMover
    else Result := Layer.DefaultTransformer;
end;

procedure TRCurveController.DecorateByTransformer(Layer: TRLayer);
begin
  AssignAgent(GetTransformerForWholeCurve(Layer).Init(Controllee));
end;

function TRCurveController.SelectRect(Layer: TRLayer; Rect: TRectF): Boolean;
begin
  Result := False; 
  if IsInAgentMode then Exit; 

  if (Options.MultiPointMode = mpmNone)
    then FSelection.Clear
    else FSelection.AcquirePoints(Curve, Rect, Layer.SelectMode);

  Result := not FSelection.Empty;
  ReviseSelection(Layer);
end;

function TRCurveController.AllowSelectFigureAsWhole: Boolean;
begin
  Result := Options.AllowSelectFigureAsWhole;
end;

function TRCurveController.AllowFurtherMultiSelect: Boolean;
begin
  Result := Options.AllowSelectFigureAsWhole;
end;

{----------------------- TRSelCurvePoint ---------------------------------}

constructor TRSelCurvePoint.Create;
begin
  inherited;
  Style := Style + [fsServant];
end;

function TRSelCurvePointController.Agent: TRFigure;
begin
  Result := Controllee;
end;

function TRSelCurvePoint.Curve: TRCurve;
begin
  Result := FCurve;
end;

procedure TRSelCurvePoint.UndoablyActualize(Layer: TRLayer);
begin
  if (not Empty) and Imaginary then
  begin
    PutUndoPoint(Layer);

    FIndex := Curve.ActualizeIntermediatePoint(FIndex, FParam01);
    FImaginary := False;
  end;
end;

procedure TRSelCurvePoint.Clear;
begin
  FCurve := nil;
  FIndex := -1;
end;

procedure TRSelCurvePoint.PutUndoPoint(Layer: TRLayer);
begin
  UndoStack(Layer.Sheet).Push(
    GetUndoPoint(Curve, Layer.Sheet, Layer, [daGeometry])
  );
end;

function TRSelCurvePoint.Sensitivity: Integer;
begin
  if Imaginary
    then Result := ImaginaryPointRadius + 1
    else Result := (Curve.Marker.Size div 2) + 2;
end;

procedure TRSelCurvePoint.Draw(Layer: TRLayer);
var xx, yy, rr: Integer;
begin
  if Empty then Exit;

  Layer.Canvas.Brush.Color := clBlack;
  Layer.Canvas.Brush.Style := bsSolid;
  Layer.Canvas.Pen.Color := clBlack;
  Layer.Canvas.Pen.Style := psSolid;

  Layer.Canvas.Pen.Mode := pmCopy;
  Layer.Canvas.Pen.Width := 1;

  Layer.Converter.LogicToScreen(CurvePoint.X, CurvePoint.Y, xx, yy);
  if FImaginary then
  begin
    rr := ImaginaryPointRadius;
    Layer.Canvas.Ellipse(xx-rr+1, yy-rr+1, xx+rr, yy+rr);
  end
  else
  begin
    Curve.Marker.PrepareDraw(Layer, dmSelected);
    Curve.Marker.Draw(Layer, xx, yy, Index, dmSelected);
  end;
end;

function TRSelCurvePoint.Empty: Boolean;
begin
  Result := (FCurve = nil)or
            (FIndex < 0)or
            (FIndex > FCurve.High)or
            (FImaginary and (FIndex = FCurve.High) and (not FCurve.Closed));
end;

function TRSelCurvePoint.GetCurvePoint: TPointF;
begin
  if FImaginary
    then Result := Curve.GetIntermediatePoint(FIndex, FParam01)
    else Result := PointF(FCurve.X[FIndex], FCurve.Y[FIndex]);
end;

function TRSelCurvePoint.Init(ACurve: TRCurve; I: Integer): TRSelCurvePoint;
begin
  Result := Self;
  FCurve := ACurve;
  FIndex := I;
  FImaginary := False;

  inherited Init(ACurve);
end;

function TRSelCurvePoint.InitImaginary(ACurve: TRCurve; I: Integer;
  t: TFloat): TRSelCurvePoint;
begin
  Result := Self;
  FCurve := ACurve;
  FIndex := I;
  FParam01 := t;
  FImaginary := True;

  inherited Init(ACurve);
end;

procedure TRSelCurvePoint.SetCurvePoint(const Value: TPointF);
begin
  if not FImaginary then
  begin
    FCurve.X[FIndex] := Value.X;
    FCurve.Y[FIndex] := Value.Y;
  end;
end;

procedure TRSelCurvePoint.UndoablyDelete(Layer: TRLayer);
begin
  if (not Empty)and(not Imaginary)and TRCurveHelper(Curve).IsResizeable then
  begin
    if Curve.Length = 1 then
    begin
      Curve.UndoablyDelete(Layer);
      Layer.Deselect;
      Clear;
    end
    else
    begin
      PutUndoPoint(Layer);
      DeletePoint(Layer);
    end;
  end;
end;

procedure TRSelCurvePoint.DeletePoint(Layer: TRLayer);
begin
  TRCurveHelper(Curve).DeleteBlock(FIndex, 1);
  Clear;
end;

{------------------- TRSelCurvePointController ---------------------------}

constructor TRSelCurvePointController.Create(ACurveController: TRCurveController);
begin
  inherited Create;
  FCurveController := ACurveController;
end;

procedure TRSelCurvePointController.Transmute(Layer: TRLayer);
var scrPt: TPoint;
    logPt: TPointF;
begin
  scrPt := Layer.Sheet.CurrPt;
  OffsetPoint(scrPt, -FHitDisplacement.X, -FHitDisplacement.Y);
  Layer.Converter.ScreenToLogic(scrPt, logPt);
  SelPoint.SetCurvePoint(logPt);
  Layer.Sheet.Redraw := True;
end;

function TRSelCurvePointController.Hit(Layer: TRLayer; Pt: TPointF): Boolean;
var
  CrvPt: TPointF;
  scrCrvPt, scrPt: TPoint;
  ptRect: TRect;
  Sens: Integer;
begin
  CrvPt := SelPoint.CurvePoint;
  Layer.Converter.LogicToScreen(CrvPt.X, CrvPt.Y, scrCrvPt.X, scrCrvPt.Y);
  Layer.Converter.LogicToScreen(Pt.X, Pt.Y, scrPt.X, scrPt.Y);

  Sens := SelPoint.Sensitivity;
  ptRect := PointRect(scrCrvPt, Sens, Sens);
  Result := PtInRect(ptRect, scrPt);
  FHitDisplacement := Point(scrPt.X - scrCrvPt.X, scrPt.Y - scrCrvPt.Y);
end;

procedure TRSelCurvePointController.KeyDown(Layer: TRLayer; var Key: Word);
var j: Integer;
    t: TFloat;
    pt, nudge: TPointF;
begin
  {Add point}
  if Key in [VK_ADD] then
  begin
    Layer.Sheet.EventHandled := True;
    if not FCurveController.Options.AllowAddAndDeletePoints then
    begin
      Key := 0;
      Exit;
    end;

    SelPoint.PutUndoPoint(Layer);
    Layer.Sheet.Redraw := True;

    if SelPoint.Imaginary then
      SelPoint.UndoablyActualize(Layer)
    else
    begin
      if (not SelPoint.Curve.Closed)and(SelPoint.Index = SelPoint.Curve.High) then Exit;

      SelPoint.Curve.CalcSegmentCenter(SelPoint.Index, t);
      j := SelPoint.Curve.ActualizeIntermediatePoint(SelPoint.Index, t);
      FCurveController.FSelection.AddPoint(SelPoint.Curve, j, smPlus);
      FCurveController.ReviseSelection(Layer);
    end;

    Key := 0;
  end;

  {Move point}
  if Key in [VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN{, VK_PRIOR, ...}] then
  begin
    Layer.Sheet.EventHandled := True;
    SelPoint.PutUndoPoint(Layer);

    nudge := Layer.Nudge;
    pt := SelPoint.CurvePoint;

    case Key of
      VK_LEFT: OffsetPointF(pt, -nudge.X, 0);
      VK_RIGHT: OffsetPointF(pt, nudge.X, 0);
      VK_UP: OffsetPointF(pt, 0, nudge.Y);
      VK_DOWN: OffsetPointF(pt, 0, -nudge.Y);
    end;
    SelPoint.CurvePoint := pt;

    Layer.Sheet.Redraw := True;
    Key := 0;
  end;
end;

procedure TRSelCurvePointController.MouseDown(Layer: TRLayer; var Handled: Boolean);
begin
  if SelPoint.Empty then Exit;
  if not(Layer.SelectMode in [smNormal, smPlus]) then Exit;

  if Hit(Layer, Layer.CurrPt) then Handled := True;

  with SelPoint do
  begin
    if Handled and Imaginary and
       not(ssAgentInitializing in Layer.Sheet.State)then
    begin
      UndoablyActualize(Layer);
      FCurveController.FSelection.Clear;
      FCurveController.FSelection.AddPoint(FCurve, Index, smNormal);
      FCurveController.ReviseSelection(Layer);
    end;
  end;

  Layer.Sheet.Redraw := True;
end;

procedure TRSelCurvePointController.MouseMove(Layer: TRLayer; var Cursor: TCursor);
begin
  if SelPoint.Empty then Exit;
  if (ssLeft in Layer.Sheet.ShiftState) then
  begin
    if Layer.Sheet.PrevMouseEvent = evMouseDown then
      SelPoint.PutUndoPoint(Layer); // {?? - only 1 point}

    Transmute(Layer);
  end;
end;

procedure TRSelCurvePointController.MouseUp(Layer: TRLayer);
begin
end;

function TRSelCurvePointController.SelPoint: TRSelCurvePoint;
begin
  Result := Controllee as TRSelCurvePoint;
end;

function TRSelCurvePointController.Supports(AObject: TObject): Boolean;
begin
  Result := AObject is TRSelCurvePoint;
end;

{-------------------- TRCurveMultiselectorController --------------------------}

constructor TRCurveMultiselectorController.Create(ACurveController: TRCurveController);
begin
  inherited Create;
  FCurveController := ACurveController;
end;

procedure TRCurveMultiselectorController.MouseDown(Layer: TRLayer; var Handled: Boolean);
var i, Sens: Integer;
begin
  if Layer.SelectMode <> smNormal then
    with FCurveController do
    begin
      Sens := (Curve.Marker.Size div 2) + 2;
      if Curve.HitPoint(Layer, Layer.CurrPt, Sens, i) then
      begin
        FSelection.AddPoint(Curve, i, Layer.SelectMode);
        ReviseSelection(Layer);
        Handled := True; //FSelection.Length > 0;
      end;
    end;
end;

function TRCurveMultiselectorController.SelectRect(Layer: TRLayer; Rect: TRectF): Boolean;
begin
  Result := False;
  if Layer.SelectMode <> smNormal then
    with FCurveController do
    begin
      FSelection.AcquirePoints(Curve, Rect, Layer.SelectMode);
      ReviseSelection(Layer);
      Result := True; //FSelection.Length > 0;
    end;
end;

procedure TRCurveMultiselectorController.MouseMove(Layer: TRLayer; var Cursor: TCursor);
begin
end;

procedure TRCurveMultiselectorController.MouseUp(Layer: TRLayer);
begin
end;

procedure TRCurveMultiselectorController.KeyDown(Layer: TRLayer; var Key: Word);
begin
  if (Key in [VK_ADD, VK_DELETE])and
     (not FCurveController.Options.AllowAddAndDeletePoints)and
     (FCurveController.FSelection.Length > 0) then
  begin
    Layer.Sheet.EventHandled := True;
    Exit; 
  end;

  if (FCurveController.FSelection.Length > 1) and (Key = VK_ADD) then
  begin
    Layer.Sheet.EventHandled := True;
    FCurveController.FSelection.UndoablyRedouble(Layer);
    FCurveController.ReviseSelection(Layer);
    Layer.Sheet.Redraw := True;
  end;
end;

{------------------------- TRCurveMoverController -----------------------------}

constructor TRCurveMoverController.Create(ACurveController: TRCurveController);
begin
  inherited Create;
  FCurveController := ACurveController;
end;

procedure TRCurveMoverController.PutUndoPoint(Layer: TRLayer);
begin
  UndoStack(Layer.Sheet).Push(
    GetUndoPoint(FCurveController.Curve, Layer.Sheet, Layer, [daGeometry])
  );
end;

procedure TRCurveMoverController.KeyDown(Layer: TRLayer; var Key: Word);
var nudge, delta: TPointF;
    data: TTransformData;
begin
  {Move point}
  if Key in [VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN{, VK_PRIOR, ...}] then
  begin
    Layer.Sheet.EventHandled := True;
    PutUndoPoint(Layer);

    nudge := Layer.Nudge;
    case Key of
      VK_LEFT: delta := PointF(-nudge.X, 0);
      VK_RIGHT: delta := PointF(nudge.X, 0);
      VK_UP: delta := PointF(0, nudge.Y);
      VK_DOWN: delta := PointF(0, -nudge.Y);
    end;
    InitTranslateData(data, delta.X, delta.Y);
    TRFigureHelper((Controllee as TRAgentDecorator).Decoree).Transform(Data);

    Layer.Sheet.Redraw := True;
    Key := 0;
  end;
  inherited;
end;

procedure TRCurveMoverController.MouseDown(Layer: TRLayer; var Handled: Boolean);
var i, Sens: Integer;
    t: TFloat;
    _Curve: TRCurve;
begin
  _Curve := (Controllee as TRAgentDecorator).Decoree as TRCurve;
  with FCurveController do
  begin
    Sens := (Curve.Marker.Size div 2) + 2;
    if _Curve.HitPoint(Layer, Layer.CurrPt, Sens, i) then
      Handled := (Options.Point = eoMoveObj)or(FCurveController.FSelection.Length > 1)
    else if _Curve.HitSegment(Layer, Layer.CurrPt, 3, i, t) then
      Handled := (Options.Segment = eoMoveObj)
    else if _Curve.HitArea(Layer, Layer.CurrPt) then
      Handled := (Options.Area = eoMoveObj);
  end;
end;

procedure TRCurveMoverController.MouseMove(Layer: TRLayer; var Cursor: TCursor);
var Data: TTransformData;
begin
  if ssLeft in Layer.Sheet.ShiftState then
  begin
    if Layer.Sheet.PrevMouseEvent = evMouseDown then
      PutUndoPoint(Layer);

    with Layer do InitTranslateData(Data, CurrPt.X-PrevPt.X, CurrPt.Y-PrevPt.Y);
    //TRFigureHelper(FCurveController.Curve).Transform(Data);
    TRFigureHelper((Controllee as TRAgentDecorator).Decoree).Transform(Data);
    Layer.Sheet.Redraw := True;
  end;
end;

procedure TRCurveMoverController.MouseUp(Layer: TRLayer);
begin
end;

{-------------------------- TRCurveAttorney -----------------------------}

constructor TRCurveAttorney.Create(ACurveController: TRCurveController);
begin
  inherited Create;
  FCurveController := ACurveController;
end;

function TRCurveAttorney.GetCurve: TRCurve;
begin
  Result := FCurveController.Curve;
end;

{--------------------- TRCurveAttorneyController ------------------------}

procedure TRCurveAttorneyController.MouseDown(Layer: TRLayer; var Handled: Boolean);
begin
end;

procedure TRCurveAttorneyController.MouseMove(Layer: TRLayer; var Cursor: TCursor);
begin
end;

procedure TRCurveAttorneyController.MouseUp(Layer: TRLayer);
begin
end;

{--------------------------- TRCurveEditOptions -------------------------------}

constructor TRCurveEditOptions.Create;
begin
  inherited;
  FSegmentSensitivity := 3;
  FPointSensitivity := 5; 
end;

procedure TRCurveEditOptions.Assign(Source: TRCurveEditOptions);
var ce: TRCurveElement;
begin
  FAllowSelectFigureAsWhole := Source.FAllowSelectFigureAsWhole;
  FAllowAddAndDeletePoints := Source.FAllowAddAndDeletePoints;
  FMultiPointMode := Source.FMultiPointMode;
  for ce := Low(TRCurveElement) to High(TRCurveElement) do
    FElements[ce] := Source.FElements[ce];
end;

function TRCurveEditOptions.GetElements(Element: TRCurveElement): TRElementAction;
begin
  Result := FElements[Element];
end;

procedure TRCurveEditOptions.SetElements(Element: TRCurveElement; const Value: TRElementAction);
begin
  FElements[Element] := Value;
end;

initialization
  theCurveEditOptions := TRCurveEditOptions.Create;
finalization
  theCurveEditOptions.Free;
end.
