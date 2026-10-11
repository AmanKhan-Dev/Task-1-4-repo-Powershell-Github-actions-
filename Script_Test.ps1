Describe "Deployment Script Tests" {

    BeforeAll {
        # Step 1: Load the functions from our main script
        if (Test-Path "$PSScriptRoot\Script.ps1") {
            . "$PSScriptRoot\Script.ps1"
        }
        elseif (Test-Path "$PSScriptRoot\SetupScript.ps1") {
            . "$PSScriptRoot\SetupScript.ps1"
        }

        # Step 2: Set up temporary folders using Pester's TestDrive
        # TestDrive creates a safe isolated folder that cleans up automatically
        $script:TestFolder = Join-Path $TestDrive "TestDestination"
        $script:TestSource = Join-Path $TestDrive "TestSource"
        $script:TestTarget = Join-Path $TestDrive "TestTarget"
        $script:TestLog = Join-Path $TestDrive "test.log"
        $script:LogFile = $script:TestLog
        $script:TestRegKey = "HKCU:\Software\TraineeTestKey"

        # Step 3: Create a dummy source folder with a test file
        New-Item -ItemType Directory -Path $script:TestSource | Out-Null
        $sampleFile = Join-Path $script:TestSource "sample.txt"
        Set-Content -Path $sampleFile -Value "Hello World"
    }

    AfterAll {
        # Cleanup: Remove the test registry key from the machine
        if (Test-Path $script:TestRegKey) {
            Remove-Item -Path $script:TestRegKey -Recurse -Force
        }
    }

    # --------------------------------------------------------
    # 1. Folder Creation Tests
    # --------------------------------------------------------
    Context "Folder Creation" {

        It "creates the folder when it does not exist" {
            # Run the function
            $result = New-DestinationFolder -Path $script:TestFolder
            $result | Should Be $true

            # Verify that the folder actually exists on disk
            $folderExists = Test-Path -Path $script:TestFolder
            $folderExists | Should Be $true
        }

        It "returns true even if the folder already exists" {
            # Call it a second time with the same folder path
            $result = New-DestinationFolder -Path $script:TestFolder
            $result | Should Be $true
        }
    }

    # --------------------------------------------------------
    # 2. Registry Operations Tests
    # --------------------------------------------------------
    Context "Registry Operations" {

        It "creates a new registry key" {
            # Call function to create key with an initial version
            $result = New-RegistryEntry -Path $script:TestRegKey -Name "Version" -Value "1.0"
            $result | Should Be $true

            # Check if registry key path exists
            $keyExists = Test-Path -Path $script:TestRegKey
            $keyExists | Should Be $true
        }

        It "saves and updates the registry value" {
            # Update the value to 2.5
            New-RegistryEntry -Path $script:TestRegKey -Name "Version" -Value "2.5" | Out-Null

            # Read the value back from the registry to confirm
            $savedValue = Get-ItemPropertyValue -Path $script:TestRegKey -Name "Version"
            $savedValue | Should Be "2.5"
        }
    }

    # --------------------------------------------------------
    # 3. File Copy Tests
    # --------------------------------------------------------
    Context "File Copy Operations" {

        It "copies files from source folder to destination folder" {
            # Call the copy function
            $result = Copy-SourceFiles -From $script:TestSource -To $script:TestTarget
            $result | Should Be $true

            # Check if the copied file exists in the destination
            $copiedFilePath = Join-Path $script:TestTarget "sample.txt"
            $fileExists = Test-Path -Path $copiedFilePath
            $fileExists | Should Be $true
        }

        It "verifies that the copied file has the correct content" {
            # Read the copied file and verify its text
            $copiedFilePath = Join-Path $script:TestTarget "sample.txt"
            $fileContent = Get-Content -Path $copiedFilePath
            $fileContent | Should Be "Hello World"
        }
    }

    # --------------------------------------------------------
    # 4. Error Handling Tests (Negative Testing)
    # --------------------------------------------------------
    Context "Error Handling" {

        It "returns false when the source folder is missing" {
            $fakeSource = Join-Path $TestDrive "FolderDoesNotExist"
            $result = Copy-SourceFiles -From $fakeSource -To $script:TestTarget
            $result | Should Be $false
        }

        It "returns false when destination folder cannot be created" {
            # Windows cannot create a folder inside an existing text file
            $dummyFile = Join-Path $TestDrive "dummyfile.txt"
            Set-Content -Path $dummyFile -Value "dummy"
            $invalidFolder = Join-Path $dummyFile "subfolder"

            $result = New-DestinationFolder -Path $invalidFolder
            $result | Should Be $false
        }

        It "writes an ERROR entry to the log file on failure" {
            $fakeSource = Join-Path $TestDrive "FolderDoesNotExist"
            Copy-SourceFiles -From $fakeSource -To $script:TestTarget | Out-Null

            # Read log file and check if ERROR was logged
            $logContent = Get-Content -Path $script:TestLog -Raw
            $logContent | Should Match "ERROR"
        }
    }

    # --------------------------------------------------------
    # 5. Logging Tests
    # --------------------------------------------------------
    Context "Logging" {

        It "writes a test message to the log file" {
            Write-Log -Message "Test log entry from unit test"

            # Check that the message appears in the log file
            $logContent = Get-Content -Path $script:TestLog -Raw
            $logContent | Should Match "Test log entry from unit test"
        }
    }
}
