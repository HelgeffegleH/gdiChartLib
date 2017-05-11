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
		This.axes        := new This.Axes( This )
		This.grid        := new This.Grid( This )
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
	
	isControlRectRelative()
	{
		return !This.hasKey( "controlRect" )
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
		if ( This.getVisible() && !This.getFreezeRedraw() )
			This.sendRedraw()
	}
	
	sendRedraw()
	{
		SendMessage,0xF,0,0,,% "ahk_id " . This.getWindowHWND() 
	}
	
	
	setFreezeRedraw( bFreeze )
	{
		bFreeze := !!bFreeze
		if ( This.getFreeze() && !bFreeze && This.hasChanged )
			This.freeze := bFreeze, This.touch
		else
			This.freeze
	}
	
	getFreezeRedraw()
	{
		return This.freeze
	}
	
	
	updateFrameRegion()
	{
		targetRect := This.getControlRect()
		marginRect := This.getMargin()
		;Get Margin and the position on the GUI
		targetFieldRect := [ targetRect.1 + marginRect.1, targetRect.2 + marginRect.2, targetRect.3 - marginRect.1 - marginRect.3, targetRect.4 - marginRect.2 - marginRect.4 ]
		;Then combine them
		sourceRect := This.getFieldRect()
		;Get the position of the Field ( basically the part of the data the Chart is displaying )
		translateRect    := [ 0, 0, targetFieldRect.3 / sourceRect.3, -targetFieldRect.4 / sourceRect.4 ]
		translateRect.1  := targetFieldRect.1 - sourceRect.1 * translateRect.3
		translateRect.2  := targetFieldRect.2 - ( sourceRect.2 + sourceRect.4 ) * translateRect.4
		
		translateRectFixed   := translateRect.Clone()
		translateRectFixed.1 := targetFieldRect.1
		translateRectFixed.2 := targetFieldRect.2 - sourceRect.4 * translateRect.4
		This.frameRegion := { translate: translateRect, region: targetFieldRect, translateFixed: translateRectFixed }
	}
	
	getFrameRegion()
	{
		return This.frameRegion
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
				This.drawAxes()
			}
			This.flushToGUI()
		}
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
	
	getAxes()
	{
		return This.axes
	}
	
	class Axes
	{
		
		__New( parent )
		{
			This.setColor( 0xFF000000 )
			This.setOrigin( [ 0, 0 ] )
			This.parent := parent
			This.setVisible()
		}
		
		setVisible( bVisible := true )
		{
			bVisible := !!bVisible 
			if ( This.getVisible() ^ bVisible )
			{
				This.visible := bVisible
				This.parent.touch()
			}
		}
		
		getVisible()
		{
			return This.hasKey( "visible" ) && This.visible
		}
		
		setColor( color )
		{
			if ( color != This.color )
			{
				This.color := color
				This.touch()
			}
		}
		
		getColor()
		{
			return This.color
		}
		
		/*
			origin: A point ( an array in the form [ x, y ] ) that defines the axes position relative to or on the field.
		*/
		
		setOrigin( origin )
		{
			This.origin := origin
			This.touch()
		}
		
		getOrigin()
		{
			return This.origin
		}
		
		setAttached( bAttached )
		{
			bAttached := !!bAttached
			if ( This.getAttached() ^ bAttached )
			{
				This.attached := bAttached
				This.touch()
			}
		}
		
		getAttached()
		{
			return This.hasKey( "attached" ) && This.attached
		}
		
		touch()
		{
			If This.getVisible()
				This.parent.touch()
		}
		
	}
	
	getGrid()
	{
		return This.grid
	}
	
	class Grid
	{
		
		__New( parent )
		{
			This.parent := parent
			This.setVisible( 0 )
			This.setOrigin( [ 0, 0 ] )
			This.setFieldSize( [ 1, 1 ] )
			This.setFieldsPerView( 10 )
			This.setColor( 0xFF7E7E7E )
			This.setVisible()
			
		}
		
		setVisible( bVisible := true )
		{
			bVisible := !!bVisible 
			if ( This.getVisible() ^ bVisible )
			{
				This.visible := bVisible
				This.parent.touch()
			}
		}
		
		getVisible()
		{
			return This.hasKey( "visible" ) && This.visible
		}
		
		setColor( color )
		{
			if ( color != This.color )
			{
				This.color := color
				This.touch()
			}
		}
		
		getColor()
		{
			return This.color
		}
		
		/*
			origin: type point
		*/
		
		setOrigin( origin )
		{
			This.origin := origin
			This.touch()
		}
		
		getOrigin()
		{
			return This.origin
		}
		
		/*
			size: type Point
		*/
		
		setFieldSize( size )
		{
			This.fieldSize := size
			This.touch()
		}
		
		getFieldSize()
		{
			return This.fieldSize
		}
		
		setFieldsPerView( perView )
		{
			This.fieldsPerView := perView
			This.touch()
		}
		
		getFieldsPerView()
		{
			return This.fieldsPerView
		}
		
		touch()
		{
			If This.getVisible()
				This.parent.touch()
		}
		
	}
	
	
	prepareBuffers()
	{
		size := This.getControlRect()
		size.removeAt( 1, 2 )
		This.bitmap := new GDIp.Bitmap( size )
		This.bitmap.getGraphics().setInterpolationMode( 7 )
		This.bitmap.getGraphics().setSmoothingMode( 4 )
		This.updateFrameRegion()
	}
	
	drawBackGround()
	{
		This.bitmap.getGraphics().clear( This.getBackgroundColor() )
	}
	
	drawGrid()
	{
		grid         := This.getGrid()
		
		
		if !( grid.getVisible() )	
			return
		
		graphics     := This.bitmap.getGraphics()
		pen          := new GDIp.Pen( grid.getColor(), 1 )
		
		fieldSize    := grid.getFieldSize()
		fieldsPerView:= grid.getFieldsPerView()
		origin       := grid.getOrigin()
		fieldRect    := This.getFieldRect()
		
		fieldSize    := [ fieldSize.1 * ( 2 ** Round( log2(  fieldRect.3 / fieldsPerView / fieldSize.1 ) ) ), fieldSize.2 * ( 2 ** Round( log2( fieldRect.4 / fieldsPerView / fieldSize.2  ) ) ) ]
		offset       := [ fieldRect.1 - modulo( origin.1 + fieldRect.1, fieldSize.1 ) , fieldRect.2 - modulo( origin.2 + fieldRect.2, fieldSize.2 ) ]
		
		Loop % ceil( fieldRect.3 / fieldSize.1 )
		{
			pos := offset.1 + fieldSize.1 * A_Index
			graphics.drawLine( pen, This.getInfiniteLine( [ [ pos , 0 ] ,[ pos , 1 ] ] ) )
		}
		
		Loop % ceil( fieldRect.4 / fieldSize.2 )
		{
			pos := offset.2 + fieldSize.2 * A_Index
			graphics.drawLine( pen, This.getInfiniteLine( [ [ 0 , pos ] ,[ 1 , pos ] ] ) )
		}
		
	}
	
	drawData()
	{
		graphics     := This.bitmap.getGraphics()
		pen          := new GDIp.Pen( 0xFF000000, 1 )
		brush        := new Gdip.SolidBrush( 0xFF000000 )
		frameRegion  := This.getFrameRegion()
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
	
	drawAxes()
	{
		axes      := This.getAxes()
		if !axes.getVisible()
			return
		graphics  := This.bitmap.getGraphics()
		pen       := new GDIp.pen( axes.getColor(), 2 )
		frameRegion := This.getFrameRegion()
		
		
		axesOrigin      := axes.getOrigin()
		translate       := axes.getAttached() ? frameRegion.translate : frameRegion.translateFixed
		axesPixelOrigin := [ axesOrigin.1 * translate.3 + translate.1, axesOrigin.2 * translate.4 + translate.2 ]
		
		if ( axesPixelOrigin.1 < frameRegion.region.1 )
			axesDisplace := 1, axesPixelOrigin.1 := frameRegion.region.1
		else if ( axesPixelOrigin.1 > frameRegion.region.1 + frameRegion.region.3 )
			axesDisplace := 3, axesPixelOrigin.1 := frameRegion.region.1 + frameRegion.region.3
		if ( axesPixelOrigin.2 < frameRegion.region.2 )
			axesDisplace := axesDisplace | 4, axesPixelOrigin.2 := frameRegion.region.2
		else if ( axesPixelOrigin.2 > frameRegion.region.2 + frameRegion.region.4 )
			axesDisplace := axesDisplace | 8, axesPixelOrigin.2 := frameRegion.region.2 + frameRegion.region.4
		
		xAxis   := [ [ frameRegion.region.1, axesPixelOrigin.2 ], [ frameRegion.region.1 + frameRegion.region.3, axesPixelOrigin.2 ] ]
		yAxis   := [ [ axesPixelOrigin.1, frameRegion.region.2 ], [ axesPixelOrigin.1, frameRegion.region.2 + frameRegion.region.4 ] ]
		
		graphics.drawLine( pen, xAxis )
		xTarget := xAxis.2
		graphics.drawLine( pen, [ [ xTarget.1 - 15, xTarget.2 - 2 ], [ xTarget.1 - 5, xTarget.2 ] ] )
		graphics.drawLine( pen, [ [ xTarget.1 - 15, xTarget.2 + 2 ], [ xTarget.1 - 5, xTarget.2 ] ] )
		;Arrows
		
		graphics.drawLine( pen, yAxis )
		yTarget := yAxis.1
		graphics.drawLine( pen, [ [ yTarget.1 - 2, yTarget.2 + 15 ], [ yTarget.1, yTarget.2 + 5 ] ] )
		graphics.drawLine( pen, [ [ yTarget.1 + 2, yTarget.2 + 15 ], [ yTarget.1, yTarget.2 + 5 ] ] )
		
		;Thanks to Nigh for these Awesome Arrows
	}
	
	/*
		points: an array of 2 [ x, y ] points that define origin and direction of the InfiniteLine
	*/
	
	getInfiniteLine( points )
	{
		origin      := [ points.1.1, points.1.2 ]
		direction   := [ points.2.1 - points.1.1, points.2.2 - points.1.2 ]
		frameRegion := This.getFrameRegion()
		translate   := frameRegion.translate
		region      := frameRegion.region
		if ( direction.1 = 0 )
			return [ [ origin.1 * translate.3 + translate.1, region.2 + region.4 ], [ origin.1 * translate.3 + translate.1, region.2 ] ]
		else
			return [ [ region.1, origin.2 * translate.4 + translate.2 ], [ region.1 + region.3, origin.2 * translate.4 + translate.2 ] ]
	}
	
	flushToGUI()
	{
		targetDC := new GDI.DC( This.gethWND() )
		graphics := targetDC.getGraphics()
		graphics.drawBitmap( This.bitmap, This.getControlRect(), This.bitmap.getRect() )
	}
	
	flushToFile( fileName )
	{
		This.bitmap.saveToFile( fileName )
	}
	
	registerRedraw()
	{
		hWND := This.getWindowhWND()
		if !( gdipChart.hasKey( "windows" ) )
		{
			OnMessage( 0xF, gdipChart.WM_PAINT )
			OnMessage( 0x214, gdipChart.WM_SIZEing )
			OnMessage( 0x5, gdipChart.WM_SIZEing )
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
			OnMessage( 0x214, gdipChart.WM_SIZEing, 0 )
			OnMessage( 0x5, gdipChart.WM_SIZEing, 0 )
		}
	}
	
	WM_PAINT( lParam, msg, hWND )
	{
		arr := gdipChart.windows[ hWND + 0 ]
		for each, obj in arr
			obj.draw()
	}
	
	WM_SIZEing( lParam, msg, hWND )
	{
		arr := gdipChart.windows[ hWND + 0 ]
		for each, obj in arr
			if ( obj.isControlRectRelative() && ( hWND = obj.getHWND() ) )
				obj.setControlRect()
	}
	
}

log2( value )
{
	static base := log( 2 )
	return log( value ) / base
}

/*
	Thanks jNizM
*/
modulo(x, y)
{
	return x - ((x // y) * y)
}