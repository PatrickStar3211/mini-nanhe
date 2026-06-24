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

$regularLength = [int]($sampleRate * 0.22)
$regular = [double[]]::new($regularLength)
for ($i = 0; $i -lt $regularLength; $i++) {
    $t = $i / $sampleRate
    $progress = $i / $regularLength
    $frequency = 650 + (420 * $progress)
    $envelope = [Math]::Pow([Math]::Sin([Math]::PI * $progress), 0.65) *
        [Math]::Exp(-2.2 * $progress)
    $sparkle = [Math]::Sin(2 * [Math]::PI * $frequency * $t) +
        (0.38 * [Math]::Sin(2 * [Math]::PI * $frequency * 2 * $t))
    $regular[$i] = 0.42 * $envelope * $sparkle
}
Write-MonoWave -Path (Join-Path $OutputDirectory "interaction_regular.wav") -Samples $regular

$hitLength = [int]($sampleRate * 0.28)
$hit = [double[]]::new($hitLength)
$random = [System.Random]::new(20260624)
for ($i = 0; $i -lt $hitLength; $i++) {
    $t = $i / $sampleRate
    $progress = $i / $hitLength
    $thumpFrequency = 125 - (55 * $progress)
    $thump = [Math]::Sin(2 * [Math]::PI * $thumpFrequency * $t) *
        [Math]::Exp(-8.5 * $progress)
    $noise = (($random.NextDouble() * 2) - 1) *
        [Math]::Exp(-18 * $progress)
    $body = [Math]::Sin(2 * [Math]::PI * 210 * $t) *
        [Math]::Exp(-13 * $progress)
    $hit[$i] = (0.7 * $thump) + (0.38 * $noise) + (0.2 * $body)
}
Write-MonoWave -Path (Join-Path $OutputDirectory "interaction_hit.wav") -Samples $hit
