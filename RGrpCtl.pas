{*******************************************************************************
*                                                                              *
*                       Author: Reonid                                         *
*                       Categoty: vector graphic                               *
*                       mailto: reonid@yahoo.com                               *
*                                                                              *
*******************************************************************************}

unit RGrpCtl;

interface

uses
  {$IFDEF UNIX} {Unix,} {$ELSE} Windows, {$ENDIF}
  RSysDep,
  RCore, RTypes, RIntf, RGroup, RSelFrm, Controls;

type
  TRMonolithGroupController = class(TRBaseGroupController)
  public
    procedure MouseDown(Layer: TRLayer; var Handled: Boolean); override;
    procedure MouseMove(Layer: TRLayer; var Cursor: TCursor); override;
    procedure MouseUp(Layer: TRLayer); override;              //CN_COMMAND
  end;

  TRScatterGroupController = class(TRBaseGroupController)
  private
    FSelectionFrame: TRSelectionFrame;
    FSelection: TRGroup;
    FMultiselector: TRAgentDecorator;
  protected
    function CreateMultiselector: TRAgentDecorator; virtual;
    function CreateSelFrame: TRSelectionFrame; virtual;
    function CreateSelection: TRGroup; virtual;
    function CreateArrangeGroup: TRGroup; virtual;

    function SelectFigure(Layer: TRLayer; Figure: TRFigure;
      Mode: TRSelectMode): Boolean; override;

    procedure SortSelection;
  public
    constructor Create; override;
    destructor Destroy; override;

    function SelectRect(Layer: TRLayer; Rect: TRectF{; Mode: TRSelectMode}): Boolean; override;

    procedure MouseDown(Layer: TRLayer; var Handled: Boolean); override;
    procedure MouseMove(Layer: TRLayer; var Cursor: TCursor); override;
    procedure MouseUp(Layer: TRLayer); override;

    procedure Deselect; override;
    procedure ExtraDraw(Layer: TRLayer; Reason: TRExtraDrawReason); override;
    procedure ReviseSelection(Layer: TRLayer);
    function AllowSelectFigureAsWhole: Boolean; override;

    {------}
    function UndoablyGroupSelectedFigures(Layer: TRLayer): TRGroup;
    procedure UndoablyUngroupSelectedFigures(Layer: TRLayer);
  end;

  TRGroupMultiselector = class(TRAgentDecorator);

  TRGroupMultiselectorController = class(TRAgentDecoratorController)
  private
    FGroupController: TRScatterGroupController;
    function NoFurtherMultiselect(var Handled: Boolean): Boolean;
  public
    constructor Create(AGroupController: TRScatterGroupController); reintroduce;

    function SelectRect(Layer: TRLayer; Rect: TRectF): Boolean; override;
    procedure KeyDown(Layer: TRLayer; var Key: Word); override;
    procedure MouseDown(Layer: TRLayer; var Handled: Boolean); override;
    procedure MouseMove(Layer: TRLayer; var Cursor: TCursor); override;
    procedure MouseUp(Layer: TRLayer); override;
  end;

  TRSelectionGroupEx = class(TRSelectionGroup)
  private
    FOwnerGroupContoller: TRScatterGroupController;
  public
    property OwnerGroupContoller: TRScatterGroupController read FOwnerGroupContoller;

    constructor CreateOwned(AOwnerGroupContoller: TRScatterGroupController);

    function OwnerGroup: TRGroup;
    procedure Sort; override;
  end;

  TRArrangeGroup = class(TRGroup)
  private
    FOwnerGroupContoller: TRScatterGroupController;
  protected  
    procedure SetMaster(Value: TRMaster); override; 
  public
    property OwnerGroupContoller: TRScatterGroupController read FOwnerGroupContoller;
    
    constructor CreateOwned(AOwnerGroupContoller: TRScatterGroupController);
    constructor Create; override; 

    destructor Destroy; override;
    function OwnerGroup: TRGroup;
  end;

implementation

uses
  Classes,
  RGeom, RUndo, RFigHlp;

function GetSelectionMinOrderNumber(Group, Selection: TRGroup): Integer; forward;

type
  THackGroup = class(TRGroup);

  TRArrangeGroupAction = (agaGroup, agaUngroup);

  TRArrangeGroupUndoPoint = class(TRUndoPoint)
  private
    FScatterGroupController: TRScatterGroupController;
    FAction: TRArrangeGroupAction;
    FList: TList;
    //FOrderData: TRGroupOrderData;
    FArrangeGroup: TRGroup; // for ungroup
  public
    constructor Create(AScatterGroupController: TRScatterGroupController;
      ArrGroup: TRGroup;
      Action: TRArrangeGroupAction;
      //OriginalOrder: TRGroupOrderData;
      ASheet: TRSheet; ALayer: TRLayer);

    destructor Destroy; override;
    procedure Restore; override;
  end;

{--------------------------- TRMonolithGroupController ------------------------}

procedure TRMonolithGroupController.MouseDown(Layer: TRLayer; var Handled: Boolean);
begin
  if not IsInAgentMode then
  begin
    Handled := Group.HitTest(Layer, Layer.DownPt);
    AssignAgent(Layer.DefaultTransformer.Init(Group));
  end;
end;

procedure TRMonolithGroupController.MouseMove(Layer: TRLayer; var Cursor: TCursor);
begin
  if HitTest(Layer, Layer.CurrPt) then
  begin
    Cursor := crMoveObj;
  end;   
end;

procedure TRMonolithGroupController.MouseUp(Layer: TRLayer);
begin
end;

{------------------------- TRScatterGroupController ----------------------------}

constructor TRScatterGroupController.Create;
begin
  inherited;
  FSelectionFrame := CreateSelFrame;
  FSelection := CreateSelection;
  FMultiselector := CreateMultiselector;
end;

destructor TRScatterGroupController.Destroy;
begin
  FSelectionFrame.Free;
  FSelection.Free;
  FMultiselector.Free;
  inherited;
end;

function TRScatterGroupController.AllowSelectFigureAsWhole: Boolean;
begin
  Result := False;
end;

procedure TRScatterGroupController.Deselect;
var i: Integer;
begin
  inherited;

  for i := 0 to FSelection.Count-1 do
    FSelection[i].Controller.Deselect;

  //FSelectionFrame.Content := nil;  // Internal Error E5907
  FSelectionFrame.Decoree{=Content} := nil;

  FSelectionFrame.Hide;

  FSelection.Clear;
  FSelection.Hide;
end;

function TRScatterGroupController.CreateSelFrame: TRSelectionFrame;
begin
  Result := TRSelectionFrame.Create;
  Result.Options := Result.Options + [sfoWideBorder];

  //Result.Options := Result.Options + [sfoProportional];
  //Result.Options := Result.Options + [sfoDelayedTransform];
  //Result.Options := Result.Options + [sfoHollowBody];

  Result.Controller := TRSelectionFrameController.Create;
end;

function TRScatterGroupController.CreateSelection: TRGroup;
begin
  Result := TRSelectionGroupEx.CreateOwned(Self);
  //Result.Controller := nil;
end;

function TRScatterGroupController.CreateArrangeGroup: TRGroup;
begin
  Result := TRArrangeGroup.CreateOwned(Self);
  Result.Controller := TRMonolithGroupController.Create;
end;

function TRScatterGroupController.CreateMultiselector: TRAgentDecorator;
begin
  Result := TRGroupMultiselector.Create; //nil;
  Result.Controller := TRGroupMultiselectorController.Create(Self);
end;

procedure TRScatterGroupController.SortSelection;
var i, j: Integer;
    list: TList;
begin
  list := TList.Create;
  try
    for i := 0 to Group.Count-1 do
      for j := 0 to FSelection.Count-1 do
        if Group.Figures[i] = FSelection.Figures[j] then
          list.Add(FSelection.Figures[j]);

    FSelection.Clear;
    for i := list.Count-1 downto 0 do
      FSelection.Add(TRFigure(list[i]));

  finally
    list.Free;
  end;
end;

procedure TRScatterGroupController.MouseDown(Layer: TRLayer; var Handled: Boolean);
var i: Integer;
    aa: TRFigure;
begin
  if not IsInAgentMode then
  begin
    Layer.DefaultTransformer := FSelectionFrame;
    with Group do
      for i := 0 to Count-1 do
        if Layer.HandleMouse(Figures[i]) then
        begin
          FSelection.Clear;
          FSelection.Add(Figures[i]);
          aa := FMultiselector.Init(Figures[i].Controller.Agent);
          AssignAgent(aa);
          Break;
        end;
  end;
end;

procedure TRScatterGroupController.MouseMove(Layer: TRLayer; var Cursor: TCursor);
var i: Integer;
begin
  with Group do
    for i := 0 to Count-1 do
      Layer.HandleMouse(Figures[i]);
end;

procedure TRScatterGroupController.MouseUp(Layer: TRLayer);
var i: Integer;
begin
  {never performed!!!!!}
  with Group do
    for i := 0 to Count-1 do
      Layer.HandleMouse(Figures[i]);
end;

procedure TRScatterGroupController.ExtraDraw(Layer: TRLayer; Reason: TRExtraDrawReason);
var i: Integer;
begin
  if Reason = drSelection then
  begin
    //inherited;
    with FSelection do
      for i :=0 to Count-1 do
        Figures[i].Controller.ExtraDraw(Layer, Reason);
  end;
end;

type TRHackController = class(TRController);

procedure TRScatterGroupController.ReviseSelection(Layer: TRLayer);
begin
  case FSelection.Count of
    0: AssignAgent(FMultiselector.Init(Group));
    1: begin
         Layer.DefaultTransformer := FSelectionFrame;
         TRHackController(FSelection[0].Controller).DecorateByTransformer(Layer);
         AssignAgent(FMultiselector.Init(FSelection[0].Controller.Agent));
       end;
    else {if FSelection.Count = Group.Count
      then AssignAgent(FMultiselector.Init(FSelectionFrame.Init(Group)))
      else} AssignAgent(FMultiselector.Init(FSelectionFrame.Init(FSelection)));
  end;
end;

function TRScatterGroupController.SelectRect(Layer: TRLayer; Rect: TRectF): Boolean;
var i: Integer;
begin
  {only Primary Selection}
  Assert(FSelection.Count = 0);

  Result := False;

  with Group do
  begin
    if Layer.SelectMode = smMinus then Exit;

    for i := 0 to Count-1 do
      if Group.Figures[i].Editable and /// ???????????????????
         Group.Figures[i].Controller.AllowSelectFigureAsWhole and
         RectInRectF(Rect, TRFigureHelper(Figures[i]).ContainingRect)
      then
        FSelection.AdvancedAdd(Figures[i], Layer.SelectMode);

    ReviseSelection(Layer);

    Result := FSelection.Count > 0;

    {Let figures select rect by themselves}
    if not Result then
      for i := 0 to Count-1 do
        if Layer.HandleMouse(Figures[i]) then
        begin
          Result := True;
          FSelection.Add(Figures[i]); //???  for multifigure selection
          AssignAgent(FMultiselector.Init(Figures[i].Controller.Agent));
          Break;
        end;

  end;
end;

function TRScatterGroupController.SelectFigure(Layer: TRLayer; Figure: TRFigure;
  Mode: TRSelectMode): Boolean;
begin
  Layer.DefaultTransformer := FSelectionFrame;
  if Mode = smNormal then FSelection.Clear;

  Assert(Group.Contains(Figure));

  FSelection.AdvancedAdd(Figure, Mode);
  ReviseSelection(Layer);
  Layer.Sheet.Redraw := True;

  Result := FSelection.Count > 0;
end;

function TRScatterGroupController.UndoablyGroupSelectedFigures(Layer: TRLayer): TRGroup;
var i, idx: Integer;
    g: TRGroup;
begin
  Result := nil;
  idx := GetSelectionMinOrderNumber(Group, FSelection);

  if FSelection.Count > 1 then
  begin
    g := CreateArrangeGroup;

    SortSelection;

    for i := FSelection.Count-1 downto 0 do
      g.Add(FSelection[i]);

    if not UndoStack(Layer.Sheet).Recovering then
      UndoStack(Layer.Sheet).Push(
        TRArrangeGroupUndoPoint.Create(Self, g, agaGroup, Layer.Sheet, Layer)
      );

    FSelection.Clear;
    Group.Add(g);
    THackGroup(Group).MoveFigure(0, idx);
    FSelection.Add(g);
    ReviseSelection(Layer);

    Result := g;
  end;
end;

procedure TRScatterGroupController.UndoablyUngroupSelectedFigures(Layer: TRLayer);
var i, idx: Integer;
    g: TRGroup;
    f: TRFigure;
begin
  if (FSelection.Count = 1)and
     (FSelection.Figures[0] is TRArrangeGroup{?}) then
  begin
    g := FSelection.Figures[0] as TRGroup;
    FSelection.Clear;
    idx := THackGroup(Group).GetFigureOrderNumber(g);

    for i := 0 to g.Count-1 do
      FSelection.Add(g.Figures[i]);

    if not UndoStack(Layer.Sheet).Recovering then
      UndoStack(Layer.Sheet).Push(
        TRArrangeGroupUndoPoint.Create(Self, g, agaUngroup, Layer.Sheet, Layer)
      );

    for i := 0 to FSelection.Count-1 do 
    begin
      f := FSelection.Figures[i];
      Group.Add(f); // ! f is removed from g
      THackGroup(Group).MoveFigure(0, idx);
    end;

    Group.Remove(g); // ! g destroyed by UndoPoint
    ReviseSelection(Layer);
  end;
end;

{---------------------- TRGroupMultiselectorController ------------------------}

constructor TRGroupMultiselectorController.Create(AGroupController: TRScatterGroupController);
begin
  inherited Create;
  FGroupController := AGroupController;
end;

procedure TRGroupMultiselectorController.MouseMove(Layer: TRLayer; var Cursor: TCursor);
begin
end;

procedure TRGroupMultiselectorController.MouseUp(Layer: TRLayer);
begin
end;

procedure TRGroupMultiselectorController.KeyDown(Layer: TRLayer; var Key: Word);
var multiselector: TRAgentDecorator;
begin
  inherited;
  case Key of
    VK_DELETE:
    begin
      multiselector := Controllee as TRAgentDecorator;
      multiselector.Decoree.UndoablyDelete(Layer);
      Layer.Deselect;
      multiselector.Decoree := nil;
      Layer.Sheet.Redraw := True;
      {!}Layer.Sheet.EventHandled := True;
      Layer.Sheet.SelectionChanged := True;
    end;
  end;
end;

function TRGroupMultiselectorController.NoFurtherMultiselect(var Handled: Boolean): Boolean;
var sel: TRGroup;
begin
  sel := FGroupController.FSelection;
  Result := (sel.Count = 1)and
            (sel[0].Controller <> nil) and // Always
            (not sel[0].Controller.AllowFurtherMultiSelect);
  if Result then Handled := True; {???}
end;

function TRGroupMultiselectorController.SelectRect(Layer: TRLayer; Rect: TRectF): Boolean;
var i: Integer;
begin
  Result := False;
  if Layer.SelectMode <> smNormal then
  begin

    with FGroupController do
    begin
      if NoFurtherMultiselect(Result) then Exit;

      for i := 0 to Group.Count-1 do
        if (Group.Figures[i].Controller <> nil)and
           Group.Figures[i].Controller.AllowSelectFigureAsWhole and
           RectInRectF(Rect, TRFigureHelper(Group.Figures[i]).ContainingRect) then
        begin
          FSelection.AdvancedAdd(Group.Figures[i], Layer.SelectMode);
          Result := True;
        end;

      if Result then
      begin
        ReviseSelection(Layer);
        Layer.Sheet.SelectionChanged := True;
      end;
    end;

  end;
end;

procedure TRGroupMultiselectorController.MouseDown(Layer: TRLayer; var Handled: Boolean);
var i: Integer;
begin
  if Layer.SelectMode <> smNormal then
  begin
    with FGroupController do
    begin
      if NoFurtherMultiselect(Handled) then Exit;

      for i := 0 to Group.Count-1 do
        if Layer.HitTest(Group.Figures[i], Layer.CurrPt) then // => Controller <> nil
        begin
          Handled := True;
          if not Group.Figures[i].Controller.AllowSelectFigureAsWhole then Exit; //????

          FSelection.AdvancedAdd(Group.Figures[i], Layer.SelectMode);
          ReviseSelection(Layer);
          Handled := True; //????//FSelection.Count > 0;
          Break;
        end;
    end;
    Layer.Sheet.SelectionChanged := True;
  end;
end;

{--------------------------- TRSelectionGroupEx -------------------------------}

constructor TRSelectionGroupEx.CreateOwned(AOwnerGroupContoller: TRScatterGroupController);
begin
  inherited CreateEx(False);
  FOwnerGroupContoller := AOwnerGroupContoller;
end;

function TRSelectionGroupEx.OwnerGroup: TRGroup;
begin
  Result := FOwnerGroupContoller.Group;
end;

procedure TRSelectionGroupEx.Sort;
begin
  FOwnerGroupContoller.SortSelection;
end;

{----------------------------- TRArrangeGroup -------------------------------}

constructor TRArrangeGroup.Create;
begin
  inherited CreateEx(True);
  FOwnerGroupContoller := NIL;
end;

constructor TRArrangeGroup.CreateOwned(AOwnerGroupContoller: TRScatterGroupController);
begin
  inherited CreateEx(True);
  FOwnerGroupContoller := AOwnerGroupContoller;
end;

destructor TRArrangeGroup.Destroy;
begin
  inherited;
end;

procedure TRArrangeGroup.SetMaster(Value: TRMaster);
begin
  inherited;
  if (Value is TRGroup) and (Value.Controller is TRScatterGroupController)then
    FOwnerGroupContoller := TRScatterGroupController(Value.Controller); 
end;

function TRArrangeGroup.OwnerGroup: TRGroup;
begin
  Result := FOwnerGroupContoller.Group;
end;

{-------------------------- TRArrangeGroupUndoPoint ---------------------------}

constructor TRArrangeGroupUndoPoint.Create(
  AScatterGroupController: TRScatterGroupController;
  ArrGroup: TRGroup; 
  Action: TRArrangeGroupAction;
  ASheet: TRSheet; ALayer: TRLayer);
var
  i: Integer;
begin
  inherited Create(ASheet, ALayer);

  FScatterGroupController := AScatterGroupController;
  FAction := Action;
  FArrangeGroup := ArrGroup;

  FList := TList.Create;

  if FAction = agaUngroup then
    for i := 0 to ArrGroup.Count-1 do
      FList.Add(ArrGroup.Figures[i]);
end;

destructor TRArrangeGroupUndoPoint.Destroy;
begin
  FList.Free;
  if FAction = agaUngroup then FArrangeGroup.Free;

  inherited;
end;

procedure TRArrangeGroupUndoPoint.Restore;
const Mode: array[Boolean]of TRSelectMode = (smNormal, smPlus);
var i, idx: Integer;
    g, MasterGroup: TRGroup;
begin
  Sheet.BeginDeal;

  masterGroup := FScatterGroupController.Group;

  if FAction = agaGroup then
  begin
    FArrangeGroup.SelectProgramly(Layer);
    FScatterGroupController.UndoablyUngroupSelectedFigures(Layer);
  end
  else // agaUngroup
  begin
    for i := 0 to FList.Count-1 do
      TRFigure(FList[i]).SelectProgramly(Layer, Mode[i>0]);

    idx := GetSelectionMinOrderNumber(masterGroup, FScatterGroupController.FSelection);

    g := FScatterGroupController.UndoablyGroupSelectedFigures(Layer);
    // Replace g by FArrangeGroup

    while g.Count > 0 do
      FArrangeGroup.Add(g[g.Count-1]);

    masterGroup.Remove(g); // g will be destroyed by undo point
    masterGroup.Add(FArrangeGroup);
    THackGroup(masterGroup).MoveFigure(0, idx);
    FArrangeGroup := nil;

  end;
  Layer.Deselect;

  Sheet.EndDeal;
end;

{------------------------------------------------------------------------------}

function GetSelectionMinOrderNumber(Group, Selection: TRGroup): Integer;
var i, idx: Integer;
begin
  Result := MaxInt;
  for i := 0 to Selection.Count-1 do
  begin
    idx := THackGroup(Group).GetFigureOrderNumber(Selection.Figures[i]);
    if idx < Result then Result := idx; 
  end;
end;

end.
