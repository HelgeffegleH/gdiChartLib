#Include %A_LineFile%/../gdipChart.ahk

SetBatchLines,-1

GUI,New
GUI +hwndGUI1

chart1  := new gdipChart( GUI1, "", [ 1, 0, 5, 255 ] )
streams := []
color   := [ 0xFFFF0000, 0xFF00FF00, 0xFF0000FF ]
Loop 3
{
	stream := chart1.addDataStream( createRandomData(1000, 0 , 255, 10), color[ A_Index ] )
	stream.setVisible()
	streams.push( stream )
}

chart1.setVisible()
SetTimer,scrollColor, 15
bColor := []
for each, stream in streams
	bColor.Push( stream.getData()[ 1, 2 ] )
startT := A_TickCount
GUI,Show, w600 h400
return

scrollColor:

frameNr :=  ( A_TickCount - startT ) / 200
if ( floor( frameNr ) != lastFrameNr )
{
	lastFrameNr := floor( frameNr )
	lastColor := bColor
	bColor  := []
	for each, stream in streams
		bColor.Push( stream.getData()[ ceil( frameNr ), 2 ] )
}
inFramePosition := frameNr - lastFrameNr
ibColor := 255
for each, color in bColor
	ibColor := ( ibColor << 8 ) | Round( bColor[ each ] * inFramePosition + lastColor[ each ] * ( 1 - inFramePosition ) )
;^Interpolates color

chart1.freezeRedraw( 1 )
chart1.setFieldRect( [ frameNr, 0, 5, 255 ] )
chart1.setBackgroundColor( ibColor )
chart1.freezeRedraw( 0 )
;^ Move Field and set BackgroundColor
;enable freezeRedraw with freezeRedraw( 1 ) to disable automatic redrawing and freezeRedraw( 0 ) to draw all new changes.
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