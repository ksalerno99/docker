[CmdletBinding()]
Param(
    [String] $Target = 'all',
    [String] $Build = '',
    [String] $AdditionalArgs = ''
)

$builds = @{
    'windows' = 'Dockerfile-windows';
    'windows-jdk11' = 'Dockerfile-windows-jdk11';
    'windows-openj9' = 'Dockerfile-windows-openj9';
    'windows-jdk11-openj9' = 'Dockerfile-windows-jdk11-openj9';
}

function Build($Target='all') {
    if($Target -eq "all") {
        foreach($build in $builds.Keys) {
            & docker build -f $builds[$build] .
            if($lastExitCode -ne 0) {
                Write-Error "Docker build failed for $build"
                exit -1
            }
        }
    } else {
        & docker build -f $builds[$Target] .
        if($lastExitCode -ne 0) {
            Write-Error "Docker build failed for $Target"
            exit -1
        }
    }
}

function Test($Target='all') {
    if($Target -eq "all") {
        foreach($build in $builds.Keys) {
            $env:DOCKERFILE="Dockerfile-$build"
            Invoke-Pester -Path tests
            Remove-Item env:\DOCKERFILE
        }
    } else {
        $env:DOCKERFILE="Dockerfile-$Target"
        Invoke-Pester -Path tests
        Remove-Item env:\DOCKERFILE
    }
}

switch -wildcard ($Target) {
    # release targets
    "all"       { Build ; Test }
    "publish"   { Publish }
    "build-*"   { Build $Target.Substring(6) }
    "test"      { Test }
    "test-*"    { Test $Target.Substring(5) }

    default { Write-Error "No target '$Target'" ; Exit -1 }
}
