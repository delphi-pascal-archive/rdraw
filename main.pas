unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, Menus, ToolWin, ImgList, ExtCtrls, StdCtrls, Spin, ExtDlgs,
  Printers,

  RTypes, RCore, RUtils, RGeom, RFigHlp,
  RUndo, RIntf, RTool, RZoom,
  RCurve, RCrvCtl,
  RBezier, RBzrCtl,
  RGroup, RGrpCtl,
  RLine,

  _createFig,
  _newArea,

  _attrMon,
  _grpMon,
  _closeMon,
  _linewMon,
  _bzrBtn,
  _myBzr,    // _myCrv,
  _imgFig,
  _fhTool,

  _rCurs;

type
  TMainForm = class(TForm)
    ControlBar1: TControlBar;
    MainMenu1: TMainMenu;
    FigurePopupMenu: TPopupMenu;
    imgTools: TImageList;
    imgBezier: TImageList;
    imgOther: TImageList;
    tbMain: TToolBar;
    File1: TMenuItem;
    Open1: TMenuItem;
    SaveAs1: TMenuItem;
    N1: TMenuItem;
    Exit1: TMenuItem;
    BEditTool: TToolButton;
    BPointTool: TToolButton;
    BZoomTool: TToolButton;
    BRectTool: TToolButton;
    BEllipseTool: TToolButton;
    tbBezier: TToolBar;
    BLine: TToolButton;
    BCurve: TToolButton;
    ToolButton12: TToolButton;
    MainPanel: TPanel;
    ToolBar1: TToolBar;
    Label1: TLabel;
    cbFill: TColorBox;
    Label2: TLabel;
    cbLine: TColorBox;
    BSymmet: TToolButton;
    BSmooth: TToolButton;
    BCusp: TToolButton;
    tbOther: TToolBar;
    BGroup: TToolButton;
    BClosed: TToolButton;
    Edit1: TMenuItem;
    Undo1: TMenuItem;
    miRotate: TMenuItem;
    DOpen: TOpenDialog;
    DSave: TSaveDialog;
    BImageTool: TToolButton;
    ImagePopupMenu: TPopupMenu;
    miLoadPicture: TMenuItem;
    Duplicate1: TMenuItem;
    BFilled: TToolButton;
    Print1: TMenuItem;
    N2: TMenuItem;
    DPrint: TPrintDialog;
    DOpenPic: TOpenPictureDialog;
    CommonPopupMenu: TPopupMenu;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    Test1: TMenuItem;
    edLineWidth: TEdit;
    UpDown1: TUpDown;
    BLineTool: TToolButton;
    BFreeHandTool: TToolButton;
    BPolyLineTool: TToolButton;
    procedure FormCreate(Sender: TObject);
    procedure BEditToolClick(Sender: TObject);
    procedure BPointToolClick(Sender: TObject);
    procedure BZoomToolClick(Sender: TObject);
    procedure BCreationToolClick(Sender: TObject);
    procedure miRotateClick(Sender: TObject);
    procedure Undo1Click(Sender: TObject);
    procedure Open1Click(Sender: TObject);
    procedure SaveAs1Click(Sender: TObject);
    procedure ChangeOrderClick(Sender: TObject);
    procedure miLoadPictureClick(Sender: TObject);
    procedure Duplicate1Click(Sender: TObject);
    procedure Print1Click(Sender: TObject);
    procedure Test1Click(Sender: TObject);
    procedure BPolyLineToolClick(Sender: TObject);
    procedure BLineToolClick(Sender: TObject);
    procedure BFreeHandToolClick(Sender: TObject);
  private
    FArea: TRNewWorkArea;
    function CreateRectFigure(Layer: TRLayer; const Rect: TRectF): TRFigure;
    function CreateEllipseFigure(Layer: TRLayer; const Rect: TRectF): TRFigure;
    function CreateImageFigure(Layer: TRLayer; const Rect: TRectF): TRFigure;
    function CreateLineFigure(Layer: TRLayer; const FirstPt, SecondPt: TPointF): TRFigure;

    procedure FreeHandCreateCurve(Layer: TRLayer; var Curve: TRCurve);
    procedure FreeHandInitNewPoint(Layer: TRLayer; Curve: TRCurve; I: Integer);

    procedure PopupHook(Info: TRPopupInfo; PopupMenu: TPopupMenu);
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  //ReportMemoryLeaksOnShutdown := True;
  

  RPopupHookProc := PopupHook;

  MainPanel.Align := alClient;
  BEditTool.Down := True;

  FArea := TRNewWorkArea.CreateEx(Self, MainPanel);
  FArea.Sheet.CommonPopupMenu := CommonPopupMenu;
  FArea.Layer.Proportional := True;
  FArea.Layer.SaveResMode := True;

  TRNewWorkArea.SetGlobalTool(EditTool);
  SetCurveEditMode(False);

  FArea.AddPropertyMonitor(TColorMonitor.Create(cbFill, cbLine));
  FArea.AddPropertyMonitor(TBezierMonitor.Create(BLine, BCurve, BCusp, BSmooth, BSymmet));
  FArea.AddPropertyMonitor(TClosedMonitor.Create(BClosed, BFilled));
  FArea.AddPropertyMonitor(TGroupMonitor.Create(BGroup, FigurePopupMenu));
  FArea.AddPropertyMonitor(TLineWidthMonitor.Create(edLineWidth));

  RegisterClasses([TMyBezier, TRBezierController, TRGroup, TRScatterGroupController,
    TRArrangeGroup, TRMonolithGroupController,
    TRImage, TRSimpleController, TRSelectionGroupEx,
    TRStraightLineController]);
end;

procedure TMainForm.PopupHook(Info: TRPopupInfo; PopupMenu: TPopupMenu);
var i: Integer;
begin
  for i := 0 to PopupMenu.Items.Count-1 do
  begin
    if PopupMenu.Items[i].Tag <> 0 then
      PopupMenu.Items[i].Visible := (Info.Figure <> nil);
  end;
end;

{------------------------------------------------------------------------------}

procedure TMainForm.BEditToolClick(Sender: TObject);
begin
  FArea.SetGlobalTool(EditTool);
  FArea.Deselect;
  SetCurveEditMode(False);
end;

procedure TMainForm.BPointToolClick(Sender: TObject);
begin
  FArea.SetGlobalTool(EditTool);
  FArea.Deselect;
  SetCurveEditMode(True);
end;

procedure TMainForm.BZoomToolClick(Sender: TObject);
begin
  TRNewWorkArea.SetGlobalTool(ZoomTool);
end;

procedure TMainForm.BCreationToolClick(Sender: TObject);
begin
  FArea.SetGlobalTool(CreationTool);
  SetCurveEditMode(False);

  if Sender = BEllipseTool then
    CreationTool.OnCreate := CreateEllipseFigure
  else if Sender = BRectTool then
    CreationTool.OnCreate := CreateRectFigure
  else if Sender = BImageTool then
    CreationTool.OnCreate := CreateImageFigure
end;

procedure TMainForm.BLineToolClick(Sender: TObject);
begin
  FArea.SetGlobalTool(LineCreationTool);
  LineCreationTool.OnCreate := CreateLineFigure;
  SetCurveEditMode(False);
end;

procedure TMainForm.BPolyLineToolClick(Sender: TObject);
begin
  FArea.SetGlobalTool(FreeHandTool);
  FreeHandTool.Mode := fhmPoint;
  FreeHandTool.OnInitNewPoint := FreeHandInitNewPoint;
  FreeHandTool.OnCreate := FreeHandCreateCurve;
  SetCurveEditMode(False);
end;

procedure TMainForm.BFreeHandToolClick(Sender: TObject);
begin
  FArea.SetGlobalTool(FreeHandTool);
  FreeHandTool.Mode := fhmContinuous;
  FreeHandTool.OnInitNewPoint := FreeHandInitNewPoint;
  FreeHandTool.OnCreate := FreeHandCreateCurve;
  SetCurveEditMode(False);
end;

{------------------------------------------------------------------------------}

procedure TMainForm.FreeHandCreateCurve(Layer: TRLayer; var Curve: TRCurve);
begin
  Curve := TMyBezier.CreateEx(0);
  Curve.Controller := TRBezierController.Create;

  Curve.Filled := False;
  Curve.Style := Curve.Style + [fsClipped];

  (Layer as TRAdvancedLayer).Root.Add(Curve);

  Curve.PopupMenu := FigurePopupMenu;
end;

procedure TMainForm.FreeHandInitNewPoint(Layer: TRLayer; Curve: TRCurve; I: Integer);
begin
  (Curve as TRBezier).NodeType[i] := ntCusp;
  (Curve as TRBezier).SegmentType[i] := stLine;
end;

function TMainForm.CreateEllipseFigure(Layer: TRLayer; const Rect: TRectF): TRFigure;
begin
  Result := CreateEllipse(Rect);
  (Layer as TRAdvancedLayer).Root.Add(Result);
  (Result as TRCurve).Filled := True;
  Result.PopupMenu := FigurePopupMenu;
  Result.Style := Result.Style + [fsClipped];// - [fsDeleteable];
end;

function TMainForm.CreateRectFigure(Layer: TRLayer; const Rect: TRectF): TRFigure;
begin
  Result := CreateRectangle(Rect);
  (Layer as TRAdvancedLayer).Root.Add(Result);
  (Result as TRCurve).Filled := True;

  Result.PopupMenu := FigurePopupMenu;
end;

function TMainForm.CreateImageFigure(Layer: TRLayer; const Rect: TRectF): TRFigure;
begin
  Result := TRImage.Create;
  Result.Controller := TRSimpleController.Create;
  TRFigureHelper(Result).PlaceInRect(Rect);
  (Layer as TRAdvancedLayer).Root.Add(Result);

  Result.PopupMenu := ImagePopupMenu;
end;

function TMainForm.CreateLineFigure(Layer: TRLayer; const FirstPt, SecondPt: TPointF): TRFigure;
begin
  Result := CreateStraightLine(FirstPt, SecondPt);
  Result.Style := Result.Style + [fsClipped];
  (Layer as TRAdvancedLayer).Root.Add(Result);

  Result.PopupMenu := FigurePopupMenu;
end;
{------------------------------------------------------------------------------}

procedure TMainForm.miRotateClick(Sender: TObject);
var info: TRPopupInfo;
    data: TTransformData;
begin
  info := GetPopupInfo(Sender);
  if Assigned(info.Figure)then
  begin
    info.Sheet.BeginDeal;
    try
      data.Operation := opRotate;
      data.Center := RectCenterF( TRFigureHelper(info.Figure).ContainingRect );
      data.Angle := Pi/8;

      UndoStack(info.Sheet).Push(
        GetUndoPoint(info.Figure, info.Sheet, nil, [daGeometry])
      );

      TRFigureHelper(info.Figure).Transform(Data);

      info.Sheet.ReadjustSelection := True;
      info.Sheet.Redraw := True;
    finally
      info.Sheet.EndDeal;
    end;
  end;
end;

procedure TMainForm.Undo1Click(Sender: TObject);
begin
  FArea.Undo;
end;

procedure TMainForm.Open1Click(Sender: TObject);
var stm: TStream;
begin
  if DOpen.Execute then
  begin
    stm := TFileStream.Create(DOpen.FileName, fmOpenRead or fmShareDenyWrite);
    try
      FArea.Sheet.LockHandleMouse;
      FArea.Deselect;
      UndoStack(FArea.Sheet).Clear;

      //FArea.Layer.Root.Controller.Free;
      //FArea.Layer.Root.Controller := nil;
      TRFigureHelper(FArea.Layer.Root).Deserialize(stm);
      FArea.Deselect;
    finally
      stm.Free;
    end;
  end;
end;

procedure TMainForm.SaveAs1Click(Sender: TObject);
var stm: TStream;
begin
  if DSave.Execute then
  begin
    FArea.Sheet.LockHandleMouse;
    stm := TFileStream.Create(DSave.FileName, fmCreate or fmShareDenyWrite);
    try
      TRFigureHelper(FArea.Layer.Root).Serialize(stm);
    finally
      stm.Free;
    end;
  end;
end;

procedure TMainForm.ChangeOrderClick(Sender: TObject);
var info: TRPopupInfo;
    op: TOrderOperation;
begin
  case (Sender as TComponent).Tag of
     2: op := opBringToFront;
     1: op := opForwardOne;
     0: op := opChangeless;
    -1: op := opBackOne;
    -2: op := opSendToBack;
    else op := opChangeless;
  end;

  info := GetPopupInfo(Sender);
  if Assigned(info.Figure)and(info.Figure.Master is TRGroup) then
  begin
    info.Sheet.BeginDeal;
    (info.Figure.Master as TRGroup).UndoablyChangeOrder(info.Layer, info.Figure, op);
    info.Sheet.EndDeal;
  end;
end;

procedure TMainForm.miLoadPictureClick(Sender: TObject);
var info: TRPopupInfo;
begin
  info := GetPopupInfo(Sender);
  if Assigned(info.Figure)and(info.Figure is TRImage) then
  begin
    if DOpenPic.Execute then
    begin
      info.Sheet.LockHandleMouse;
      (info.Figure as TRImage).UndoablyLoadFromFile(info.Sheet, DOpenPic.FileName);
    end;
  end;
end;

procedure TMainForm.Duplicate1Click(Sender: TObject);
begin
  UndoablyDuplicateSelection(PointF(20, 20));
end;

procedure TMainForm.Print1Click(Sender: TObject);
var R: TRect;
begin
  if DPrint.Execute then
  begin
    R := Rect(0, 0, Printer.PageWidth, Printer.PageHeight);
    InflateRect(R, -400, -400);
    FArea.PrintContent(R);
  end;
end;

procedure TMainForm.Test1Click(Sender: TObject);
begin
  ShowMessage('Test');
end;

end.
