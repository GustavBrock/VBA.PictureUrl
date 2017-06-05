Option Compare Database
Option Explicit

Private Declare Function URLDownloadToFile Lib "Urlmon" Alias "URLDownloadToFileA" ( _
    ByVal pCaller As Long, _
    ByVal szURL As String, _
    ByVal szFileName As String, _
    ByVal dwReserved As Long, _
    ByVal lpfnCB As Long) _
    As Long

Private Declare Function URLDownloadToCacheFile Lib "Urlmon" Alias "URLDownloadToCacheFileA" ( _
    ByVal pCaller As Long, _
    ByVal szURL As String, _
    ByVal szFileName As String, _
    ByVal cchFileName As Long, _
    ByVal dwReserved As Long, _
    ByVal lpfnCB As Long) _
    As Long
'

' Download a file or a page with public access from the web.
' Returns 0 if success, error code if not.
'
' If parameter NoOverwrite is True, no download will be attempted 
' if an existing local file exists, thus this will not be overwritten.
'
' Examples:
'
' Download a file:
'   Url = "https://www.codeproject.com/script/Membership/ProfileImages/%7Ba82bcf77-ba9f-4ec3-bbb3-1d9ce15cae23%7D.jpg"
'   FileName = "C:\Test\CodeProjectProfile.jpg"
'   Result = DownloadFile(Url, FileName)
'
' Download a page:
'   Url = "https://www.codeproject.com/Tips/1022704/Rounding-Values-Up-Down-By-Or-To-Significant-Figur?display=Print"
'   FileName = "C:\Test\CodeProject1022704.html"
'   Result = DownloadFile(Url, FileName)
'
' Error codes:
' -2146697210   "file not found".
' -2146697211   "domain not found".
' -1            "local file could not be created."
'
' 2004-12-17. Gustav Brock, Cactus Data ApS, CPH.
' 2017-05-25. Gustav Brock, Cactus Data ApS, CPH. Added check for local file.
' 2017-06-05. Gustav Brock, Cactus Data ApS, CPH. Added option to no overwrite the local file.
'
Public Function DownloadFile( _
    ByVal Url As String, _
    ByVal LocalFileName As String, _
    Optional ByVal NoOverwrite As Boolean) _
    As Long
    
    Const BindFDefault  As Long = 0
    Const ErrorNone     As Long = 0
    Const ErrorNotFound As Long = -1

    Dim Result  As Long

    If NoOverwrite = True Then
        ' Page or file should not be overwritten.
        ' Check that the local file exists.
        If Dir(LocalFileName, vbNormal) <> "" Then
            ' File exists. Don't proceed.
            Exit Function
        End If
    End If
      
    ' Download file or page.
    ' Return success or error code.
    Result = URLDownloadToFile(0, Url & vbNullChar, LocalFileName & vbNullChar, BindFDefault, 0)
    
    If Result = ErrorNone Then
        ' Page or file was retrieved.
        ' Check that the local file exists.
        If Dir(LocalFileName, vbNormal) = "" Then
            Result = ErrorNotFound
        End If
    End If
    
    DownloadFile = Result
  
End Function

' Download a file or a page with public access from the web as a cached file of Internet Explorer.
' Returns the full path of the cached file if success, an empty string if not.
'
' Examples:
'
' Download a file:
'   Url = "https://www.codeproject.com/script/Membership/ProfileImages/%7Ba82bcf77-ba9f-4ec3-bbb3-1d9ce15cae23%7D.jpg"
'   Result = DownloadCacheFile(Url)
'   Result -> C:\Users\UserName\AppData\Local\Microsoft\Windows\INetCache\IE\B2IHEJQZ\{a82bcf77-ba9f-4ec3-bbb3-1d9ce15cae23}[2].png
'
' Download a page:
'   Url = "https://www.codeproject.com/Tips/1022704/Rounding-Values-Up-Down-By-Or-To-Significant-Figur?display=Print"
'   Result = DownloadCacheFile(Url)
'   Result -> C:\Users\UserName\AppData\Local\Microsoft\Windows\INetCache\IE\B2IHEJQZ\Rounding-Values-Up-Down-By-Or-To-Significant-Figur[1].htm
'
' 2017-05-25. Gustav Brock, Cactus Data ApS, CPH.
'
Public Function DownloadCacheFile( _
    ByVal Url As String) _
    As String
    
    Const BufferLength  As Long = 1024
    Const BindFDefault  As Long = 0
    Const ErrorNone     As Long = 0

    Dim FileName        As String
    Dim LocalFileName   As String
    Dim Result          As Long
    
    ' Create buffer for name of downloaded and/or cached file.
    FileName = Space(BufferLength - 1) & vbNullChar
    ' Download file or page.
    ' Return name of cached file in parameter FileName.
    Result = URLDownloadToCacheFile(0, Url & vbNullChar, FileName, BufferLength, BindFDefault, 0)
    
    ' Trim file name.
    LocalFileName = Split(FileName, vbNullChar)(0)
    
    DownloadCacheFile = LocalFileName
  
End Function

' Download (picture) file from a URL of a hyperlink field to a
' (temporary) folder, and return the full path to the downloaded file.
'
' This can be used as the control source for a bound picture control.
' If no Folder is specified, the user's IE cache folder is used.
'
' Typical usage in the RecordSource for a form or report where Id is
' the unique ID and Url is the hyperlink field holding the URL to
' the picture file to be displayed:
'
'   - to a cached file where parameter Id is not used:
'
'   Select *, UrlContent(0, [Url]) As Path From SomeTable;
'
'   - or, where Id is used to create the local file name:
'
'   Select *, UrlContent([Id], [Url], "d:\somefolder") As Path From SomeTable;
'
' Then, set ControlSource of the bound picture control to: Path
'
' 2017-05-28. Gustav Brock, Cactus Data ApS, CPH.
'
Public Function UrlContent( _
    ByVal Id As Long, _
    ByVal Url As String, _
    Optional ByVal Folder As String) _
    As Variant

    Const NoError   As Long = 0
    Const Dot       As String = "."
    Const BackSlash As String = "\"
    
    Dim Address     As String
    Dim Ext         As String
    Dim Path        As String
    Dim Result      As String
    
    ' Strip leading and trailing octothorpes from URL string.
    Address = HyperlinkPart(Url, acAddress)
    ' If Address is a zero-length string, Url was not wrapped in octothorpes.
    If Address = "" Then
        ' Use Url as is.
        Address = Url
    End If
    
    If Folder = "" Then
        ' Import to IE cache.
        Result = DownloadCacheFile(Address)
    Else
        If Right(Folder, 1) <> BackSlash Then
            ' Append a backslash.
            Folder = Folder & BackSlash
        End If
    
        ' Retrieve extension of file name.
        Ext = StrReverse(Split(StrReverse(Address), Dot)(0))
        ' Build full path for downloaded file.
        Path = Folder & CStr(Id) & Dot & Ext
        
        If DownloadFile(Address, Path) = NoError Then
            Result = Path
        End If
    End If
    
    UrlContent = Result
    
End Function
