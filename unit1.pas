unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, syncobjs, Forms, Controls, Graphics, Dialogs, StdCtrls, LCLIntf, LCLType, LMessages;

const
  LM_STOPTHREAD = LM_USER + $101;

type

  { TActThr }

  TActThr = class(TThread)
  private
    FLabelValue: Integer;
    procedure SetLabelValue;
  protected
    procedure Execute; override;
  public
    constructor Create(CreateSuspended: Boolean);
    destructor Destroy; override;
  end;

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Label1: TLabel;
    Label2: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LmStopThread(var Msg: TLMessage); message LM_STOPTHREAD;
    procedure IdleEventHandler(Sender: TObject; var Done: Boolean);
   private
     FMyThr: TActThr;
   public
  end;

var
  Form1: TForm1;
  MyEvent: TEvent;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
begin
  if not Assigned(FMyThr)
    then
      begin
        FMyThr:= TActThr.Create(False);
        Self.Caption:= 'The thread is created and started...' ;
      end
    else
      Self.Caption:= 'The thread is started...' ;

  if Assigned(MyEvent) then MyEvent.ResetEvent;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  if Assigned(MyEvent) then
  begin
    MyEvent.SetEvent;
    Self.Caption:= 'The thread is stopped...';
  end;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  if Assigned(FMyThr) then
  begin
    FMyThr.Terminate;
    PostMessage(Self.Handle,LM_STOPTHREAD,0,0);
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Label1.Caption:= '...';
  Application.OnIdle:= @IdleEventHandler;
end;

procedure TForm1.LmStopThread(var Msg: TLMessage);
begin
  if Assigned(FMyThr) then FreeAndNil(FMyThr);
  Self.Caption:= 'The thread is destroyed...';
  Label1.Caption:= '...';
end;

procedure TForm1.IdleEventHandler(Sender: TObject; var Done: Boolean);
begin
  Self.Caption:= '123356';
  //Done:= False;
end;

{ TActThr }

procedure TActThr.SetLabelValue;
begin
  Form1.Label1.Caption:= Format('%d',[FLabelValue]);
end;

procedure TActThr.Execute;
begin
  while (FLabelValue < 1000) and not Terminated do
    if MyEvent.WaitFor(20) <> wrSignaled then
    begin
      Queue(@SetLabelValue);
      Inc(FLabelValue);
      if FLabelValue > 999 then FLabelValue:= 0;
    end;
end;

constructor TActThr.Create(CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  FreeOnTerminate:= False;
  Priority:= tpLower;
  FLabelValue:= 0;
  MyEvent:= TEvent.Create(nil,True,False,'MyThrEvent');
end;

destructor TActThr.Destroy;
begin
  if Assigned(MyEvent) then FreeAndNil(MyEvent);
  inherited Destroy;
end;

end.

