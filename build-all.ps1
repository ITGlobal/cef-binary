$python = 'C:\Python27\python.exe'
$automateUrl = 'https://bitbucket.org/itglobalru/cef/raw/itglobal/tools/automate/automate-git.py'
$source = 'source'
$cefUrl = 'https://bitbucket.org/itglobalru/cef.git'
$cefCheckout = 'origin/itglobal'
$cefBranch = '2623'

$automate = Split-Path $automateUrl -leaf
$automatePath = Join-Path $PSScriptRoot $automate
$sourceDir = Join-Path $PSScriptRoot $source
$distribDir = Join-Path $PSScriptRoot (Join-Path $source 'chromium\src\cef\binary_distrib')

$env:GYP_GENERATORS = 'ninja,msvs-ninja'
$env:GYP_MSVS_VERSION = '2013'

if (!(Test-Path $automatePath))
{
    Invoke-WebRequest $automateUrl -OutFile $automatePath
}

function Automate-Git($extra)
{
    $args = @(
        "$automate"
        "--url=$cefUrl"
        "--download-dir=$sourceDir"
        "--branch=$cefBranch"
        "--checkout=$cefCheckout"
        '--force-build'
    )

    Write-Host ($args + $extra)
    &$python ($args + $extra)
}

function Copy-Distrib($filter)
{
    $inputDirName = @(Get-ChildItem $distribDir -filter $filter)[0]
    $inputDir = Join-Path $distribDir $inputDirName
    $outputDir = Join-Path $PSScriptRoot @(Get-ChildItem $PSScriptRoot -filter $filter)[0]

    Write-Host "Clean $outputDir"
    Remove-Item (Join-Path $outputDir '*') -Exclude '.empty' -Recurse

    Write-Host "Copy $inputDir to $outputDir"
    if ($inputDirName -eq $null)
    {
        Write-Error "Cannot found $(Join-Path $distribDir $filter)"
        return
    }
    Copy-Item (Join-Path $inputDir '*') $outputDir -Recurse
}

function Run-All($productName, $filter, $extra)
{
    Write-Host "Building $productName..." -foreground Green
    Automate-Git($extra);

    Write-Host "Copying $productName..." -foreground Green
    Copy-Distrib($filter);
}

Run-All 'CEF x86' '*_windows32' @(
)
Run-All 'CEF x64' '*_windows64' @(
    '--x64-build'
)
