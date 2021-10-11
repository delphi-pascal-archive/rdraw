unit StrFunc;

interface

function StrBetween(const str, strFrom, strTill: string;
  strictFrom: Boolean = True; strictTill: Boolean = True): string;

function NextDelimPos(Delim: Char; const S: string; startsFrom: Integer): Integer;
function GetTokenCount(const S: string; Delimiter: Char): Integer;
function GetTokenNo(const S: string;  Delimiter: Char; Number: Integer): string;

function StrInBraces(const S: string; LeftBr, RightBr: Char): string;

type
  TSubStrPos = record
    Start: Integer;
    Length: Integer;
  end;

function GetWordNo(const S: string; Number: Integer): string;
function GetWordCount(const S: string): Integer;
function NextSpacePos(Space: Char; const S: string; startsFrom: Integer): TSubStrPos;

function GetAttrPos(const S, Attr: string): TSubStrPos;
function GetAttrValue(const S, Attr: string): string;
function SetAttrValue(const S, Attr, Value: string; Add: Boolean = False; const Delim: string = ''): string;

function BoolToInt(ABool: Boolean): Integer;
function StrToBool(const AStr: string): Boolean;

implementation

uses
  SysUtils;

function StrBetween(const str, strFrom, strTill: string;
  strictFrom: Boolean = True; strictTill: Boolean = True): string;
var start, fin, toLen, L: Integer;
    s: string;
begin
  Result := '';
  L := Length(str);
  toLen := Length(strFrom);

  start := Pos(strFrom, str);
  if start > 0 then
  begin
    start := start + toLen - 1;
    s := Copy(str, start+1, L-start);
  end
  else if (strFrom = '') or (not strictFrom) then s := str
  else Exit;

  if strTill = '' then fin := Length(s)+1
                  else fin := Pos(strTill, s);

  if (fin = 0) and (not strictTill) then fin := Length(s)+1;
  if (fin > 0) then Result := Copy(s, 1, fin-1);
end;

{------------------------------------------------------------------------------}
function NextDelimPos(Delim: Char; const S: string; startsFrom: Integer): Integer;
var i: Integer;
begin
  Result := Length(S)+1;
  if startsFrom > Length(S) then Result := -1;
  for i := startsFrom to Length(S) do
    if S[i] = Delim then begin Result := i; Break; end;
end;

function GetTokenCount(const S: string; Delimiter: Char): Integer;  // 0-based
var startPos{, finPos}: Integer;
begin
  startPos := 0;
  Result := -1;
  repeat
    startPos := NextDelimPos(Delimiter, S, startPos+1);
    Inc(Result);
  until startPos = -1;
end;

function GetTokenNo(const S: string; Delimiter: Char; Number: Integer): string;
var i, startPos, finPos: Integer;
begin
  startPos := 0;
  for i := 1 to Number do
    startPos := NextDelimPos(Delimiter, S, startPos+1);
  finPos := NextDelimPos(Delimiter, S, startPos+1);
  Result := Copy(S, startPos+1, finPos-startPos-1);
end;

{------------------------------------------------------------------------------}

function GetWordNo(const S: string; Number: Integer): string;
var i: Integer;
    startPos, finPos: TSubStrPos;
    S1: string;
begin
  S1 := Trim(S);
  if S1 = '' then begin Result := ''; Exit; end;

  startPos.Start := 0;
  startPos.Length := 1;
  for i := 1 to Number do
    startPos := NextSpacePos(' ', S1, startPos.Start+startPos.Length);

  finPos := NextSpacePos(' ', S1, startPos.Start + startPos.Length);
  Result := Copy(S1, startPos.Start + startPos.Length, finPos.Start-startPos.Start-startPos.Length);
end;

function GetWordCount(const S: string): Integer;
var i: Integer;
    startPos: TSubStrPos;
    S1: string;
begin
  S1 := Trim(S);
  if S1 = '' then begin Result := 0; Exit; end;

  startPos.Start := 0;
  startPos.Length := 1;

  i := 1;
  repeat
    startPos := NextSpacePos(' ', S1, startPos.Start+startPos.Length);
    if startPos.Length < 1 then
    begin
      Result := i; 
      Exit;
    end else
      Inc(i);
  until False;
end;

function NextSpacePos(Space: Char; const S: string; startsFrom: Integer): TSubStrPos;
var i: Integer;
begin
  if startsFrom > Length(S)
    then begin Result.Start := -1; Result.Length := -1; end
    else begin Result.Start := Length(S)+1; Result.Length := 0; end;

  for i := startsFrom to Length(S) do
    if S[i] = Space then begin Result.Start := i; Break; end;

  for i := i to Length(S) do
    if S[i] <> Space then begin Result.Length := i - Result.Start; Break; end;
end;
{------------------------------------------------------------------------------}

function StrInBraces(const S: string; LeftBr, RightBr: Char): string;
var i, j: Integer;
begin
  i := 1;
  j := Length(S);
  while (i < j) and(S[i]<>LeftBr ) do Inc(i);
  while (j >= i)and(S[j]<>RightBr) do Dec(j);
  Result := Copy(S, i+1, j-i-1);
end;

function GetAttrValue(const S, Attr: string): string;
var pos: TSubStrPos;
begin
  pos := GetAttrPos(S, Attr);
  Result := Copy(S, pos.Start, pos.Length);
end;

function SetAttrValue(const S, Attr, Value: string; Add: Boolean = False; const Delim: string = ''): string;
var pos: TSubStrPos;
begin
  pos := GetAttrPos(S, Attr);
  if pos.Length > -1 then
    Result := Copy(S, 1, pos.Start-1) + Value +
      Copy(S, pos.Start + pos.Length, Length(S) - pos.Start - pos.Length + 1)
  else
  begin
    if Add then
      Result := S + Delim + ' ' + Attr + '="' + Value + '"'
    else
      Result := S;
  end;
end;

function GetAttrPos(const S, Attr: string): TSubStrPos;
type
  TParseStatus = record
    inToken: Boolean;
    inQuot: Boolean;
    attrFound: Boolean;
    valueFound: Boolean;

    start: Integer;
    fin: Integer;
  end;

var
  status: TParseStatus;
  currAttr: string[255];
  i: Integer;

begin
  Result.Start := 1;
  Result.Length := -1;

  status.inQuot := False;
  status.inToken := False;
  status.attrFound := False;
  status.valueFound := False;
  status.start := 0;
  status.fin := -1;

  for i := 1 to Length(S) do
  begin
    //--------------
    if S[i] = '"' then
    begin
      status.inQuot := not status.inQuot;

      if status.attrFound then
      begin
        if status.inQuot then
        begin
          status.start := i+1;
        end
        else
        begin
          status.fin := i-1;
          status.valueFound := True;
          Result.Start := status.start;
          Result.Length := status.fin - status.start + 1;
          Break;
        end;
      end;
      Continue;
    end;
    //--------------
    if status.inQuot then Continue;
    //--------------
    if S[i] in [' ', ',', ';', '='] then
    begin
      if status.inToken then
      begin
        status.fin := i-1;
        currAttr := Copy(S, status.start, status.fin-status.start+1);
        if CompareText(currAttr, Attr) = 0 then
        begin
          status.attrFound := True;
        end;
      end;
      status.inToken := False;
      Continue;
    end else
    //--------------
    //if (S[i] in ['A'..'Z', 'a'..'z', '1'..'0', '.', '@', '$']) then
    begin
      if not status.inToken then
      begin
        status.inToken := True;
        status.start := i;
        if status.attrFound then Break; //raise Exception.Create('not found Value');
      end;
      Continue;
    end;
    //--------------
  end;
end;

function BoolToInt(ABool: Boolean): Integer;
begin
  if ABool then Result := 1 else Result := 0;
end;

function StrToBool(const AStr: string): Boolean;
begin
  Result := (CompareStr(AStr, 'True') = 0)or
            (CompareStr(AStr, 'On'  ) = 0)or
            (CompareStr(AStr, 'Yes' ) = 0);
end;

end.
