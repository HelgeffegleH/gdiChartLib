#Include gdipChart.ahk

SetBatchLines,-1

GUI,New
GUI +hwndGUI1

chart1 := new gdipChart( GUI1, "", [ 1, 0, 10, 255 ] )
data := []
Loop 255
{
	Random,y,0,255
	data.Push( [ A_Index, y ] )
}
stream := chart1.addDataStream( data, 0xFF00FF00 )
startT := A_TickCount
stream.setVisible()
chart1.setVisible()
GUI,Show, w600 h400
SetTimer,scroll,15
return

GUIClose:
ExitApp

scroll:
chart1.setFieldRect( [ ( A_TickCount - startT ) / 500 + 1,0 ,10, 255 ] )
return