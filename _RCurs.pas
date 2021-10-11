unit _RCurs;

interface

implementation

uses
  Windows, Forms, RCore;

{$R RCurs2.res}
  
initialization

  crMoveObj := 8;
  crZoomIn := 9;
  crMovePoint := 10;
  crZoomOut := 11;

  Screen.Cursors[crMoveObj] := LoadCursor(HInstance, 'MoveObj');
  Screen.Cursors[crZoomIn] := LoadCursor(HInstance, 'ZoomIn');
  Screen.Cursors[crMovePoint] := LoadCursor(HInstance, 'MovePt');
  Screen.Cursors[crZoomOut] := LoadCursor(HInstance, 'ZoomOut');

finalization

end.
