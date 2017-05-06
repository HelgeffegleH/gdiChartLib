#Include gdipChart.ahk

SetBatchLines,-1

GUI,New
GUI +hwndGUI1
GUI,Show, w600 h400

chart1 := new gdipChart( GUI1, "", [ 0, 0, 255, 255 ] )
data := []
Loop 255
{
	Random,y,0,255
	data.Push( [ A_Index, y ] )
}
stream := chart1.addDataStream( data, 0xFF00FF00 )
stream.setVisible()
chart1.setVisible()
return

GUIClose:
ExitApp