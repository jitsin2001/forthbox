{ ========== derived-controls.f ========================================

Define a window subclass to make using a windows standard control
such as a button or listbox as a child in a GUI-FRAMEWORK defined
window class/object.

Various derived controls are defined here, added as needed.

(C) 2020 Rick VanNorman  -- rick@digital-sawdust.com
====================================================================== }

class reflected-message
   single hwnd
   single msg
   single wparam
   single lparam

   : capture ( hwnd msg wparam lparam -- )
      to lparam  to wparam  to msg  to hwnd ;

end-class

derivedwindow subclass derived-control

   single x             \ where in the device context to
   single y             \ actually draw the image
   single xsize         \ size to draw
   single ysize         \

   single id            \ control id for forwarded messages
   single hdc
   single hfont
   single charw
   single charh
   single high
   single wide

   reflected-message builds reflected

   2 constant margin   ( match surface)
   margin 2* constant border

{ ----------------------------------------------------------------------
control placement of surface objects
---------------------------------------------------------------------- }

   : xr ( -- x )   x xsize + border + ;
   : yb ( -- y )   y ysize + border + ;

   : ul ( -- x y )   x  y  ;
   : ur ( -- x y )   xr y  ;
   : lr ( -- x y )   xr yb ;
   : ll ( -- x y )   x  yb ;

   : below ( -- x y )   ll ;
   : beside ( -- x y )   ur ;

   : mywindow_shape ( -- x y cx cy )   0 0 100 20 ;

   : extents ( -- x y cx cy )   ul xsize ysize ;

   textmetric builds tm

   : measure-font ( -- )
      hdc tm addr GetTextMetrics drop
      tm height @ to charh
      tm avecharwidth @ to charw ;

   : measure-client ( -- )
      mhwnd pad GetClientRect drop  pad 2 cells + @+ to wide  @ to high ;

   defer: pre-make ;
   defer: post-make ;
   defer: pre-placed ;
   defer: post-placed ;

   \ x and y are where you were told to be
   \ maxes are max of both values

   : placed ( xmax ymax x y -- xmax ymax )
      pre-placed
      to y to x  lr rot max >r  max r>
      x y xsize ysize resize   measure-client
      post-placed ;

   : sized ( xsize ysize -- )   to ysize to xsize  ;

   : title ( zstr -- )   mhwnd swap SetWindowText drop ;

   defer: font ( -- hfont )   lucida-console-10 CreateFont ;

   : set-font ( hfont -- )   to hfont
      mhwnd WM_SETFONT hfont 0 SendMessage drop
      hdc hfont SelectObject drop ;

   : make ( hwnd xsize ysize zname -- )
      pre-make
      >r  sized  attach   r> title
      addr  hparent WM_GETBASEADDR 0 0 SendMessage  -  to id
      mhwnd getdc to hdc
      font ?dup if  dup to hfont  set-font  then  measure-font
      post-make ;

   : reflect ( -- )
      hwnd msg wparam lparam reflected capture
      hparent WM_COMMAND  msg >h<  id or  mhwnd SendMessage ;

   : get-ztext ( addr len -- len )
      1- mhwnd pad rot GetWindowText  pad over fourth zplace  nip ;

   : set-text ( addr len -- )
      r-buf  r@ zplace  r> title ;

   : clicked? ( x y -- x y bool )
      2dup
      y dup ysize + rot within >r
      x dup xsize + rot within r> and ;

   : send ( msg wparam lparam -- res )   >r mhwnd -rot r> sendmessage ;
   : tell ( msg wparam lparam -- res )   send drop ;

   : show ( -- )   mhwnd SW_SHOW ShowWindow drop ;
   : hide ( -- )   mhwnd SW_HIDE ShowWindow drop ;

end-class

{ ======================================================================
Create derived controls as needed; append here. These serve as much
as examples as useful derivations. The subclassing of a derived
control allows access to things that are ordinarilly more difficult
to do in the win32 api
====================================================================== }


{ ========== user defined button behavior ==============================

A simple user button; the WM_LBUTTONDOWN message handler is
commented out as not generally useful, but left in as an example
of what is easy to get to when needed for user behavior

MYWINDOW_CLASSNAME is required; almost all other things can be
defaulted and defined as needed by the actual program use.

====================================================================== }

derived-control subclass mybutton
   : mywindow_classname z" BUTTON" ;

    WM_LBUTTONDOWN    message:  defproc  reflect ;
    WM_RBUTTONDOWN    message:  defproc  reflect ;

end-class

derived-control subclass mystatic
   : mywindow_classname z" STATIC" ;
end-class

mystatic subclass myltext      \ left justified; alias
end-class

mystatic subclass myrtext     \ right justified
   : mywindow_style ( -- n )
      0 WS_TABSTOP OR
        WS_CHILD OR
        WS_VISIBLE OR
        SS_RIGHT or ;
end-class

mystatic subclass myctext     \ right justified
   : mywindow_style ( -- n )
      0 WS_TABSTOP OR
        WS_CHILD OR
        WS_VISIBLE OR
        SS_CENTER or ;
end-class

mystatic subclass mybmp
   single image   \ points to memory image of bmp file
   : set-image ( bmp-addr -- )   to image ;
   WM_PAINT message:
      (o bitmap: bm )
      mhwnd pad BeginPaint drop
      image mhwnd bm centered
      mhwnd pad EndPaint drop  0 ;
end-class

\ ======================================================================

derived-control subclass mylistbox
   : mywindow_classname z" LISTBOX" ;
   : mywindow_style ( -- n )
      0 WS_TABSTOP OR
        WS_CHILD OR
        WS_VISIBLE OR
        WS_BORDER OR
        LBS_NOINTEGRALHEIGHT OR
        WS_VSCROLL OR
        WS_HSCROLL OR ;
   : TYPE ( addr len -- )   R-BUF R@ ZPLACE
      LB_ADDSTRING 0 R> tell
      LB_GETCOUNT 0 0 send 500 > IF
         LB_DELETESTRING 0 0 tell
      THEN
      LB_GETCOUNT 0 0 send 1-
      LB_SETCURSEL ROT 0 tell ;
end-class

\ ======================================================================

derived-control subclass myeditbox
   : mywindow_classname z" EDIT" ;
   : mywindow_style ( -- n )
      0 WS_TABSTOP OR
        WS_CHILD OR
        WS_VISIBLE OR
        WS_BORDER OR
        WS_THICKFRAME or
        ES_RIGHT or ;
end-class

derived-control subclass myrichbox
   : mywindow_classname ( -- z )
      z" Msftedit.dll" loadlibrary drop   z" RICHEDIT50W" ;
   : mywindow_style ( -- n )
      0 WS_TABSTOP OR WS_CHILD OR WS_VISIBLE OR
        WS_VSCROLL or WS_HSCROLL or ES_MULTILINE or ES_AUTOVSCROLL or
        ES_AUTOHSCROLL or ;
   : font ( -- hfont )   lucida-console-12 CreateFont ;
   : sized-as-chars ( cols rows  -- )
      >r charw  * dup to xsize  SM_CXVSCROLL GetSystemMetrics +  charw 2/ +
      r> charh  * dup to ysize  SM_CXHSCROLL GetSystemMetrics +  charh 2/ +
      sized ;
   : post-make ( -- )   xsize ysize sized-as-chars ;

   : sol? ( -- flag )
      EM_GETSEL 0 0 send $ffff and
      EM_LINEFROMCHAR third 0 send
      EM_LINEINDEX rot 0 send = ;

   : goto-end ( -- )   EM_SETSEL -1 -1 tell  WM_VSCROLL SB_BOTTOM 0 tell ;
   : replace ( zstr -- )   EM_REPLACESEL 0 rot tell ;
   : append ( zstr -- )   goto-end replace ;
   : select-all ( -- )   EM_SETSEL 0 -1 tell ;
   : page ( -- )   select-all  0 append ;
   : emit ( char -- )   sp@ append drop ;
   : cr ( -- )   z\" \n" append ;
   : type ( addr len -- )   r-buf
      begin
         2dup 250 min r@ zplace  r@ append
         250 /string  dup 1 <
      until  2drop  r> drop ;
   : writeln ( addr len -- )   type cr ;

end-class

derived-control subclass mynumberbox
   : mywindow_classname
      z" Msftedit.dll" loadlibrary drop
      z" RICHEDIT50W" ;
   : mywindow_style ( -- n )
      0 WS_TABSTOP OR
        WS_CHILD OR
        WS_VISIBLE OR
        WS_BORDER OR
        WS_EX_STATICEDGE or
        ES_RIGHT or ;
   WM_CHAR message:
      defproc  wparam 13 = if  reflect  then ;
   : post-placed ( -- )
      EM_GETRECT 0 pad send
      high tm ascent @ - 2/ pad cell+ +!
      charh negate pad 2 cells + +!
      EM_SETRECT 0 pad send ;
   : get-float ( -- ) f( -- rval )
      pad dup 32 get-ztext >float ?exit  0.0e0 ;
   : set-float ( -- ) f( rval -- )
      (f.3) set-text ;
end-class

\ ======================================================================

derived-control subclass mygroupbox
   : mywindow_classname z" BUTTON" ;
   : mywindow_style ( -- n )
      0 WS_VISIBLE or  WS_CHILD or  BS_GROUPBOX or ;
   : surrounds ( xmax ymax x y -- xmax ymax )
      third over max >r  fourth third  max >r
      y - to ysize  x - to xsize
      mhwnd  HWND_BOTTOM x y xsize ysize  SWP_NOMOVE SetWindowPos drop
      r> border + r>  border + ;
end-class

\ ======================================================================

\ ----------------------------------------------------------------------

myctext subclass myflatbutton
   : mywindow__style WS_CHILD WS_VISIBLE or SS_BITMAP or ;
   single pressed
   single down-color
   single up-color

   single xoffset
   single yoffset
   single wide

   4 constant margin

   256 buffer: text

   : set-colors ( up down -- )   to down-color  to up-color ;

   : thecolor ( -- color )
      pressed if down-color else up-color then  ;

   : draw-button ( -- )
      hdc thecolor  SetBkColor drop
      hdc xoffset yoffset ETO_OPAQUE
      here mhwnd over GetClientRect drop
      text count  0 ExtTextOut DROP ;

   : release ( -- )   pressed -exit   0 to pressed  draw-button ;
   : press   ( -- )   pressed ?exit   1 to pressed  draw-button ;

   : re-text ( -- )
      mhwnd text 1+ 254 GetWindowText wide min  text c!
      xsize  text c@ charw *  - 2/  to xoffset ;

   : set-text ( z -- )
      mhwnd swap SetWindowText drop  re-text  draw-button ;

   : post-make ( -- )
      xsize to wide   margin to yoffset
      xsize charw *  margin 2* + to xsize
      ysize charh *  margin 2* + to ysize
      $bebebe $ffc0ff set-colors
      re-text draw-button ;

   WM_PAINT MESSAGE: ( -- 0 )
      mHWND PAD BeginPaint DROP
         draw-button
      mHWND PAD EndPaint DROP ;

end-class

\ ----------------------------------------------------------------------

derived-control subclass mytextpane
   : mywindow_classname z" STATIC" ;
   : mywindow__style WS_CHILD WS_VISIBLE or SS_BITMAP or ;

   : font ( -- hfont )   lucida-console-12 CreateFont ;

   : char>pixel ( x y -- x y )   >r charw * r> charh * ;

   : dot-text ( addr len x y -- )
      2swap 2>r  2>r   hdc  2r> char>pixel 2r> TextOut drop ;

   : print-column ( addr len x y -- )   locals| y x |
      begin ( a l)
         dup 0> while
         2dup eol-scanner >r
         third swap x y dot-text 1 +to y
         r> /string
      repeat 2drop ;

   : post-make ( -- )
      ysize charh * to ysize  xsize charw * to xsize ;

   defer: render ( -- )   ;

   WM_PAINT MESSAGE: ( -- 0 )
      mHWND PAD BeginPaint DROP
         render
      mHWND PAD EndPaint DROP ;

end-class

