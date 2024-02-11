
resource "tls_private_key" "opencloudplay" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "opencloudplay" {
  key_name   = "opencloudplay-com-key"
  public_key = tls_private_key.opencloudplay.public_key_openssh
}

resource "aws_iam_user" "opencloudplay" {
  name = "opencloudplay-com-user"
}

resource "aws_iam_access_key" "opencloudplay" {
  user    = aws_iam_user.opencloudplay.name
}

resource "aws_iam_user_policy_attachment" "opencloudplay" {
  user       = aws_iam_user.opencloudplay.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# output "access_key_id" {
#   value     = aws_iam_access_key.opencloudplay.id
#   sensitive = true
# }

# output "secret_access_key" {
#   value     = aws_iam_access_key.opencloudplay.secret
#   sensitive = true
# }

resource "aws_instance" "opencloudplay" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = aws_key_pair.opencloudplay.key_name

  subnet_id              = aws_subnet.opencloudplay.id
  vpc_security_group_ids = [aws_security_group.allow_ssh_rdp.id]

  user_data = <<-EOF
    <powershell>
    # Install Chrome
    $Path = "$env:TEMP\brave_installer.exe"
    Invoke-WebRequest "https://referrals.brave.com/latest/BraveBrowserSetup-BRV011.exe" -OutFile $Path
    Start-Process -FilePath $Path -Args '/silent /install' -Wait
    Remove-Item $Path

    # Install Steam
    $Path = "$env:TEMP\steam_installer.exe"
    Invoke-WebRequest "https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe" -OutFile $Path
    Start-Process -FilePath $Path -Args '/S -NoNewWindow -Wait -PassThru' -Wait
    Remove-Item $Path



    # Attempt to enable audio - note, this may not fully enable remote audio playback
    Set-Service Audiosrv -StartupType Automatic
    Start-Service Audiosrv

    # Start Steam and run updates
    Start-Process -FilePath "C:\Program Files (x86)\Steam\Steam.exe"

    $desktopPath = [System.Environment]::GetFolderPath('Desktop')
    $parsecPath = Join-Path -Path $desktopPath -ChildPath 'parsec_installer.exe'
    Invoke-WebRequest "https://builds.parsec.app/package/parsec-windows.exe" -OutFile $parsecPath

    $env:AWS_ACCESS_KEY_ID = "${aws_iam_access_key.opencloudplay.id}"
    $env:AWS_SECRET_ACCESS_KEY = "${aws_iam_access_key.opencloudplay.secret}"

    $Bucket = "nvidia-gaming"
    $KeyPrefix = "windows/latest"
    $LocalPath = "$home\Desktop\NVIDIA"
    $Objects = Get-S3Object -BucketName $Bucket -KeyPrefix $KeyPrefix -Region us-east-1
    foreach ($Object in $Objects) {
        $LocalFileName = $Object.Key
        if ($LocalFileName -ne '' -and $Object.Size -ne 0) {
            $LocalFilePath = Join-Path $LocalPath $LocalFileName
            Copy-S3Object -BucketName $Bucket -Key $Object.Key -LocalFile $LocalFilePath -Region us-east-1
        }
    }

    $scriptPath = Join-Path -Path $desktopPath -ChildPath 'Nvidia-License.ps1'
    "New-ItemProperty -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global`" -Name `"vGamingMarketplace`" -PropertyType `"DWord`" -Value `"2`"" > $scriptPath
    Invoke-WebRequest -Uri "https://nvidia-gaming.s3.amazonaws.com/GridSwCert-Archive/GridSwCertWindows_2023_9_22.cert" -OutFile "$Env:PUBLIC\Documents\GridSwCert.txt"

    </powershell>
  EOF

  tags = {
    Name = "WindowsGPUDedicatedInstance"
  }
  depends_on = [aws_internet_gateway.opencloudplay, aws_key_pair.opencloudplay, aws_iam_user_policy_attachment.opencloudplay]
}

resource "time_sleep" "wait" {
  depends_on = [aws_instance.opencloudplay]
  create_duration = "60s"
}

resource "null_resource" "local" {
  provisioner "local-exec" {
    command = <<EOT
      echo '${tls_private_key.opencloudplay.private_key_pem}' > key.pem &&
      echo '${aws_iam_access_key.opencloudplay.id}  ${aws_iam_access_key.opencloudplay.secret}' > credentials &&
      echo username: Administrator password: $(aws ec2 get-password-data --instance-id ${aws_instance.opencloudplay.id} --priv-launch-key key.pem --query PasswordData --output text) > vm.txt &&
      echo ${aws_eip.opencloudplay.public_ip} >> vm.txt
    EOT
  }
  depends_on = [time_sleep.wait]
}