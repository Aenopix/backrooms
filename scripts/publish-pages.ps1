# Publishes the exported web build in pages/ (a worktree of the gh-pages
# branch) to GitHub as a single amended commit, so gh-pages never grows.
#
# Usage: export the "Web" preset in Godot to pages/backrooms.html first,
# then run this script from anywhere. index.html (a redirect to
# backrooms.html) already lives in pages/ and isn't touched by exports.

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$pagesDir = Join-Path $repoRoot "pages"

if (-not (Test-Path (Join-Path $pagesDir "backrooms.html"))) {
    throw "pages/backrooms.html not found. Export the Web preset in Godot first."
}

Push-Location $pagesDir
try {
    git add -A
    $status = git status --porcelain --cached
    if (-not $status) {
        Write-Host "No changes to publish."
        return
    }
    git commit --amend --no-edit -q
    git push origin gh-pages --force
    Write-Host "Published to gh-pages."
}
finally {
    Pop-Location
}
