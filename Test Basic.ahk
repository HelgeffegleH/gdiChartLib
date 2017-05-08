#Include gdipChart.ahk

SetBatchLines,-1

GUI,New
GUI +hwndGUI1
GUI,Show, w600 h400

chart1 := new gdipChart( GUI1, "", [ 1, 0, 255, 255 ] )

stream := chart1.addDataStream( createRandomData(), 0xFF00FF00 )

stream.setVisible()
chart1.setVisible()
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