#Include gdipChart.ahk

SetBatchLines,-1

GUI,New
GUI +hwndGUI1
GUI,Show, w600 h400

chart1  := new gdipChart( GUI1, "", [ 1, 0, 255, 255 ] )
streams := []
color   := [ 0xFF00FF00, 0xFFFF0000, 0xFF0000FF ]
Loop 3
{
	data := []
	Random,y,0,255
	Loop 255
	{
		Random,y,% ( y - 1 < 0 ) ? 0 : y -5  ,% ( y + 1 > 255 ) ? 255 : y + 5
		data.Push( [ A_Index, y ] )
	}
	stream := chart1.addDataStream( data, color[ A_Index ] )
	stream.setVisible()
	streams.push( stream )
}
chart1.setVisible()
return

GUIClose:
ExitApp