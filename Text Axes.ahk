#Include %A_LineFile%/../gdipChart.ahk

SetBatchLines,-1

GUI,New
GUI +hwndGUI1
chart1 := new gdipChart( GUI1, "", [ -127, -127, 255, 255 ] )

stream := chart1.addDataStream( createRandomData( 335, -127, 127, 20, -167 ), 0xFF00FF00 )

stream.setVisible()
chart1.getAxes().setAttached( 1 ) 
chart1.getAxes().setColor( 0xFFFF0000 )
chart1.setVisible()
Start := A_TickCount
SetTimer,Rotate,15
GoSub,Rotate
GUI,Show, w600 h600
return

Rotate:
frame := ( A_TickCount - Start ) / 300
chart1.setFieldRect( [ -127 + sin( frame ) * 40 , -127 + cos( frame ) * 40, 255, 255 ] )
return

GUIClose:
ExitApp


createRandomData( fields := 255 ,min := 0 ,max := 255 ,variance := 5, startField := 1 )
{
	data := []
	Random,y,% min,% max
	Loop % fields
	{
		Random,y,% ( y - variance < min ) ? min : y - variance  ,% ( y + variance > max ) ? max : y + variance
		data[ A_Index - 1 ] := [ startField + A_Index, y ]
	}
	return data
}