<#

.SYNOPSIS
Export-Font uses the ttx command line tool to export TrueType and OpenType fonts imported by Import-Font.

.DESCRIPTION

Export-Font takes a custom object generated by Import-Font as an input and compiles it info a TrueType or
OpenType font using ttx. 


.PARAMETER ImpObject
Import-Font object to export.
Alias: -i

.PARAMETER OutPath
Lets you specify an output path for the font. May be either a full path or a folder.
If only a folder is specified, the file name will be generated from the PS font name,
full font name or the base name of the imported font in case no font names are available.
If not specified, the font will be written to the folder of the imported font.
Alias: -o

.PARAMETER Format
Supported output formats are otf for an OpenType font or ttf for a TrueType font.

Defaults to otf or the file extension of the specified OutPath
Alias: -f

.EXAMPLE
Export-Font $font -f otf -o X:\Fonts
Writes an OpenType font to the X:\Fonts folder

.LINK
https://github.com/line0/FontToys

#>
#requires -version 3

function Export-Font
{
[CmdletBinding()]
param
(
[Parameter(Position=0, Mandatory=$true, HelpMessage='Object generated by Import-Font.')]
[alias("i")]
[PSCustomObject]$ImpObject,
[Parameter(Mandatory=$false, HelpMessage='Output path or full font name.')]
[alias("o")]
[string]$OutPath,
[Parameter(Mandatory=$false, HelpMessage='Output format (ttf or otf).')]
[alias("f")]
[string]$Format="otf"
)

Check-CmdInPath ttx.cmd -Name ttx

$nameCandidates=@(
    $ImpObject.GetNames(6,1,0,0).Name,
    $ImpObject.GetNames(6,3,1,1033).Name,
    ,@($ImpObject.GetNames(6))[0].Name,
    $ImpObject.GetNames(4,1,0,0).Name,
    $ImpObject.GetNames(4,3,1,1033).Name,
    ,@($ImpObject.GetNames(4))[0].Name,
    $ImpObject.Path.BaseName
)
foreach($nameCandidate in $nameCandidates)
{
    if ($nameCandidate -and $nameCandidate.Trim() -and (Test-Path $nameCandidate -IsValid)) {
        $outName = $nameCandidate+".$Format"
        break;
    }
}


if (!$outPath) {
    $OutPath = Join-Path $ImpObject.Path.DirectoryName $outName
}
elseif (Test-Path -LiteralPath $OutPath -PathType Container)
{
    $OutPath = Join-Path $OutPath $outName
}

if (!(Test-Path -LiteralPath $OutPath -IsValid)) {
    throw "Invalid OutPath: $OutPath"
}

$ttxFile = Join-Path (Resolve-Path ([System.IO.Path]::GetDirectoryName($OutPath))).Path `
           "$([System.IO.Path]::GetFileNameWithoutExtension($OutName)).Export.ttx"

$ImpObject.XML.Save($ttxFile)  

$xmlNoBOM = Get-Content $ttxFile
[System.IO.File]::WriteAllLines($ttxFile, $xmlNoBOM)

&ttx -m $ImpObject.Path.FullName -o $OutPath $ttxFile | Write-Host
Remove-Item $ttxFile

}

Export-ModuleMember Export-Font