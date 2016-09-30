unit uScreenPosition;

interface

uses Windows, Forms, Graphics, SysUtils;
type TScreenInfo = record
  MonitorNum: Integer;
  MonitorIndex : Integer;
  Rect: TRect;
end;

type TListTrect = array of TScreenInfo;
type TScreenListInfo = record
  List: TListTrect;
  MaxRect: TRect;
  MonitorCount: Integer;
end;

type TScreenPosition = class(TObject)
  private
  public
//    constructor Create(ScreenData: TScreen);
    function GetAllRects() : TScreenListInfo;
    function GetAllClientsRect(masterClientRect : TRect) : TScreenListInfo;
    procedure DrawMonitors(Canvas: TCanvas);
    function getScreenCount(): Integer;
end;

implementation

uses Types;

{ TScreenPosition }

procedure TScreenPosition.DrawMonitors(Canvas: TCanvas);
var
 i: integer;
 res : TScreenListInfo;
 str : String;
 tw, th : Integer;
 tmpRect : TRect;
begin
  Canvas.Brush.Color := clBlack;
  Canvas.Rectangle(Canvas.ClipRect);
  res := GetAllClientsRect(canvas.ClipRect);

  for i := 0 to Res.MonitorCount - 1 do
  begin
    Canvas.Pen.Color := $cccccc;
    Canvas.Pen.Width := 3;
    Canvas.Brush.Color := RGB(4, 158, 209);

//    str := IntToStr(Res.List[i].MonitorNum);
    str := IntToStr(Res.List[i].MonitorIndex);
    tmpRect := Res.List[i].Rect;
    Canvas.Rectangle(tmpRect);
    th := Canvas.TextHeight(str);
    tw := Canvas.TextWidth(str);

    canvas.Font.Color := clWhite;
    canvas.Font.Style := [fsBold]; 
    canvas.Font.Size := 20;
    canvas.TextOut(
      Round(tmpRect.Left + ((tmpRect.Right - tmpRect.Left) / 2) - (tw / 2)),
      Round(tmpRect.Top + ((tmpRect.Bottom - tmpRect.Top) / 2) - (th / 2)),
      str
    );
  end;
end;

function TScreenPosition.GetAllClientsRect(masterClientRect : TRect): TScreenListInfo;
var
  originalPosition : TScreenListInfo;
  totalWidth, totalHeight : Integer;
  clientWidth, clientHeight : Integer;
  i : Integer;
  tmpRect, orgRect : Trect;
  scaleX, scaleY : Real;
begin
  originalPosition := GetAllRects();
  Result.MonitorCount := originalPosition.MonitorCount;
  SetLength(Result.List, originalPosition.MonitorCount);

  totalWidth := originalPosition.MaxRect.Right - originalPosition.MaxRect.Left;
  totalHeight := originalPosition.MaxRect.Bottom - originalPosition.MaxRect.Top;
  clientWidth := masterClientRect.Right - masterClientRect.Left;
  clientHeight := masterClientRect.Bottom - masterClientRect.Top;

  scaleX := clientWidth / totalWidth;
  scaleY := clientHeight / totalHeight;

  for i := 0 to Result.MonitorCount - 1 do
  begin
    orgRect := originalPosition.List[i].Rect;
    tmpRect.Left := Round((orgRect.Left - originalPosition.MaxRect.Left) * scaleX);
    tmpRect.Right := Round((orgRect.Right - originalPosition.MaxRect.Left) * scaleX);
    tmpRect.Top := Round((orgRect.Top - originalPosition.MaxRect.Top) * scaleY);
    tmpRect.Bottom := Round((orgRect.Bottom - originalPosition.MaxRect.Top) * scaleY);
    Result.List[i].Rect := tmpRect;
    Result.List[i].MonitorNum := originalPosition.List[i].MonitorNum;
    Result.List[i].MonitorIndex := originalPosition.List[i].MonitorIndex;
  end;

end;

function TScreenPosition.GetAllRects: TScreenListInfo;
var
  i : integer;
begin
  Result.MonitorCount := Screen.MonitorCount;
  SetLength(Result.List, Screen.MonitorCount);
  for i := 0 to Screen.MonitorCount - 1 do
  begin
    if i = 0 then
    begin
      Result.MaxRect := Screen.Monitors[i].BoundsRect;
    end;
    Result.List[i].Rect := Screen.Monitors[i].BoundsRect;
    Result.List[i].MonitorNum := Screen.Monitors[i].MonitorNum;
    Result.List[i].MonitorIndex := i;
    if Result.MaxRect.Left > Screen.Monitors[i].BoundsRect.Left then
      Result.MaxRect.Left := Screen.Monitors[i].BoundsRect.Left;
    if Result.MaxRect.Top > Screen.Monitors[i].BoundsRect.Top then
      Result.MaxRect.Top := Screen.Monitors[i].BoundsRect.Top;
    if Result.MaxRect.Right < Screen.Monitors[i].BoundsRect.Right then
      Result.MaxRect.Right := Screen.Monitors[i].BoundsRect.Right;
    if Result.MaxRect.Bottom < Screen.Monitors[i].BoundsRect.Bottom then
      Result.MaxRect.Bottom := Screen.Monitors[i].BoundsRect.Bottom;
  end;

end;

function TScreenPosition.getScreenCount: Integer;
begin
  Result := Screen.MonitorCount;
end;

end.
