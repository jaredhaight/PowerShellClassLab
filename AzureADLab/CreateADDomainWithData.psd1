@{ 
    AllNodes = @( 
        @{ 
            Nodename = 'localhost'
            PSDscAllowDomainUser = $true
        }
    )o

    NonNodeData = @{

        UserData = Get-Content .\users.csv
        AdminData = Get-Content .\admins.csv

        RootOUs = 'Accounting','IT','Marketing','Operations','Class'
        ChildOUs = 'Users','Computers','Groups'
        TestObjCount = 5

    }
} 
