function sudo() {
	powershell -Command "Start-Process wt -Verb RunAs"
}

function monorepo() {
	cd C:/Code/bb-monorepo/
}

function rebase() {
	git fetch
	git rebase origin/main --autostash
}

function tryprune() {
	git checkout main; git remote update origin --prune; git branch -vv | Select-String -Pattern ": gone]" | % { $_.toString().Trim().Split(" ")[0]} | % {git branch -D $_ --dry-run}
}

function prune() {
	git checkout main; git remote update origin --prune; git branch -vv | Select-String -Pattern ": gone]" | % { $_.toString().Trim().Split(" ")[0]} | % {git branch -D $_}
}

function gs() {
    git status
}

function git-fetch() {
    git fetch
    git status
}

function git-rc() {
    git rebase --continue
}

function git-ra() {
    git rebase --abort
}

function git-clean-repo() {
    git clean -xdf -e License.config
}

function openthis(){
	Get-ChildItem *.sln | invoke-item
}

function open($myVar){
    if ($myVar) {
        Set-Location "./services/$myVar"
        Get-ChildItem *.sln | Invoke-Item
        Set-Location -Path ../../
    } 
    else {
        Get-ChildItem *.sln | Invoke-Item
    }
}

function touch($filename){
	New-Item ./$filename -type file
}

Set-Alias .. cd.. -option AllScope
