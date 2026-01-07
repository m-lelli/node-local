# =============================================================================
# networkExceptions.ps1 - Eccezioni per operazioni di rete
# =============================================================================

class NetworkDownloadError : System.Exception {
    [string]$Url
    [string]$Details

    NetworkDownloadError([string]$message) : base($message) {}
    
    NetworkDownloadError([string]$message, [string]$url) : base($message) {
        $this.Url = $url
    }

    NetworkDownloadError([string]$message, [string]$url, [string]$details) : base($message) {
        $this.Url = $url
        $this.Details = $details
    }
}

class NetworkChecksumError : System.Exception {
    [string]$FilePath
    [string]$ExpectedChecksum
    [string]$ActualChecksum

    NetworkChecksumError([string]$message) : base($message) {}
    
    NetworkChecksumError([string]$message, [string]$filePath) : base($message) {
        $this.FilePath = $filePath
    }

    NetworkChecksumError([string]$message, [string]$filePath, [string]$expected, [string]$actual) : base($message) {
        $this.FilePath = $filePath
        $this.ExpectedChecksum = $expected
        $this.ActualChecksum = $actual
    }
}

class NetworkCorruptedFileError : System.Exception {
    [string]$FilePath

    NetworkCorruptedFileError([string]$message) : base($message) {}
    
    NetworkCorruptedFileError([string]$message, [string]$filePath) : base($message) {
        $this.FilePath = $filePath
    }
}

# =============================================================================
# Factory class per eccezioni Network
# =============================================================================

class NetworkException {
    # Lancia quando il download fallisce
    static [NetworkDownloadError] DownloadFailed([string]$url) {
        return [NetworkDownloadError]::new("Download fallito da $url", $url)
    }

    static [NetworkDownloadError] DownloadFailed([string]$url, [string]$details) {
        return [NetworkDownloadError]::new("Download fallito da $url", $url, $details)
    }

    # Lancia quando la verifica checksum fallisce
    static [NetworkChecksumError] ChecksumFailed([string]$filePath) {
        return [NetworkChecksumError]::new("Verifica checksum SHA256 fallita per $filePath", $filePath)
    }

    static [NetworkChecksumError] ChecksumFailed([string]$filePath, [string]$expected, [string]$actual) {
        return [NetworkChecksumError]::new(
            "Checksum non corrispondente per $filePath`nAtteso: $expected`nOttenuto: $actual",
            $filePath,
            $expected,
            $actual
        )
    }

    # Lancia quando un file è corrotto (ZIP non valido, ecc.)
    static [NetworkCorruptedFileError] CorruptedFile([string]$filePath) {
        return [NetworkCorruptedFileError]::new("File corrotto o danneggiato: $filePath", $filePath)
    }
}
