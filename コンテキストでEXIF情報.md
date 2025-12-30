右クリックのコンテキで、EXIF情報を表示させる工夫です。超便利です。  

    
![Image](https://github.com/user-attachments/assets/3e71d00f-ea88-4451-a94a-da5a1fbc921f)

①次の内容を、「add_exif_context.reg」として保存する

Windows Registry Editor Version 5.00  
[HKEY_CLASSES_ROOT\*\shell\ShowEXIF]  
@="EXIFを表示（ExifTool）"  
"Icon"="C:\\Tools\\exiftool.exe"　　
  
[HKEY_CLASSES_ROOT\*\shell\ShowEXIF\command]  
@="pwsh -NoExit -Command \"& 'C:\\Tools\\exiftool.exe' '%1'\""  

② add_exif_context.reg をＷクリックで、レジストリへ書き込まれる  

以上


