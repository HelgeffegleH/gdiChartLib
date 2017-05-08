#Include classGDIp.ahk

/*
A rewrite of Nighs gdiChart.ahk
Thanks for gdiCharts awesome code.
	
*/

class gdipChart
{
	
	__New( hWND, controlRect := "", fieldRect := "", type := "line" )
	{
		This.API := new GDIp()
		This.allData     := []
		This.visibleData := []
		This.sethWND( hWND )
		if controlRect
			This.setControlRect( controlRect )
		This.setFieldRect( isObject( fieldRect ) ? fieldRect : [ 0, 0, 1, 1 ] )
		This.setType( type )
		This.setBackgroundColor( 0xFFFFFFFF )
		This.setMargin( [ 20, 20, 20, 20 ] )
	}
	
	__Delete()
	{
		This.setVisible( false )
		This.base := ""
	}
	
	
	setType( type := "line" )
	{
		if ( This.type!= type )
		{
			This.type := type
			This.touch()
		}
	}
	
	getType()
	{
		return This.type
	}
	
	
	setBackgroundColor( color )
	{
		if ( This.color != color )
		{
			This.color := color
			This.touch()
		}
	}
	
	getBackgroundColor()
	{
		return This.color
	}
	
	
	setVisible( bVisible := true )
	{
		bVisible := !!bVisible 
		if ( This.getVisible() ^ bVisible )
		{
			This.visible := bVisible
			This.sendRedraw()
		}
	}
	
	getVisible()
	{
		return This.hasKey( "visible" ) && This.visible
	}
	
	
	setFieldRect( rect )
	{
		This.fieldRect := rect
		This.touch()
	}
	
	getFieldRect()
	{
		return This.fieldRect.clone()
	}
	
	
	setControlRect( rect := "" )
	{
		if rect
			This.controlRect := rect
		This.touch()
	}
	
	getControlRect()
	{
		static rectI := "", init := VarSetCapacity( rectI, 16, 1 )
		if This.hasKey( "controlRect" )
			return This.controlRect.clone()
		DllCall( "GetClientRect", "UPtr", This.getHWND(), "UPtr", &rectI )
		outRect := []
		Loop 4
			outRect.Push( numGet( rectI, A_Index * 4 - 4, "UInt" ) )
		return outRect
	}
	
	
	getMultiplier()
	{
		targetRect := This.getControlRect()
		marginRect := This.getMargin()
		;Get Margin and the position on the GUI
		targetFieldRect := [ targetRect.1 + marginRect.1, targetRect.2 + marginRect.2, targetRect.3 - marginRect.1 - marginRect.3, targetRect.4 - marginRect.2 - marginRect.4 ]
		;Then combine them
		sourceRect := This.getFieldRect()
		;Get the position of the Field ( basically the part of the data the Chart is displaying )
		translateRect := [ 0, 0, targetFieldRect.3 / sourceRect.3, -targetFieldRect.4 / sourceRect.4 ]
		translateRect.1 := targetFieldRect.1 - sourceRect.1 * translateRect.3
		translateRect.2 := targetFieldRect.2 - ( sourceRect.2 + sourceRect.4 ) * translateRect.4
		return { translate: translateRect, region: targetFieldRect }
	}
	
	
	setHWND( hWND )
	{
		if  ( This.hWND && same := hWND != This.hWND )
			This.unregisterRedraw(), This.sendRedraw()
		This.hWND := hWND
		if !same
			This.registerRedraw(),This.touch()
	}
	
	getHWND()
	{
		return This.hWND
	}
	
	getWindowHWND()
	{
		return DllCall( "GetAncestor", "UPtr", This.hWND, "UInt", 3 )
	}
	
	
	setMargin( margin )
	{
		This.margin := margin
		This.touch()
	}
	
	getMargin()
	{
		return This.margin
	}
	
	
	setNameVisibility( bVisible )
	{
		bVisible := !!bVisible
		if ( bVisible ^ This.nameVisible )
		{
			This.nameVisible := bVisible
			This.touch()
		}
	}
	
	getNameVisibility()
	{
		return This.hasKey( "nameVisible" ) && This.nameVisible
	}
	
	
	touch()
	{
		This.hasChanged := 1
		if This.getVisible()
			This.sendRedraw()
	}
	
	sendRedraw()
	{
		SendMessage,0xF,0,0,,% "ahk_id " . This.getWindowHWND() 
	}
	
	
	draw()
	{
		if This.getVisible()
		{
			if This.hasChanged
			{
				This.hasChanged := 0
				This.prepareBuffers()
				This.drawBackGround()
				This.drawGrid()
				This.drawData()
				This.drawAxis()
			}
			This.flushToGUI()
		}
	}
	
	prepareBuffers()
	{
		size := This.getControlRect()
		size.removeAt( 1, 2 )
		This.bitmap := new GDIp.Bitmap( size )
		This.bitmap.getGraphics().setInterpolationMode( 7 )
		This.bitmap.getGraphics().setSmoothingMode( 4 )
	}
	
	drawBackGround()
	{
		This.bitmap.getGraphics().clear( This.getBackgroundColor() )
	}
	
	drawData()
	{
		graphics     := This.bitmap.getGraphics()
		pen          := new GDIp.Pen( 0xFF000000, 1 )
		brush        := new Gdip.SolidBrush( 0xFF000000 )
		frameRegion  := This.getMultiplier()
		translate    := frameRegion.translate
		fieldRect    := frameRegion.region
		graphics.setClipRect( This.bitmap.getRegion() )
		graphics.setClipRect( fieldRect, 3 )
		For each, visibleDataStream in This.visibleData
		{
			streamColor := visibleDataStream.getColor()
			pen.setColor( streamColor )
			brush.setColor( streamColor )
			data := visibleDataStream.getData()
			lastPoint      := ""
			lastPointDrawn := ""
			For each, point in data
			{
				thisPoint := [ point.1 * translate.3 + translate.1, point.2 * translate.4 + translate.2 ]
 				if ( isObject( lastpoint ) && ( thispoint.1 >= fieldRect.1 ) && ( thispoint.1 <= fieldRect.1 + fieldRect.3 ) )
					graphics.drawLine( pen, [ lastpoint, thispoint ] ), lastPointDrawn := 1
				else if ( lastPointDrawn )
				{
					graphics.drawLine( pen, [ lastpoint, thispoint ] )
					break, 1
				}
 				lastPoint := thispoint
			}
		}
		graphics.resetClip()
	}
	
	drawAxis()
	{
		graphics  := This.bitmap.getGraphics()
		pen       := new GDIp.pen( 0xFF000000, 2 )
		
		fieldRect := This.getMultiplier().region
		origin    := [ fieldRect.1, fieldRect.2 + fieldRect.4 ]
		xTarget   := [ origin.1 + fieldRect.3, origin.2 ]
		yTarget   := [ origin.1, origin.2 - fieldRect.4 ]
		
		graphics.drawLine( pen, [ origin, xTarget ] )
		
		graphics.drawLine( pen, [ [ xTarget.1 - 15, xTarget.2 - 2 ], [ xTarget.1 - 5, xTarget.2 ] ] )
		graphics.drawLine( pen, [ [ xTarget.1 - 15, xTarget.2 + 2 ], [ xTarget.1 - 5, xTarget.2 ] ] )
		;Arrows
		
		graphics.drawLine( pen, [ origin, yTarget ] )
		graphics.drawLine( pen, [ [ yTarget.1 - 2, yTarget.2 + 15 ], [ yTarget.1, yTarget.2 + 5 ] ] )
		graphics.drawLine( pen, [ [ yTarget.1 + 2, yTarget.2 + 15 ], [ yTarget.1, yTarget.2 + 5 ] ] )
		
		/*
			Thanks to Nigh for these Awesome Arrows
		*/
	}
	
	flushToGUI()
	{
		targetDC := new GDI.DC( This.gethWND() )
		graphics := targetDC.getGraphics()
		graphics.drawBitmap( This.bitmap, This.getControlRect(), This.bitmap.getRect() )
	}
	
	
	registerRedraw()
	{
		hWND := This.getWindowhWND()
		if !( gdipChart.hasKey( "windows" ) )
		{
			OnMessage( 0xF, gdipChart.WM_PAINT )
			gdipChart.windows := { ( hWND ): { &This: new indirectReference( This ) } }
		}
		else if !gdipChart.windows.hasKey( hWND )
			gdipChart.windows[ hWND ] := { ( &This ): new indirectReference( This ) }
		else
			gdipChart.windows[ hWND, &This ] := new indirectReference( This )
	}
	
	unregisterRedraw()
	{
		hWND := This.getWindowhWND()
		gdipChar.windows[ hWND ].Delete( &This )
		if !gdipChar.windows[ hWND ]._NewEnum().Next( key, value )
			gdipChar.windows.Delete( hWND )
		else if !gdipChar.windows._NewEnum().Next( key, value )
		{
			gdipChar.Delete( "windows" )
			OnMessage( 0xF, gdipChart.WM_PAINT, 0 )
		}
	}
	
	WM_PAINT( lParam, msg, hWND )
	{
		arr := gdipChart.windows[ hWND + 0 ]
		for each, obj in arr
			obj.draw()
	}
	
	
	addDataStream( data := "", color:="", name := "" )
	{
		dataStream := new This.DataStream( This, data, color, name )
		This.allData[ &dataStream ] := new indirectReference( dataStream )
		return dataStream
	}
	
	removeDataStream( dataStream )
	{
		This.allData.Delete( &dataStream )
	}
	
	class DataStream
	{
		
		__New( parent, data := "", color := 0xFF000000, name := "" )
		{
			This.parent := new indirectReference( parent )
			if data
				This.setData( data )
			This.setColor( color )
			if name
				This.setName( name )
		}
		
		__Delete()
		{
			This.setVisible( false )
			This.parent.removeDataStream( This )
			This.base := ""
		}
		
		
		setVisible( bVisible := true )
		{
			bVisible := !!bVisible 
			if ( This.getVisible() ^ bVisible )
			{
				This.visible := bVisible
				if This.visible
					This.parent.addVisibleData( This )
				else
					This.parent.removeVisibleData( This )
			}
		}
		
		getVisible()
		{
			return This.hasKey( "visible" ) && This.visible
		}
		
		
		setColor( color )
		{
			if ( This.color != color )
			{
				This.color := color
				This.touch()
			}
		}
		
		getColor()
		{
			return This.color
		}
		
		
		setName( name )
		{
			if ( This.name != name )
			{
				This.name := name
				if This.parent.getNameVisible()
					This.touch()
			}
		}
		
		getName()
		{
			return This.name
		}
		
		
		setData( data := "" )
		{
			If ( data )
				This.data := data
			If This.hasKey( "data" )
				This.touch()
		}
		
		getData()
		{
			return This.data
		}
		
		
		touch()
		{
			if This.getVisible()
				This.parent.touch()
		}
		
	}
	
	addVisibleData( dataStream )
	{
		This.visibleData[ &dataStream ] := new indirectReference( dataStream )
	}
	
	removeVisibleData( dataStream )
	{
		This.visibleData.Delete( &dataStream )
	}
	
}