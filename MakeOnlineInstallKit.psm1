###########################################################
# PowerShell Online Install Kit 作成
###########################################################
function MakeOnlineInstallKit(){


####################################
# ヒア文字列を配列にする
####################################
	function HereString2StringArray( $HereString ){
		$Temp = $HereString.Replace("`r","")
		$StringArray = $Temp.Split("`n")
		return $StringArray
	}

### バージョンチェックを関数に組み込む追加コード
$AddCode = @'
function AddCode(, [switch]$VertionCheck){

	if( $VertionCheck ){
		$ModuleName = "##ModuleName##"
		$GitHubName = "##MGitHubName##"

		$HomeDirectory = "~/"
		$Module = $ModuleName + ".psm1"
		$Installer = "Install" + $ModuleName + ".ps1"
		$UnInstaller = "UnInstall" + $ModuleName + ".ps1"
		$Vertion = "Vertion" + $ModuleName + ".txt"
		$GithubCommonURI = "https://raw.githubusercontent.com/$GitHubName/$ModuleName/master/"

		$VertionTemp = "VertionTemp" + $ModuleName + ".tmp"
		$VertionFilePath = Join-Path "~/" $Vertion
		$VertionTempFilePath = Join-Path "~/" $VertionTemp
		$VertionFileURI = $GithubCommonURI + "Vertion.txt"


		$Update = $False

		if( -not (Test-Path $VertionFilePath)){
			$Update = $True
		}
		else{
			$LocalVertion = Get-Content -Path $VertionFilePath

			$URI = $VertionFileURI
			$OutFile = $VertionTempFilePath
			Invoke-WebRequest -Uri $URI -OutFile $OutFile
			$NowVertion = Get-Content -Path $VertionTempFilePath
			Remove-Item $VertionTempFilePath

			if( $LocalVertion -ne $NowVertion ){
				$Update = $True
			}
		}

		if( $Update ){
			Write-Output "最新版に更新します"
			Write-Output "更新完了後、PowerShell プロンプトを開きなおしてください"

			$URI = $GithubCommonURI + $Module
			$ModuleFile = $HomeDirectory + $Module
			Invoke-WebRequest -Uri $URI -OutFile $ModuleFile

			$URI = $GithubCommonURI + "install.ps1"
			$InstallerFile = $HomeDirectory + $Installer
			Invoke-WebRequest -Uri $URI -OutFile $InstallerFile

			$URI = $GithubCommonURI + "uninstall.ps1"
			$OutFile = $HomeDirectory + $UnInstaller
			Invoke-WebRequest -Uri $URI -OutFile $OutFile

			$URI = $GithubCommonURI + "Vertion.txt"
			$OutFile = $HomeDirectory + $Vertion
			Invoke-WebRequest -Uri $URI -OutFile $OutFile

			& $InstallerFile

			Remove-Item $ModuleFile
			Remove-Item $InstallerFile

			Write-Output "更新完了"
			Write-Output "PowerShell プロンプトを開きなおしてください"
		}
		else{
			Write-Output "更新の必要はありません"
		}
		return
	}

	# 以下本来のコード

'@

### インストーラー
$Install = @'
# Module Name
$ModuleName = "##ModuleName##"

# Module Path
if(($PSVersionTable.Platform -eq "Win32NT") -or ($PSVersionTable.Platform -eq $null)){
	$ModulePath = Join-Path (Split-Path $PROFILE -Parent) "Modules"
}
else{
	$ModulePath = Join-Path ($env:HOME) "/.local/share/powershell/Modules"
}
$NewPath = Join-Path $ModulePath $ModuleName

# Make Directory
if( -not (Test-Path $NewPath)){
	New-Item $NewPath -ItemType Directory -ErrorAction SilentlyContinue
}

# Copy Module
$ModuleFileName = Join-Path $PSScriptRoot ($ModuleName + ".psm1")
Copy-Item $ModuleFileName $NewPath

'@

### オンラインインストーラー
$OnlineInstall = @'
# Online installer

$ModuleName = "##ModuleName##"
$GitHubName = "##MGitHubName##"

$HomeDirectory = "~/"
$Module = $ModuleName + ".psm1"
$Installer = "Install" + $ModuleName + ".ps1"
$UnInstaller = "UnInstall" + $ModuleName + ".ps1"
$Vertion = "Vertion" + $ModuleName + ".txt"
$GithubCommonURI = "https://raw.githubusercontent.com/$GitHubName/$ModuleName/master/"
$OnlineInstaller = $HomeDirectory + "OnlineInstall.ps1"

$URI = $GithubCommonURI + $Module
$ModuleFile = $HomeDirectory + $Module
Invoke-WebRequest -Uri $URI -OutFile $ModuleFile

$URI = $GithubCommonURI + "install.ps1"
$InstallerFile = $HomeDirectory + $Installer
Invoke-WebRequest -Uri $URI -OutFile $InstallerFile

$URI = $GithubCommonURI + "uninstall.ps1"
$OutFile = $HomeDirectory + $UnInstaller
Invoke-WebRequest -Uri $URI -OutFile $OutFile

$URI = $GithubCommonURI + "Vertion.txt"
$OutFile = $HomeDirectory + $Vertion
Invoke-WebRequest -Uri $URI -OutFile $OutFile

& $InstallerFile

Remove-Item $ModuleFile
Remove-Item $InstallerFile
Remove-Item $OnlineInstaller

'@

### 公開リポジトリと初期インストールコマンドを Readme.txt として出力
$Readme = @'
■ これは何?

■ オプション

-VertionCheck

最新版のスクリプトがあるか確認します
最新版があれば、自動ダウンロード & 更新します


■ GitHub
以下リポジトリで公開しています
https://github.com/##MGitHubName##/##ModuleName##
git@github.com:##MGitHubName##/##ModuleName##.git

■ スクリプトインストール方法

--- 以下を PowerShell プロンプトにコピペ ---

$ModuleName = "##ModuleName##"
$GitHubName = "##MGitHubName##"
$URI = "https://raw.githubusercontent.com/$GitHubName/$ModuleName/master/OnlineInstall.ps1"
$OutFile = "~/OnlineInstall.ps1"
Invoke-WebRequest -Uri $URI -OutFile $OutFile
& $OutFile

'@

### アンインストーラー
$Uninstall = @'
# Module Name
$ModuleName = "##ModuleName##"

# Module Path
if(($PSVersionTable.Platform -eq "Win32NT") -or ($PSVersionTable.Platform -eq $null)){
	$ModulePath = Join-Path (Split-Path $PROFILE -Parent) "Modules"
}
else{
	$ModulePath = Join-Path ($env:HOME) "/.local/share/powershell/Modules"
}
$RemovePath = Join-Path $ModulePath $ModuleName

# Remove Direcory
if( Test-Path $RemovePath ){
	Remove-Item $RemovePath -Force -Recurse
}

'@


####################################
# main
####################################

	$URI = Get-Clipboard

	[array]$Parts = $URI.Split("/")

	# GitHub URL か確認

	$IsGitHubURL = $True

	if( $Parts.Count -eq 1 ){
		$IsGitHubURL = $False
	}

	if( $Parts[0] -ne "https:" ){
		$IsGitHubURL = $False
	}

	if( $Parts[2] -ne "github.com" ){
		$IsGitHubURL = $False
	}

	$GitHubName = $Parts[3]
	if( $GitHubName -eq $null ){
		$IsGitHubURL = $False
	}

	$ModuleName = $Parts[4]
	if( $ModuleName -eq $null ){
		$IsGitHubURL = $False
	}

	if( -Not $IsGitHubURL ){
		Write-Output "$URI は 有効な URL ではありません"
		return
	}

	$CurrentDirectory = Get-Location

	# バージョンチェック組み込み用追加コード
	$AddCodeStrings = HereString2StringArray $AddCode
	$Temp = $AddCodeStrings.Replace("##ModuleName##", $ModuleName)
	$OutAddCodeStrings = $Temp.Replace("##MGitHubName##", $GitHubName)
	$AddCodeStringsPath = Join-Path $CurrentDirectory "AddCode.ps1"
	Set-Content -Value $OutAddCodeStrings -Path $AddCodeStringsPath -Encoding utf8

	# インストーラー
	$InstallStrings = HereString2StringArray $Install
	$Temp = $InstallStrings.Replace("##ModuleName##", $ModuleName)
	$OutInstallStrings = $Temp.Replace("##MGitHubName##", $GitHubName)
	$InstallStringsPath = Join-Path $CurrentDirectory "Install.ps1"
	Set-Content -Value $OutInstallStrings -Path $InstallStringsPath -Encoding utf8

	# オンラインインストーラー
	$OnlineInstallStrings = HereString2StringArray $OnlineInstall
	$Temp = $OnlineInstallStrings.Replace("##ModuleName##", $ModuleName)
	$OutOnlineInstallStrings = $Temp.Replace("##MGitHubName##", $GitHubName)
	$OnlineInstallStringsPath = Join-Path $CurrentDirectory "OnlineInstall.ps1"
	Set-Content -Value $OutOnlineInstallStrings -Path $OnlineInstallStringsPath -Encoding utf8

	# 公開リポジトリ初期インストールコマンド
	$ReadmeStrings = HereString2StringArray $Readme
	$Temp = $ReadmeStrings.Replace("##ModuleName##", $ModuleName)
	$OutReadmeStrings = $Temp.Replace("##MGitHubName##", $GitHubName)
	$ReadmeStringsPath = Join-Path $CurrentDirectory "Readme.txt"
	Set-Content -Value $OutReadmeStrings -Path $ReadmeStringsPath -Encoding utf8

	# アンインストーラー
	$UninstallStrings = HereString2StringArray $Uninstall
	$Temp = $UninstallStrings.Replace("##ModuleName##", $ModuleName)
	$OutUninstallStrings = $Temp.Replace("##MGitHubName##", $GitHubName)
	$UninstallStringsPath = Join-Path $CurrentDirectory "Uninstall.ps1"
	Set-Content -Value $OutUninstallStrings -Path $UninstallStringsPath -Encoding utf8

	# バージョンチェックファイル
	$OutVertion = (Get-Date).ToString("yyyy年MM月dd日(ddd) HH:mm")
	$VertionPath = Join-Path $CurrentDirectory "Vertion.txt"
	Set-Content -Value $OutVertion -Path $VertionPath -Encoding utf8
}

