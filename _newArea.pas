unit _newArea;

interface

uses
  RTypes, RCore, RUndo,
  RAxesOld,
  RCurve, RCrvCtl,
  RGroup, RGrpCtl,
  RZoom, RTool,

  Messages,
  {$IFDEF UNIX}
  {$ELSE}
  Windows,
  {$ENDIF}
  Classes, Graphics, Controls, ExtCtrls, Contnrs;

type

  {
  Note: This component was not designed for use in IDE
  It is simply the wrapper on the library and doesn't have useful properties
  }

  TRAdvancedLayer = class;

  TRNewWorkArea = class(TCustomControl)
  private
    FPlotColor: TColor;
    FMarginColor: TColor;
    FMargins: TRect;

    FSheet: TRSheet;

    FLayers: TObjectList;
    FLayer: TRAdvancedLayer;
    FRightLayer: TRAdvancedLayer;

    FBgRoot: TRGroup;
    FTopRoot: TRGroup;

//    FEditTool: TREditTool;
//    FZoomTool: TRZoomTool;
//    FCreationTool: TRCreationTool;

    FLockZoomSync: Boolean;

    FPropMonitors: TObjectList;

    FInit: Boolean;

    procedure SetMargins(const Value: TRect);
    function GetLayerCount: Integer;
    function GetLayers(I: Integer): TRAdvancedLayer;
  public
    property Canvas;
    property BgRoot: TRGroup read FBgRoot;
    property TopRoot: TRGroup read FTopRoot;
    property LayerCount: Integer read GetLayerCount;
    property Layers[I: Integer]: TRAdvancedLayer read GetLayers;

    property PlotColor: TColor read FPlotColor write FPlotColor;
    property MarginColor: TColor read FMarginColor write FMarginColor;
    property Margins: TRect read FMargins write SetMargins;
    property Sheet: TRSheet read FSheet;
    property Layer: TRAdvancedLayer read FLayer;

//    property EditTool: TREditTool read FEditTool;
//    property ZoomTool: TRZoomTool read FZoomTool;
//    property CreationTool: TRCreationTool read FCreationTool;

    constructor Create(AOwner: TComponent); override;
    constructor CreateEx(AOwner: TComponent; AParent: TWinControl; AAlign: TAlign = alClient);
    destructor Destroy; override;

    procedure ClearArea;

    procedure Resize; override;
    procedure Paint; override;
    procedure Repaint; override;

    procedure PrintContent(const APrintRect: TRect); virtual;

    procedure AddPropertyMonitor(PropertyMonitor: TRPropertyMonitor);

    property PopupMenu;
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;

    procedure HandleKbd(Event: TKbdEventID; var Key: Word; Shift: TShiftState);
    procedure HandleMouse(Event: TMouseEventID; X, Y: Integer;
      Shift: TShiftState; Button: TMouseButton);

    procedure WMEraseBkgnd(var Message: TMessage); message WM_ERASEBKGND;
    {$IFDEF FPC} {$ELSE}
    procedure CMWantSpecialKey(var Message: TCMWantSpecialKey); message CM_WANTSPECIALKEY;
    {$ENDIF}

    procedure ZoomSync(ALayer: TRLayer);
    class procedure ZoomOut(ALayer: TRLayer; var NewViewPort: TRectF);
    procedure SelectionChanged(Sheet: TRSheet);

    procedure ProcessContent; virtual;

    procedure CreateRObjects;
    function CreateLayer: TRAdvancedLayer; virtual;
    function CreateRoot: TRGroup; virtual;

    procedure CalcPlotRect(var R: TRect); virtual;
  public
    function NewLayer(ARect: TRect): TRAdvancedLayer;
    procedure Deselect;
    procedure Undo;

    class function GetGlobalTool: TRTool;
    class procedure SetGlobalTool(ATool: TRTool);
  end;

  TRAdvancedLayer = class(TRLayer)
  private
    FOnZoomSync: TRLayerEvent;
    FRoot: TRGroup;
    FAxes: TRAxes;
  protected
    property OnZoomSync: TRLayerEvent read FOnZoomSync write FOnZoomSync;
    function CreateAxes: TRAxes; virtual;
    procedure ZoomChanged; override;
    procedure AdjustNewViewPort(const OldValue: TRectF; var NewValue: TRectF); override;
  public
    property Root: TRGroup read FRoot;
    property Axes: TRAxes read FAxes;

    constructor Create(ARoot: TRGroup);
    destructor Destroy; override;

    procedure ProcessContent; virtual;
  end;

  TRSheetWithUndoStack = class(TRSheet)
  private
    FUndoStack: TRUndoStack;
  protected
    function _UndoStack: TObject; override;
  public
    destructor Destroy; override;
    procedure Prepare(Reason: TPrepareReason); override;
  end;

procedure SetCurveEditMode(EditPoint: Boolean; AMultiPointMode: TRMultiPointMode = mpmAllOp);

implementation

uses
  SysUtils, RFigHlp, RGeom, Printers;

var
  GlobalTool: TRTool;

{---------------------------- TRAdvancedLayer ---------------------------------}

constructor TRAdvancedLayer.Create(ARoot: TRGroup);
begin
  inherited Create;
  FRoot := ARoot;
  FAxes := CreateAxes;
end;

destructor TRAdvancedLayer.Destroy;
begin
  FRoot.Free;
  FAxes.Free;
  inherited;
end;

function TRAdvancedLayer.CreateAxes: TRAxes;
begin
  Result := TRAxes.Create;
end;

procedure TRAdvancedLayer.ProcessContent;
begin
  ProcessFigure(FAxes);
  ProcessFigure(FRoot);
  //ProcessFigure(FAxes);
end;

procedure TRAdvancedLayer.ZoomChanged;
begin
  inherited;
  if Assigned(FOnZoomSync) then FOnZoomSync(Self);
end;

procedure TRAdvancedLayer.AdjustNewViewPort(const OldValue: TRectF; var NewValue: TRectF);
begin
  inherited;
  // property Layer.Proportional is not still compatible
  // with usage of several layers with the same X scale.
end;
                                                
{function TRAdvancedLayer.CreateRoot: TRGroup;
begin
  Result := TRGroup.Create;
  Result.Controller := TRScatterGroupController.Create;
end;}

{---------------------------- TRPlotManager -----------------------------------}

constructor TRNewWorkArea.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csOpaque];
  FInit := True; 

  CreateRObjects;

  //FSheet.Tool := FZoomTool;

  FPlotColor := clBtnFace;
  FMarginColor := clBtnFace;

  //FZoomTool.OnZoomOut := ZoomOut;
  FSheet.OnSelect := SelectionChanged;
end;

constructor TRNewWorkArea.CreateEx(AOwner: TComponent;
  AParent: TWinControl; AAlign: TAlign = alClient);
begin
  Create(AOwner);

  Parent := AParent;
  Align := AAlign;
end;

function TRNewWorkArea.CreateLayer: TRAdvancedLayer;
var root: TRGroup;
begin
  root := CreateRoot;
  Result := TRAdvancedLayer.Create(root);
  Result.OnZoomSync := ZoomSync;
end;

function TRNewWorkArea.CreateRoot: TRGroup;
begin
  Result := TRGroup.CreateEx(True);
  Result.Controller := TRScatterGroupController.Create;
end;

function TRNewWorkArea.NewLayer(ARect: TRect): TRAdvancedLayer;
begin
  Result := CreateLayer;
  FLayers.Add(Result);
  Result.ViewPort := RectF(-1000, -1000, 1000, 1000);
  Result.DisplayRect := ARect;
  case FLayers.Count of
    1: begin
         Result.Axes.Align := aaLeftBottom;
       end;
    2: begin
         Result.Axes.Align := aaRightBottom;
         Result.Axes.YAxis.LabelPosition := RAxesOld.lpRight;
         Result.Axes.XAxis.Visible := False;
       end;
    3: begin
         Result.Axes.Align := aaLeftBottom;
         Result.Axes.YAxis.LabelPosition := RAxesOld.lpRight;
         Result.Axes.XAxis.Visible := False;
       end;
    4: begin
         Result.Axes.Align := aaRightBottom;
         Result.Axes.YAxis.LabelPosition := RAxesOld.lpLeft;
         Result.Axes.XAxis.Visible := False;
       end;
    else
       begin
         Result.Axes.Align := aaLeftBottom;
         Result.Axes.XAxis.Visible := False;
       end;
     end;
end;

procedure TRNewWorkArea.CreateRObjects;
var R: TRect;
begin
  if Assigned(FSheet) then Exit;

  FMargins := Rect(50, 30, 50, 30);

  {Sheet & Layers}
  FSheet := TRSheetWithUndoStack.Create(Canvas, Self);

  R := Rect(0, 0, Width, Height); // It's impossible to use ClientRect here
  Sheet.DisplayRect := R;

  Inc(R.Left, FMargins.Left);
  Inc(R.Top, FMargins.Top);
  Dec(R.Right, FMargins.Right);
  Dec(R.Bottom, FMargins.Bottom);

  FLayers := TObjectList.Create(True);
  FLayer := NewLayer(R);
  FRightLayer := NewLayer(R);
  FRightLayer.Axes.Visible := False;

  FSheet.WorkingLayer := Layer;

  FBgRoot := CreateRoot;
  FTopRoot := CreateRoot;

  {Tools}
  //FEditTool := TREditTool.Create('Edit');
  //FZoomTool := TRZoomTool.Create('Zoom');
  //FCreationTool := TRCreationTool.Create('Create');

  if not Assigned(ZoomTool.OnZoomOut) then ZoomTool.OnZoomOut := ZoomOut;

  FPropMonitors := TObjectList.Create;
end;

destructor TRNewWorkArea.Destroy;
begin
  FSheet.Free;
  FLayers.Free;
  //FLayer.Free;
  //FRightLayer.Free;

  FBgRoot.Free;
  FTopRoot.Free;

  //FEditTool.Free;
  //FZoomTool.Free;
  //FCreationTool.Free;

  FPropMonitors.Free;

  inherited;
end;

function TRNewWorkArea.GetLayerCount: Integer;
begin
  Result := FLayers.Count;
end;

function TRNewWorkArea.GetLayers(I: Integer): TRAdvancedLayer;
begin
  Result := FLayers[I] as TRAdvancedLayer;
end;

procedure TRNewWorkArea.ProcessContent;
var i: Integer;
begin
  if Sheet.Event = evDraw then
  begin
    FLayer.ProcessFigure(FBgRoot);
    for i := 0 to LayerCount-1 do Layers[i].ProcessContent;
    FLayer.ProcessFigure(FTopRoot);
  end else
  begin
    FLayer.ProcessFigure(FTopRoot);
    for i := 0 to LayerCount-1 do Layers[i].ProcessContent;
    FLayer.ProcessFigure(FBgRoot);
  end;
end;

procedure TRNewWorkArea.Deselect;
begin
  //Assert(not InsideRBrackets);
  if InsideRBrackets then Exit;

  FSheet.BeginDeal;
  try
    if Assigned(FSheet.ActiveLayer) then
      FSheet.ActiveLayer.Deselect;
    FSheet.Redraw := True;
  finally
    FSheet.EndDeal;
  end;
end;

procedure TRNewWorkArea.ClearArea;
begin
  Sheet.Canvas.Brush.Color := FMarginColor;
  Sheet.Canvas.Brush.Style := bsSolid;
  Sheet.Canvas.FillRect(FSheet.Rect);
end;

procedure TRNewWorkArea.CalcPlotRect(var R: TRect);
begin
  Inc(R.Left, FMargins.Left);
  Inc(R.Top, FMargins.Top);
  Dec(R.Right, FMargins.Right);
  Dec(R.Bottom, FMargins.Bottom);
end;

procedure TRNewWorkArea.Resize;
var R: TRect;
    i: Integer;
    _saveRes: Boolean;
begin
  R := Sheet.Dest.ClientRect;
  Sheet.DisplayRect := R;

  CalcPlotRect(R);

  for i := 0 to LayerCount-1 do
  begin
    _saveRes := Layers[i].SaveResMode;
    if FInit then Layers[i].SaveResMode := False;
    FInit := False;
    Layers[i].DisplayRect := R;
    Layers[i].SaveResMode := _saveRes;
  end;

  inherited;
end;

procedure TRNewWorkArea.SetMargins(const Value: TRect);
begin
  FMargins := Value;
  Resize;
  Refresh;
end;

procedure TRNewWorkArea.Paint;
var i: Integer;
begin
  if InsideRBrackets then
  begin
    FSheet.Redraw := True;
    Exit;
  end;

  inherited;

  Sheet.Tool := GetGlobalTool;
  Sheet.BeginDraw(True);
  try
    ClearArea;
    FLayer.Fill(FPlotColor);

    for i := 0 to LayerCount-1 do
      Layers[i].SetBgColor(FPlotColor);

    ProcessContent;
  finally
    Sheet.EndDraw;
  end;
end;

procedure TRNewWorkArea.Repaint;
begin
  if InsideRBrackets then
  begin
    FSheet.Redraw := True;
    Exit;
  end;

  inherited Repaint;
  
  {$IFDEF FPC}
  //??
  {$ENDIF}
end;

procedure TRNewWorkArea.WMEraseBkgnd(var Message: TMessage);
begin
  // inherited; // Do nothing!
end;

{$IFDEF FPC} {$ELSE}
procedure TRNewWorkArea.CMWantSpecialKey(var Message: TCMWantSpecialKey);
begin
  inherited;
  Message.Result := DLGC_WANTALLKEYS; 
end;
{$ENDIF}

procedure TRNewWorkArea.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;
  HandleMouse(evMouseDown, X, Y, Shift, Button);
end;

procedure TRNewWorkArea.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  HandleMouse(evMouseMove, X, Y, Shift, mbMiddle);
end;

procedure TRNewWorkArea.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;
  HandleMouse(evMouseUp, X, Y, Shift, Button);
end;

procedure TRNewWorkArea.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;
  HandleKbd(evKeyDown, Key, Shift);
end;

procedure TRNewWorkArea.KeyUp(var Key: Word; Shift: TShiftState);
begin
  inherited;
  HandleKbd(evKeyUp, Key, Shift);
end;

procedure TRNewWorkArea.HandleKbd(Event: TKbdEventID;
  var Key: Word; Shift: TShiftState);
begin
  //Assert(not InsideRBrackets);
  if InsideRBrackets then Exit;

  UndoStack(Sheet).HandleKbd(Event, Key, Shift);
  if Key = 0 then
  begin
    Sheet.SelectionChanged := True;
    Sheet.ReadjustSelection := True;
    Sheet.Redraw := True;
    Exit;
  end;

  Sheet.Tool := GetGlobalTool;
  Sheet.BeginHandleKbd(Event, Key, Shift);
  try
    ProcessContent;
  finally
    Sheet.EndHandleKbd;
  end;
end;

procedure TRNewWorkArea.HandleMouse(Event: TMouseEventID;
  X, Y: Integer; Shift: TShiftState; Button: TMouseButton);
begin
  //Assert(not InsideRBrackets);
  if InsideRBrackets then Exit;

  Sheet.Tool := GetGlobalTool;
  Sheet.BeginHandleMouse(Event, X, Y, Shift, Button);
  try
    ProcessContent;
  finally
    Sheet.EndHandleMouse;
  end;
end;

class procedure TRNewWorkArea.ZoomOut(ALayer: TRLayer; var NewViewPort: TRectF);
var R: TRectF;
    root: TRFigure;
    W, H: Double;
begin
  root := (ALayer as TRAdvancedLayer).Root;
  R := TRFigureHelper(root).ContainingRect;
  if IsEmptyF(R) then R := RectF(-1, -1, 1, 1);

  W := RectWidthF(R); if W = 0 then W := 1;
  H := RectHeightF(R); if H = 0 then H := 1;

  InflateRectF(R, W*0.05, H*0.05);
  NewViewPort := R;
end;

procedure TRNewWorkArea.ZoomSync(ALayer: TRLayer);
var i: Integer;
    VP, VPi: TRectF;
begin
  if FLockZoomSync then Exit;
  FLockZoomSync := True;
  try
    VP := ALayer.ViewPort;
    for i := 0 to LayerCount-1 do
      if Layers[i] <> ALayer then
      begin
        VPi := Layers[i].ViewPort;
        VPi.XMin := VP.XMin;
        VPi.XMax := VP.XMax;
        Layers[i].ViewPort := VP;
      end;
  finally
    FLockZoomSync := False;
  end;
end;

procedure TRNewWorkArea.SelectionChanged(Sheet: TRSheet);
var i: Integer;
begin
  for i := 0 to FPropMonitors.Count-1 do
    TRPropertyMonitor(FPropMonitors[i]).Process(Sheet);
end;

procedure TRNewWorkArea.AddPropertyMonitor(PropertyMonitor: TRPropertyMonitor);
begin
  FPropMonitors.Add(PropertyMonitor);
end;

procedure TRNewWorkArea.Undo;
begin
  //Assert(not InsideRBrackets);
  if InsideRBrackets then Exit;

  UndoStack(Sheet).Pop;

  Sheet.BeginDeal;
  try
    Sheet.SelectionChanged := True;
    Sheet.Redraw := True;
    Sheet.ReadjustSelection := True;
  finally
    Sheet.EndDeal;
  end;
end;

procedure TRNewWorkArea.PrintContent(const APrintRect: TRect);
var i: Integer;
    R, orgR, prnR: TRect;
    orgMrg, prnMrg: TRect;
    layerR: TRect;
    prnK: TPointF;
    prnAsp, layerAsp: Double;
    halfW, halfH: Integer;
begin
  //Assert(not InsideRBrackets);
  if InsideRBrackets then Exit;

  orgR := Sheet.DisplayRect;
  orgMrg := Margins;

  {prnR := Rect(0, 0, Printer.PageWidth, Printer.PageHeight);
  InflateRect(prnR, -400, -400);}

  prnR := APrintRect;

  {-------------------------}
  if Layer.Proportional then
  begin
    layerR := Layer.Rect;
    prnAsp := RectHeight(prnR)/RectWidth(prnR);
    layerAsp := RectHeight(layerR)/RectWidth(layerR);

    if prnAsp > layerAsp then
    begin
      {x doesn't change}
      halfW := RectWidth(prnR) div 2;
      //halfH := RectHeight(prnR) div 2;
      prnR := PointRect(RectCenter(prnR), halfW, Round(halfW*layerAsp) );
    end
    else
    begin
      {y doesn't change}
      //halfW := RectWidth(prnR) div 2;
      halfH := RectHeight(prnR) div 2;
      prnR := PointRect(RectCenter(prnR), Round(halfH/layerAsp), halfH );
    end;
  end;
  {-------------------------}

  Sheet.PrintRect := prnR;
  Printer.BeginDoc;
  try
    Sheet.BeginDraw(False, True);
    try
      //prnR := Sheet.Rect;
      //prnK.X := RectWidth(prnR)/RectWidth(orgR);
      //prnK.Y := RectHeight(prnR)/RectHeight(orgR);

      prnK := Sheet.PrintData.RectScale;

      prnMrg.Left   := Round(orgMrg.Left*prnK.X);
      prnMrg.Right  := Round(orgMrg.Right*prnK.X);
      prnMrg.Top    := Round(orgMrg.Top*prnK.Y);
      prnMrg.Bottom := Round(orgMrg.Bottom*prnK.Y);

      R.Left   := prnR.Left   + prnMrg.Left;
      R.Right  := prnR.Right  - prnMrg.Right;
      R.Top    := prnR.Top    + prnMrg.Top;
      R.Bottom := prnR.Bottom - prnMrg.Bottom;

      //ClearArea;
      //FLayer.Fill(FPlotColor);

      for i := 0 to LayerCount-1 do
      begin
        Layers[i].SetBgColor(clWhite);
        Layers[i].PrintRect := R;
      end;

      ProcessContent;
    finally
      Sheet.EndDraw;
    end;
  finally
    Printer.EndDoc;
  end;
  Invalidate;
end;

{-------------------------- TRSheetWithUndoStack ------------------------------}

function TRSheetWithUndoStack._UndoStack: TObject;
begin
  if FUndoStack = nil then
    FUndoStack := TRUndoStack.Create;

  Result := FUndoStack;
end;

destructor TRSheetWithUndoStack.Destroy;
begin
  FUndoStack.Free;
  inherited;
end;

procedure TRSheetWithUndoStack.Prepare(Reason: TPrepareReason);
var i: Integer;
begin
  inherited;

  if Dest is TRNewWorkArea then
  begin
    for i := 0 to TRNewWorkArea(Dest).LayerCount-1 do
      TRNewWorkArea(Dest).Layers[i].Prepare(Reason);
  end;
end;

{------------------------------------------------------------------------------}

class function TRNewWorkArea.GetGlobalTool: TRTool;
begin
  Result := GlobalTool;
end;

class procedure TRNewWorkArea.SetGlobalTool(ATool: TRTool);
begin
  GlobalTool := ATool;
end;

procedure SetCurveEditMode(EditPoint: Boolean; AMultiPointMode: TRMultiPointMode = mpmAllOp);
begin
  TRCurveController.Options.AllowSelectFigureAsWhole := not EditPoint;
  TRCurveController.Options.AllowAddAndDeletePoints := EditPoint;
  if EditPoint then
  begin
    TRCurveController.Options.Point := eoEdit;
    TRCurveController.Options.Segment := eoEdit;
    TRCurveController.Options.Area := eoIgnore;
    TRCurveController.Options.MultiPointMode := AMultiPointMode;
  end
  else
  begin
    TRCurveController.Options.Point := eoSelect;
    TRCurveController.Options.Segment := eoSelect;
    TRCurveController.Options.Area := eoSelect;
    TRCurveController.Options.MultiPointMode := mpmNone;
  end;
end;

initialization
  SetCurveEditMode(False);
end.

