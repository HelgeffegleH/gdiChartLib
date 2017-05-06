#Include classGDIp.ahk

class gdipChart
{
	
	__New( hWND, controlRect := "", fieldRect := "", type := "line" )
	{
		
		This.setVisible( false )
		if controlRect
			This.setControlRect( controlRect )
		This.sethWND( hWND )
		This.setFieldRect( isObject( fieldRect ) ? fieldRect : [ 0, 0, 1, 1 ] )
		This.setType( type )
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
		return This.fieldRect
	}
	
	
	setControlRect( rect )
	{
		This.controlRect := rect
		This.touch()
	}
	
	getControlRect()
	{
		static rectI := "", init := VarSetCapacity( rectI, 16 )
		If This.hasKey( "controlRect" )
			return This.controlRect
		DllCall( "getClientRect", "UPtr", This.getHWND(), "UPtr", &rectI )
		outRect := []
		Loop 4
			outRect.Push( numGet( rectI, A_Index * 4 - 4, "UInt" ) )
		return outRect
	}
	
	
	setHWND( hWND )
	{
		If ( This.hWND && hWND != This.hWND )
			This.unregisterRedraw(), This.sendRedraw()
		This.hWND := hWND
		This.registerRedraw()
		This.touch()
	}
	
	getHWND()
	{
		return This.hWND
	}
	
	getWindowHWND()
	{
		return DllCall( "GetAncestor", "UPtr", This.hWND, "UInt", 3 )
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
				This.drawBackGround()
				This.drawGrid()
				This.drawDataStream()
				This.drawAxis()
			}
			This.flushToGUI()
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
	
}