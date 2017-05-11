#Include gdipChart.ahk

SetBatchLines,-1

GUI,New
GUI +hwndGUI1

chart1  := new gdipChart( GUI1, "", [ 1, 0, 255, 255 ] )
streams := []
color   := [ 0xFF00FF00, 0xFFFF0000, 0xFF0000FF ]
Loop 3
{
	stream := chart1.addDataStream( createRandomData(), color[ A_Index ] )
	stream.setVisible()
	streams.push( stream )
}
chart1.setVisible()
GUI,Show, w600 h400
chart1.flushToFile( "Screenshot.png" )
return

GUIClose:
ExitApp

createRandomData( fields := 255 ,min := 0 ,max := 255 ,variance := 5 )
{
	data := []
	Random,y,% min,% max
	Loop % fields
	{
		Random,y,% ( y - variance < min ) ? min : y - variance  ,% ( y + variance > max ) ? max : y + variance
		data.Push( [ A_Index, y ] )
	}
	return data
}