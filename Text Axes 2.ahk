#Include %A_LineFile%/../gdipChart.ahk

SetBatchLines,-1
CoordMode,Mouse,Client

GUI,New
GUI +hwndGUI1
chart1 := new gdipChart( GUI1, "", [ 0, 0, 255, 255 ] )

stream := chart1.addDataStream( createRandomData(), 0xFF00FF00 )

stream.setVisible()
chart1.setVisible()
Start := A_TickCount
SetTimer,Move,15
GoSub,Move
GUI,Show, w600 h400
return

Move:
MouseGetPos, x, y, hWND
frameRegion := chart1.getFrameRegion()
if ( hWND + 0 = GUI1 + 0 && x > frameRegion.region.1 && x < frameRegion.region.1 + frameRegion.region.3 && y > frameRegion.region.2 && y < frameRegion.region.2 + frameRegion.region.4 ) 
{
	;When the mouse is 
	trans := frameRegion.translateFixed
	chart1.setFreezeRedraw( 1 )
	chart1.getAxes().setVisible()
	chart1.getAxes().setOrigin( [ ( x - trans.1 ) / trans.3 , ( y - trans.2 ) / trans.4  ] )
	chart1.setFreezeRedraw( 0 )
}
else
	chart1.getAxes().setVisible( 0 )
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