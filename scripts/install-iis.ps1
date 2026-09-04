# Instala o IIS e as ferramentas de gerenciamento no Windows Server.
# Execute em uma sessão elevada do PowerShell.

Install-WindowsFeature -Name Web-Server -IncludeManagementTools

# Exibe o estado da função após a instalação.
Get-WindowsFeature -Name Web-Server
