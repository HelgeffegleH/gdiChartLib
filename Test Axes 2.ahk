#Include %A_LineFile%/../gdipChart.ahk

SetBatchLines,-1
CoordMode,Mouse,Client

GUI,New
GUI +hwndGUI1
chart1 := new gdipChart( GUI1, "", [ 0, 0, 256, 256 ] )

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


createRandomData( x := 0, y := 0, w := 256, h := 256, variance := 5, steps := 1 )
{
	data := []
	dSteps := 1 / steps
	x *= dSteps
	y *= dSteps
	w *= dSteps
	h *= dSteps
	variance *= dSteps
	Random,val,% y,% y + h
	Loop % ( w-x )
	{
		Random,val,% ( val - variance < y ) ? y : val - variance  ,% ( val + variance > ( y + h ) ) ? ( y + h ) : val + variance
		data[ A_Index ] := [ ( x + A_Index - 1 ) * steps, val * steps ]
	}
	return data
}