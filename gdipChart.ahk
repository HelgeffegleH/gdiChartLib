#Include classGDIp.ahk

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
		if This.visible^bVisible
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
		static rectI := "", init := VarSetCapacity( rectI, 16 )
		if This.hasKey( "controlRect" )
			return This.controlRect.clone()
		DllCall( "getClientRect", "UPtr", This.getHWND(), "UPtr", &rectI )
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
		translateRect.2 := targetFieldRect.2 - sourceRect.2 * translateRect.4
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
	
	getMarging()
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
				This.prepareBuffers()
				This.drawBackGround()
				This.drawGrid()
				This.drawDataStream()
				This.drawAxis()
			}
			This.flushToGUI()
		}
	}
	
	prepareBuffers()
	{
		This.bitmap := new GDIp.Bitmap( ( Thi.getControlRect().removeAt( 1, 2 ) )* )
	}
	
	drawBackGround()
	{
		This.bitmap.getGraphics().clear( This.getBackgroundColor() )
	}
	
	drawData()
	{
		graphics     := This.getGraphics()
		pen          := new Gdip.Pen( 0xFF000000 )
		brush        := new Gdip.SolidBrush( 0xFF000000 )
		frameRegion  := This.getMultiplier()
		translate    := frameRegion.translate
		fieldRect    := frameRegion.region
		
		For each, visibleDataStream in This.visibleData
		{
			streamColor := visibleDataStream.getColor()
			pen.setColor( streamColor )
			brush.setColor( streamColor )
			data := visibleDataStream.getData()
			For each, point in data
				graphics.drawLines( pen, data )
			graphics.fillPie
		}
	}
	
	
	registerRedraw()
	{
		hWND := This.getWindowhWND()
		if !gdipChart.hasKey( "windows" )
		{
			OnMessage( 0xF, gdipChart.WM_PAINT )
			gdipChart.windows := { hWND: { &This: new indirectReference( This ) } }
		}
		else if !gdipChart.windows.hasKey( hWND )
			gdipChar.windows[ hWND ] := { &This: new indirectReference( This ) }
		else
			gdipChar.windows[ hWND, &This ] := new indirectReference( This )
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
		for each, object in gdipChart.windows[ hWND ]
			object.draw()
	}
	
	
	addDataStream( data := "", color:="", name := "" )
	{
		dataStream := new This.DataStream( This, name, color, data )
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
			if ( This.visible ^ bVisible )
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