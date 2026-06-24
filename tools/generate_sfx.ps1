param(
    [string]$OutputDirectory = "assets/audio"
)

$sampleRate = 44100

function Write-MonoWave {
    param(
        [string]$Path,
        [double[]]$Samples
    )

    $stream = [System.IO.File]::Create($Path)
    $writer = [System.IO.BinaryWriter]::new($stream)
    $dataLength = $Samples.Length * 2

    $writer.Write([System.Text.Encoding]::ASCII.GetBytes("RIFF"))
    $writer.Write(36 + $dataLength)
    $writer.Write([System.Text.Encoding]::ASCII.GetBytes("WAVE"))
    $writer.Write([System.Text.Encoding]::ASCII.GetBytes("fmt "))
    $writer.Write(16)
    $writer.Write([int16]1)
    $writer.Write([int16]1)
    $writer.Write($sampleRate)
    $writer.Write($sampleRate * 2)
    $writer.Write([int16]2)
    $writer.Write([int16]16)
    $writer.Write([System.Text.Encoding]::ASCII.GetBytes("data"))
    $writer.Write($dataLength)

    foreach ($sample in $Samples) {
        $clamped = [Math]::Max(-1.0, [Math]::Min(1.0, $sample))
        $writer.Write([int16]($clamped * 32767))
    }

    $writer.Dispose()
    $stream.Dispose()
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

# Daily interaction: one rounded "boop" with a fast pitch drop.
$regularLength = [int]($sampleRate * 0.18)
$regular = [double[]]::new($regularLength)
for ($i = 0; $i -lt $regularLength; $i++) {
    $t = $i / $sampleRate
    $p = $i / $regularLength
    $phase = 2 * [Math]::PI * ((430 * $t) - (125 * $t * $p))
    $attack = [Math]::Min(1.0, $p / 0.025)
    $envelope = $attack * [Math]::Exp(-7.2 * $p)
    $fundamental = [Math]::Sin($phase)
    $softBody = 0.28 * [Math]::Sin($phase * 0.5)
    $regular[$i] = 0.58 * $envelope * ($fundamental + $softBody)
}
Write-MonoWave -Path (Join-Path $OutputDirectory "interaction_regular.wav") -Samples $regular

# Hit interaction: one dry palm slap, without drum resonance.
$hitLength = [int]($sampleRate * 0.19)
$hit = [double[]]::new($hitLength)
$random = [System.Random]::new(8848)
$fastNoise = 0.0
$slowNoise = 0.0
for ($i = 0; $i -lt $hitLength; $i++) {
    $t = $i / $sampleRate
    $p = $i / $hitLength
    $raw = ($random.NextDouble() * 2) - 1
    $fastNoise = (0.16 * $fastNoise) + (0.84 * $raw)
    $slowNoise = (0.72 * $slowNoise) + (0.28 * $raw)
    $crack = $fastNoise * [Math]::Exp(-48 * $p)
    $skin = ($fastNoise - $slowNoise) * [Math]::Exp(-20 * $p)
    $palm = [Math]::Sin(2 * [Math]::PI * 185 * $t) *
        [Math]::Exp(-24 * $p)
    $air = $slowNoise * [Math]::Exp(-11 * $p)
    $hit[$i] = (0.78 * $crack) + (0.55 * $skin) +
        (0.18 * $palm) + (0.25 * $air)
}
Write-MonoWave -Path (Join-Path $OutputDirectory "interaction_hit.wav") -Samples $hit
