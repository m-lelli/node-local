function Get-ParsedArgs {
    param(
        [string[]]$RawArgs
    )

    # Restituisce un PSCustomObject con i campi: FirstPositional, Alias, Latest, LatestLts, Force, Yes, NonInteractive, RemainingPositionals, Remaining
    $result = [PSCustomObject]@{
        FirstPositional = $null
        Alias = $null
        Latest = $false
        LatestLts = $false
        LtsOnly = $false
        All = $false
        Limit = $null
        Force = $false
        Yes = $false
        NonInteractive = $false
        RemainingPositionals = @()
        Remaining = @()
        Clean = $false
        Clear = $false
        List = $false
        From = $null
        To = $null
    }

    if (-not $RawArgs) { return $result }

    $i = 0
    while ($i -lt $RawArgs.Count) {
        $token = $RawArgs[$i]

        switch -regex ($token) {
            '^--?latest$' {
                $result.Latest = $true
                $i++
                continue
            }
            '^--?latest-lts$' {
                $result.LatestLts = $true
                $i++
                continue
            }
            '^--?alias$' {
                if (($i + 1) -lt $RawArgs.Count) {
                    $result.Alias = $RawArgs[$i + 1]
                    $i += 2
                    continue
                } else {
                    # alias without value -> ignore
                    $i++ ; continue
                }
            }
            '^--?from$' {
                if (($i + 1) -lt $RawArgs.Count) {
                    $result.From = $RawArgs[$i + 1]
                    $i += 2
                    continue
                } else {
                    $i++ ; continue
                }
            }
            '^--?to$' {
                if (($i + 1) -lt $RawArgs.Count) {
                    $result.To = $RawArgs[$i + 1]
                    $i += 2
                    continue
                } else {
                    $i++ ; continue
                }
            }
            '^--?force$' {
                $result.Force = $true ; $i++ ; continue
            }
            '^--?lts$' {
                $result.LtsOnly = $true ; $i++ ; continue
            }
            '^--?all$' {
                $result.All = $true ; $i++ ; continue
            }
            '^--?limit$' {
                if (($i + 1) -lt $RawArgs.Count) {
                    $result.Limit = [int]$RawArgs[$i + 1]
                    $i += 2
                    continue
                } else {
                    $i++ ; continue
                }
            }
            '^--?y$' {
                $result.Yes = $true ; $result.NonInteractive = $true ; $i++ ; continue
            }
            '^--?yes$' {
                $result.Yes = $true ; $result.NonInteractive = $true ; $i++ ; continue
            }
            '^--?non-interactive$' {
                $result.NonInteractive = $true ; $i++ ; continue
            }
            '^--?clean$' {
                $result.Clean = $true
                $i++
                continue
            }
            '^--?clear$' {
                $result.Clear = $true
                $i++
                continue
            }
            '^--list$' {
                $result.List = $true
                $i++
                continue
            }
            '^--?help$' { $result.Remaining += $token ; $i++ ; continue }
            '^-{1,2}.*' {
                # Unknown flag, push to Remaining
                $result.Remaining += $token ; $i++ ; continue
            }
            default {
                # Positional: first non-flag token is FirstPositional (se non ancora impostata)
                if (-not $result.FirstPositional) {
                    $result.FirstPositional = $token
                } else {
                    $result.RemainingPositionals += $token
                }
                $i++ ; continue
            }
        }
    }

    return $result
}
