{*******************************************************************************
*                                                                              *
*                       Author: Reonid                                         *
*                       Categoty: vector graphic                               *
*                       mailto: reonid@yahoo.com                               *
*                                                                              *
*******************************************************************************}

unit RCore;

interface

uses
  {$IFDEF UNIX} {$ELSE} Windows, {$ENDIF}
  RSysDep,

  Classes, Messages, Graphics, Controls, Forms, Menus,

  RIntf, RTypes, RGeom;

var
  crMoveObj: TCursor = crSizeAll;
  crZoomIn: TCursor = crCross;
  crZoomOut: TCursor = crCross;
  crMovePoint: TCursor = crDefault;
  crZoomHand: TCursor = crHandPoint;

const
  WM_DELAYEDPOPUP = WM_USER + 137;

type
  TRFigure = class;
  TRLayer = class;
  TRSheet = class;
  TRController = class;
  TRMaster = class;
  TRPopupInfo = class;

  INamedObject = interface
  ['{E07F5A27-1612-46CE-83D6-4034BA08A283}']
    function Name: string;
    procedure Rename(const NewName: string);
    // function GetNameResolver: INameResolver;
  end;

  IStreamPersist = interface
    ['{B8CD12A3-267A-11D4-83DA-00C04F60B2DD}']
    procedure LoadFromStream(Stream: TStream);
    procedure SaveToStream(Stream: TStream);
  end;

  ITransformable = interface
  ['{CDCD829B-910A-4BDD-9CA3-418D0BF92C09}']
    function Transform(var Data: TTransformData): Boolean;
    function ContainingRect: TRectF;
    function HitTest(Layer: TRLayer; const Pt: TPointF): Boolean;
  end;

  IRectangular = interface
  ['{F6B47FF9-5039-401A-979C-289C74EEF1BF}']
    function GetRect: TRectF;
    procedure SetRect(const Value: TRectF);
    function HitTest(Layer: TRLayer; const Pt: TPointF): Boolean;

    property Rect: TRectF read GetRect write SetRect;
  end;

  IContextPopup = interface
  ['{4046B52C-0BD4-40D6-AE83-B24CF9D53247}']
    function Popup(Info: TRPopupInfo): Boolean;
  end;

  TRFigureStyle = set of (fsClipped, fsPrintable, fsEditable,
    fsSelectable, fsServant, {fsAgent,} fsDeleteable, fsParentClipped{, fsDeleted});

  TRSelectionType = (stNone, stOrdinary, stSpecial);

  TRSelectMode = (smNormal, smPlus, smMinus, smXor);

  TRExtraDrawReason = (drSelection, drHighlight);

  IAutoController = interface
  ['{24537CEA-0B19-4EA6-9C63-BEC25194BA51}']
    procedure HandleMouse(Layer: TRLayer);
    procedure HandleKbd(Layer: TRLayer);

    function Agent: TRFigure;
    procedure Deselect;

    procedure ExtraDraw(Layer: TRLayer; Reason: TRExtraDrawReason);
  end;

  TRDrawEvent = procedure(Sender: TRFigure; Layer: TRLayer) of object;

  TRFigureClass = class of TRFigure;

  TRFigure = class(TRInterfacedObject)
  private
    FMaster: TRMaster;
    FVisible: Boolean;
    FStyle: TRFigureStyle;
    FController: TRController;
    FOnDraw: TRDrawEvent;
    FPopupMenu: TPopupMenu;

    procedure DoDraw(Layer: TRLayer);
  protected
    function GetEditable: Boolean; virtual;
    function GetDeleteable: Boolean; virtual;

    function GetController: TRController;
    procedure SetController(Value: TRController); virtual;
    procedure SetMaster(Value: TRMaster); virtual;

    function GetPopupMenu: TPopupMenu; virtual;
    procedure SetPopupMenu(const Value: TPopupMenu); virtual;

    function Popup(Info: TRPopupInfo): Boolean; virtual;
    function DoContextPopup(Info: TRPopupInfo): Boolean;

    procedure Draw(Layer: TRLayer); virtual; abstract;
  public
    property Master: TRMaster read FMaster; // write SetMaster;
    property Visible: Boolean read FVisible write FVisible;
    property Editable: Boolean read GetEditable;
    property Deleteable: Boolean read GetDeleteable;
    property Style: TRFigureStyle read FStyle write FStyle;
    property PopupMenu: TPopupMenu read GetPopupMenu write SetPopupMenu;
    property Controller: TRController read GetController write SetController;
    property OnDraw: TRDrawEvent read FOnDraw write FOnDraw;

    constructor Create; virtual;
    destructor Destroy; override;

    procedure UndoablyDelete(Layer: TRLayer); virtual;
    procedure SelectProgramly(Layer: TRLayer; Mode: TRSelectMode = smNormal);

    procedure Show;
    procedure Hide;
  end;

  TRMaster = class(TRFigure)
  protected
    procedure InternalAdd(Figure: TRFigure); virtual; abstract;
    procedure InternalRemove(Figure: TRFigure); virtual; abstract;
    procedure UndoablyDeleteFigure(Layer: TRLayer; Figure: TRFigure); virtual; abstract;
    //procedure DeleteFigures; virtual; abstract;
    function SelectFigure(Layer: TRLayer; Figure: TRFigure; Mode: TRSelectMode): Boolean; virtual;
  public
    function OwnsFigures: Boolean; virtual; abstract;
    function Contains(Figure: TRFigure): Boolean; virtual; abstract;
    procedure Add(Figure: TRFigure);
    procedure Remove(Figure: TRFigure);
    procedure AdvancedAdd(Figure: TRFigure; Mode: TRSelectMode);
  end;

  TRAgentDecorator = class(TRFigure, ITransformable)
  private
    FDecoree: TRFigure;
  protected
    function ContainingRect: TRectF;
    function HitTest(Layer: TRLayer; const Pt: TPointF): Boolean;
    function Transform(var Data: TTransformData): Boolean;

    function GetDecoree: TRFigure;
    procedure SetDecoree(Value: TRFigure); virtual;

    procedure Draw(Layer: TRLayer); override;
  public
    property Decoree: TRFigure read GetDecoree write SetDecoree;

    constructor Create; override;

    procedure UndoablyDelete(Layer: TRLayer); override;

    function Init(Figure: TRFigure): TRFigure;
    procedure Adjust; virtual;
  end;

  TRControllerClass = class of TRController;

  //TRExtraDrawReason = (drSelection, drHighlight);
  TRControllerState = set of (csCaptured, csSpecific);

  TRController = class(TRInterfacedObject)
  private
    FControllee: TRFigure;
    FAgent: TRFigure;
    FState: TRControllerState;
    procedure SetControllee(Value: TRFigure);
  protected
    property State: TRControllerState read FState;

    function HitTest(Layer: TRLayer; const Pt: TPointF): Boolean; virtual;

    procedure AssignAgent(Value: TRFigure);
    procedure UpgradeAgent(var AAgent: TRFigure); virtual;

    procedure DecorateByTransformer(Layer: TRLayer); virtual;
    function SelectFigure(Layer: TRLayer; Figure: TRFigure;
      Mode: TRSelectMode): Boolean; virtual;
  public
    //property Controllee: TRFigure read FControllee;
    function Controllee: TRFigure;

    constructor Create; virtual;
    destructor Destroy; override;

    procedure HandleMouse(Layer: TRLayer); virtual; abstract;
    procedure HandleKbd(Layer: TRLayer); virtual; abstract;

    function Supports(Figure: TObject): Boolean; virtual;
    function Clone: TRController; virtual;
    function IsInAgentMode: Boolean;

    function Agent: TRFigure; virtual;
    function AllowSelectFigureAsWhole: Boolean; virtual;
    function AllowFurtherMultiSelect: Boolean; virtual;
    procedure Deselect; virtual;

    procedure ExtraDraw(Layer: TRLayer; Reason: TRExtraDrawReason); virtual;
  end;

  TRControllerEx = class(TRController)
  protected
    function SelectRect(Layer: TRLayer; Rect: TRectF): Boolean; virtual;
    procedure MouseDown(Layer: TRLayer; var Handled: Boolean); virtual; abstract;
    procedure MouseMove(Layer: TRLayer; var Cursor: TCursor); virtual; abstract;
    procedure MouseUp(Layer: TRLayer); virtual; abstract;
    procedure KeyDown(Layer: TRLayer; var Key: Word); virtual;
    procedure KeyUp(Layer: TRLayer; var Key: Word); virtual;
  public
    procedure HandleMouse(Layer: TRLayer); override;
    procedure HandleKbd(Layer: TRLayer); override;
  end;

  TRSimpleController = class(TRController)
  public
    procedure HandleMouse(Layer: TRLayer); override;
    procedure HandleKbd(Layer: TRLayer); override;
    function Supports(AObject: TObject): Boolean; override;
  end;

  TRAgentDecoratorController = class(TRControllerEx)
  public
    function Decorator: TRAgentDecorator;

    function Supports(AObject: TObject): Boolean; override;
    procedure HandleMouse(Layer: TRLayer); override;
    procedure HandleKbd(Layer: TRLayer); override;
  end;

  TRLayerEvent = procedure(Layer: TRLayer) of object;
  TRGetNudgeEvent = procedure(Layer: TRLayer; var Nudge: TPointF) of object; // -> Tool
  TRSelectEvent = procedure(Sheet: TRSheet) of object;
  TPrepareReason = (prDraw, prHandleMouse, prHandleKbd, prCalc);

  TRLayer = class
  private
    FViewPort: TRectF;
    FRect: TRect;
    FPrintRect: TRect;
    FConverter: TRCoordConverter;

    FRootActiveFigure: TRFigure;
    FActiveFigures: TList;
    //FFigureThatHasCapturedMouse: TRFigure;
    FDefaultTransformer: TRAgentDecorator;

    FPreparedEventNumber: Integer;
    //FHandlingLevel: Integer;
    FDownPt, FPrevPt, FCurrPt: TPointF;

    FClipping: Boolean;
    FClipRgn: TClipRegion;

    FOnGetNudge: TRGetNudgeEvent;
    FOnZoomChanged: TRLayerEvent;
    FBgColor: TColor; //????

    FErroneous: Boolean;
    FProportional: Boolean;
    FSaveResMode: Boolean; {?}

    function GetCanvas: TCanvas;
    function GetSheet: TRSheet;

    function CheckErroneous: Boolean;

    procedure SetDefaultTransformer(Value: TRAgentDecorator);

    function GetRect: TRect;
    function GetPrinting: Boolean;
  protected
    procedure SetProportional(Value: Boolean);
    procedure SetSaveResMode(Value: Boolean);

    procedure SetRect(const Value: TRect); virtual;
    procedure SetViewPort(const Value: TRectF); virtual;
    procedure SetBgColor(Color: TColor);
    procedure ZoomChanged; virtual;
    procedure AdjustNewViewPort(const OldValue: TRectF; var NewValue: TRectF); virtual;

    procedure Clip(TurnOn: Boolean); virtual;
    function CreateConverter: TRCoordConverter; virtual;
  public
    property Sheet: TRSheet read GetSheet;
    property Canvas: TCanvas read GetCanvas;
    property Converter: TRCoordConverter read FConverter;
    property ViewPort: TRectF read FViewPort write SetViewPort;
    property Rect: TRect read GetRect;// write SetRect;
    property DisplayRect: TRect read FRect write SetRect;
    property PrintRect: TRect read FPrintRect write FPrintRect;
    property Printing: Boolean read GetPrinting;
    property RootActiveFigure: TRFigure read FRootActiveFigure;
    property DefaultTransformer: TRAgentDecorator read
      FDefaultTransformer write SetDefaultTransformer;

    property Proportional: Boolean read FProportional write SetProportional; // !Experimental
    property SaveResMode: Boolean read FSaveResMode write SetSaveResMode; // !Experimental

    property CurrPt: TPointF read FCurrPt;
    property PrevPt: TPointF read FPrevPt;
    property DownPt: TPointF read FDownPt;

    property BgColor: TColor read FBgColor; // write FBgColor;

    property OnZoomChanged: TRLayerEvent read FOnZoomChanged write FOnZoomChanged;
    property OnGetNudge: TRGetNudgeEvent read FOnGetNudge write FOnGetNudge;

    constructor Create;
    destructor Destroy; override;

    procedure Prepare(Reason: TPrepareReason);
    procedure Fill(Color: TColor);
    procedure Select(Figure: TRFigure);
    procedure Deselect;
    function SelectMode: TRSelectMode; // -> Tool
    function Nudge: TPointF; // -> Tool

    function ProcessFigure(Figure: TRFigure): Boolean;

    function Draw(Figure: TRFigure): Boolean;
    function HitTest(Figure: TRFigure; const Pt: TPointF): Boolean;
    function HandleMouse(Figure: TRFigure): Boolean;
    function HandleKbd(Figure: TRFigure): Boolean; 

    procedure DrawBitmap(Bitmap: TBitmap; const DesTRect: TRectF);
    procedure DrawGraphic(Graphic: TGraphic; const DestRect: TRectF);
  end;

  TRDrawSelProc = procedure(Sheet: TRSheet; const Rect: TRect;
    const FirstPt, SecondPt: TPoint) of object;

  TRTool = class
  private
    FName: string;
  protected
    procedure XorDraw(Sheet: TRSheet; DrawProc: TRDrawSelProc;
      PenMode: TPenMode = pmNot);

    function Filter(Figure: TRFigure): Boolean; virtual;
    function KeepActiveFigure(Sheet: TRSheet): Boolean; virtual; abstract;
    procedure ProcessLayer(Layer: TRLayer); virtual;  // Zoom
    function SelectMode(Layer: TRLayer): TRSelectMode; virtual;

    procedure BeginHandleMouse(Sheet: TRSheet; var Handled: Boolean); virtual; abstract;
    procedure EndHandleMouse(Sheet: TRSheet); virtual; abstract;
    procedure HandleKbd(Sheet: TRSheet); virtual;
    procedure Activate(Value: Boolean); virtual;
    procedure Prepare(Sheet: TRSheet; Reason: TPrepareReason); virtual;
  public
    property Name: string read FName;
    constructor Create(AName: string); virtual;
  end;

  TRSheetState = set of(ssMouseDownHandling{?}, ssActiveFigureProcessing,
    ssAgentInitializing, ssLockMouseHandling, ssMouseDown);

  TPrintData = record
    RectScale: TPointF;
    PixelScale: TPointF;
    FontScale: TPointF;
  end;

  TRSheet = class
  private
    FDest: TControl;
    FDestCanvas: TCanvas;
    FCanvas: TCanvas;

    FBuffered: Boolean;
    FRect: TRect;
    FClipRect: TRect;
    FClipRgn: TClipRegion;

    FPrinting: Boolean;
    FPrintRect: TRect;
    FPrintData: TPrintData;

    // For Handle Mouse
    FActiveLayer: TRLayer;
    FWorkingLayer: TRLayer; 
    FCursor: TCursor;
    FEvent: TEventID;

    FInternalEventNumber: Integer;
    FMouseDownTime: TDateTime;
    FSkipMouseMove: Boolean;
    FHandlingLevel: Integer; // <- Layer

    FDownPt, FPrevPt, FCurrPt: TPoint;
    FShiftState: TShiftState;
    FMouseBtn: TMouseButton;
    FKey: Word;
    FPrevMouseEvent: TEventID;

    // Flags to change by user
    FEventHandled: Boolean;
    FRedraw: Boolean;
    FReadjustSelection: Boolean;
    FAllowSelectRect: Boolean;
    FSelectionChanged: Boolean;

    FState: TRSheetState;

    FTool: TRTool;

    FCommonPopupMenu: TPopupMenu;
    FPopupInfo: TRPopupInfo;

    FOnSelect: TRSelectEvent;

    procedure IncEventNo;
    function Skip(Figure: TRFigure): Boolean;
    procedure AcquireFocus;
    procedure DoSelectionChanged;
    procedure SetTool(Value: TRTool);
    function GetTool: TRTool;
    procedure DoRedraw;
    procedure DoReadjustSelection;
    procedure SetReadjustSelection(const Value: Boolean);
    procedure SetSelectionChanged(const Value: Boolean);

    function GetCanvas: TCanvas;
    function GetDestCanvas: TCanvas;
    function GetDest: TControl;
    function GetRect: TRect;

    procedure PreparePrint;
  protected
    property DestCanvas: TCanvas read GetDestCanvas;

    function _UndoStack: TObject; virtual;
  public
    property Dest: TControl read GetDest write FDest;
    property Rect: TRect read GetRect;// write FRect;{?}
    property Canvas: TCanvas read GetCanvas;
    property MouseBtn: TMouseButton read FMouseBtn;

    property ActiveLayer: TRLayer read FActiveLayer;
    property WorkingLayer: TRLayer read FWorkingLayer write FWorkingLayer;
    property Cursor: TCursor read FCursor write FCursor;
    property ClipRect: TRect read FClipRect;

    property Tool: TRTool read GetTool write SetTool;

    property CommonPopupMenu: TPopupMenu read FCommonPopupMenu write FCommonPopupMenu;
    property PopupInfo: TRPopupInfo read FPopupInfo;

    property PrevMouseEvent: TEventID read FPrevMouseEvent;
    property Event: TEventID read FEvent;

    property Printing: Boolean read FPrinting;
    property PrintData: TPrintData read FPrintData;
    property PrintRect: TRect read FPrintRect write FPrintRect;
    property DisplayRect: TRect read FRect write FRect;

    property CurrPt: TPoint read FCurrPt;
    property PrevPt: TPoint read FPrevPt;
    property DownPt: TPoint read FDownPt;
    property ShiftState: TShiftState read FShiftState;
    property Key: Word read FKey write FKey;
    property State: TRSheetState read FState;

    property EventHandled: Boolean read FEventHandled write FEventHandled;
    property AllowSelectRect: Boolean read FAllowSelectRect write FAllowSelectRect;
    property Redraw: Boolean read FRedraw write FRedraw;
    property ReadjustSelection: Boolean read FReadjustSelection write SetReadjustSelection;
    property SelectionChanged: Boolean read FSelectionChanged write SetSelectionChanged;
    property HandlingLevel: Integer read FHandlingLevel;

    property OnSelect: TRSelectEvent read FOnSelect write FOnSelect;

    constructor Create(ADestCanvas: TCanvas; ADest: TControl);
    destructor Destroy; override;

    procedure Clip;
    //function UndoStack: TRUndoStack;

    function LBtnDown: Boolean;
    function RBtnDown: Boolean;
    function DblClick: Boolean;

    // Procedures to call by Tools

    function GetCurrentAgent: TRFigure;
    procedure ProcessActiveFigure;
    procedure ProcessContextPopup;
    procedure InitializeAgent;

    procedure LockHandleMouse;

    procedure Prepare(Reason: TPrepareReason); virtual;
    procedure Fill(Color: TColor);

    // Main bracket procedures

    procedure BeginDraw(Buffered: Boolean; Print: Boolean = False);
    procedure EndDraw;

    procedure BeginHandleMouse(AEvent: TMouseEventID; X, Y: Integer;
      Shift: TShiftState; Button: TMouseButton);
    procedure EndHandleMouse;

    procedure BeginHandleKbd(AEvent: TKbdEventID; var AKey: Word; Shift: TShiftState);
    procedure EndHandleKbd;

    procedure BeginDeal;
    procedure EndDeal;
  end;

  TRLayerCoordConverter = class(TRCoordConverter)
  private
    FLayer: TRLayer;
    FXSL: TCKCoeffs;
    FYSL: TCKCoeffs;
    FXLS: TCKCoeffs;
    FYLS: TCKCoeffs;
  public
    constructor Create(Layer: TRLayer);
    procedure Prepare; override;
    procedure ScreenToLogic(SX, SY: Integer; var LX, LY: TFloat); override;
    procedure LogicToScreen(LX, LY: TFloat; var SX, SY: Integer);  override;
  end;

  TREditTool = class(TRTool)
  protected
    procedure DrawSelRect(Sheet: TRSheet; const Rect: TRect;
      const FirstPt, SecondPt: TPoint); virtual;
    function KeepActiveFigure(Sheet: TRSheet): Boolean; override;
    procedure BeginHandleMouse(Sheet: TRSheet; var Handled: Boolean); override;
    procedure EndHandleMouse(Sheet: TRSheet); override;
    procedure HandleKbd(Sheet: TRSheet); override;
    procedure ProcessLayer(Layer: TRLayer); override;
  end;

  TRPopupInfo = class({TComponent}TWinControl)
  private
    FFigure: TRFigure;
    FSheet: TRSheet;
    FLayer: TRLayer;
    FPoint: TPoint;

    procedure Init(ASheet: TRSheet; ALayer: TRLayer; APoint: TPoint);
    procedure Hook(AMenu: TPopupMenu);
    procedure DoPopup(AdditionalPopup: TPopupMenu);
  protected
    procedure WMDelayedPopup(var Msg: TMessage); message WM_DELAYEDPOPUP;
  public
    property Figure: TRFigure read FFigure write FFigure;
    property Layer: TRLayer read FLayer;
    property Sheet: TRSheet read FSheet;
    property Point: TPoint read FPoint;

    procedure Popup(AdditionalPopup: TPopupMenu);
  end;

  TREmptyTool = class(TRTool)
  protected
    procedure BeginHandleMouse(Sheet: TRSheet; var Handled: Boolean); override;
    procedure EndHandleMouse(Sheet: TRSheet); override;
    function KeepActiveFigure(Sheet: TRSheet): Boolean; override;
  end;

  TRPropertyMonitor = class
  public
    procedure Process(Sheet: TRSheet); virtual; abstract;
  end;

  function InputSheet: TRSheet;

var
  RPopupHookProc: procedure(Info: TRPopupInfo; PopupMenu: TPopupMenu) of object;

const
  daAll = [daGeometry, daAttributes, daPicture, daText, daLinks, daOther];

function InsideRBrackets: Boolean;

implementation

uses
  SysUtils, Math, Printers,
  RFigHlp, RUtils, RUndo;

var
  theBufferBmp: TBitmap;
  theEmptyTool: TRTool;

  CurrentSheet: TRSheet = nil;
  CurrentLayer: TRLayer = nil;

  CurrentInputSheet: TRSheet = nil;

  thePrinterDest: TControl = nil; 

const
  crUndefined: TCursor = Low(TCursor);

function InsideRBrackets: Boolean;
begin
  Result := Assigned(CurrentSheet);
end;

{------------------------------- TRFigure ------------------------------------}

constructor TRFigure.Create;
begin
  inherited;
  Visible := True;
  FStyle := [fsEditable, fsPrintable, fsSelectable, fsDeleteable];
end;

destructor TRFigure.Destroy;
begin
  if Assigned(FMaster) then FMaster.Remove(Self);
  FController.Free;
  inherited;
end;

function TRFigure.GetController: TRController;
begin
  Result := FController;
end;

procedure TRFigure.SetController(Value: TRController);
begin
  if (FController <> Value) then
  begin
    FController.SetControllee(nil);
    Value.SetControllee(Self);
  end;  
end;

procedure TRFigure.SetMaster(Value: TRMaster);
begin
  if FMaster <> Value then
  begin
    if Assigned(Value) and not Value.OwnsFigures then
      raise Exception.Create('Invalid Master');

    if Assigned(FMaster) then FMaster.InternalRemove(Self);
    FMaster := nil;
    if Assigned(Value) then Value.InternalAdd(Self);
    FMaster := Value;
  end;
end;

procedure TRFigure.Show;
begin
  Visible := True;
end;

procedure TRFigure.Hide;
begin
  Visible := False;
end;

procedure TRFigure.UndoablyDelete(Layer: TRLayer);
begin
  if GetDeleteable then
  begin
    FMaster.UndoablyDeleteFigure(Layer, Self);
    Layer.Deselect;
  end;  
end;

procedure TRFigure.SelectProgramly(Layer: TRLayer; Mode: TRSelectMode = smNormal);
begin
  if Assigned(FMaster) then
  begin
    if FMaster.SelectFigure(Layer, Self, Mode) then
      FMaster.SelectProgramly(Layer, smNormal); // Deselect if selection is empty ????
  end
  else
  begin
    if Layer.RootActiveFigure <> Self then Layer.Select(Self);
  end;

  Layer.Sheet.SelectionChanged := True;
end;

function TRFigure.GetEditable: Boolean;
begin
  Result := (fsEditable in FStyle)and Assigned(Controller);
end;

function TRFigure.GetDeleteable: Boolean;
begin
  Result := (fsDeleteable in FStyle);//and Assigned(Controller);
end;

function TRFigure.GetPopupMenu: TPopupMenu;
begin
  Result := FPopupMenu;
end;

procedure TRFigure.SetPopupMenu(const Value: TPopupMenu);
begin
  FPopupMenu := Value;
end;

procedure TRFigure.DoDraw(Layer: TRLayer);
begin
  Draw(Layer);
  if Assigned(FOnDraw) then FOnDraw(Self, Layer);
  if Assigned(Controller) then Controller.ExtraDraw(Layer, drHighlight);
end;

function TRFigure.Popup(Info: TRPopupInfo): Boolean;
begin
  Result := True;
  Info.Figure := Self;
  Info.Popup(PopupMenu);
end;

function TRFigure.DoContextPopup(Info: TRPopupInfo): Boolean;
begin
  Result := False;
  if Self = nil then Exit; 
  if Assigned(PopupMenu) then
  begin
    Result := Popup(Info);
  end
  else if InheritsFrom(TRAgentDecorator) then
  begin
    Result := TRAgentDecorator(Self).Decoree.DoContextPopup(Info);
  end;
end;

{-------------------------------- TRMaster ------------------------------------}

function TRMaster.SelectFigure(Layer: TRLayer; Figure: TRFigure;
  Mode: TRSelectMode): Boolean;
begin
  Result := False;
  //Controller.Select(Layer);
  if Assigned(Controller)then
    Result := Controller.SelectFigure(Layer, Figure, Mode);
end;

procedure TRMaster.Add(Figure: TRFigure);
begin
  if OwnsFigures
    then Figure.SetMaster(Self)
    else InternalAdd(Figure);
end;

procedure TRMaster.Remove(Figure: TRFigure);
begin
  if OwnsFigures
    then Figure.SetMaster(nil)
    else InternalRemove(Figure);
end;

procedure TRMaster.AdvancedAdd(Figure: TRFigure; Mode: TRSelectMode);
begin
  case Mode of
    smNormal: Add(Figure); //  Clear??
    smPlus: Add(Figure);
    smMinus: Remove(Figure);
    smXor: if Contains(Figure) then Remove(Figure) else Add(Figure);
  end;
end;

{--------------------------- TRAgentDecorator -----------------------------}

constructor TRAgentDecorator.Create;
begin
  inherited;
  Style := Style + [fsServant];
end;

procedure TRAgentDecorator.Draw(Layer: TRLayer);
begin
  //inherited;
  if IsServant(Decoree) then Layer.Draw(Decoree);
end;

function TRAgentDecorator.GetDecoree: TRFigure;
begin
  Result := FDecoree;
end;

procedure TRAgentDecorator.SetDecoree(Value: TRFigure);
begin
  FDecoree := Value;
end;

function TRAgentDecorator.ContainingRect: TRectF;
begin
  Result := TRFigureHelper(FDecoree).ContainingRect;
end;

function TRAgentDecorator.Transform(var Data: TTransformData): Boolean;
begin
  Result := TRFigureHelper(Decoree).Transform(Data);
end;

function TRAgentDecorator.HitTest(Layer: TRLayer; const Pt: TPointF): Boolean;
begin
  raise Exception.Create('Never called');
end;

procedure TRAgentDecorator.UndoablyDelete(Layer: TRLayer);
begin
  Decoree.UndoablyDelete(Layer);
end;

function TRAgentDecorator.Init(Figure: TRFigure): TRFigure;
begin
  if Figure = nil then
  begin
    Result := nil;
  end
  else if Self <> nil then
  begin
    Result := Self;
    Decoree := Figure;
    Adjust;
    Show;
  end
  else
    Result := Figure;
end;

procedure TRAgentDecorator.Adjust;
begin
end;

{--------------------------------- TLayer -------------------------------------}

constructor TRLayer.Create;
begin
  inherited;
  FRect.Left := 0;
  FRect.Top := 0;
  FRect.Right := 100;
  FRect.Bottom := 100;
  FViewPort := RectF(0, 0, 100, 100);
  FConverter := CreateConverter;
  FActiveFigures := TList.Create;
  FBgColor := clWhite; 
end;

destructor TRLayer.Destroy;
begin
  FConverter.Free;
  FActiveFigures.Free;
  DeleteClipRegion(FClipRgn);
  inherited;
end;

function TRLayer.CreateConverter: TRCoordConverter;
begin
  Result := TRLayerCoordConverter.Create(Self);
end;

function TRLayer.GetSheet: TRSheet;
begin
  Result := CurrentSheet;
end;

function TRLayer.GetCanvas: TCanvas;
begin
  Result := CurrentSheet.Canvas;
end;

function TRLayer.SelectMode: TRSelectMode;
begin
  Result := Sheet.Tool.SelectMode(Self);
end;

function TRLayer.ProcessFigure(Figure: TRFigure): Boolean;
begin
  Result := True;
  case Sheet.Event of
    evDraw: Draw(Figure);
    evMouseDown, evMouseMove, evMouseUp: Result := HandleMouse(Figure);
    evKeyDown, evKeyUp: Result := HandleKbd(Figure);
  end;
end;

function TRLayer.Draw(Figure: TRFigure): Boolean;
begin
  Result := True;
  if FErroneous then Exit;
  Prepare(prDraw); // on the first place !
  if Sheet.Skip(Figure) then Exit;
  if not (fsParentClipped in Figure.Style){?} then Clip(fsClipped in Figure.Style);
  Figure.DoDraw(Self);
end;

function TRLayer.HitTest(Figure: TRFigure; const Pt: TPointF): Boolean;
begin
  Result := False; // ?
  if FErroneous then Exit;

  if Assigned(Figure.Controller) then
    Result := Figure.Controller.HitTest(Self, Pt);
  // else Result := TRFigureHelper(Figure).HitTest(Self, Pt);
end;

procedure TRLayer.Prepare(Reason: TPrepareReason);
var R: TRect;
begin
  if FErroneous then Exit;

  if CurrentLayer = Self then Exit; 
  if FPreparedEventNumber = Sheet.FInternalEventNumber then Exit;
  FPreparedEventNumber := Sheet.FInternalEventNumber;

  //if CurrentLayer <> nil then CurrentLayer.Unprepare(Reason);
  CurrentLayer := Self;

  Converter.Prepare; // ?????? ” мен€, кажетс€, были какие-то соображени€ против
  //FHandlingLevel := 0;
  FActiveFigures.Clear; // i-> Deselect???

  case Reason of
    prDraw:
    begin
      //FBgColor := clWhite;
      IntersectRect(R, Sheet.ClipRect, Rect);

      DeleteClipRegion(FClipRgn);
      FClipRgn := CreateClipRegion(R);
      {$IFDEF UNIX}
      {$ELSE}
      if (not Sheet.FBuffered) and (not (Sheet.Dest is TWinControl)) then
        OffsetRgn(FClipRgn, Sheet.Dest.Left, Sheet.Dest.Top);
      {$ENDIF}

      Clip(False); // FClipping := False;
    end;

    prHandleMouse:
    begin
      FPrevPt := FCurrPt;
      Converter.ScreenToLogic(Sheet.FCurrPt, FCurrPt);
      if Sheet.FEvent = evMouseDown then FDownPt := FCurrPt;

      Sheet.Tool.ProcessLayer(Self);
    end;

    prHandleKbd:
    begin
      Sheet.Tool.ProcessLayer(Self);
    end;
  end;
end;

procedure TRLayer.Fill(Color: TColor);
begin
  FBgColor := Color;
  Canvas.Brush.Color := FBgColor;
  Canvas.FillRect(Rect);
end;

procedure TRLayer.Select(Figure: TRFigure);
begin
  if Assigned(Figure)and(fsSelectable in Figure.Style) then
  begin
    // if FRootActiveFigure <> Figure !!??
    if Assigned(FRootActiveFigure) then Deselect; // w/o redraw
    FRootActiveFigure := Figure;
    Sheet.FActiveLayer := Self;
    Sheet.SelectionChanged := True;
  end;
end;

procedure TRLayer.Deselect;
begin
  try
    if Assigned(FRootActiveFigure) then
      FRootActiveFigure.Controller.Deselect;
  finally
    Sheet.SelectionChanged := True;
    FRootActiveFigure := nil;
    Sheet.FActiveLayer := nil;
    Sheet.Redraw := True;
  end;
end;

procedure TRLayer.Clip(TurnOn: Boolean);
begin
  //if FClipping = TurnOn then Exit;
  FClipping := TurnOn;
  if TurnOn
    then SelectClipRegion(Canvas, FClipRgn)
    else Sheet.Clip;
end;

function TRLayer.HandleMouse(Figure: TRFigure): Boolean;
begin
  Result := False;
  if FErroneous then Exit;
  Prepare(prHandleMouse);
  if Sheet.Skip(Figure) then Exit;

  Inc(Sheet.FHandlingLevel);
  try
    Figure.Controller.HandleMouse(Self);
  finally
    Dec(Sheet.FHandlingLevel);
  end;

  if (Sheet.Event in [evMouseDown, evMouseUp]       )and
     (Sheet.FEventHandled                           )and
     (not(ssActiveFigureProcessing in Sheet.FState) )and
     (not(ssAgentInitializing in Sheet.FState)      )then
  begin
    if (Sheet.HandlingLevel = 0) then
    begin
      Select(Figure);
      FActiveFigures.Clear;
    end;
    FActiveFigures.Add(Figure);
  end;

  Result := Sheet.EventHandled;

  if Sheet.Event = evMouseDown then
  begin
    if Result
      then Include(Figure.Controller.FState, csCaptured)
      else Exclude(Figure.Controller.FState, csCaptured);
  end;

  if Sheet.Event = evMouseUp then
    Exclude(Figure.Controller.FState, csCaptured);
end;

function TRLayer.HandleKbd(Figure: TRFigure): Boolean;
begin
  Result := False;
  if FErroneous then Exit;
  Prepare(prHandleKbd);
  if Sheet.Skip(Figure) then Exit;

  Inc(Sheet.FHandlingLevel);
  try
    Figure.Controller.HandleKbd(Self);
  finally
    Dec(Sheet.FHandlingLevel);
  end;

  Result := Sheet.EventHandled;
end;

procedure TRLayer.DrawBitmap(Bitmap: TBitmap; const DestRect: TRectF);
var ScrDestRect: TRect;
    BmpRect, IntsRect: TRect;
begin
  FConverter.LogicToScreen(DestRect, ScrDestRect);

  BmpRect := Classes.Rect(0, 0, Bitmap.Width, Bitmap.Height);
  if not IntersectRect(IntsRect, ScrDestRect, Rect) then Exit;

  Canvas.CopyRect(ScrDestRect, Bitmap.Canvas, BmpRect);
end;

procedure TRLayer.DrawGraphic(Graphic: TGraphic; const DestRect: TRectF);
var ScrDestRect, IntsRect: TRect;
begin
  FConverter.LogicToScreen(DestRect, ScrDestRect);
  if not IntersecTRect(IntsRect, ScrDestRect, Rect) then Exit;
  Canvas.StretchDraw(ScrDestRect, Graphic);
end;

function TRLayer.CheckErroneous: Boolean;
begin
  Result := (Rect.Left = Rect.Right)or
            (Rect.Top = Rect.Bottom)or
            (ViewPort.XMin = ViewPort.XMax)or
            (ViewPort.YMin = ViewPort.YMax);
end;

procedure TRLayer.ZoomChanged;
begin
  if Assigned(FOnZoomChanged) then
    FOnZoomChanged(Self);
end;

procedure TRLayer.AdjustNewViewPort(const OldValue: TRectF; var NewValue: TRectF);
begin
  if FProportional then
    NewValue := ProportionalRectF(Rect, NewValue, '-');
end;

procedure TRLayer.SetProportional(Value: Boolean);
begin
  if FProportional <> Value then
  begin
    FProportional := Value;
    if Value then SetViewPort(ViewPort);
  end;
end;

procedure TRLayer.SetSaveResMode(Value: Boolean);
begin
  if FSaveResMode <> Value then
  begin
    FSaveResMode := Value;
    //if Value then SetViewPort(ViewPort);
  end;
end;

procedure TRLayer.SetViewPort(const Value: TRectF);
var NewValue: TRectF;
begin
  NewValue := Value;

  AdjustNewViewPort(FViewPort, NewValue);

  FViewPort := NewValue;

  FErroneous := CheckErroneous;
  if FErroneous then Exit;

  FConverter.Prepare;

  if Assigned(CurrentSheet) then
  begin
    Converter.ScreenToLogic(Sheet.DownPt, FDownPt);
    Converter.ScreenToLogic(Sheet.PrevPt, FPrevPt);
    Converter.ScreenToLogic(Sheet.CurrPt, FCurrPt);
  end;

  ZoomChanged;
end;

function TRLayer.GetRect: TRect;
begin
  Result := FRect;
  if Assigned(Sheet)and Sheet.Printing then
    Result := PrintRect;
end;

function TRLayer.GetPrinting: Boolean;
begin
  Result := Sheet.Printing;
end;

procedure TRLayer.SetRect(const Value: TRect);
var oldRes: Double;
    vp: TRectF;
begin
  if RectWidth(FRect) <> 0
    then oldRes := RectWidthF(FViewPort)/RectWidth(FRect)
    else oldRes := 0; 

  FRect := Value;

  FErroneous := CheckErroneous;
  if FErroneous then Exit;

  FConverter.Prepare;

  if Assigned(CurrentSheet) then
  begin
    Converter.ScreenToLogic(Sheet.DownPt, FDownPt);
    Converter.ScreenToLogic(Sheet.PrevPt, FPrevPt);
    Converter.ScreenToLogic(Sheet.CurrPt, FCurrPt);
  end;

  if Proportional then
  begin
    if SaveResMode then
    begin
      vp := FViewPort;
      vp.XMax := FViewPort.XMin + Abs(  RectWidth(FRect)*oldRes   );
      vp.YMin := FViewPort.YMax - Abs(  RectHeight(FRect)*oldRes  );
      SetViewPort(vp);
    end
    else
      SetViewPort(FViewPort);
  end;  
end;

procedure TRLayer.SetBgColor(Color: TColor);
begin
  FBgColor := Color;
end;

procedure TRLayer.SetDefaultTransformer(Value: TRAgentDecorator);
begin
  if FDefaultTransformer = nil then FDefaultTransformer := Value;
end;

function TRLayer.Nudge: TPointF;
var pt0, pt1: TPointF;
begin
  Converter.ScreenToLogic(0, 0, pt0.X, pt0.Y);
  Converter.ScreenToLogic(1, 1, pt1.X, pt1.Y);
  Result.X := Abs(pt1.X - pt0.X);
  Result.Y := Abs(pt1.Y - pt0.Y);
  if not (ssCtrl in Sheet.ShiftState) then
  begin
    Result.X := Result.X*5;
    Result.Y := Result.Y*5;
  end;
  if Assigned(FOnGetNudge) then
    FOnGetNudge(Self, Result);
end;

{---------------------------- TRSheet ----------------------------------------}

procedure Readjust(Agent: TRFigure); forward;

constructor TRSheet.Create(ADestCanvas: TCanvas; ADest: TControl);
begin
  inherited Create;
  FInternalEventNumber := Random(100000);
  FDestCanvas := ADestCanvas;
  FDest := ADest;
  FPrevMouseEvent := evNone;
  //FPopupInfo := TRPopupInfo.Create(nil);
  {$IFDEF FPC}
  FPopupInfo := TRPopupInfo.Create(nil); /// ?????
  {$ELSE}
  FPopupInfo := TRPopupInfo.CreateParented(Application.Handle);
  {$ENDIF}
end;

destructor TRSheet.Destroy;
begin
  if CurrentInputSheet = Self then CurrentInputSheet := nil;
  DeleteClipRegion(FClipRgn);
  FPopupInfo.Free;
  inherited;
end;

procedure TRSheet.IncEventNo;
begin
  Inc(FInternalEventNumber);
end;

function TRSheet.GetCanvas: TCanvas;
begin
  Result := FCanvas;
end;

function TRSheet.GetDestCanvas: TCanvas;
begin
  Result := FDestCanvas;
  if Printing then Result := Printer.Canvas;
end;

function TRSheet.GetDest: TControl;
begin
  Result := FDest;
  if Printing then Result := thePrinterDest;
end;

function TRSheet.GetRect: TRect;
begin
  Result := FRect;
  if Printing then Result := PrintRect; //thePrinterDest.ClientRect;
end;

procedure TRSheet.PreparePrint;
var inchP, inchW: TPoint;
    pd: TPrintData; {for debug}
begin
  thePrinterDest.Left := 0;
  thePrinterDest.Top := 0;
  thePrinterDest.Width := Printer.PageWidth;
  thePrinterDest.Height := Printer.PageHeight;

  {--------------------------}
  pd.RectScale.X := RectWidth(FPrintRect)/RectWidth(FRect);
  pd.RectScale.Y := RectHeight(FPrintRect)/RectHeight(FRect);

  {--------------------------}
  inchP.X := GetDeviceCaps(Printer.Canvas.Handle, LOGPIXELSX);
  inchP.Y := GetDeviceCaps(Printer.Canvas.Handle, LOGPIXELSY);
  inchW.X := GetDeviceCaps({F!}FCanvas.Handle, LOGPIXELSX);
  inchW.Y := GetDeviceCaps({F!}FCanvas.Handle, LOGPIXELSY);

  pd.PixelScale.X := inchP.X/inchW.X;
  pd.PixelScale.Y := inchP.Y/inchW.Y;

  {--------------------------}

  pd.FontScale.X := {?}{0.5} 0.45 * pd.PixelScale.X*RectWidth(FPrintRect)/Printer.PageWidth;
  pd.FontScale.Y := {?}{0.5} 0.45 * pd.PixelScale.Y*RectHeight(FPrintRect)/Printer.PageHeight;

  FPrintData := pd;
end;

function TRSheet._UndoStack: TObject;
begin
  Result := RUndo.CommonUndoStack;
end;

function TRSheet.GetCurrentAgent: TRFigure;
begin
  Result := nil;

  if Assigned(FActiveLayer)then
  begin
    Assert(FActiveLayer.FRootActiveFigure <> nil);
    Result := FActiveLayer.FRootActiveFigure.Controller.Agent;
    if Result = nil then Result := FActiveLayer.FRootActiveFigure;
    if not Result.Visible then Result.Show;
  end;
end;

procedure TRSheet.ProcessActiveFigure;
begin
  if Assigned(ActiveLayer) then
  begin
    Include(FState, ssActiveFigureProcessing);

    try
    {--------------------------}
    case FEvent of
      evMouseDown, evMouseMove, evMouseUp:
        FActiveLayer.HandleMouse(GetCurrentAgent);
      evKeyDown, evKeyUp:
        FActiveLayer.HandleKbd(GetCurrentAgent);
    end;
    {--------------------------}
    finally

      if (Event = evMouseMove)and LBtnDown then EventHandled := True;
      if (Event = evMouseUp) then EventHandled := True; //??

      if (not EventHandled) then
      begin
        Exclude(FState, ssActiveFigureProcessing);
        if (Event in [evMouseDown, evMouseUp]) and
           (not Tool.KeepActiveFigure(Self)  ) then
          ActiveLayer.Deselect;
      end;
    end;
  end;
end;

procedure TRSheet.ProcessContextPopup;
var pt: TPoint;
begin
  if (FEvent = evMouseDown     )and
     (FMouseBtn = mbRight      ){and
     Assigned(FCommonPopupMenu)}then
  begin
    Dest.Invalidate; {! First}

    pt := Dest.ClientToScreen(FDownPt);
    FPopupInfo.Init(Self, ActiveLayer, pt);

    //Include(FState, ssLockMouseHandling);

    if Assigned(ActiveLayer) and
       GetCurrentAgent.DoContextPopup(FPopupInfo)
    then
      {*}
    else
    begin
      if Assigned(FCommonPopupMenu) then FPopupInfo.Popup(nil);
    end;
  end;
end;

procedure TRSheet.InitializeAgent;
var ActiveFig, SelAgent: TRFigure;
begin
  if (Event = evMouseDown       )and
     (Assigned(FActiveLayer)    )and
     (not (ssActiveFigureProcessing in FState))then
  begin
    ActiveFig := FActiveLayer.RootActiveFigure;
    SelAgent := GetCurrentAgent;
    if ActiveFig <> SelAgent then
    begin
      Include(FState, ssAgentInitializing);
      FEventHandled := False;
      FActiveLayer.HandleMouse(SelAgent);
      FEventHandled := True;
      Exclude(FState, ssAgentInitializing);
    end;
  end;

  if FEvent in [evMouseDown, evMouseUp] then
    SelectionChanged := True;
end;

procedure TRSheet.SetSelectionChanged(const Value: Boolean);
begin
  FSelectionChanged := Value;
end;

procedure TRSheet.DoSelectionChanged;
begin
  if Assigned(FOnSelect) then
    FOnSelect(Self);

  FSelectionChanged := False;  
end;

function TRSheet.GetTool: TRTool;
begin
  if Assigned(FTool)
    then Result := FTool
    else Result := theEmptyTool;
end;

procedure TRSheet.SetTool(Value: TRTool);
begin
  if FTool <> Value then
  begin
    if Assigned(FTool) then FTool.Activate(False);
    FTool := Value;
    if Assigned(FTool) then FTool.Activate(True);
  end;
end;

function TRSheet.Skip(Figure: TRFigure): Boolean;
begin
  {?????????}if CurrentInputSheet = nil then AcquireFocus; 

  Result := True;

  if (Figure = nil)or(not Figure.Visible) then Exit;

  if FEvent in [evMouseDown, evMouseMove, evMouseUp, evKeyDown, evKeyUp] then
  begin
    if not Assigned(Figure.Controller ) then Exit;
    if not (fsEditable in Figure.Style) then Exit;
    if not Assigned(Figure.Controller ) then Exit;
    if FEventHandled and not (ssAgentInitializing in FState) then Exit;
    if not Tool.Filter(Figure) then Exit;
  end;

  if FEvent = evMouseMove then
  begin
    if ( LBtnDown or RBtnDown )and
       ( not (csCaptured in Figure.Controller.FState)   )then Exit;

    if FSkipMouseMove then Exit;
  end;

  Result := False;
end;

procedure TRSheet.AcquireFocus;
var ParentForm: TCustomForm;
begin
  CurrentInputSheet := Self;
  ParentForm := GetParentForm(Dest);
  if Assigned(ParentForm) then
  begin
    if Dest is TWinControl
      then ParentForm.FocusControl(Dest as TWinControl)
      else ParentForm.FocusControl(nil);
  end;
end;

procedure TRSheet.DoRedraw;
begin
  //Dest.Refresh;
  Dest.Invalidate;
end;

procedure TRSheet.SetReadjustSelection(const Value: Boolean);
begin
  FReadjustSelection := Value;
  Redraw := True;
end;

procedure TRSheet.DoReadjustSelection;
begin
  FReadjustSelection := False;
  Readjust(GetCurrentAgent);
end;

procedure TRSheet.BeginDraw(Buffered: Boolean; Print: Boolean = False);
begin
  CurrentSheet := Self;
  FHandlingLevel := 0;
  IncEventNo;

  FEvent := evDraw;
  FBuffered := Buffered;

  FPrinting := Print;
  if Printing then PreparePrint;

  if FBuffered then
  begin
    FCanvas := theBufferBmp.Canvas;
    if theBufferBmp.Width < Rect.Right then theBufferBmp.Width := Rect.Right;
    if theBufferBmp.Height < Rect.Bottom then theBufferBmp.Height := Rect.Bottom;
  end else
    FCanvas := DestCanvas;

  FClipRect := DestCanvas.ClipRect;

  DeleteClipRegion(FClipRgn);
  FClipRgn := CreateClipRegion(FClipRect);
  {$IFDEF UNIX}
  {$ELSE}
  if (not FBuffered)and (not (Dest is TWinControl)) then
    OffsetRgn(FClipRgn, Dest.Left, Dest.Top);
  {$ENDIF}

  Prepare(prDraw);

  if (not LBtnDown)and
     (not RBtnDown)and
     (FReadjustSelection) then
    DoReadjustSelection;
end;

procedure TRSheet.EndDraw;
var anAgent: TRFigure;
begin
  if Assigned(FActiveLayer)and(not Printing) then
  begin
    //FActiveLayer.FRootActiveFigure.Controller.ExtraDraw(FActiveLayer, drHighlight);
    FActiveLayer.FRootActiveFigure.Controller.ExtraDraw(FActiveLayer, drSelection);

    anAgent := GetCurrentAgent;
    if (fsServant in anAgent.Style) then
      FActiveLayer.Draw(GetCurrentAgent);
  end;

  if FBuffered then DestCanvas.CopyRect(Rect, theBufferBmp.Canvas, Rect);

  //if CurrentLayer <> nil then CurrentLayer.Unprepare(prDraw);
  CurrentLayer := nil;
  CurrentSheet := nil;

  FPrinting := False; 

  //DeleteClipRegion(FClipRgn);
end;

procedure TRSheet.Clip;
begin
  SelectClipRegion(Canvas, FClipRgn);
end;

{function TRSheet.UndoStack: TRUndoStack;
begin
  Result := RUndo.UndoStack; 
end;}

procedure TRSheet.LockHandleMouse;
begin
  Include(FState, ssLockMouseHandling);
end;

procedure TRSheet.Fill(Color: TColor);
begin
  Canvas.Brush.Color := Color;
  Canvas.FillRect(Rect);
end;

procedure TRSheet.Prepare(Reason: TPrepareReason);
begin
  {}
end;

procedure TRSheet.BeginHandleMouse(AEvent: TMouseEventID; X, Y: Integer;
  Shift: TShiftState; Button: TMouseButton);
const MOUSE_DOWN_DELAY = 1{d}/24{h}/60{m}/60{s}/1000{ms} * 150;
      MOUSE_DEAD_ZONE = 6;
begin
  CurrentSheet := Self;
  FHandlingLevel := 0;
  IncEventNo;

  FAllowSelectRect := True;
  FCanvas := DestCanvas;
  FEvent := AEvent;
  FShiftState := Shift;
  FMouseBtn := Button;
  FEventHandled := False;
  FSkipMouseMove := False;
  FRedraw := False;
  //FReadjustSelection := False;

  if (Event = evMouseDown) then Include(FState, ssMouseDown);

  {$IFDEF UNIX}
  if (  FEvent = evMouseMove                             )and
     //(  [ssLeft, ssMiddle, ssRight] * FShiftState <> []  )and
     (ssLeft in FState)and
     (  not (ssMouseDown in FState)              ) then
    LockHandleMouse;
  {$ENDIF}

  if (ssLockMouseHandling in FState)then
  begin
    FEventHandled := True;
    if (FEvent = evMouseUp) then Exclude(FState, ssLockMouseHandling);
    if (FEvent = evMouseDown) then FEventHandled := False;
  end;


  if FEvent = evMouseDown then AcquireFocus;

  if Event = evMouseMove then FCursor := crUndefined; // else FCursor := Dest.Cursor; {!!}
  if Event = evMouseDown then FAllowSelectRect := False;
  if Event = evMouseDown then FMouseDownTime := Now;

  if (Event = evMouseMove)and
     (ssLeft in FShiftState)and
     (Abs(X - DownPt.X)    < MOUSE_DEAD_ZONE )and
     (Abs(Y - DownPt.Y)    < MOUSE_DEAD_ZONE )and
     (Now - FMouseDownTime < MOUSE_DOWN_DELAY)then
    FSkipMouseMove := True;

  if not FSkipMouseMove then
  begin
    FPrevPt := FCurrPt;
    FCurrPt := Point(X, Y);
  end;
  if Event = evMouseDown then FDownPt := FCurrPt;

  if FSkipMouseMove then FEventHandled := True;

  Prepare(prHandleMouse);

  Tool.Prepare(Self, prHandleMouse);
  Tool.BeginHandleMouse(Self, FEventHandled);
  Tool.Prepare(Self, prHandleMouse); // before or after????

  if (Event = evMouseMove) and (ssMouseDownHandling in FState) and (FActiveLayer <> nil) then
    FEventHandled := True;
end;

procedure TRSheet.EndHandleMouse;
begin
  if FEvent = evMouseMove then
  begin
    if FCursor = crUndefined then FCursor := crDefault;
    Dest.Cursor := FCursor;
  end;

  // if FEvent in [evMouseDown, evMouseUp] then Redraw := True;

  {$IFDEF UNIX}
  if not (ssLockMouseHandling in FState) then {?Linux}
  {$ENDIF}
    Tool.EndHandleMouse(Self); // => InitializeAgent;

  if (Event = evMouseUp) then Exclude(FState, ssMouseDown);

  if (Event = evMouseDown)and FEventHandled then Include(FState, ssMouseDownHandling);
  if (Event = evMouseUp) then Exclude(FState, ssMouseDownHandling);
  Exclude(FState, ssActiveFigureProcessing);

  if SelectionChanged then DoSelectionChanged;

  //if CurrentLayer <> nil then CurrentLayer.Unprepare(prHandleMouse);
  CurrentSheet := nil;
  CurrentLayer := nil;

  if not FSkipMouseMove then FPrevMouseEvent := FEvent;

  if Redraw then DoRedraw;
end;

procedure TRSheet.BeginHandleKbd(AEvent: TKbdEventID; var AKey: Word;
  Shift: TShiftState);
begin
  CurrentSheet := Self;
  FHandlingLevel := 0;
  IncEventNo;

  FEvent := AEvent;
  FEventHandled := False;
  FShiftState := Shift;
  FKey := AKey;
  FRedraw := False;

  Prepare(prHandleKbd);
  Tool.Prepare(Self, prHandleKbd);
  Tool.HandleKbd(Self);

  Key := FKey;
end;

procedure TRSheet.EndHandleKbd;
begin
  SelectionChanged := True; {???}
  if SelectionChanged then DoSelectionChanged;

  //if CurrentLayer <> nil then CurrentLayer.Unprepare(prHandleKbd);
  CurrentSheet := nil;
  CurrentLayer := nil;

  if Redraw then DoRedraw;
end;

procedure TRSheet.BeginDeal;
begin
  CurrentSheet := Self;
  IncEventNo;

  Prepare(prCalc);

  FEvent := evNone;
end;

procedure TRSheet.EndDeal;
begin
  case FEvent of
    evNone:
    begin
      CurrentSheet := nil;
      CurrentLayer := nil;
      if Redraw then DoRedraw;
    end;
    evDraw: EndDraw;
    evMouseDown, evMouseMove, evMouseUp: EndHandleMouse;
    evKeyDown, evKeyUp: EndHandleKbd;
  end;
end;

function TRSheet.LBtnDown: Boolean;
begin
  Result := ssLeft in ShiftState;
end;

function TRSheet.RBtnDown: Boolean;
begin
  Result := ssRight in ShiftState;
end;

function TRSheet.DblClick: Boolean;
begin
  Result := ssDouble in ShiftState;
end;

{------------------------------ TRTool ----------------------------------------}

constructor TRTool.Create(AName: string);
begin
  FName := AName;
end;

procedure TRTool.Prepare(Sheet: TRSheet; Reason: TPrepareReason);
begin
  if Assigned(Sheet.WorkingLayer) then
    Sheet.WorkingLayer.Prepare(Reason);
end;

function TRTool.Filter(Figure: TRFigure): Boolean;
begin
  Result := True;
end;

procedure TRTool.Activate(Value: Boolean);
begin
  {;}
end;

procedure TRTool.HandleKbd(Sheet: TRSheet);
begin
  {;}
end;

procedure TRTool.ProcessLayer(Layer: TRLayer);
begin
  {;}
end;

function TRTool.SelectMode(Layer: TRLayer): TRSelectMode;
begin
  if ssShift in Layer.Sheet.ShiftState
    then Result := smXor
    else Result := smNormal;
end;

procedure TRTool.XorDraw(Sheet: TRSheet; DrawProc: TRDrawSelProc;
  PenMode: TPenMode = pmNot);
var R: TRect;
begin
  with Sheet do
  begin
    Canvas.Pen.Mode := PenMode;

    if (Event <> evMouseDown) then
    begin
      R := CalcSelRect(FDownPt, FPrevPt);
      DrawProc(Sheet, R, Sheet.DownPt, Sheet.PrevPt);
    end;

    R := CalcSelRect(FDownPt, FCurrPt);
    DrawProc(Sheet, R, Sheet.DownPt, Sheet.CurrPt);

    Canvas.Pen.Mode := pmCopy;
    Canvas.Pen.Style := psSolid;
    Canvas.Brush.Style := bsSolid;

    Redraw := False;
  end;
end;

{------------------------ TLayerCoordConverter --------------------------------}

constructor TRLayerCoordConverter.Create(Layer: TRLayer);
begin
  FLayer := Layer;
end;

procedure TRLayerCoordConverter.Prepare;
begin
  with FLayer.Rect, FLayer.FViewPort do
  begin
    FXSL.K := (XMax - XMin)/(Right - Left);
    FXSL.C := XMin - Left*FXSL.K;

    FYSL.K := (YMax - YMin)/(Top - Bottom);
    FYSL.C := YMin - Bottom*FYSL.K;

    FXLS.K := (Right - Left)/(XMax - XMin);
    FXLS.C := Left - XMin*FXLS.K;

    FYLS.K := (Top - Bottom)/(YMax - YMin);
    FYLS.C := Bottom - YMin*FYLS.K;
  end;
end;

procedure TRLayerCoordConverter.LogicToScreen(LX, LY: TFloat; var SX, SY: Integer);
begin
{  with FLayer.Rect, FLayer.FViewPort do
  begin
    SX := Round( Left + (LX - XMin)*(Right - Left)/(XMax - XMin) );
    SY := Round( Bottom + (LY - YMin)*(Top - Bottom)/(YMax - YMin) );
  end; }
  SX := Round(FXLS.C + FXLS.K*LX);
  SY := Round(FYLS.C + FYLS.K*LY);
end;

procedure TRLayerCoordConverter.ScreenToLogic(SX, SY: Integer; var LX, LY: TFloat);
begin
{  with FLayer.Rect, FLayer.FViewPort do
  begin
    LX := XMin + (SX - Left)*(XMax - XMin)/(Right - Left);
    LY := YMin + (SY - Bottom)*(YMax - YMin)/(Top - Bottom);
  end; }
  LX := FXSL.C + FXSL.K*SX;
  LY := FYSL.C + FYSL.K*SY;
end;

{------------------------------- TRController ---------------------------------}

constructor TRController.Create;
begin
end;

destructor TRController.Destroy;
begin
  if Assigned(FControllee) then
    FControllee.Controller := nil; 
  inherited;
end;

function TRController.Controllee: TRFigure;
begin
  Result := FControllee;
end;

procedure TRController.SetControllee(Value: TRFigure);
begin
  if Self = nil then Exit;

  if FControllee <> Value then
  begin
    if Assigned(FControllee) then FControllee.FController := nil;
    FControllee := Value;
    if Assigned(FControllee) then FControllee.FController := Self;
  end;
end;

function TRController.HitTest(Layer: TRLayer; const Pt: TPointF): Boolean;
begin
  Result := TRFigureHelper(Controllee).HitTest(Layer, Pt);
end;

function TRController.AllowSelectFigureAsWhole: Boolean;
begin
  Result := True;
end;

function TRController.AllowFurtherMultiSelect: Boolean; 
begin
  Result := True;
end;

function TRController.IsInAgentMode: Boolean;
begin
  Result := (ssActiveFigureProcessing in CurrentSheet.FState)or
            (ssAgentInitializing      in CurrentSheet.FState);
end;

function TRController.Agent: TRFigure;
begin
  Result := FAgent;
end;

procedure TRController.AssignAgent(Value: TRFigure);
begin
  FAgent := Value;
  UpgradeAgent(FAgent);
end;

procedure TRController.UpgradeAgent(var AAgent: TRFigure);
begin
  {}
end;

function TRController.Supports(Figure: TObject): Boolean;
begin
  Result := False;
end;

procedure TRController.ExtraDraw(Layer: TRLayer; Reason: TRExtraDrawReason);
begin
end;

procedure TRController.DecorateByTransformer(Layer: TRLayer);
begin
  FAgent := Layer.DefaultTransformer.Init(Controllee);
  Include(FState, csCaptured);
end;

procedure TRController.Deselect;
begin
  FAgent := nil;
  FState := [];
end;

function TRController.Clone: TRController;
begin
  Result := TRControllerClass(ClassType).Create;
end;

function TRController.SelectFigure(Layer: TRLayer; Figure: TRFigure;
  Mode: TRSelectMode): Boolean;
begin
  Result := False;
end;

{--------------------------- TRControllerEx -----------------------------------}

procedure TRControllerEx.HandleKbd(Layer: TRLayer);
var Key: Word;
begin
  Key := Layer.Sheet.Key;
  case Layer.Sheet.Event of
    evKeyDown: KeyDown(Layer, Key);
    evKeyUp: KeyUp(Layer, Key);
  end;
  Layer.Sheet.Key := Key;
end;

procedure TRControllerEx.HandleMouse(Layer: TRLayer);
var R: TRectF;
begin
  case Layer.Sheet.Event of
    evMouseDown: MouseDown(Layer, Layer.Sheet.FEventHandled);
    evMouseMove:
      begin
        MouseMove(Layer, Layer.Sheet.FCursor);
        if Layer.Sheet.Cursor <> crUndefined then Layer.Sheet.EventHandled := True;
      end;
    evMouseUp:
      if (Layer.RootActiveFigure <> nil)and
         (Layer.Sheet.Tool.SelectMode(Layer) = smNormal) then
      begin
        MouseUp(Layer);
        Layer.Sheet.EventHandled := (Layer.RootActiveFigure <> nil);
      end
      else if Layer.Sheet.AllowSelectRect then
      begin
        R := CalcSelRectF(Layer.DownPt, Layer.CurrPt, True);
        if SelectRect(Layer, R) then Layer.Sheet.EventHandled := True;
      end;
  end;
end;

procedure TRControllerEx.KeyDown(Layer: TRLayer; var Key: Word);
begin
end;

procedure TRControllerEx.KeyUp(Layer: TRLayer; var Key: Word);
begin
end;

function TRControllerEx.SelectRect(Layer: TRLayer; Rect: TRectF): Boolean;
begin
  Result := False;
end;

{------------------------------ TRSimpleController ----------------------------}

procedure TRSimpleController.HandleKbd(Layer: TRLayer);
begin
end;

procedure TRSimpleController.HandleMouse(Layer: TRLayer);
begin
  if Layer.HitTest(Controllee, Layer.CurrPt) then
    case Layer.Sheet.Event of
      evMouseDown:
        if not IsInAgentMode then
        begin
          Layer.Sheet.EventHandled := True;
          AssignAgent(Layer.DefaultTransformer.Init(Controllee));
        end;
      evMouseMove: Layer.Sheet.Cursor := crMoveObj;
      evMouseUp:   Layer.Sheet.EventHandled := False;
    end;
end;

function TRSimpleController.Supports(AObject: TObject): Boolean;
begin
  Result := TRFigureHelper(AObject).IsTransformable;
end;


{------------------------------ TREditTool ---------------------------------}

procedure TREmptyTool.BeginHandleMouse(Sheet: TRSheet; var Handled: Boolean);
begin
  Handled := True;
end;

procedure TREmptyTool.EndHandleMouse(Sheet: TRSheet);
begin
end;

function TREmptyTool.KeepActiveFigure(Sheet: TRSheet): Boolean;
begin
  Result := False;
end;

{------------------------------ TREditTool ---------------------------------}

procedure TREditTool.BeginHandleMouse(Sheet: TRSheet; var Handled: Boolean);
begin
  Sheet.ProcessActiveFigure;
end;

procedure TREditTool.EndHandleMouse(Sheet: TRSheet);
begin
  if (Sheet.Event = evMouseMove) and
     (  (Sheet.ActiveLayer = nil)or (ssShift in Sheet.ShiftState){!} )  and
     (  Sheet.AllowSelectRect   )and(ssLeft  in Sheet.ShiftState     ) then
  begin
    Sheet.Canvas.Pen.Style := psDot;
    Sheet.Canvas.Brush.Style := bsClear;
    XORDraw(Sheet, DrawSelRect, pmNot);
  end;

  if Sheet.Event in [evMouseDown, evMouseUp] then
    Sheet.Redraw := True;

  Sheet.InitializeAgent;
  Sheet.ProcessContextPopup;
end;

procedure TREditTool.DrawSelRect(Sheet: TRSheet; const Rect: TRect;
  const FirstPt, SecondPt: TPoint);
begin
  Sheet.Canvas.Rectangle(Rect);
end;

procedure TREditTool.HandleKbd(Sheet: TRSheet);
begin
  Sheet.ProcessActiveFigure;
end;

function TREditTool.KeepActiveFigure(Sheet: TRSheet): Boolean;
begin
  Result := (ssShift in Sheet.ShiftState)and
            (Sheet.Event = evMouseDown  );
end;

procedure TREditTool.ProcessLayer(Layer: TRLayer);
begin
end;

{------------------------------------------------------------------------------}

procedure Readjust(Agent: TRFigure);
begin
  if Agent is TRAgentDecorator then
  begin
    Readjust(TRAgentDecorator(Agent).Decoree);
    TRAgentDecorator(Agent).Adjust;
  end;
end;

{-------------------- TRAgentDecoratorController --------------------------}

function TRAgentDecoratorController.Decorator: TRAgentDecorator;
begin
  Result := Controllee as TRAgentDecorator;
end;

procedure TRAgentDecoratorController.HandleKbd(Layer: TRLayer);
begin
  if not Layer.HandleKbd(TRAgentDecorator(Controllee).Decoree) then inherited;
end;

procedure TRAgentDecoratorController.HandleMouse(Layer: TRLayer);
begin
  if not Layer.HandleMouse(TRAgentDecorator(Controllee).Decoree) then inherited;
end;

function TRAgentDecoratorController.Supports(AObject: TObject): Boolean;
begin
  Result := AObject is TRAgentDecorator;
end;

{----------------------------- TRPopupInfo ------------------------------------}

procedure TRPopupInfo.Init(ASheet: TRSheet; ALayer: TRLayer; APoint: TPoint);
begin
  FSheet := ASheet;
  FLayer := ALayer;
  FPoint := APoint;
  FFigure := nil;

  if Assigned(FSheet)and Assigned(FSheet.CommonPopupMenu)then
    FSheet.CommonPopupMenu.PopupComponent := Self;
end;

procedure TRPopupInfo.Hook(AMenu: TPopupMenu);
begin
  if Assigned(RPopupHookProc) then
    RPopupHookProc(Self, AMenu);
end;

procedure TRPopupInfo.Popup(AdditionalPopup: TPopupMenu);
begin
  //DoPopup(AdditionalPopup);
  PostMessage(Handle, WM_DELAYEDPOPUP, Integer(AdditionalPopup), 0);
end;

procedure TRPopupInfo.WMDelayedPopup(var Msg: TMessage);
begin
  DoPopup(TPopupMenu(Msg.WParam));
end;

procedure TRPopupInfo.DoPopup(AdditionalPopup: TPopupMenu);
var menu: TPopupMenu;
    addItems: array of TMenuItem;
    i, N: Integer;
begin
  menu := FSheet.CommonPopupMenu;

  if (menu = nil)and(AdditionalPopup = nil) then Exit;

  if (menu = nil) then
  begin
    AdditionalPopup.PopupComponent := Self;
    Hook(AdditionalPopup);
    AdditionalPopup.Popup(FPoint.X, FPoint.Y);
    Exit;
  end else
    menu.PopupComponent := Self;

  if (AdditionalPopup = nil) then
  begin
    Hook(menu);
    menu.Popup(FPoint.X, FPoint.Y);
    Exit;
  end else
    AdditionalPopup.PopupComponent := Self;

  N := AdditionalPopup.Items.Count;
  SetLength(addItems, N);

  for i := 0 to N-1 do
    addItems[i] := AdditionalPopup.Items[i];

  for i := 0 to N-1 do
  begin
    AdditionalPopup.Items.Remove(addItems[i]);
    menu.Items.Add(addItems[i]);
  end;

  Hook(menu);
  menu.Popup(FPoint.X, FPoint.Y);

  for i := 0 to N-1 do
  begin
    menu.Items.Remove(addItems[i]);
    AdditionalPopup.Items.Add(addItems[i]);
  end;
end;

{------------------------------ TPrinterDest ----------------------------------}

type
  TPrinterDest = class(TControl);

{------------------------------------------------------------------------------}

function InputSheet: TRSheet;
begin
  Result := CurrentInputSheet;
end;

initialization
  theBufferBmp := TBitmap.Create;
  theBufferBmp.PixelFormat := pf32bit;

  theEmptyTool := TREditTool.Create('');

  thePrinterDest := TPrinterDest.Create(nil);
finalization
  theBufferBmp.Free;
  theEmptyTool.Free;
  thePrinterDest.Free; 
end.

